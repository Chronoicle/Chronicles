/*
 * Rebuild of the repack's closed-source "many_in_one_donate" Donate Vendor: a token shop browsed through gossip.
 *   Balance:    auth.account.donate (per game account)
 *   Catalogue:  auth.donate_categories, auth.donate_products  (edits apply on the next click)
 *   Items open in a real vendor window (prices shown as N gold = N tokens, charged in Player::BuyItemFromVendorSlot);
 *   everything else is bought through gossip with a confirmation popup.
 *   Purchases:  logged in auth.donate_history
 *   GM:         .donate add|take|balance <account> [amount]
 *   Players:    .donate morph use <productId> | .donate morph remove (morphs bought in the shop)
 *   The ChroniclesShop addon (donate_shop_addon below) sells the same catalogue in a shop window.
 *
 * Also rebuilds "multi_vendor", the Service manager: name/race/faction/appearance changes, level-ups,
 * gold and extra item bonuses for the same tokens. Services: auth.donate_services, level prices: auth.donate_level_prices.
 */

#include "ScriptMgr.h"
#include "QuestData.h"
#include "QuestDef.h"
#include "TemporarySummon.h"
#include "BattlegroundMgr.h"
#include <fstream>
#include "ScriptedGossip.h"
#include "AccountMgr.h"
#include "Chat.h"
#include "CollectionMgr.h"
#include "ChatPackets.h"
#include "Config.h"
#include "Creature.h"
#include "DatabaseEnv.h"
#include "DB2Stores.h"
#include "GameTables.h"
#include "Item.h"
#include "Log.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "SpellMgr.h"
#include "Util.h"
#include "World.h"
#include "WorldSession.h"
#include <algorithm>
#include <sstream>
#include <mutex>

enum DonateProductType : uint8
{
    PRODUCT_ITEM        = 0, // param1 = item entry, bonus = bonus list IDs separated by spaces, or "ilvl:N" for item level N (sold in the vendor window and the shop addon)
    PRODUCT_CURRENCY    = 1, // param1 = currency ID, param2 = amount
    PRODUCT_TITLE       = 2, // param1 = CharTitles ID
    PRODUCT_ACHIEVEMENT = 3, // param1 = achievement ID
    PRODUCT_SPELL       = 4, // param1 = spell ID (mounts, pets, illusions, ...)
    PRODUCT_LEVEL       = 5, // param1 = target level
    PRODUCT_GOLD        = 6, // param1 = gold
    PRODUCT_PREMIUM     = 7, // param1 = days of premium (auth.account_premium), extends a running premium
    PRODUCT_AT_LOGIN    = 8, // param1 = AtLoginFlags: 1 name, 8 appearance/gender, 64 faction, 128 race (used at the next login)
    // phase 3 (#64): the shop addon only (the Donate Vendor never lists type 9 and up)
    PRODUCT_MORPH          = 9,  // param1 = CreatureDisplayInfo ID: the account owns it (donate_owned), applied now and with .donate morph use
    PRODUCT_ARTIFACT_LEVEL = 10, // param1 = most levels per purchase, token = price per level (shop BUYN); Deliver's param1 = levels to add
    PRODUCT_BUNDLE         = 11, // param1 = bundle ID: the rows of auth.donate_bundle_items, all or nothing
    PRODUCT_QUEST          = 12, // param1 = quest ID, marked rewarded without its rewards (hidden artifact appearance unlocks)
    PRODUCT_PERK           = 13, // param1 = bonus list ID, param2 = group (one perk per group on an item): the shop's perks, kept in
                                 // a disabled category, read by PERKS/PERKADD/PERKDEL (the Service manager's perks, UWOW prices)
};

enum DonateBundlePart : uint8   // auth.donate_bundle_items.type: any product type above except bundles, and
{
    BUNDLE_GEARSET   = 100,     // the Gear Master's set of the character's spec (world.gear_npc_items); bonus "ilvl:N" or empty
    BUNDLE_ARTIFACTS = 101,     // every artifact weapon of the class the character doesn't have yet
};

enum DonateSender : uint32
{
    SENDER_MAIN     = 1,   // main menu (also refreshes the balance line)
    SENDER_BUY      = 2,   // action = product ID
    SENDER_VENDOR   = 3,   // action = category ID, opens its items in a vendor window
    SENDER_CATEGORY = 100, // + page number, action = category ID
};

constexpr uint32 PRODUCTS_PER_PAGE = 20;
constexpr uint32 DONATE_TEXT_ID = 60000; // repack's npc_text with the shop introduction (broadcast text 200000)
constexpr char const* BAGS_FULL = "Your bags are full. Free a bag slot first.";   // Deliver's error for items, nothing was given

static uint32 GetTokens(uint32 accountId)
{
    if (QueryResult result = LoginDatabase.PQuery("SELECT `donate` FROM `account` WHERE `id` = %u", accountId))
        return result->Fetch()[0].GetUInt32();
    return 0;
}

static uint32 FactionFilter(Player* player)
{
    return player->GetTeam() == ALLIANCE ? 1 : 2;
}

static std::vector<uint32> ParseBonuses(std::string const& bonus, uint32 itemId)
{
    std::vector<uint32> ids;
    std::istringstream in(bonus);
    for (std::string token; in >> token;)
    {
        // "ilvl:N": the bonus list that lifts this item to item level N, like the in-game shop did
        if (token.compare(0, 5, "ilvl:") == 0)
        {
            if (ItemTemplate const* proto = sObjectMgr->GetItemTemplate(itemId))
                if (uint32 id = sDB2Manager.GetItemBonusListForItemLevelDelta(int16(atoi(token.c_str() + 5) - int32(proto->GetBaseItemLevel()))))
                    ids.push_back(id);
        }
        else
            ids.push_back(uint32(atoi(token.c_str())));
    }
    return ids;
}

static void Notify(Player* player, std::string const& text)
{
    player->GetSession()->SendNotification("%s", text.c_str());
}

// Checks the balance and takes the tokens; returns false (and tells the player) if there aren't enough.
static bool TakeTokens(Player* player, uint32 price)
{
    uint32 accountId = player->GetSession()->GetAccountId();
    uint32 balance = GetTokens(accountId);
    if (balance < price)
    {
        Notify(player, "You do not have enough tokens: " + std::to_string(balance));
        return false;
    }
    LoginDatabase.DirectPExecute("UPDATE `account` SET `donate` = `donate` - %u WHERE `id` = %u", price, accountId);
    LoginDatabase.DirectPExecute("INSERT INTO `donate_history` (`account`, `char_guid`, `product`, `item`, `token`) VALUES (%u, %u, 0, 0, %u)",
        accountId, player->GetGUID().GetGUIDLow(), price);
    return true;
}

// the shop addon's products (and the new product types at the Donate Vendor): GM accounts only, unless Shop.OpenToPlayers = 1
static bool ShopOpenFor(Player* player)
{
    return AccountMgr::IsModeratorAccount(player->GetSession()->GetSecurity()) || sConfigMgr->GetBoolDefault("Shop.OpenToPlayers", false);
}

// the Donate Vendor sells titles, achievements, mounts/pets and character services only once the shop is open
// (the Service manager NPC sells the character services to everyone on its own); the phase 3 types only in the shop
static char const* VendorTypeFilter(Player* player)
{
    return ShopOpenFor(player) ? " AND `type` < 9" : " AND `type` NOT IN (2, 3, 4, 8) AND `type` < 9";
}

// Deliver's errors that the shop answers with their own FAIL code
constexpr char const* NO_ARTIFACT   = "You must have an artifact weapon equipped.";       // NOART
constexpr char const* ARTIFACT_MAX  = "Your artifact can't gain that many more levels.";  // LIMIT
constexpr char const* MORPH_UNKNOWN = "There is no morph with this number.";              // GONE

// the account owns a morph of this display (auth.donate_owned: bought per product, used per display)
static bool MorphOwned(uint32 accountId, uint32 display)
{
    return LoginDatabase.PQuery("SELECT 1 FROM `donate_owned` o JOIN `donate_products` p ON p.`id` = o.`product` WHERE o.`account` = %u AND p.`type` = %u AND p.`param1` = %u LIMIT 1",
        accountId, uint32(PRODUCT_MORPH), display) != nullptr;
}

// a morph as the native display, so shapeshifts and transforms end on it; 0 = the race's own look again
static void ApplyMorph(Player* player, uint32 display)
{
    if (display)
        player->SetNativeDisplayId(display);
    else
        player->InitDisplayIds();
    player->RestoreDisplayId();
}

// .donate morph use|remove and the shop's MORPH: an owned morph (productId 0 = remove it), kept for the next login in
// characters.character_morph; "" = done
static std::string UseMorph(Player* player, uint32 productId)
{
    uint32 display = 0;
    if (productId)
    {
        QueryResult result = LoginDatabase.PQuery("SELECT `param1` FROM `donate_products` WHERE `id` = %u AND `type` = %u", productId, uint32(PRODUCT_MORPH));
        if (!result)
            return MORPH_UNKNOWN;
        display = (*result)[0].GetUInt32();
        if (!sCreatureDisplayInfoStore.LookupEntry(display) || !MorphOwned(player->GetSession()->GetAccountId(), display))
            return "You don't own this morph. Buy it in the shop first.";
        CharacterDatabase.PExecute("REPLACE INTO `character_morph` (`guid`, `display`) VALUES (%u, %u)", player->GetGUIDLow(), display);
    }
    else
        CharacterDatabase.PExecute("DELETE FROM `character_morph` WHERE `guid` = %u", player->GetGUIDLow());
    ApplyMorph(player, display);
    return "";
}

// the equipped class artifact (not the fishing one), or null
static Item* ClassArtifact(Player* player)
{
    Item* artifact = player->GetArtifactWeapon();
    ArtifactEntry const* entry = artifact ? sArtifactStore.LookupEntry(artifact->GetTemplate()->GetArtifactID()) : nullptr;
    return entry && entry->ArtifactCategoryID == ARTIFACT_CATEGORY_CLASS ? artifact : nullptr;
}

// the artifact XP for `levels` more ranks than the artifact's unspent XP already pays for, at the forge's costs
// (ArtifactLevelXP: XP, XP2 after the artifact tier upgrade, like WorldSession::HandleArtifactAddPower); 0 = past the last rank
static uint64 ArtifactXpFor(Item* artifact, uint32 levels)
{
    bool upgraded = artifact->GetModifier(ITEM_MODIFIER_ARTIFACT_TIER) == 1;
    auto cost = [upgraded](uint32 rank) -> uint64
    {
        GtArtifactLevelXPEntry const* row = sArtifactLevelXPGameTable.GetRow(rank);
        return row ? uint64(upgraded ? row->XP2 : row->XP) : 0;
    };

    uint32 rank = artifact->GetTotalPurchasedArtifactPowers() + 1;   // the next rank to buy
    uint64 unspent = artifact->GetUInt64Value(ITEM_FIELD_ARTIFACT_XP);
    for (; cost(rank) && cost(rank) <= unspent; ++rank)
        unspent -= cost(rank);

    uint64 xp = 0;
    for (uint32 i = 0; i < levels; ++i, ++rank)
    {
        if (!cost(rank))
            return 0;
        xp += cost(rank);
    }
    return levels ? xp - unspent : 0;   // unspent < the cost of the first of them
}

static uint32 CountRows(char const* table, char const* where, uint32 category, uint32 faction)
{
    if (QueryResult result = LoginDatabase.PQuery("SELECT COUNT(*) FROM `%s` WHERE `%s` = %u AND `enable` = 1 AND `faction` IN (0, %u)", table, where, category, faction))
        return uint32(result->Fetch()[0].GetUInt64());
    return 0;
}

class many_in_one_donate : public CreatureScript
{
public:
    many_in_one_donate() : CreatureScript("many_in_one_donate") { }

    bool OnGossipHello(Player* player, Creature* creature) override
    {
        ShowCategory(player, creature, 0, 0);
        return true;
    }

    bool OnGossipSelect(Player* player, Creature* creature, uint32 sender, uint32 action) override
    {
        if (sender == SENDER_VENDOR)
            OpenVendor(player, creature, action);
        else if (sender == SENDER_BUY)
        {
            uint32 category = Buy(player, action);
            ShowCategory(player, creature, category, 0);
        }
        else if (sender >= SENDER_CATEGORY)
            ShowCategory(player, creature, action, sender - SENDER_CATEGORY);
        else
            ShowCategory(player, creature, 0, 0);
        return true;
    }

private:
    static void ShowCategory(Player* player, Creature* creature, uint32 category, uint32 page)
    {
        player->PlayerTalkClass->ClearMenus();
        uint32 faction = FactionFilter(player);

        // A category with only items (e.g. "985 ilevel" -> "Head") opens straight into the vendor window.
        uint32 itemCount = 0;
        if (QueryResult result = LoginDatabase.PQuery("SELECT COUNT(*) FROM `donate_products` WHERE `category` = %u AND `type` = %u AND `enable` = 1 AND `faction` IN (0, %u)", category, uint32(PRODUCT_ITEM), faction))
            itemCount = uint32(result->Fetch()[0].GetUInt64());
        if (category && itemCount && itemCount == CountRows("donate_products", "category", category, faction) && !CountRows("donate_categories", "parent", category, faction))
        {
            OpenVendor(player, creature, category);
            return;
        }

        if (!category)
            player->ADD_GOSSIP_ITEM(GossipOptionNpc::Vendor, "Your balance: \"" + std::to_string(GetTokens(player->GetSession()->GetAccountId())) + "\"", SENDER_MAIN, 0);

        if (QueryResult result = LoginDatabase.PQuery("SELECT `id`, `name` FROM `donate_categories` WHERE `parent` = %u AND `enable` = 1 AND `faction` IN (0, %u) ORDER BY `sort`, `id`", category, faction))
        {
            do
            {
                Field* f = result->Fetch();
                player->ADD_GOSSIP_ITEM(GossipOptionNpc::Vendor, f[1].GetString(), SENDER_CATEGORY, f[0].GetUInt32());
            } while (result->NextRow());
        }

        if (itemCount)
            player->ADD_GOSSIP_ITEM(GossipOptionNpc::Vendor, "Browse items", SENDER_VENDOR, category);

        bool morePages = false;
        if (QueryResult result = LoginDatabase.PQuery("SELECT `id`, `name`, `token` FROM `donate_products` WHERE `category` = %u AND `type` <> %u AND `enable` = 1 AND `faction` IN (0, %u)%s ORDER BY `sort`, `id` LIMIT %u OFFSET %u",
            category, uint32(PRODUCT_ITEM), faction, VendorTypeFilter(player), PRODUCTS_PER_PAGE + 1, page * PRODUCTS_PER_PAGE))
        {
            uint32 shown = 0;
            do
            {
                if (++shown > PRODUCTS_PER_PAGE)
                {
                    morePages = true;
                    break;
                }
                Field* f = result->Fetch();
                std::string name = f[1].GetString();
                std::string price = std::to_string(f[2].GetUInt32()) + " tokens";
                player->ADD_GOSSIP_ITEM_EXTENDED(GossipOptionNpc::None, name + " - " + price, SENDER_BUY, f[0].GetUInt32(), "Buy " + name + " for " + price + "?", 0, false);
            } while (result->NextRow());
        }

        if (page)
            player->ADD_GOSSIP_ITEM(GossipOptionNpc::None, "<< Previous page", SENDER_CATEGORY + page - 1, category);
        if (morePages)
            player->ADD_GOSSIP_ITEM(GossipOptionNpc::None, ">> Next page", SENDER_CATEGORY + page + 1, category);

        if (category)
        {
            uint32 parent = 0;
            if (QueryResult result = LoginDatabase.PQuery("SELECT `parent` FROM `donate_categories` WHERE `id` = %u", category))
                parent = result->Fetch()[0].GetUInt32();
            player->ADD_GOSSIP_ITEM(GossipOptionNpc::None, "Back", SENDER_CATEGORY, parent);
        }

        player->SEND_GOSSIP_MENU(DONATE_TEXT_ID, creature->GetGUID());
    }

    static void OpenVendor(Player* player, Creature* creature, uint32 category)
    {
        VendorItemData& items = player->ResetScriptedVendor(creature->GetGUID());
        if (QueryResult result = LoginDatabase.PQuery("SELECT `param1`, `bonus`, `token` FROM `donate_products` WHERE `category` = %u AND `type` = %u AND `enable` = 1 AND `faction` IN (0, %u) ORDER BY `sort`, `id` LIMIT %u",
            category, uint32(PRODUCT_ITEM), FactionFilter(player), uint32(MAX_VENDOR_ITEMS)))
        {
            do
            {
                Field* f = result->Fetch();
                items.AddItem(int32(f[0].GetUInt32()), 0, 0, 0, ITEM_VENDOR_TYPE_ITEM, uint64(f[2].GetUInt32()) * GOLD, 0, 0, ParseBonuses(f[1].GetString(), f[0].GetUInt32()));
            } while (result->NextRow());
        }

        player->CLOSE_GOSSIP_MENU();
        player->GetSession()->SendListInventory(creature->GetGUID());
    }

    // Returns the product's category, so the menu can go back to it.
    static uint32 Buy(Player* player, uint32 productId)
    {
        QueryResult result = LoginDatabase.PQuery("SELECT `name`, `type`, `param1`, `param2`, `token`, `category` FROM `donate_products` WHERE `id` = %u AND `enable` = 1 AND `type` <> %u%s", productId, uint32(PRODUCT_ITEM), VendorTypeFilter(player));
        if (!result)
            return 0;

        Field* f = result->Fetch();
        std::string name = f[0].GetString();
        uint8 type = f[1].GetUInt8();
        uint32 param1 = f[2].GetUInt32();
        uint32 param2 = f[3].GetUInt32();
        uint32 price = f[4].GetUInt32();
        uint32 category = f[5].GetUInt32();

        uint32 accountId = player->GetSession()->GetAccountId();
        uint32 balance = GetTokens(accountId);
        if (balance < price)
        {
            Notify(player, "Not enough tokens. Your balance: " + std::to_string(balance));
            return category;
        }

        // ponytail: deliver first, then charge; one account has one session, so no double-spend race
        std::string error = Deliver(player, type, param1, param2);
        if (!error.empty())
        {
            Notify(player, error);
            return category;
        }

        LoginDatabase.DirectPExecute("UPDATE `account` SET `donate` = `donate` - %u WHERE `id` = %u", price, accountId);
        LoginDatabase.DirectPExecute("INSERT INTO `donate_history` (`account`, `char_guid`, `product`, `item`, `token`) VALUES (%u, %u, %u, 0, %u)",
            accountId, player->GetGUID().GetGUIDLow(), productId, price);
        Notify(player, "You bought " + name + ". Balance: " + std::to_string(balance - price));
        return category;
    }

    // bought with donate tokens: refundable at the refund NPC (item_back reads every type; 2 = shop addon).
    // ponytail: not stackables, whose row would point at the merged stack; refund by count if they get sold
    static void RecordRefund(Player* player, Item* item, uint32 price)
    {
        if (price && item->GetMaxStackCount() == 1)   // bundle items come with price 0: not refundable one by one
            CharacterDatabase.PExecute("REPLACE INTO character_donate (owner_guid, itemguid, type, itemEntry, efircount, count, account) VALUES (%u, %u, 2, %u, %u, 1, %u)",
                player->GetGUIDLow(), item->GetGUIDLow(), item->GetEntry(), price, player->GetSession()->GetAccountId());
    }

    // the shop addon's delivery when the bags are full: the same item (built like Player::StoreNewItem does) by mail
    static std::string MailItem(Player* player, uint32 itemId, std::string const& bonus, uint32 price)
    {
        Item* item = Item::CreateItem(itemId, 1, player);
        if (!item)
            return "The item could not be created";
        item->SetItemRandomProperties(Item::GenerateItemRandomPropertyId(itemId, player->GetLootSpecID()));
        if (uint32 upgradeID = sDB2Manager.GetRulesetItemUpgrade(itemId))
            item->SetModifier(ITEM_MODIFIER_UPGRADE_ID, upgradeID);
        for (uint32 bonusListId : ParseBonuses(bonus, itemId))
            item->AddBonuses(bonusListId);
        item->SetFixedLevel(player->getLevel());
        RecordRefund(player, item, price);   // before the mail takes the item

        CharacterDatabaseTransaction trans = CharacterDatabase.BeginTransaction();
        item->RemoveFromUpdateQueueOf(player);   // a random property queued it for the player's save; the mail owns it now
        item->SaveToDB(trans);
        // from the player himself and marked returned, like battlepay_services: the client offers Delete, not Return
        // (a return to a missing sender would delete the item), and nothing can be sent back to anyone
        MailDraft("Chronicles Shop", "Your bags were full, so the shop sent your purchase by mail. Take it out within 30 days: "
            "mail left longer is deleted with the item.").AddItem(item)
            .SendMailTo(trans, MailReceiver(player), MailSender(player, MAIL_STATIONERY_GM), MailCheckMask(MAIL_CHECK_MASK_COPIED | MAIL_CHECK_MASK_RETURNED));
        CharacterDatabase.CommitTransaction(trans);
        return "";
    }

public:
    // Returns an empty string on success, otherwise the reason it failed (nothing was given).
    // bonus and price are only used for items (the shop addon; the Donate Vendor sells items in its vendor window).
    // With mailed (the shop addon), an item that doesn't fit in the bags is mailed and *mailed is set.
    static std::string Deliver(Player* player, uint8 type, uint32 param1, uint32 param2, std::string const& bonus = "", uint32 price = 0, bool* mailed = nullptr)
    {
        switch (type)
        {
            case PRODUCT_ITEM:
            {
                if (!sObjectMgr->GetItemTemplate(param1))
                    return "Item not found";
                ItemPosCountVec dest;
                InventoryResult canStore = player->CanStoreNewItem(NULL_BAG, NULL_SLOT, dest, param1, 1);
                // heirlooms are not mailed: the collection only learns them from the bags (Player::StoreNewItem)
                if (canStore == EQUIP_ERR_INV_FULL && mailed && !sDB2Manager.GetHeirloomByItemId(param1))
                {
                    std::string error = MailItem(player, param1, bonus, price);
                    *mailed = error.empty();
                    return error;
                }
                if (canStore == EQUIP_ERR_INV_FULL)
                    return BAGS_FULL;
                if (canStore != EQUIP_ERR_OK)
                    return "You already have as many of this item as you can carry";
                Item* item = player->StoreNewItem(dest, param1, true, Item::GenerateItemRandomPropertyId(param1, player->GetLootSpecID()), GuidSet(), ParseBonuses(bonus, param1));
                if (!item)
                    return "The item could not be created";
                player->SendNewItem(item, 1, true, false);
                RecordRefund(player, item, price);
                return "";
            }
            case PRODUCT_CURRENCY:
                if (!sCurrencyTypesStore.LookupEntry(param1))
                    return "Currency not found";
                player->ModifyCurrency(param1, int32(std::max<uint32>(param2, 1)), true);
                return "";
            case PRODUCT_TITLE:
            {
                CharTitlesEntry const* title = sCharTitlesStore.LookupEntry(param1);
                if (!title)
                    return "Title not found";
                if (player->HasTitle(title))
                    return "You already have this title";
                player->SetTitle(title);
                return "";
            }
            case PRODUCT_ACHIEVEMENT:
            {
                AchievementEntry const* achievement = sAchievementStore.LookupEntry(param1);
                if (!achievement)
                    return "Achievement not found";
                if (player->HasAchieved(param1))
                    return "You already have this achievement";
                player->CompletedAchievement(achievement);
                if (!player->HasAchieved(param1))   // AchievementMgr does nothing for a GM in GM mode
                    return "Turn GM mode off first (.gm off)";
                return "";
            }
            case PRODUCT_SPELL:
                if (!sSpellMgr->GetSpellInfo(param1))
                    return "Spell not found";
                if (player->HasSpell(param1))
                    return "You already know this spell";
                player->learnSpell(param1, false);
                return "";
            case PRODUCT_LEVEL:
                if (param1 > 255 || player->getLevel() >= param1)
                    return "Your level is already this high";
                player->GiveLevel(uint8(param1));
                return "";
            case PRODUCT_GOLD:
                if (!player->ModifyMoney(int64(param1) * GOLD))
                    return "You can't carry that much gold";
                return "";
            case PRODUCT_PREMIUM:
            {
                // same as the shop's battlepay_premium: extends a running premium, otherwise starts now
                WorldSession* session = player->GetSession();
                uint32 expires = std::max(uint32(time(nullptr)), session->GetPremiumExpires()) + param1 * DAY;
                LoginDatabase.PExecute("REPLACE INTO account_premium (account_id, expires) VALUES (%u, %u)", session->GetAccountId(), expires);
                session->SetPremiumExpires(expires);
                ChatHandler(session).PSendSysMessage("Premium activated: %u days added. Type .prem to open the premium menu.", param1);
                return "";
            }
            case PRODUCT_AT_LOGIN:   // like the Service manager's SERVICE_AT_LOGIN
            {
                AtLoginFlags flag = AtLoginFlags(param1);
                if (flag != AT_LOGIN_RENAME && flag != AT_LOGIN_CUSTOMIZE && flag != AT_LOGIN_CHANGE_FACTION && flag != AT_LOGIN_CHANGE_RACE)
                    return "This product is not set up correctly";
                if (player->HasAtLoginFlag(flag))
                    return "You have already purchased this service";
                player->SetAtLoginFlag(flag);
                ChatHandler(player->GetSession()).SendSysMessage("Done! Log out to the character screen to use it.");
                return "";
            }
            case PRODUCT_MORPH:     // the account owns it from now on (the first product with this display), worn right away
            {
                QueryResult result = LoginDatabase.PQuery("SELECT `id` FROM `donate_products` WHERE `type` = %u AND `param1` = %u ORDER BY `id` LIMIT 1", uint32(PRODUCT_MORPH), param1);
                if (!result || !sCreatureDisplayInfoStore.LookupEntry(param1))
                    return "Morph not found";
                uint32 accountId = player->GetSession()->GetAccountId();
                if (MorphOwned(accountId, param1))
                    return "You already own this morph";
                uint32 productId = (*result)[0].GetUInt32();
                LoginDatabase.DirectPExecute("INSERT IGNORE INTO `donate_owned` (`account`, `product`) VALUES (%u, %u)", accountId, productId);
                UseMorph(player, productId);
                // players have dot commands only with AllowPlayerCommands = 1
                if (sWorld->getBoolConfig(CONFIG_ALLOW_PLAYER_COMMANDS) || !AccountMgr::IsPlayerAccount(player->GetSession()->GetSecurity()))
                    ChatHandler(player->GetSession()).PSendSysMessage("You can use your morph with the macro: .donate morph use %u (to remove a morph, write .donate morph remove)", productId);
                else
                    ChatHandler(player->GetSession()).SendSysMessage("You can put your morph on and take it off in the shop's Morphs category.");
                return "";
            }
            case PRODUCT_ARTIFACT_LEVEL:    // param1 = levels (the shop's BUYN count)
            {
                Item* artifact = ClassArtifact(player);
                if (!artifact)
                    return NO_ARTIFACT;
                uint64 xp = ArtifactXpFor(artifact, param1);
                if (!xp)
                    return ARTIFACT_MAX;
                artifact->GiveArtifactXp(xp, nullptr, 0);
                ChatHandler(player->GetSession()).PSendSysMessage("Artifact power for %u more ranks added: spend it at your artifact forge.", param1);
                return "";
            }
            case PRODUCT_QUEST:     // rewarded like a tracking quest done by a spell (Spell::EffectQuestComplete): no quest rewards
            {
                Quest const* quest = sQuestDataStore->GetQuestTemplate(param1);
                if (!quest || quest->IsRepeatable() || quest->IsDaily() || quest->IsWeekly())
                    return "This product is not set up correctly";
                if (player->IsQuestRewarded(param1))
                    return "You already have this";
                if (player->FindQuestSlot(param1) < MAX_QUEST_LOG_SIZE)
                    return "Finish or abandon this quest in your quest log first";
                player->SetRewardedQuest(param1);
                player->SetQuestCompletedBit(sDB2Manager.GetQuestUniqueBitFlag(param1), true);
                return "";
            }
            default:
                return "This product is not set up correctly";
        }
    }
};

// ChroniclesShop addon (#64): the shop window from the micro menu Shop button and /shop. Same catalogue, balance and
// delivery as the Donate Vendor; the server checks everything. The core passes prefix "SHOP" addon messages here as
// "SHOP:<text>" and never forwards them; replies are addon whispers to the player himself (space separated, the name last).
//   client -> server: OPEN | LIST <categoryId> [ilvl] | BUY <productId> <shownPrice> <reqId> [ilvl]
//                     | BUYN <productId> <count> <shownTotal> <reqId> (type 10: count 1..param1, shownTotal = count * price)
//                     | MORPH <productId> <reqId> (use an owned morph) | MORPH 0 <reqId> (remove it)
//                     | PERKS <bag> <slot> | PERKADD <bag> <slot> <perkId> <shownPrice> <reqId> | PERKDEL <bag> <slot> <perkId> <reqId> (free)
//   server -> client: CLOSED | BAL <tokens> | CAT <id> <parentId> <order> #<flags> <name> ... CEND
//                     | ITEM <productId> <type> <param1> <price> <ilvl> <bonuses> #<flags> <display> <name> ...
//                       [ILV <categoryId> <current> <ilvl>,<ilvl>,...] LEND <categoryId> <count>
//                     | PERK <perkId> <price> <has> #<flags> <name> ... PEND <bag> <slot> <itemEntry>
//                     | OK <reqId> <productId|perkId> <tokens> [MAIL]
//                     | FAIL <reqId> NOFUNDS|GONE|PRICE|BAGS|OWNED|BUSY|CLOSED|FAILED|NOART|NOITEM|LIMIT <tokens> | ERR <text>
//   flags: SHOP_KNOWN (ITEM only), SHOP_NEW (CAT: a new product in it or below it); display = creature display of a
//   mount, pet or morph product for the 3D preview (0 = none); MAIL = the bags were full, the item went to the mailbox.
//   Item levels (v3): an item product with "ilvl:N" in its bonus, N a row of auth.donate_ilvl_prices, is sold at every
//   item level of that table for token * percent(ilvl) / percent(N). LIST with an ilvl lists them at it (an ilvl not in
//   the table: their own N), BUY with an ilvl buys at it (not in the table: FAIL PRICE); ILV: current = the item level
//   they are listed at, then the table's item levels, highest first. Other products ignore the ilvl.
//   Perks (v3): bag 0 = backpack, 1-4 = the bags, slot from 1 (the addon's numbers); only equipment in the bags.
//   PERK flags: PERK_BLOCKED = can't be added to this item (legendary/artifact, or another perk of its group is on it);
//   has = 1/0; PEND itemEntry 0 = no equipment item there. NOART = no class artifact equipped, NOITEM = the perk item is
//   gone, LIMIT = count out of range or past the artifact's last rank.
// GM accounts only, unless Shop.OpenToPlayers = 1 in worldserver.conf.
constexpr std::size_t SHOP_MAX_MESSAGE = 250;   // bytes per addon message
constexpr uint32 SHOP_MAX_REQUESTS     = 10;    // per second, the rest is dropped (every request runs auth queries on the player's map thread)
constexpr uint32 SHOP_MAX_REQ_ID       = 999999;
constexpr char const* SHOP_IS_NEW      = "`added` > NOW() - INTERVAL 14 DAY";   // donate_products.added (fix_shop_new_flag_64.sql)

enum ShopFlags : uint32
{
    SHOP_KNOWN = 1,     // the character has it already ("Already Known", no Buy button)
    SHOP_NEW   = 2,     // added to the shop in the last 14 days
    PERK_BLOCKED = 1,   // PERK: can't be added to this item
};

struct ShopThrottle
{
    uint32 WindowStart = 0;
    uint32 Requests = 0;
    uint32 LastBuy = 0;
    uint32 Tokens = 0;      // last balance read, for FAIL BUSY without a query
};

static std::unordered_map<ObjectGuid, ShopThrottle> ShopThrottles;
static std::mutex ShopThrottlesLock;   // OnChat and OnLogout run on the map threads; only the lookup and the erase need it (the
                                       // nodes never move, and each one is only used by its own session)

// the category and all its parents enabled and for this faction: a typed LIST or BUY can't reach what OPEN hides
static bool ShopCategoryOpen(uint32 category, uint32 faction)
{
    for (uint32 depth = 0; category && depth < 10; ++depth)
    {
        QueryResult result = LoginDatabase.PQuery("SELECT `parent` FROM `donate_categories` WHERE `id` = %u AND `enable` = 1 AND `faction` IN (0, %u)", category, faction);
        if (!result)
            return false;
        category = (*result)[0].GetUInt32();
    }
    return !category;
}

static void SendShop(Player* player, std::string text)
{
    if (text.size() > SHOP_MAX_MESSAGE)   // cut at a UTF-8 character boundary
    {
        text.resize(SHOP_MAX_MESSAGE);
        while (!text.empty() && (uint8(text.back()) & 0xC0) == 0x80)
            text.pop_back();
        if (!text.empty() && uint8(text.back()) >= 0xC0)
            text.pop_back();
    }
    // like premium_menu's SendAddon: Player::WhisperAddon leaves the prefix out
    WorldPackets::Chat::Chat packet;
    packet.Initialize(CHAT_MSG_WHISPER, LANG_ADDON, player, player, text, 0, "", DEFAULT_LOCALE, "SHOP");
    player->SendDirectMessage(packet.Write());
}

// a name as the last field of a message: no UI escape codes or line breaks
static std::string ShopName(std::string name)
{
    name.erase(std::remove_if(name.begin(), name.end(), [](char c) { return c == '|' || c == '\n' || c == '\r'; }), name.end());
    return name;
}

// enable and faction are checked in SQL; items only for the character's class and race and its own armour type
// (the item checks of BattlepayManager::ProductFilter)
static bool ShopVisible(Player* player, uint8 type, uint32 param1)
{
    if (type != PRODUCT_ITEM)
        return true;

    ItemTemplate const* proto = sObjectMgr->GetItemTemplate(param1);
    if (!proto)
        return false;
    if (proto->AllowableClass && (proto->AllowableClass & player->getClassMask()) == 0)
        return false;
    if (proto->AllowableRace && (proto->AllowableRace & player->getRaceMask()) == 0)
        return false;

    if (proto->GetClass() == ITEM_CLASS_WEAPON || proto->GetClass() == ITEM_CLASS_ARMOR)
    {
        if (player->CanUseItem(proto) != EQUIP_ERR_OK)
            return false;

        if (proto->GetClass() == ITEM_CLASS_ARMOR && proto->GetInventoryType() != INVTYPE_CLOAK
            && proto->GetSubClass() >= ITEM_SUBCLASS_ARMOR_CLOTH && proto->GetSubClass() <= ITEM_SUBCLASS_ARMOR_PLATE)
        {
            uint32 armor = player->HasSkill(SKILL_PLATE_MAIL) ? ITEM_SUBCLASS_ARMOR_PLATE
                : player->HasSkill(SKILL_MAIL) ? ITEM_SUBCLASS_ARMOR_MAIL
                : player->HasSkill(SKILL_LEATHER) ? ITEM_SUBCLASS_ARMOR_LEATHER : ITEM_SUBCLASS_ARMOR_CLOTH;
            if (proto->GetSubClass() != armor)
                return false;
        }
    }
    return true;
}

// the spell a mount or pet product teaches: the spell product itself, or the learn spell of an item (mount, pet and recipe items)
static uint32 ShopTaughtSpell(uint8 type, uint32 param1)
{
    if (type == PRODUCT_SPELL)
        return param1;
    if (type == PRODUCT_ITEM)
        if (ItemTemplate const* proto = sObjectMgr->GetItemTemplate(param1))
            for (ItemEffectEntry const* effect : proto->Effects)
                if (effect->TriggerType == ITEM_SPELLTRIGGER_LEARN_SPELL_ID && effect->SpellID > 0)
                    return uint32(effect->SpellID);
    return 0;
}

// the character has this already: the addon shows "Already Known" (Deliver still checks titles, achievements, spells, services)
static bool ShopKnown(Player* player, uint8 type, uint32 param1)
{
    switch (type)
    {
        case PRODUCT_TITLE:
        {
            CharTitlesEntry const* title = sCharTitlesStore.LookupEntry(param1);
            return title && player->HasTitle(title);
        }
        case PRODUCT_ACHIEVEMENT:
            return player->HasAchieved(param1);
        case PRODUCT_LEVEL:
            return player->getLevel() >= param1;
        case PRODUCT_AT_LOGIN:
            return player->HasAtLoginFlag(AtLoginFlags(param1));
        case PRODUCT_MORPH:
            return MorphOwned(player->GetSession()->GetAccountId(), param1);
        case PRODUCT_QUEST:
            return player->IsQuestRewarded(param1);
        case PRODUCT_ITEM:
            if (player->GetCollectionMgr()->HasToy(param1) || player->GetCollectionMgr()->HasHeirloom(param1))
                return true;
            // fallthrough: mount, pet and recipe items
        case PRODUCT_SPELL:
        {
            uint32 spell = ShopTaughtSpell(type, param1);
            if (!spell)
                return false;
            if (BattlePetSpeciesEntry const* species = sDB2Manager.GetSpeciesBySpell(spell))
                return player->GetBattlePetCountForSpecies(species->ID) > 0;
            return player->HasSpell(spell);
        }
        default:
            return false;
    }
}

// the creature display of a mount, pet or morph product, for the addon's 3D preview (0 = none)
static uint32 ShopDisplay(uint8 type, uint32 param1)
{
    if (type == PRODUCT_MORPH)
        return param1;
    uint32 spell = ShopTaughtSpell(type, param1);
    if (!spell)
        return 0;
    if (MountEntry const* mount = sDB2Manager.GetMount(spell))
        if (auto const* displays = sDB2Manager.GetMountDisplays(mount->ID))
            if (!displays->empty())
                return uint32(displays->front()->CreatureDisplayInfoID);
    if (BattlePetSpeciesEntry const* species = sDB2Manager.GetSpeciesBySpell(spell))
        if (CreatureTemplate const* creature = sObjectMgr->GetCreatureTemplate(species->CreatureID))
            return creature->GetFirstVisibleModel();
    return 0;
}

// auth.donate_ilvl_prices: item level -> percent of the price (985 = 100)
static std::map<uint32, uint32> ShopItemLevelPrices()
{
    std::map<uint32, uint32> percents;
    if (QueryResult result = LoginDatabase.Query("SELECT `ilvl`, `percent` FROM `donate_ilvl_prices`"))
    {
        do
        {
            Field* f = result->Fetch();
            percents[f[0].GetUInt32()] = f[1].GetUInt32();
        } while (result->NextRow());
    }
    return percents;
}

// an item product at item level ilvl (a row of donate_ilvl_prices; others leave it as it is): its "ilvl:N" and its price
// follow it. Returns the item level it is sold at, 0 = not sold by item level (no "ilvl:N" with N in the table).
static uint32 ShopAtItemLevel(std::map<uint32, uint32> const& percents, uint32 ilvl, std::string& bonus, uint32& price)
{
    std::size_t at = bonus.find("ilvl:");
    if (at == std::string::npos)
        return 0;
    auto own = percents.find(uint32(atoi(bonus.c_str() + at + 5)));
    if (own == percents.end() || !own->second)
        return 0;
    auto wanted = percents.find(ilvl);
    if (wanted == percents.end())
        return own->first;

    std::size_t end = bonus.find(' ', at);
    bonus.replace(at, end == std::string::npos ? std::string::npos : end - at, "ilvl:" + std::to_string(ilvl));
    price = uint32(uint64(price) * wanted->second / own->second);
    return ilvl;
}

// one thing a bundle gives, after BUNDLE_GEARSET / BUNDLE_ARTIFACTS are turned into their items
struct ShopPart
{
    uint8 Type;
    uint32 Param1;
    uint32 Param2;
    std::string Bonus;
};

// BUNDLE_GEARSET: the Gear Master's set (world.gear_npc_items, fill_character export) of the character's spec, or of the
// class's default spec if the character's has none; without the artifact rows and legendaries (sold on their own), and
// without the items the character has already. bonus "ilvl:N" = every piece at item level N, empty = the rows' own
// bonuses (985 with tertiary stats and sockets).
static void ShopGearParts(Player* player, std::string const& bonus, std::vector<ShopPart>& parts)
{
    char const* query = "SELECT `item`, `bonus` FROM `gear_npc_items` WHERE `spec` = %u AND `slot` NOT LIKE 'artifact%%' ORDER BY `slot`";
    QueryResult result = WorldDatabase.PQuery(query, player->GetSpecializationId());
    ChrSpecializationEntry const* spec = result ? nullptr : sDB2Manager.GetDefaultChrSpecializationForClass(player->getClass());
    if (spec)
        result = WorldDatabase.PQuery(query, spec->ID);
    if (!result)
        return;
    do
    {
        Field* f = result->Fetch();
        uint32 item = f[0].GetUInt32();
        ItemTemplate const* proto = sObjectMgr->GetItemTemplate(item);
        if (!proto || proto->GetQuality() >= ITEM_QUALITY_LEGENDARY || player->HasItemCount(item, 1, true))
            continue;
        parts.push_back({ uint8(PRODUCT_ITEM), item, 1, bonus.empty() ? f[1].GetString() : bonus });
    } while (result->NextRow());
}

// BUNDLE_ARTIFACTS: the artifact rows of gear_npc_items for every spec of the class (with the off-hand parts), the ones
// the character doesn't have yet (bags and bank)
static void ShopArtifactParts(Player* player, std::vector<ShopPart>& parts)
{
    std::string specs;
    for (uint32 i = 0; i < MAX_SPECIALIZATIONS; ++i)
        if (ChrSpecializationEntry const* spec = sDB2Manager.GetChrSpecializationByIndex(player->getClass(), i))
            specs += (specs.empty() ? "" : ",") + std::to_string(spec->ID);
    if (specs.empty())
        return;

    std::set<uint32> added;
    if (QueryResult result = WorldDatabase.PQuery("SELECT `item` FROM `gear_npc_items` WHERE `slot` LIKE 'artifact%%' AND `spec` IN (%s) ORDER BY `spec`, `slot`", specs.c_str()))
    {
        do
        {
            uint32 item = result->Fetch()[0].GetUInt32();
            if (added.insert(item).second && !player->HasItemCount(item, 1, true))
                parts.push_back({ uint8(PRODUCT_ITEM), item, 1, "" });
        } while (result->NextRow());
    }
}

// why a bundle part can't be delivered ("" = it can): what Deliver would refuse, checked before anything is given
static std::string ShopPartError(Player* player, ShopPart const& part)
{
    switch (part.Type)
    {
        case PRODUCT_ITEM:
        {
            if (!sObjectMgr->GetItemTemplate(part.Param1))
                return "Item not found";
            ItemPosCountVec dest;
            InventoryResult canStore = player->CanStoreNewItem(NULL_BAG, NULL_SLOT, dest, part.Param1, 1);
            if (canStore == EQUIP_ERR_OK || (canStore == EQUIP_ERR_INV_FULL && !sDB2Manager.GetHeirloomByItemId(part.Param1)))   // or mailed
                return "";
            return canStore == EQUIP_ERR_INV_FULL ? BAGS_FULL : "You already have as many of an item in this bundle as you can carry";
        }
        case PRODUCT_CURRENCY:
            return sCurrencyTypesStore.LookupEntry(part.Param1) ? "" : "Currency not found";
        case PRODUCT_GOLD:
            return player->GetMoney() + uint64(part.Param1) * GOLD > MAX_MONEY_AMOUNT ? "You can't carry that much gold" : "";
        case PRODUCT_PREMIUM:
            return "";
        case PRODUCT_LEVEL:
            if (player->InBattleground() || player->InArena() || player->GetMap()->IsDungeon())
                return "Levels can't be bought in a battleground, arena or dungeon.";
            return player->getLevel() >= part.Param1 ? "Your level is already this high" : "";
        case PRODUCT_ARTIFACT_LEVEL:
        {
            Item* artifact = ClassArtifact(player);
            return !artifact ? NO_ARTIFACT : !ArtifactXpFor(artifact, part.Param1) ? ARTIFACT_MAX : "";
        }
        case PRODUCT_QUEST:
            if (player->FindQuestSlot(part.Param1) < MAX_QUEST_LOG_SIZE)
                return "Finish or abandon the bundle's quest in your quest log first";
            // fallthrough
        case PRODUCT_TITLE:
        case PRODUCT_ACHIEVEMENT:
        case PRODUCT_SPELL:
        case PRODUCT_AT_LOGIN:
        case PRODUCT_MORPH:
            return ShopKnown(player, part.Type, part.Param1) ? "You already have something in this bundle" : "";
        default:    // bundles in bundles too
            return "This product is not set up correctly";
    }
}

// PRODUCT_BUNDLE: every row of auth.donate_bundle_items in sort order through Deliver, all of them checked first;
// "" = delivered. Items are not refundable one by one (price 0); *mailed = at least one went to the mailbox.
static std::string DeliverBundle(Player* player, uint32 bundleId, bool* mailed)
{
    std::vector<ShopPart> parts;
    QueryResult result = LoginDatabase.PQuery("SELECT `type`, `param1`, `param2`, `bonus` FROM `donate_bundle_items` WHERE `bundle` = %u ORDER BY `sort`", bundleId);
    if (!result)
        return "This product is not set up correctly";
    do
    {
        Field* f = result->Fetch();
        uint8 type = f[0].GetUInt8();
        if (type == BUNDLE_GEARSET)
            ShopGearParts(player, f[3].GetString(), parts);
        else if (type == BUNDLE_ARTIFACTS)
            ShopArtifactParts(player, parts);
        else
            parts.push_back({ type, f[1].GetUInt32(), f[2].GetUInt32(), f[3].GetString() });
    } while (result->NextRow());

    if (parts.empty())
        return "You already have everything in this bundle";
    for (ShopPart const& part : parts)
    {
        std::string error = ShopPartError(player, part);
        if (!error.empty())
            return error;
    }

    for (ShopPart const& part : parts)
    {
        bool partMailed = false;
        std::string error = many_in_one_donate::Deliver(player, part.Type, part.Param1, part.Param2, part.Bonus, 0, &partMailed);
        *mailed = *mailed || partMailed;
        if (!error.empty())     // missed by the checks above: the rest is still given and the bundle charged, a GM makes it up
        {
            TC_LOG_ERROR("server.shop", "Shop bundle %u: part type %u param1 %u not delivered to %s (guid %u, account %u): %s",
                bundleId, uint32(part.Type), part.Param1, player->GetName(), player->GetGUIDLow(), player->GetSession()->GetAccountId(), error.c_str());
            ChatHandler(player->GetSession()).PSendSysMessage("Part of the bundle could not be delivered (%s). Please tell a GM.", error.c_str());
        }
    }
    return "";
}

// Perks (#64): an extra bonus list (tertiary stat, prismatic socket) on an item, sold by the Service manager
// (donate_services type 4, the item in the first backpack slot) and the shop (donate_products type 13, PERKADD)
static bool ItemHasBonus(Item* item, uint32 bonusId)
{
    std::vector<uint32> const& bonuses = item->GetDynamicValues(ITEM_DYNAMIC_FIELD_BONUS_LIST_IDS);
    return std::find(bonuses.begin(), bonuses.end(), bonusId) != bonuses.end();
}

// why the perk can't be added to the item ("" = it can); group = the bonus IDs of the other perks of its group
static std::string PerkError(Item* item, uint32 bonusId, std::vector<uint32> const& group)
{
    // the item loader (ObjectMgr::DeleteBugBonus) strips sockets and tertiary stats from legendary and artifact items
    if (item->GetTemplate()->GetQuality() >= ITEM_QUALITY_LEGENDARY && (bonusId == 1808 || (bonusId >= 40 && bonusId <= 42)))
        return "Legendary and artifact items can't get this bonus.";
    if (ItemHasBonus(item, bonusId))
        return "You already have this bonus!";
    for (uint32 other : group)
        if (ItemHasBonus(item, other))
            return "You already have another similar bonus!";
    return "";
}

static void AddPerk(Player* player, Item* item, uint32 bonusId)
{
    item->AddBonuses(bonusId);
    item->SetState(ITEM_CHANGED, player);
}

static void RemovePerk(Player* player, Item* item, uint32 bonusId)
{
    // ponytail: the item's cached stats only rebuild from the database, hence the relog
    item->RemoveDynamicValue(ITEM_DYNAMIC_FIELD_BONUS_LIST_IDS, bonusId);
    item->SetState(ITEM_CHANGED, player);
}

struct ShopPerk
{
    uint32 Id;
    uint32 Bonus;
    uint32 Group;
    uint32 Price;
    std::string Name;
};

static std::vector<ShopPerk> ShopPerkList(Player* player)
{
    std::vector<ShopPerk> perks;
    if (QueryResult result = LoginDatabase.PQuery("SELECT `id`, `param1`, `param2`, `token`, `name` FROM `donate_products` WHERE `type` = %u AND `enable` = 1 AND `faction` IN (0, %u) ORDER BY `sort`, `id`",
        uint32(PRODUCT_PERK), FactionFilter(player)))
    {
        do
        {
            Field* f = result->Fetch();
            perks.push_back({ f[0].GetUInt32(), f[1].GetUInt32(), f[2].GetUInt32(), f[3].GetUInt32(), f[4].GetString() });
        } while (result->NextRow());
    }
    return perks;
}

static std::vector<uint32> ShopPerkGroup(std::vector<ShopPerk> const& perks, ShopPerk const& perk)
{
    std::vector<uint32> group;
    if (perk.Group)
        for (ShopPerk const& other : perks)
            if (other.Group == perk.Group && other.Id != perk.Id)
                group.push_back(other.Bonus);
    return group;
}

// an equipment item in the bags by the addon's numbers (bag 0 = backpack, 1-4 = the bags, slot from 1), or null
static Item* ShopBagItem(Player* player, uint32 bag, uint32 slot)
{
    if (bag > 4 || slot < 1 || slot > 255)
        return nullptr;
    Item* item = nullptr;
    if (bag == 0)
    {
        if (INVENTORY_SLOT_ITEM_START + slot - 1 < INVENTORY_SLOT_ITEM_END)
            item = player->GetItemByPos(INVENTORY_SLOT_BAG_0, uint8(INVENTORY_SLOT_ITEM_START + slot - 1));
    }
    else
        item = player->GetItemByPos(uint8(INVENTORY_SLOT_BAG_START + bag - 1), uint8(slot - 1));
    return item && item->GetTemplate()->GetInventoryType() != INVTYPE_NON_EQUIP ? item : nullptr;
}

class donate_shop_addon : public PlayerScript
{
public:
    donate_shop_addon() : PlayerScript("donate_shop_addon") { }

    void OnChat(Player* player, uint32 type, uint32 lang, std::string& msg) override
    {
        if (type != CHAT_MSG_ADDON || lang != LANG_ADDON || msg.compare(0, 5, "SHOP:") != 0)
            return;

        std::istringstream in(msg.substr(5));
        std::string command;
        uint32 a[6] = { };     // the numbers after the command, missing ones 0
        in >> command;
        for (uint32& value : a)
            if (!(in >> value))
                break;
        // "buy" = every command that changes something: its <reqId> is the n-th number (0 = none)
        uint32 reqAt = command == "BUY" ? 3 : command == "BUYN" ? 4 : command == "MORPH" ? 2 : command == "PERKADD" ? 5 : command == "PERKDEL" ? 4 : 0;
        uint32 reqId = reqAt ? a[reqAt - 1] : 0;
        bool buy = reqId >= 1 && reqId <= SHOP_MAX_REQ_ID;

        ShopThrottle* entry;
        {
            std::lock_guard<std::mutex> guard(ShopThrottlesLock);
            entry = &ShopThrottles[player->GetGUID()];
        }
        ShopThrottle& throttle = *entry;
        uint32 now = getMSTime();
        if (getMSTimeDiff(throttle.WindowStart, now) >= IN_MILLISECONDS)
        {
            throttle.WindowStart = now;
            throttle.Requests = 0;
        }
        if (++throttle.Requests > SHOP_MAX_REQUESTS || (buy && throttle.LastBuy && getMSTimeDiff(throttle.LastBuy, now) < IN_MILLISECONDS))
        {
            if (buy)
                SendShop(player, "FAIL " + std::to_string(reqId) + " BUSY " + std::to_string(throttle.Tokens));
            return;
        }

        if (!ShopOpenFor(player))
        {
            SendShop(player, "CLOSED");
            if (buy)
                SendShop(player, "FAIL " + std::to_string(reqId) + " CLOSED " + std::to_string(throttle.Tokens));
            return;
        }

        if (command == "OPEN")
            Open(player, throttle);
        else if (command == "LIST")
            List(player, a[0], a[1]);
        else if (command == "PERKS")
            Perks(player, a[0], a[1]);
        else if (buy)
        {
            throttle.LastBuy = now;
            if (command == "BUY")
                Buy(player, throttle, a[0], a[1], reqId, a[3], false, 0);
            else if (command == "BUYN")
                Buy(player, throttle, a[0], a[2], reqId, 0, true, a[1]);
            else if (command == "MORPH")
                Morph(player, throttle, a[0], reqId);
            else
                Perk(player, throttle, command == "PERKADD", a[0], a[1], a[2], command == "PERKADD" ? a[3] : 0, reqId);
        }
    }

    // a bought morph comes back at every login (characters.character_morph)
    void OnLogin(Player* player) override
    {
        if (QueryResult result = CharacterDatabase.PQuery("SELECT `display` FROM `character_morph` WHERE `guid` = %u", player->GetGUIDLow()))
            if (sCreatureDisplayInfoStore.LookupEntry((*result)[0].GetUInt32()))
                ApplyMorph(player, (*result)[0].GetUInt32());
    }

    void OnLogout(Player* player) override
    {
        std::lock_guard<std::mutex> guard(ShopThrottlesLock);
        ShopThrottles.erase(player->GetGUID());
    }

private:
    // the balance, then every category with a product this character can buy, with all its parents
    static void Open(Player* player, ShopThrottle& throttle)
    {
        uint32 faction = FactionFilter(player);
        throttle.Tokens = GetTokens(player->GetSession()->GetAccountId());
        SendShop(player, "BAL " + std::to_string(throttle.Tokens));

        struct Category { uint32 Parent; uint32 Sort; std::string Name; };
        std::map<uint32, Category> categories;
        if (QueryResult result = LoginDatabase.PQuery("SELECT `id`, `parent`, `sort`, `name` FROM `donate_categories` WHERE `enable` = 1 AND `faction` IN (0, %u)", faction))
        {
            do
            {
                Field* f = result->Fetch();
                categories[f[0].GetUInt32()] = { f[1].GetUInt32(), f[2].GetUInt32(), f[3].GetString() };
            } while (result->NextRow());
        }

        std::set<uint32> shown, withNew;
        if (QueryResult result = LoginDatabase.PQuery("SELECT `category`, `type`, `param1`, %s FROM `donate_products` WHERE `enable` = 1 AND `faction` IN (0, %u)", SHOP_IS_NEW, faction))
        {
            do
            {
                Field* f = result->Fetch();
                uint32 id = f[0].GetUInt32();
                bool isNew = f[3].GetUInt64() != 0;
                if ((shown.count(id) && (!isNew || withNew.count(id))) || !ShopVisible(player, f[1].GetUInt8(), f[2].GetUInt32()))
                    continue;

                // only when the whole path up to the top is enabled (the depth limit stops a parent loop)
                std::vector<uint32> path;
                for (uint32 depth = 0; id && depth < 10 && categories.count(id); ++depth)
                {
                    path.push_back(id);
                    id = categories[id].Parent;
                }
                if (!id)
                {
                    shown.insert(path.begin(), path.end());
                    if (isNew)
                        withNew.insert(path.begin(), path.end());
                }
            } while (result->NextRow());
        }

        for (uint32 id : shown)
        {
            Category const& c = categories[id];
            SendShop(player, "CAT " + std::to_string(id) + " " + std::to_string(c.Parent) + " " + std::to_string(c.Sort)
                + " #" + std::to_string(withNew.count(id) ? SHOP_NEW : 0) + " " + ShopName(c.Name));
        }
        SendShop(player, "CEND");
    }

    // the category's products; ilvl = the item level for its products sold by item level (0 or not in the table: their own)
    static void List(Player* player, uint32 category, uint32 ilvl)
    {
        uint32 count = 0;
        if (!ShopCategoryOpen(category, FactionFilter(player)))
        {
            SendShop(player, "LEND " + std::to_string(category) + " 0");
            return;
        }
        std::map<uint32, uint32> percents = ShopItemLevelPrices();
        uint32 current = 0;     // the item level the products sold by item level are listed at
        if (QueryResult result = LoginDatabase.PQuery("SELECT `id`, `type`, `param1`, `token`, `bonus`, `name`, %s FROM `donate_products` WHERE `category` = %u AND `enable` = 1 AND `faction` IN (0, %u) ORDER BY `sort`, `id`",
            SHOP_IS_NEW, category, FactionFilter(player)))
        {
            do
            {
                Field* f = result->Fetch();
                uint8 type = f[1].GetUInt8();
                uint32 param1 = f[2].GetUInt32();
                if (!ShopVisible(player, type, param1))
                    continue;

                std::string name = f[5].GetString();
                uint32 price = f[3].GetUInt32();
                int32 itemLevel = 0;
                std::string bonuses;
                if (type == PRODUCT_ITEM)
                {
                    ItemTemplate const* proto = sObjectMgr->GetItemTemplate(param1);   // ShopVisible checked it
                    std::string bonus = f[4].GetString();
                    current = std::max(current, ShopAtItemLevel(percents, ilvl, bonus, price));
                    itemLevel = int32(proto->GetBaseItemLevel());
                    for (uint32 bonusListId : ParseBonuses(bonus, param1))
                    {
                        bonuses += (bonuses.empty() ? "" : ",") + std::to_string(bonusListId);
                        if (DB2Manager::ItemBonusList const* list = sDB2Manager.GetItemBonusList(bonusListId))
                            for (ItemBonusEntry const* bonus : *list)
                                if (bonus->Type == ITEM_BONUS_ITEM_LEVEL)
                                    itemLevel += bonus->Value[0];
                    }
                    if (name.empty())   // the gear rows have no name in the catalogue
                        name = proto->GetName()->Get(player->GetSession()->GetSessionDbLocaleIndex());
                }

                uint32 flags = (ShopKnown(player, type, param1) ? SHOP_KNOWN : 0) | (f[6].GetUInt64() ? SHOP_NEW : 0);
                SendShop(player, "ITEM " + std::to_string(f[0].GetUInt32()) + " " + std::to_string(type) + " " + std::to_string(param1) + " " + std::to_string(price)
                    + " " + std::to_string(itemLevel) + " " + (bonuses.empty() ? "-" : bonuses) + " #" + std::to_string(flags)
                    + " " + std::to_string(ShopDisplay(type, param1)) + " " + ShopName(name));
                ++count;
            } while (result->NextRow());
        }
        if (current)
        {
            std::string levels;
            for (auto itr = percents.rbegin(); itr != percents.rend(); ++itr)
                levels += (levels.empty() ? "" : ",") + std::to_string(itr->first);
            SendShop(player, "ILV " + std::to_string(category) + " " + std::to_string(current) + " " + levels);
        }
        SendShop(player, "LEND " + std::to_string(category) + " " + std::to_string(count));
    }

    // BUY (ilvl: see the header) and BUYN (buyN: artifact levels, count 1..param1, the price is per level)
    static void Buy(Player* player, ShopThrottle& throttle, uint32 productId, uint32 shownPrice, uint32 reqId, uint32 ilvl, bool buyN, uint32 count)
    {
        uint32 accountId = player->GetSession()->GetAccountId();
        throttle.Tokens = GetTokens(accountId);
        auto fail = [&](char const* code) { SendShop(player, "FAIL " + std::to_string(reqId) + " " + code + " " + std::to_string(throttle.Tokens)); };

        QueryResult result = LoginDatabase.PQuery("SELECT `type`, `param1`, `param2`, `bonus`, `token`, `category` FROM `donate_products` WHERE `id` = %u AND `enable` = 1 AND `faction` IN (0, %u)",
            productId, FactionFilter(player));
        if (!result || !ShopCategoryOpen((*result)[5].GetUInt32(), FactionFilter(player)))
            return fail("GONE");

        Field* f = result->Fetch();
        uint8 type = f[0].GetUInt8();
        uint32 param1 = f[1].GetUInt32();
        std::string bonus = f[3].GetString();
        uint32 price = f[4].GetUInt32();
        if (!ShopVisible(player, type, param1))
            return fail("GONE");
        if ((type == PRODUCT_ARTIFACT_LEVEL) != buyN)   // artifact levels only with BUYN, BUYN only for them
            return fail(buyN ? "FAILED" : "LIMIT");
        if (buyN)
        {
            if (!count || count > param1)
                return fail("LIMIT");
            if (uint64(price) * count != shownPrice)
                return fail("PRICE");
            price = shownPrice;
            param1 = count;     // Deliver adds this many levels
        }
        if (ilvl)
        {
            std::map<uint32, uint32> percents = ShopItemLevelPrices();
            if (!percents.count(ilvl))
                return fail("PRICE");
            if (type == PRODUCT_ITEM)
                ShopAtItemLevel(percents, ilvl, bonus, price);
        }
        if (shownPrice != price)
            return fail("PRICE");
        if (throttle.Tokens < price)
            return fail("NOFUNDS");
        if (type == PRODUCT_LEVEL && (player->InBattleground() || player->InArena() || player->GetMap()->IsDungeon()))
        {
            SendShop(player, "ERR Levels can't be bought in a battleground, arena or dungeon.");
            return fail("FAILED");
        }

        // ponytail: deliver first, then charge, like the Donate Vendor; safe while one account has one session
        // (the guarded UPDATE only keeps the balance from going below zero, it can't take the item back)
        bool mailed = false;
        std::string error = type == PRODUCT_BUNDLE ? DeliverBundle(player, param1, &mailed)
            : many_in_one_donate::Deliver(player, type, param1, f[2].GetUInt32(), bonus, price, &mailed);
        if (!error.empty())
        {
            if (type == PRODUCT_BUNDLE)     // which part is in the way
                SendShop(player, "ERR " + ShopName(error));
            if (error == BAGS_FULL)
                return fail("BAGS");
            if (error == NO_ARTIFACT)
                return fail("NOART");
            if (error == ARTIFACT_MAX)
                return fail("LIMIT");
            if (error.find("already") != std::string::npos)
                return fail("OWNED");
            if (type != PRODUCT_BUNDLE)
                SendShop(player, "ERR " + ShopName(error));
            return fail("FAILED");
        }

        Charge(player, throttle, productId, type == PRODUCT_ITEM ? param1 : 0, price);
        SendShop(player, "OK " + std::to_string(reqId) + " " + std::to_string(productId) + " " + std::to_string(throttle.Tokens) + (mailed ? " MAIL" : ""));
    }

    // after a delivery: takes the tokens, logs it (donate_history: product, item entry) and reads the new balance
    static void Charge(Player* player, ShopThrottle& throttle, uint32 productId, uint32 itemEntry, uint32 price)
    {
        uint32 accountId = player->GetSession()->GetAccountId();
        player->SaveToDB();     // the delivery is saved before the tokens go (a crash in between must not charge for nothing)
        LoginDatabase.DirectPExecute("UPDATE `account` SET `donate` = `donate` - %u WHERE `id` = %u AND `donate` >= %u", price, accountId, price);
        LoginDatabase.DirectPExecute("INSERT INTO `donate_history` (`account`, `char_guid`, `product`, `item`, `token`) VALUES (%u, %u, %u, %u, %u)",
            accountId, player->GetGUIDLow(), productId, itemEntry, price);
        throttle.Tokens = GetTokens(accountId);
    }

    // MORPH <productId> | MORPH 0: wear an owned morph or the race's own look again (free)
    static void Morph(Player* player, ShopThrottle& throttle, uint32 productId, uint32 reqId)
    {
        throttle.Tokens = GetTokens(player->GetSession()->GetAccountId());
        std::string error = UseMorph(player, productId);
        if (error.empty())
        {
            SendShop(player, "OK " + std::to_string(reqId) + " " + std::to_string(productId) + " " + std::to_string(throttle.Tokens));
            return;
        }
        if (error != MORPH_UNKNOWN)
            SendShop(player, "ERR " + ShopName(error));
        SendShop(player, "FAIL " + std::to_string(reqId) + (error == MORPH_UNKNOWN ? " GONE " : " FAILED ") + std::to_string(throttle.Tokens));
    }

    // PERKS: the perks for the item at bag/slot (none if there is no equipment item), then PEND
    static void Perks(Player* player, uint32 bag, uint32 slot)
    {
        Item* item = ShopBagItem(player, bag, slot);
        if (item)
        {
            std::vector<ShopPerk> perks = ShopPerkList(player);
            for (ShopPerk const& perk : perks)
            {
                bool has = ItemHasBonus(item, perk.Bonus);
                uint32 flags = !has && !PerkError(item, perk.Bonus, ShopPerkGroup(perks, perk)).empty() ? PERK_BLOCKED : 0;
                SendShop(player, "PERK " + std::to_string(perk.Id) + " " + std::to_string(perk.Price) + " " + (has ? "1" : "0")
                    + " #" + std::to_string(flags) + " " + ShopName(perk.Name));
            }
        }
        SendShop(player, "PEND " + std::to_string(bag) + " " + std::to_string(slot) + " " + std::to_string(item ? item->GetEntry() : 0));
    }

    // PERKADD (charged like BUY, no refund row) and PERKDEL (free; the tokens paid for the perk are not given back)
    static void Perk(Player* player, ShopThrottle& throttle, bool add, uint32 bag, uint32 slot, uint32 perkId, uint32 shownPrice, uint32 reqId)
    {
        throttle.Tokens = GetTokens(player->GetSession()->GetAccountId());
        auto fail = [&](char const* code) { SendShop(player, "FAIL " + std::to_string(reqId) + " " + code + " " + std::to_string(throttle.Tokens)); };

        Item* item = ShopBagItem(player, bag, slot);
        if (!item)
            return fail("NOITEM");
        std::vector<ShopPerk> perks = ShopPerkList(player);
        auto perk = std::find_if(perks.begin(), perks.end(), [perkId](ShopPerk const& p) { return p.Id == perkId; });
        if (perk == perks.end())
            return fail("GONE");

        if (!add)
        {
            if (!ItemHasBonus(item, perk->Bonus))
            {
                SendShop(player, "ERR This item doesn't have this bonus.");
                return fail("FAILED");
            }
            RemovePerk(player, item, perk->Bonus);
            ChatHandler(player->GetSession()).SendSysMessage("The bonus was removed from the item. Relog before equipping it.");
            SendShop(player, "OK " + std::to_string(reqId) + " " + std::to_string(perkId) + " " + std::to_string(throttle.Tokens));
            return;
        }

        if (shownPrice != perk->Price)
            return fail("PRICE");
        if (throttle.Tokens < perk->Price)
            return fail("NOFUNDS");
        if (ItemHasBonus(item, perk->Bonus))
            return fail("OWNED");
        std::string error = PerkError(item, perk->Bonus, ShopPerkGroup(perks, *perk));
        if (!error.empty())
        {
            SendShop(player, "ERR " + ShopName(error));
            return fail("FAILED");
        }

        AddPerk(player, item, perk->Bonus);
        Charge(player, throttle, perkId, item->GetEntry(), perk->Price);
        SendShop(player, "OK " + std::to_string(reqId) + " " + std::to_string(perkId) + " " + std::to_string(throttle.Tokens));
    }
};

enum ServiceType : uint8
{
    SERVICE_AT_LOGIN     = 1, // param = AtLoginFlags: 1 name, 8 appearance/gender, 64 faction, 128 race
    SERVICE_LEVEL        = 2, // opens the level menu; prices per level in donate_level_prices
    SERVICE_GOLD         = 3, // token = price per 1000 gold
    SERVICE_ITEM_BONUS   = 4, // param = bonus list ID added to the first item of the backpack; grp > 0 = only one bonus per group
    SERVICE_REMOVE_BONUS = 5, // opens a free menu to remove type-4 bonuses from that item
};

enum ServiceSender : uint32
{
    SERVICE_SENDER_MAIN        = 1,
    SERVICE_SENDER_BUY         = 2, // action = service ID
    SERVICE_SENDER_LEVEL_MENU  = 3,
    SERVICE_SENDER_LEVEL_BUY   = 4, // code = target level
    SERVICE_SENDER_LEVEL_CALC  = 5, // code = target level
    SERVICE_SENDER_GOLD        = 6, // action = service ID, code = thousands of gold
    SERVICE_SENDER_REMOVE_MENU = 7,
    SERVICE_SENDER_REMOVE      = 8, // action = bonus list ID
};

// Greeting texts that come with the repack
constexpr uint32 TEXT_SERVICES = 100006;
constexpr uint32 TEXT_LEVELS   = 100007;
constexpr uint32 TEXT_BONUSES  = 100008;

class multi_vendor : public CreatureScript
{
public:
    multi_vendor() : CreatureScript("multi_vendor") { }

    bool OnGossipHello(Player* player, Creature* creature) override
    {
        ShowServices(player, creature);
        return true;
    }

    bool OnGossipSelect(Player* player, Creature* creature, uint32 sender, uint32 action) override
    {
        switch (sender)
        {
            case SERVICE_SENDER_BUY:
                BuyService(player, action);
                break;
            case SERVICE_SENDER_LEVEL_MENU:
                ShowLevelMenu(player, creature);
                return true;
            case SERVICE_SENDER_REMOVE_MENU:
                ShowRemoveMenu(player, creature);
                return true;
            case SERVICE_SENDER_REMOVE:
                RemoveBonus(player, action);
                ShowRemoveMenu(player, creature);
                return true;
            default:
                break;
        }
        ShowServices(player, creature);
        return true;
    }

    bool OnGossipSelectCode(Player* player, Creature* creature, uint32 sender, uint32 action, char const* code) override
    {
        uint32 value = code ? uint32(std::max(0, atoi(code))) : 0;
        switch (sender)
        {
            case SERVICE_SENDER_LEVEL_BUY:
            case SERVICE_SENDER_LEVEL_CALC:
                BuyLevel(player, value, sender == SERVICE_SENDER_LEVEL_CALC);
                ShowLevelMenu(player, creature);
                return true;
            case SERVICE_SENDER_GOLD:
                BuyGold(player, action, value);
                break;
            default:
                break;
        }
        ShowServices(player, creature);
        return true;
    }

private:
    static void ShowServices(Player* player, Creature* creature)
    {
        player->PlayerTalkClass->ClearMenus();
        player->ADD_GOSSIP_ITEM(GossipOptionNpc::Vendor, "Your balance of Donate tokens: " + std::to_string(GetTokens(player->GetSession()->GetAccountId())), SERVICE_SENDER_MAIN, 0);

        if (QueryResult result = LoginDatabase.Query("SELECT `id`, `name`, `type`, `token` FROM `donate_services` WHERE `enable` = 1 ORDER BY `sort`, `id`"))
        {
            do
            {
                Field* f = result->Fetch();
                uint32 id = f[0].GetUInt32();
                std::string name = f[1].GetString();
                uint32 price = f[3].GetUInt32();
                switch (f[2].GetUInt8())
                {
                    case SERVICE_AT_LOGIN:
                    case SERVICE_ITEM_BONUS:
                        player->ADD_GOSSIP_ITEM_EXTENDED(GossipOptionNpc::None, name + ": " + std::to_string(price) + " Tokens", SERVICE_SENDER_BUY, id,
                            name + "\nAre you sure you want to buy this service?", 0, false);
                        break;
                    case SERVICE_LEVEL:
                        player->ADD_GOSSIP_ITEM(GossipOptionNpc::Trainer, name, SERVICE_SENDER_LEVEL_MENU, id);
                        break;
                    case SERVICE_GOLD:
                        player->ADD_GOSSIP_ITEM_EXTENDED(GossipOptionNpc::Vendor, name + ". 1k = " + std::to_string(price) + " Tokens", SERVICE_SENDER_GOLD, id,
                            "How much gold do you want to buy? You only need to specify thousands, ie if you want to buy 1000 gold - write 1, 25000 - 25, etc.", 0, true);
                        break;
                    case SERVICE_REMOVE_BONUS:
                        player->ADD_GOSSIP_ITEM(GossipOptionNpc::None, name, SERVICE_SENDER_REMOVE_MENU, id);
                        break;
                    default:
                        break;
                }
            } while (result->NextRow());
        }

        player->SEND_GOSSIP_MENU(TEXT_SERVICES, creature->GetGUID());
    }

    static void ShowLevelMenu(Player* player, Creature* creature)
    {
        player->PlayerTalkClass->ClearMenus();
        player->ADD_GOSSIP_ITEM_EXTENDED(GossipOptionNpc::Trainer, "Buy level", SERVICE_SENDER_LEVEL_BUY, 0, "Specify the desired Level", 0, true);
        player->ADD_GOSSIP_ITEM_EXTENDED(GossipOptionNpc::None, "Calculate the cost (not buy)", SERVICE_SENDER_LEVEL_CALC, 0, "Specify the desired Level", 0, true);
        player->ADD_GOSSIP_ITEM(GossipOptionNpc::None, "Back", SERVICE_SENDER_MAIN, 0);
        player->SEND_GOSSIP_MENU(TEXT_LEVELS, creature->GetGUID());
    }

    static Item* FirstBackpackItem(Player* player)
    {
        return player->GetItemByPos(INVENTORY_SLOT_BAG_0, INVENTORY_SLOT_ITEM_START);
    }

    static void ShowRemoveMenu(Player* player, Creature* creature)
    {
        player->PlayerTalkClass->ClearMenus();
        if (Item* item = FirstBackpackItem(player))
        {
            if (QueryResult result = LoginDatabase.PQuery("SELECT `name`, `param` FROM `donate_services` WHERE `type` = %u AND `enable` = 1 ORDER BY `sort`, `id`", uint32(SERVICE_ITEM_BONUS)))
            {
                do
                {
                    Field* f = result->Fetch();
                    if (ItemHasBonus(item, f[1].GetUInt32()))
                        player->ADD_GOSSIP_ITEM_EXTENDED(GossipOptionNpc::None, "Delete bonus \"" + f[0].GetString() + "\"", SERVICE_SENDER_REMOVE, f[1].GetUInt32(),
                            "Are you sure you want to delete this bonus? You will not receive the tokens spent on it.", 0, false);
                } while (result->NextRow());
            }
        }
        else
            Notify(player, "Put the item in the first slot of your backpack!");

        player->ADD_GOSSIP_ITEM(GossipOptionNpc::None, "Back", SERVICE_SENDER_MAIN, 0);
        player->SEND_GOSSIP_MENU(TEXT_BONUSES, creature->GetGUID());
    }

    static void BuyService(Player* player, uint32 serviceId)
    {
        QueryResult result = LoginDatabase.PQuery("SELECT `type`, `param`, `grp`, `token` FROM `donate_services` WHERE `id` = %u AND `enable` = 1", serviceId);
        if (!result)
            return;

        Field* f = result->Fetch();
        uint8 type = f[0].GetUInt8();
        uint32 param = f[1].GetUInt32();
        uint32 groupId = f[2].GetUInt32();
        uint32 price = f[3].GetUInt32();

        if (type == SERVICE_AT_LOGIN)
        {
            AtLoginFlags flag = AtLoginFlags(param);
            if (player->HasAtLoginFlag(flag))
                Notify(player, "You have already purchased this service");
            else if (TakeTokens(player, price))
            {
                player->SetAtLoginFlag(flag);
                Notify(player, "Done! Log out to the character screen to use it.");
            }
            return;
        }

        if (type != SERVICE_ITEM_BONUS)
            return;

        Item* item = FirstBackpackItem(player);
        if (!item || item->GetTemplate()->GetInventoryType() == INVTYPE_NON_EQUIP)
        {
            Notify(player, "Put the item in the first slot of your backpack!");
            return;
        }
        std::vector<uint32> group;
        if (groupId)
        {
            if (QueryResult others = LoginDatabase.PQuery("SELECT `param` FROM `donate_services` WHERE `type` = %u AND `grp` = %u AND `id` <> %u", uint32(SERVICE_ITEM_BONUS), groupId, serviceId))
            {
                do
                {
                    group.push_back(others->Fetch()[0].GetUInt32());
                } while (others->NextRow());
            }
        }

        std::string error = PerkError(item, param, group);   // the same checks as the shop's perks
        if (!error.empty())
        {
            Notify(player, error);
            return;
        }
        if (!TakeTokens(player, price))
            return;

        AddPerk(player, item, param);
        Notify(player, "Bonus successfully imposed!");
    }

    static void RemoveBonus(Player* player, uint32 bonusId)
    {
        Item* item = FirstBackpackItem(player);
        if (!item || !ItemHasBonus(item, bonusId))
        {
            Notify(player, "You don't have this bonus!");
            return;
        }
        RemovePerk(player, item, bonusId);
        Notify(player, "This bonus has been successfully deleted! Relog before equipping the item.");
    }

    static uint32 LevelCost(uint32 from, uint32 to)
    {
        uint32 cost = 0;
        if (QueryResult result = LoginDatabase.Query("SELECT `level_min`, `level_max`, `token` FROM `donate_level_prices`"))
        {
            do
            {
                Field* f = result->Fetch();
                uint32 low = std::max(from, f[0].GetUInt32());
                uint32 high = std::min(to, f[1].GetUInt32());
                if (high > low)
                    cost += (high - low) * f[2].GetUInt32();
            } while (result->NextRow());
        }
        return cost;
    }

    static void BuyLevel(Player* player, uint32 level, bool calculateOnly)
    {
        uint32 current = player->getLevel();
        if (level <= current || level > sWorld->getIntConfig(CONFIG_MAX_PLAYER_LEVEL))
        {
            Notify(player, "Specify a level between " + std::to_string(current + 1) + " and " + std::to_string(sWorld->getIntConfig(CONFIG_MAX_PLAYER_LEVEL)));
            return;
        }

        uint32 cost = LevelCost(current, level);
        if (calculateOnly)
            Notify(player, "Level-up to " + std::to_string(level) + " level will cost " + std::to_string(cost) + " Tokens.");
        else if (TakeTokens(player, cost))
        {
            player->GiveLevel(uint8(level));
            Notify(player, "You are now level " + std::to_string(level) + "!");
        }
    }

    static void BuyGold(Player* player, uint32 serviceId, uint32 thousands)
    {
        QueryResult result = LoginDatabase.PQuery("SELECT `token` FROM `donate_services` WHERE `id` = %u AND `type` = %u AND `enable` = 1", serviceId, uint32(SERVICE_GOLD));
        if (!result || !thousands)
            return;

        uint64 money = uint64(thousands) * 1000 * GOLD;
        if (player->GetMoney() + money > MAX_MONEY_AMOUNT)
        {
            Notify(player, "You can't carry that much gold");
            return;
        }

        uint32 cost = thousands * result->Fetch()[0].GetUInt32();
        if (TakeTokens(player, cost))
        {
            player->ModifyMoney(int64(money));
            Notify(player, "You bought " + std::to_string(thousands * 1000) + " gold for " + std::to_string(cost) + " Tokens");
        }
    }
};

// Transmogrification (Donated items), npc 230005. The item to change goes in the first slot of the backpack,
// the item whose look it takes in the second; works where the normal transmog window refuses (donate items,
// looks from another armor type), but only between items for the same slot. Texts: npc_text 100009, trinity_string.
enum TransmogNpc
{
    TRANSMOG_TEXT_ID        = 100009,
    STR_TRANSMOG_SLOTS      = 20057,    // Put the items in the first and second slot!
    STR_TRANSMOG            = 20084,    // Transmogrify!
    STR_TRANSMOG_CANCEL     = 20085,    // Cancel transmogrify!
    STR_TRANSMOG_CONFIRM    = 20086,    // Are you really want to transmogrify?
    TRANSMOG_COST           = 50 * GOLD,
    TRANSMOG_ACTION_APPLY   = 1,
    TRANSMOG_ACTION_CANCEL  = 2,
    // equipped main/off hand: the second half of an artifact (e.g. the sword of sword and shield) can't go in a bag
    TRANSMOG_ACTION_APPLY_MAINHAND  = 3,
    TRANSMOG_ACTION_APPLY_OFFHAND   = 4,
    TRANSMOG_ACTION_CANCEL_MAINHAND = 5,
    TRANSMOG_ACTION_CANCEL_OFFHAND  = 6,
};

class npc_transmogrify : public CreatureScript
{
public:
    npc_transmogrify() : CreatureScript("npc_transmogrify") { }

    bool OnGossipHello(Player* player, Creature* creature) override
    {
        WorldSession* session = player->GetSession();
        player->PlayerTalkClass->ClearMenus();
        player->ADD_GOSSIP_ITEM_EXTENDED(GossipOptionNpc::None, session->GetTrinityString(STR_TRANSMOG), GOSSIP_SENDER_MAIN, TRANSMOG_ACTION_APPLY,
            session->GetTrinityString(STR_TRANSMOG_CONFIRM), TRANSMOG_COST, false);
        player->ADD_GOSSIP_ITEM(GossipOptionNpc::None, session->GetTrinityString(STR_TRANSMOG_CANCEL), GOSSIP_SENDER_MAIN, TRANSMOG_ACTION_CANCEL);
        player->ADD_GOSSIP_ITEM_EXTENDED(GossipOptionNpc::Transmogrify, "Equipped main hand: take the look of the item in backpack slot 1", GOSSIP_SENDER_MAIN,
            TRANSMOG_ACTION_APPLY_MAINHAND, session->GetTrinityString(STR_TRANSMOG_CONFIRM), TRANSMOG_COST, false);
        player->ADD_GOSSIP_ITEM_EXTENDED(GossipOptionNpc::Transmogrify, "Equipped off hand: take the look of the item in backpack slot 1", GOSSIP_SENDER_MAIN,
            TRANSMOG_ACTION_APPLY_OFFHAND, session->GetTrinityString(STR_TRANSMOG_CONFIRM), TRANSMOG_COST, false);
        player->ADD_GOSSIP_ITEM(GossipOptionNpc::None, "Equipped main hand: restore its own look", GOSSIP_SENDER_MAIN, TRANSMOG_ACTION_CANCEL_MAINHAND);
        player->ADD_GOSSIP_ITEM(GossipOptionNpc::None, "Equipped off hand: restore its own look", GOSSIP_SENDER_MAIN, TRANSMOG_ACTION_CANCEL_OFFHAND);
        player->SEND_GOSSIP_MENU(TRANSMOG_TEXT_ID, creature->GetGUID());
        return true;
    }

    bool OnGossipSelect(Player* player, Creature* /*creature*/, uint32 /*sender*/, uint32 action) override
    {
        player->CLOSE_GOSSIP_MENU();

        bool cancel = action == TRANSMOG_ACTION_CANCEL || action == TRANSMOG_ACTION_CANCEL_MAINHAND || action == TRANSMOG_ACTION_CANCEL_OFFHAND;
        Item* target;
        Item* source;
        if (action >= TRANSMOG_ACTION_APPLY_MAINHAND)
        {
            bool mainHand = action == TRANSMOG_ACTION_APPLY_MAINHAND || action == TRANSMOG_ACTION_CANCEL_MAINHAND;
            target = player->GetItemByPos(INVENTORY_SLOT_BAG_0, mainHand ? EQUIPMENT_SLOT_MAINHAND : EQUIPMENT_SLOT_OFFHAND);
            source = player->GetItemByPos(INVENTORY_SLOT_BAG_0, INVENTORY_SLOT_ITEM_START);
            if (!target)
            {
                Notify(player, mainHand ? "You have nothing equipped in your main hand." : "You have nothing equipped in your off hand.");
                return true;
            }
            if (!cancel && !source)
            {
                Notify(player, "Put the item whose look you want in the first slot of your backpack!");
                return true;
            }
        }
        else
        {
            target = player->GetItemByPos(INVENTORY_SLOT_BAG_0, INVENTORY_SLOT_ITEM_START);
            source = player->GetItemByPos(INVENTORY_SLOT_BAG_0, INVENTORY_SLOT_ITEM_START + 1);
            if (!target || (!cancel && !source))
            {
                Notify(player, player->GetSession()->GetTrinityString(STR_TRANSMOG_SLOTS));
                return true;
            }
        }

        if (cancel)
        {
            SetAppearance(player, target, 0);
            Notify(player, "The item's own appearance is restored.");
            return true;
        }

        if (!IsEquipment(target) || !IsEquipment(source) || SlotGroup(target) != SlotGroup(source))
        {
            Notify(player, "Both items must be equipment for the same slot.");
            return true;
        }

        ItemModifiedAppearanceEntry const* appearance = sDB2Manager.GetItemModifiedAppearance(source->GetEntry(), source->GetAppearanceModId());
        if (!appearance)
            appearance = sDB2Manager.GetDefaultItemModifiedAppearance(source->GetEntry());
        if (!appearance)
        {
            Notify(player, "This item's appearance can't be copied.");
            return true;
        }

        if (!player->HasEnoughMoney(uint64(TRANSMOG_COST)))
        {
            player->SendEquipError(EQUIP_ERR_NOT_ENOUGH_MONEY, nullptr, nullptr);
            return true;
        }

        player->ModifyMoney(-int64(TRANSMOG_COST));
        SetAppearance(player, target, appearance->ID);
        Notify(player, "Transmogrification complete.");
        return true;
    }

private:
    static bool IsEquipment(Item* item)
    {
        ItemTemplate const* proto = item->GetTemplate();
        return (proto->GetClass() == ITEM_CLASS_ARMOR || proto->GetClass() == ITEM_CLASS_WEAPON) && proto->GetInventoryType() != INVTYPE_NON_EQUIP;
    }

    // items that go in the same equipment slot share a look: robes are chests, one-handers are one-handers
    static uint32 SlotGroup(Item* item)
    {
        switch (uint32 type = item->GetTemplate()->GetInventoryType())
        {
            case INVTYPE_ROBE:              return INVTYPE_CHEST;
            case INVTYPE_WEAPONMAINHAND:
            case INVTYPE_WEAPONOFFHAND:     return INVTYPE_WEAPON;
            case INVTYPE_RANGEDRIGHT:       return INVTYPE_RANGED;
            default:                        return type;
        }
    }

    // appearance = ItemModifiedAppearance ID, 0 = the item's own look; same modifiers the transmog window sets
    static void SetAppearance(Player* player, Item* item, uint32 appearance)
    {
        item->SetModifier(ITEM_MODIFIER_TRANSMOG_APPEARANCE_ALL_SPECS, appearance);
        item->SetModifier(ITEM_MODIFIER_TRANSMOG_APPEARANCE_SPEC_1, appearance);
        item->SetModifier(ITEM_MODIFIER_TRANSMOG_APPEARANCE_SPEC_2, appearance);
        item->SetModifier(ITEM_MODIFIER_TRANSMOG_APPEARANCE_SPEC_3, appearance);
        item->SetModifier(ITEM_MODIFIER_TRANSMOG_APPEARANCE_SPEC_4, appearance);
        item->SetNotRefundable(player);
        item->SetState(ITEM_CHANGED, player);
        if (item->IsEquipped())   // show the new look on the character right away
            player->SetVisibleItemSlot(item->GetSlot(), item);
    }
};

// printf-style trinity_string with one argument, e.g. "Set personal rate of xp = x%.0f"
template<typename T>
static std::string FormatString(Player* player, uint32 entry, T value)
{
    char buf[512];
    snprintf(buf, sizeof(buf), player->GetSession()->GetTrinityString(entry), value);
    return buf;
}

// Personal XP rate (npc 230007): from x1 up to the server's kill XP rate. The core stores it per account
// (auth.account_rates) and applies it to kill, quest, exploration and gathering XP.
enum ChangeRates
{
    RATES_TEXT_ID       = 100011,   // You can change the personal rating of the experience to one of the following
    STR_RATE_NOW        = 20065,    // Now your personal rate of xp: x%.0f
    STR_RATE_SERVER     = 20066,    // Now server`s rate of xp: x%.0f
    STR_RATE_SET        = 20068,    // Set personal rate of xp = x%.0f
    STR_RATE_CHANGED    = 20069,    // Your personal rate of xp has been changed to %u
};

class npc_change_rates : public CreatureScript
{
public:
    npc_change_rates() : CreatureScript("npc_change_rates") { }

    bool OnGossipHello(Player* player, Creature* creature) override
    {
        float server = sWorld->getRate(RATE_XP_KILL);
        float current = player->GetSession()->GetPersonalXPRate() ? player->GetSession()->GetPersonalXPRate() : server;

        player->PlayerTalkClass->ClearMenus();
        player->ADD_GOSSIP_ITEM(GossipOptionNpc::None, FormatString(player, STR_RATE_NOW, current), GOSSIP_SENDER_MAIN, 0);
        player->ADD_GOSSIP_ITEM(GossipOptionNpc::None, FormatString(player, STR_RATE_SERVER, server), GOSSIP_SENDER_MAIN, 0);
        for (uint32 rate = 1; rate <= uint32(server); ++rate)
            if (float(rate) != current)
                player->ADD_GOSSIP_ITEM(GossipOptionNpc::Trainer, FormatString(player, STR_RATE_SET, float(rate)), GOSSIP_SENDER_MAIN, rate);
        player->SEND_GOSSIP_MENU(RATES_TEXT_ID, creature->GetGUID());
        return true;
    }

    bool OnGossipSelect(Player* player, Creature* creature, uint32 /*sender*/, uint32 action) override
    {
        if (!action)    // the two info lines
            return OnGossipHello(player, creature);

        player->CLOSE_GOSSIP_MENU();
        float server = sWorld->getRate(RATE_XP_KILL);
        player->GetSession()->SetPersonalXPRate(float(action) >= server ? 0.0f : float(action));   // 0 = follow the server rate
        Notify(player, FormatString(player, STR_RATE_CHANGED, action));
        return true;
    }
};

// Refunds (npc 220011): items bought with tokens (characters.character_donate, written by the Donate Vendor and the
// in-game shop) go back for 70% of what they cost, except gear at item level 985 or higher (UWOW's rule).
// Also restores this account's deleted characters, which the server keeps only with CharDelete.Method = 1.
enum ItemBack
{
    STR_REFUNDED            = 20002,    // For the item you have received %u Tokens
    STR_REFUND_INFO         = 20006,    // You can exchange the item -30% of its cost. INFORMATION: Items of the 985th ilvl are not refundable
    STR_RESTORE_INFO        = 20007,    // You can recovery delete char.
    STR_NO_ITEMS            = 20008,    // You do not have item. ...
    STR_NO_DELETED          = 20009,    // You do not have deleted char.
    STR_RESTORED            = 20011,    // Char restored to your account.
    STR_RESTORE_ERROR       = 20012,    // Error char restore.
    STR_NAME_TAKEN          = 20013,    // Character with the same name already exists.
    STR_REFUND_CONFIRM      = 20042,    // You are confident that want to return this item?

    REFUND_PERCENT          = 70,
    REFUND_MAX_ITEM_LEVEL   = 985,      // this item level and up is not refundable
    MAX_CHARACTERS          = 10,

    BACK_SENDER_MAIN        = 1,
    BACK_SENDER_ITEMS       = 2,
    BACK_SENDER_REFUND      = 3,        // action = item guid
    BACK_SENDER_DELETED     = 4,
    BACK_SENDER_RESTORE     = 5,        // action = character guid
};

class item_back : public CreatureScript
{
public:
    item_back() : CreatureScript("item_back") { }

    bool OnGossipHello(Player* player, Creature* creature) override
    {
        WorldSession* session = player->GetSession();
        player->PlayerTalkClass->ClearMenus();
        player->ADD_GOSSIP_ITEM(GossipOptionNpc::Vendor, session->GetTrinityString(STR_REFUND_INFO), BACK_SENDER_ITEMS, 0);
        player->ADD_GOSSIP_ITEM(GossipOptionNpc::None, session->GetTrinityString(STR_RESTORE_INFO), BACK_SENDER_DELETED, 0);
        player->SEND_GOSSIP_MENU(DEFAULT_GOSSIP_MESSAGE, creature->GetGUID());
        return true;
    }

    bool OnGossipSelect(Player* player, Creature* creature, uint32 sender, uint32 action) override
    {
        WorldSession* session = player->GetSession();
        player->PlayerTalkClass->ClearMenus();

        switch (sender)
        {
            case BACK_SENDER_ITEMS:
            {
                uint32 listed = 0;
                if (QueryResult result = CharacterDatabase.PQuery("SELECT itemguid, efircount FROM character_donate WHERE owner_guid = %u AND state = 0 ORDER BY date DESC",
                    player->GetGUIDLow()))
                {
                    do
                    {
                        Field* f = result->Fetch();
                        Item* item = RefundableItem(player, f[0].GetUInt32());
                        if (!item)
                            continue;

                        std::string line = item->GetTemplate()->GetName()->Get(session->GetSessionDbLocaleIndex()) + std::string(" - ") + std::to_string(Refund(f[1].GetUInt32())) + " tokens";
                        player->ADD_GOSSIP_ITEM_EXTENDED(GossipOptionNpc::Vendor, line, BACK_SENDER_REFUND, f[0].GetUInt32(), session->GetTrinityString(STR_REFUND_CONFIRM), 0, false);
                    } while (++listed < 30 && result->NextRow());
                }

                if (!player->PlayerTalkClass->GetGossipMenu().GetMenuItemCount())
                {
                    Notify(player, session->GetTrinityString(STR_NO_ITEMS));
                    return OnGossipHello(player, creature);
                }

                player->ADD_GOSSIP_ITEM(GossipOptionNpc::None, "Back", BACK_SENDER_MAIN, 0);
                player->SEND_GOSSIP_MENU(DEFAULT_GOSSIP_MESSAGE, creature->GetGUID());
                return true;
            }
            case BACK_SENDER_REFUND:
            {
                player->CLOSE_GOSSIP_MENU();
                QueryResult result = CharacterDatabase.PQuery("SELECT efircount FROM character_donate WHERE owner_guid = %u AND itemguid = %u AND state = 0",
                    player->GetGUIDLow(), action);
                Item* item = result ? RefundableItem(player, action) : nullptr;
                if (!item)
                {
                    Notify(player, session->GetTrinityString(STR_NO_ITEMS));
                    return true;
                }

                uint32 tokens = Refund(result->Fetch()[0].GetUInt32());
                player->DestroyItem(item->GetBagSlot(), item->GetSlot(), true);
                CharacterDatabase.DirectPExecute("UPDATE character_donate SET state = 1, deletedate = NOW() WHERE owner_guid = %u AND itemguid = %u",
                    player->GetGUIDLow(), action);
                LoginDatabase.DirectPExecute("UPDATE `account` SET `donate` = `donate` + %u WHERE `id` = %u", tokens, session->GetAccountId());
                Notify(player, FormatString(player, STR_REFUNDED, tokens));
                return true;
            }
            case BACK_SENDER_DELETED:
            {
                if (QueryResult result = CharacterDatabase.PQuery("SELECT guid, deleteInfos_Name, level FROM characters WHERE deleteInfos_Account = %u AND deleteDate IS NOT NULL LIMIT 30",
                    session->GetAccountId()))
                {
                    do
                    {
                        Field* f = result->Fetch();
                        player->ADD_GOSSIP_ITEM_EXTENDED(GossipOptionNpc::None, f[1].GetString() + " (level " + std::to_string(f[2].GetUInt8()) + ")", BACK_SENDER_RESTORE,
                            uint32(f[0].GetUInt64()), "Restore " + f[1].GetString() + "?", 0, false);
                    } while (result->NextRow());
                }
                else
                {
                    Notify(player, session->GetTrinityString(STR_NO_DELETED));
                    return OnGossipHello(player, creature);
                }

                player->ADD_GOSSIP_ITEM(GossipOptionNpc::None, "Back", BACK_SENDER_MAIN, 0);
                player->SEND_GOSSIP_MENU(DEFAULT_GOSSIP_MESSAGE, creature->GetGUID());
                return true;
            }
            case BACK_SENDER_RESTORE:
                player->CLOSE_GOSSIP_MENU();
                Notify(player, session->GetTrinityString(RestoreCharacter(session->GetAccountId(), action)));
                return true;
            default:
                return OnGossipHello(player, creature);
        }
    }

private:
    static uint32 Refund(uint32 paid) { return paid * REFUND_PERCENT / 100; }

    // the item if the player still owns it and it may be refunded
    static Item* RefundableItem(Player* player, uint32 itemGuid)
    {
        Item* item = player->GetItemByGuid(ObjectGuid::Create<HighGuid::Item>(itemGuid));
        if (!item || item->GetItemLevel(player->getLevel()) >= REFUND_MAX_ITEM_LEVEL)
            return nullptr;
        return item;
    }

    // same steps as .character deleted restore; returns the trinity_string to show
    static uint32 RestoreCharacter(uint32 accountId, uint32 guidLow)
    {
        QueryResult result = CharacterDatabase.PQuery("SELECT deleteInfos_Name, race, class, gender, level FROM characters WHERE guid = %u AND deleteInfos_Account = %u AND deleteDate IS NOT NULL",
            guidLow, accountId);
        if (!result)
            return STR_RESTORE_ERROR;

        Field* f = result->Fetch();
        std::string name = f[0].GetString();
        if (ObjectMgr::GetPlayerGUIDByName(name))
            return STR_NAME_TAKEN;

        if (AccountMgr::GetCharactersCount(accountId) >= MAX_CHARACTERS)
            return STR_RESTORE_ERROR;

        CharacterDatabasePreparedStatement* stmt = CharacterDatabase.GetPreparedStatement(CHAR_UDP_RESTORE_DELETE_INFO);
        stmt->setString(0, name);
        stmt->setUInt32(1, accountId);
        stmt->setUInt64(2, guidLow);
        CharacterDatabase.DirectExecute(stmt);

        sWorld->AddCharacterInfo(ObjectGuid::Create<HighGuid::Player>(guidLow), accountId, name, f[3].GetUInt8(), f[1].GetUInt8(), f[2].GetUInt8(), f[4].GetUInt8());
        return STR_RESTORED;
    }
};

// Arena 1v1, SoloQ (npc 230003): joins the core's custom queues. 1v1 turns away tank and healer specs;
// Solo Queue 3v3 builds teams from the players' specs. (UWOW's DeathMatch isn't in this core.)
class npc_1v1arena : public CreatureScript
{
public:
    npc_1v1arena() : CreatureScript("npc_1v1arena") { }

    bool OnGossipHello(Player* player, Creature* creature) override
    {
        player->PlayerTalkClass->ClearMenus();
        player->ADD_GOSSIP_ITEM(GossipOptionNpc::BattleMaster, "Join Arena 1v1 (damage specs only)", GOSSIP_SENDER_MAIN, MS::Battlegrounds::BracketType::Arena1v1);
        player->ADD_GOSSIP_ITEM(GossipOptionNpc::BattleMaster, "Join Solo Queue 3v3", GOSSIP_SENDER_MAIN, MS::Battlegrounds::BracketType::ArenaSoloQ3v3);
        player->SEND_GOSSIP_MENU(DEFAULT_GOSSIP_MESSAGE, creature->GetGUID());
        return true;
    }

    bool OnGossipSelect(Player* player, Creature* /*creature*/, uint32 /*sender*/, uint32 action) override
    {
        player->CLOSE_GOSSIP_MENU();
        if (action == MS::Battlegrounds::BracketType::Arena1v1 || action == MS::Battlegrounds::BracketType::ArenaSoloQ3v3)
            player->GetSession()->JoinBracket(uint8(action));
        return true;
    }
};

// Quest Repair (npc 230006): completes a quest from the player's log that is stuck on a server bug.
// The player still turns it in as usual.
class npc_quest_giver : public CreatureScript
{
public:
    npc_quest_giver() : CreatureScript("npc_quest_giver") { }

    bool OnGossipHello(Player* player, Creature* creature) override
    {
        player->PlayerTalkClass->ClearMenus();
        for (uint16 slot = 0; slot < MAX_QUEST_LOG_SIZE; ++slot)
        {
            uint32 questId = player->GetQuestSlotQuestId(slot);
            Quest const* quest = questId ? sQuestDataStore->GetQuestTemplate(questId) : nullptr;
            if (!quest || player->GetQuestStatus(questId) != QUEST_STATUS_INCOMPLETE)
                continue;

            player->ADD_GOSSIP_ITEM_EXTENDED(GossipOptionNpc::None, "Complete: " + quest->LogTitle, GOSSIP_SENDER_MAIN, questId,
                "Mark \"" + quest->LogTitle + "\" as complete? Only use this if the quest is bugged.", 0, false);
        }

        if (!player->PlayerTalkClass->GetGossipMenu().GetMenuItemCount())
            Notify(player, "You have no unfinished quests.");
        player->SEND_GOSSIP_MENU(DEFAULT_GOSSIP_MESSAGE, creature->GetGUID());
        return true;
    }

    bool OnGossipSelect(Player* player, Creature* /*creature*/, uint32 /*sender*/, uint32 action) override
    {
        player->CLOSE_GOSSIP_MENU();
        if (player->GetQuestStatus(action) == QUEST_STATUS_INCOMPLETE)
        {
            player->CompleteQuest(action);
            Notify(player, "Quest completed. You can turn it in now.");
        }
        return true;
    }
};

// Fashion mannequin (npc 230017): shows any creature display ID on a copy of itself for a minute, free.
enum MorphPreview
{
    MORPH_TEXT_ID       = 60002,    // You can select any morphs for previewing. It is free.
    STR_MORPH_SUMMON    = 20088,    // Summon npc dummy for viewing morphs
    MORPH_PREVIEW_TIME  = 60 * IN_MILLISECONDS,
};

class npc_morph_previewr : public CreatureScript
{
public:
    npc_morph_previewr() : CreatureScript("npc_morph_previewr") { }

    bool OnGossipHello(Player* player, Creature* creature) override
    {
        player->PlayerTalkClass->ClearMenus();
        player->ADD_GOSSIP_ITEM_EXTENDED(GossipOptionNpc::None, player->GetSession()->GetTrinityString(STR_MORPH_SUMMON), GOSSIP_SENDER_MAIN, 1,
            "Enter a creature display ID", 0, true);
        player->SEND_GOSSIP_MENU(MORPH_TEXT_ID, creature->GetGUID());
        return true;
    }

    bool OnGossipSelectCode(Player* player, Creature* creature, uint32 /*sender*/, uint32 /*action*/, char const* code) override
    {
        player->CLOSE_GOSSIP_MENU();
        uint32 displayId = uint32(atoul(code));
        if (!sCreatureDisplayInfoStore.LookupEntry(displayId))
        {
            Notify(player, "There is no display with that ID.");
            return true;
        }

        Position pos = player->GetPosition();
        player->MovePosition(pos, 4.0f, 0.0f);   // in front of the player
        if (TempSummon* dummy = player->SummonCreature(creature->GetEntry(), pos, TEMPSUMMON_TIMED_DESPAWN, MORPH_PREVIEW_TIME))
        {
            dummy->SetDisplayId(displayId);
            dummy->SetFacingToObject(player);
            dummy->RemoveFlag(UNIT_FIELD_NPC_FLAGS, UNIT_NPC_FLAG_GOSSIP);
        }
        return true;
    }
};

class donate_commandscript : public CommandScript
{
public:
    donate_commandscript() : CommandScript("donate_commandscript") { }

    std::vector<ChatCommand> GetCommands() const override
    {
        static std::vector<ChatCommand> morphCommandTable =
        {
            { "use",     SEC_PLAYER, false, &HandleMorphUse,    "" },
            { "remove",  SEC_PLAYER, false, &HandleMorphRemove, "" },
        };
        static std::vector<ChatCommand> donateCommandTable =
        {
            { "add",     SEC_ADMINISTRATOR, true, &HandleAdd,     "" },
            { "take",    SEC_ADMINISTRATOR, true, &HandleTake,    "" },
            { "balance", SEC_ADMINISTRATOR, true, &HandleBalance, "" },
            { "itemdump", SEC_ADMINISTRATOR, true, &HandleItemDump, "" },
            { "morph",   SEC_PLAYER, false, nullptr, "", morphCommandTable },
        };
        static std::vector<ChatCommand> commandTable =
        {
            { "donate", SEC_ADMINISTRATOR, true, nullptr, "", donateCommandTable },
        };
        return commandTable;
    }

private:
    // Parses "<account> [amount]"; returns 0 if the account doesn't exist.
    static uint32 ParseArgs(ChatHandler* handler, char const* args, int64* amount)
    {
        char* name = strtok((char*)args, " ");
        char* value = strtok(nullptr, " ");
        if (!name || (amount && !value))
        {
            handler->PSendSysMessage("Usage: .donate add|take <account> <amount>  or  .donate balance <account>");
            return 0;
        }
        if (amount)
            *amount = atoll(value);

        std::string account = name;
        Utf8ToUpperOnlyLatin(account);
        uint32 accountId = AccountMgr::GetId(account);
        if (!accountId)
            handler->PSendSysMessage("Account %s not found.", account.c_str());
        return accountId;
    }

    static bool HandleAdd(ChatHandler* handler, char const* args)
    {
        int64 amount = 0;
        uint32 accountId = ParseArgs(handler, args, &amount);
        if (!accountId || amount <= 0)
            return true;
        LoginDatabase.DirectPExecute("UPDATE `account` SET `donate` = `donate` + %u WHERE `id` = %u", uint32(amount), accountId);
        handler->PSendSysMessage("You add %u tokens. New balance: %u", uint32(amount), GetTokens(accountId));
        return true;
    }

    static bool HandleTake(ChatHandler* handler, char const* args)
    {
        int64 amount = 0;
        uint32 accountId = ParseArgs(handler, args, &amount);
        if (!accountId || amount <= 0)
            return true;
        uint32 balance = GetTokens(accountId);
        if (balance < amount)
        {
            handler->PSendSysMessage("Account only has %u tokens.", balance);
            return true;
        }
        LoginDatabase.DirectPExecute("UPDATE `account` SET `donate` = `donate` - %u WHERE `id` = %u", uint32(amount), accountId);
        handler->PSendSysMessage("You delete %u tokens. New balance: %u", uint32(amount), balance - uint32(amount));
        return true;
    }

    // Writes every item the server knows to items_dump.tsv (next to worldserver): the source for shop catalogs.
    static bool HandleItemDump(ChatHandler* handler, char const* /*args*/)
    {
        std::ofstream out("items_dump.tsv");
        out << "entry\tname\tquality\tclass\tsubclass\tinvtype\titemlevel\treqlevel\texpansion\tallowableclass\tflags\ticon\n";
        uint32 count = 0;
        for (auto const& itr : *sObjectMgr->GetItemTemplateStore())
        {
            ItemTemplate const& t = itr.second;
            out << itr.first << '\t' << t.GetName()->Get(LOCALE_enUS) << '\t' << t.GetQuality() << '\t' << t.GetClass() << '\t'
                << t.GetSubClass() << '\t' << uint32(t.GetInventoryType()) << '\t' << t.GetBaseItemLevel() << '\t'
                << t.GetBaseRequiredLevel() << '\t' << uint32(t.GetExpansion()) << '\t' << t.AllowableClass << '\t' << t.GetFlags() << '\t' << sDB2Manager.GetItemDIconFileDataId(itr.first) << '\n';
            ++count;
        }
        handler->PSendSysMessage("Wrote %u items to items_dump.tsv", count);
        return true;
    }

    static bool HandleBalance(ChatHandler* handler, char const* args)
    {
        if (uint32 accountId = ParseArgs(handler, args, nullptr))
            handler->PSendSysMessage("Balance: %u tokens", GetTokens(accountId));
        return true;
    }

    // .donate morph use <productId>: a morph bought in the shop (the number is in the shop's chat line after the purchase)
    static bool HandleMorphUse(ChatHandler* handler, char const* args)
    {
        uint32 productId = args ? uint32(atoul(args)) : 0;
        if (!productId)
        {
            handler->SendSysMessage("Usage: .donate morph use <number>  (the number is shown when you buy the morph in the shop)");
            return true;
        }
        std::string error = UseMorph(handler->GetSession()->GetPlayer(), productId);
        handler->SendSysMessage(error.empty() ? "Morph applied. To remove it, write .donate morph remove" : error.c_str());
        return true;
    }

    static bool HandleMorphRemove(ChatHandler* handler, char const* /*args*/)
    {
        UseMorph(handler->GetSession()->GetPlayer(), 0);
        handler->SendSysMessage("Morph removed.");
        return true;
    }
};

void AddSC_many_in_one_donate()
{
    new many_in_one_donate();
    new donate_shop_addon();
    new multi_vendor();
    new npc_transmogrify();
    new npc_change_rates();
    new item_back();
    new npc_1v1arena();
    new npc_quest_giver();
    new npc_morph_previewr();
    new donate_commandscript();
}
