/*
 * Rebuild of the repack's closed-source "many_in_one_donate" Donate Vendor: a token shop browsed through gossip.
 *   Balance:    auth.account.donate (per game account)
 *   Catalogue:  auth.donate_categories, auth.donate_products  (edits apply on the next click)
 *   Items open in a real vendor window (prices shown as N gold = N tokens, charged in Player::BuyItemFromVendorSlot);
 *   everything else is bought through gossip with a confirmation popup.
 *   Purchases:  logged in auth.donate_history
 *   GM:         .donate add|take|balance <account> [amount]
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
#include "ChatPackets.h"
#include "Config.h"
#include "Creature.h"
#include "DatabaseEnv.h"
#include "DB2Stores.h"
#include "Item.h"
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
        if (QueryResult result = LoginDatabase.PQuery("SELECT `id`, `name`, `token` FROM `donate_products` WHERE `category` = %u AND `type` <> %u AND `enable` = 1 AND `faction` IN (0, %u) ORDER BY `sort`, `id` LIMIT %u OFFSET %u",
            category, uint32(PRODUCT_ITEM), faction, PRODUCTS_PER_PAGE + 1, page * PRODUCTS_PER_PAGE))
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
        QueryResult result = LoginDatabase.PQuery("SELECT `name`, `type`, `param1`, `param2`, `token`, `category` FROM `donate_products` WHERE `id` = %u AND `enable` = 1 AND `type` <> %u", productId, uint32(PRODUCT_ITEM));
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
        if (item->GetMaxStackCount() == 1)
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
        item->SaveToDB(trans);
        MailDraft("Chronicles Shop", "Your bags were full, so the shop sent your purchase by mail.").AddItem(item)
            .SendMailTo(trans, MailReceiver(player), MailSender(MAIL_NORMAL, 0, MAIL_STATIONERY_GM));
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
                if (canStore == EQUIP_ERR_INV_FULL && mailed)
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
            default:
                return "This product is not set up correctly";
        }
    }
};

// ChroniclesShop addon (#64): the shop window from the micro menu Shop button and /shop. Same catalogue, balance and
// delivery as the Donate Vendor; the server checks everything. The core passes prefix "SHOP" addon messages here as
// "SHOP:<text>" and never forwards them; replies are addon whispers to the player himself (space separated, the name last).
//   client -> server: OPEN | LIST <categoryId> | BUY <productId> <shownPrice> <reqId>
//   server -> client: CLOSED | BAL <tokens> | CAT <id> <parentId> <order> #<flags> <name> ... CEND
//                     | ITEM <productId> <type> <param1> <price> <ilvl> <bonuses> #<flags> <display> <name> ... LEND <categoryId> <count>
//                     | OK <reqId> <productId> <tokens> [MAIL] | FAIL <reqId> NOFUNDS|GONE|PRICE|BAGS|OWNED|BUSY|CLOSED|FAILED <tokens> | ERR <text>
//   flags: SHOP_KNOWN (ITEM only), SHOP_NEW (CAT: a new product in it or below it); display = creature display of a
//   mount or pet product for the 3D preview (0 = none); MAIL = the bags were full, the item went to the mailbox.
// GM accounts only, unless Shop.OpenToPlayers = 1 in worldserver.conf.
constexpr std::size_t SHOP_MAX_MESSAGE = 250;   // bytes per addon message
constexpr uint32 SHOP_MAX_REQUESTS     = 10;    // per second, the rest is dropped (every request runs auth queries on the player's map thread)
constexpr uint32 SHOP_MAX_REQ_ID       = 999999;
constexpr char const* SHOP_IS_NEW      = "`added` > NOW() - INTERVAL 14 DAY";   // donate_products.added (fix_shop_new_flag_64.sql)

enum ShopFlags : uint32
{
    SHOP_KNOWN = 1,     // the character has it already ("Already Known", no Buy button)
    SHOP_NEW   = 2,     // added to the shop in the last 14 days
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

// the creature display of a mount or pet product, for the addon's 3D preview (0 = none)
static uint32 ShopDisplay(uint8 type, uint32 param1)
{
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
        uint32 arg1 = 0, arg2 = 0, reqId = 0;
        in >> command >> arg1 >> arg2 >> reqId;
        bool buy = command == "BUY" && reqId >= 1 && reqId <= SHOP_MAX_REQ_ID;

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

        if (!AccountMgr::IsModeratorAccount(player->GetSession()->GetSecurity()) && !sConfigMgr->GetBoolDefault("Shop.OpenToPlayers", false))
        {
            SendShop(player, "CLOSED");
            if (buy)
                SendShop(player, "FAIL " + std::to_string(reqId) + " CLOSED " + std::to_string(throttle.Tokens));
            return;
        }

        if (command == "OPEN")
            Open(player, throttle);
        else if (command == "LIST")
            List(player, arg1);
        else if (buy)
        {
            throttle.LastBuy = now;
            Buy(player, throttle, arg1, arg2, reqId);
        }
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

    static void List(Player* player, uint32 category)
    {
        uint32 count = 0;
        if (!ShopCategoryOpen(category, FactionFilter(player)))
        {
            SendShop(player, "LEND " + std::to_string(category) + " 0");
            return;
        }
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
                int32 itemLevel = 0;
                std::string bonuses;
                if (type == PRODUCT_ITEM)
                {
                    ItemTemplate const* proto = sObjectMgr->GetItemTemplate(param1);   // ShopVisible checked it
                    itemLevel = int32(proto->GetBaseItemLevel());
                    for (uint32 bonusListId : ParseBonuses(f[4].GetString(), param1))
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
                SendShop(player, "ITEM " + std::to_string(f[0].GetUInt32()) + " " + std::to_string(type) + " " + std::to_string(param1) + " " + std::to_string(f[3].GetUInt32())
                    + " " + std::to_string(itemLevel) + " " + (bonuses.empty() ? "-" : bonuses) + " #" + std::to_string(flags)
                    + " " + std::to_string(ShopDisplay(type, param1)) + " " + ShopName(name));
                ++count;
            } while (result->NextRow());
        }
        SendShop(player, "LEND " + std::to_string(category) + " " + std::to_string(count));
    }

    static void Buy(Player* player, ShopThrottle& throttle, uint32 productId, uint32 shownPrice, uint32 reqId)
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
        uint32 price = f[4].GetUInt32();
        if (!ShopVisible(player, type, param1))
            return fail("GONE");
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
        std::string error = many_in_one_donate::Deliver(player, type, param1, f[2].GetUInt32(), f[3].GetString(), price, &mailed);
        if (!error.empty())
        {
            if (error == BAGS_FULL)
                return fail("BAGS");
            if (error.find("already") != std::string::npos)
                return fail("OWNED");
            SendShop(player, "ERR " + ShopName(error));
            return fail("FAILED");
        }

        player->SaveToDB();     // the delivery is saved before the tokens go (a crash in between must not charge for nothing)
        LoginDatabase.DirectPExecute("UPDATE `account` SET `donate` = `donate` - %u WHERE `id` = %u AND `donate` >= %u", price, accountId, price);
        LoginDatabase.DirectPExecute("INSERT INTO `donate_history` (`account`, `char_guid`, `product`, `item`, `token`) VALUES (%u, %u, %u, %u, %u)",
            accountId, player->GetGUIDLow(), productId, type == PRODUCT_ITEM ? param1 : 0, price);
        throttle.Tokens = GetTokens(accountId);
        SendShop(player, "OK " + std::to_string(reqId) + " " + std::to_string(productId) + " " + std::to_string(throttle.Tokens) + (mailed ? " MAIL" : ""));
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

    static bool HasBonus(Item* item, uint32 bonusId)
    {
        std::vector<uint32> const& bonuses = item->GetDynamicValues(ITEM_DYNAMIC_FIELD_BONUS_LIST_IDS);
        return std::find(bonuses.begin(), bonuses.end(), bonusId) != bonuses.end();
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
                    if (HasBonus(item, f[1].GetUInt32()))
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
        uint32 group = f[2].GetUInt32();
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
        // the item loader (ObjectMgr::DeleteBugBonus) strips sockets and tertiary stats from legendary and artifact items
        if (item->GetTemplate()->GetQuality() >= ITEM_QUALITY_LEGENDARY && (param == 1808 || (param >= 40 && param <= 42)))
        {
            Notify(player, "Legendary and artifact items can't get this bonus.");
            return;
        }

        if (HasBonus(item, param))
        {
            Notify(player, "You already have this bonus!");
            return;
        }
        if (group)
        {
            if (QueryResult others = LoginDatabase.PQuery("SELECT `param` FROM `donate_services` WHERE `type` = %u AND `grp` = %u AND `id` <> %u", uint32(SERVICE_ITEM_BONUS), group, serviceId))
            {
                do
                {
                    if (HasBonus(item, others->Fetch()[0].GetUInt32()))
                    {
                        Notify(player, "You already have another similar bonus!");
                        return;
                    }
                } while (others->NextRow());
            }
        }
        if (!TakeTokens(player, price))
            return;

        item->AddBonuses(param);
        item->SetState(ITEM_CHANGED, player);
        Notify(player, "Bonus successfully imposed!");
    }

    static void RemoveBonus(Player* player, uint32 bonusId)
    {
        Item* item = FirstBackpackItem(player);
        if (!item || !HasBonus(item, bonusId))
        {
            Notify(player, "You don't have this bonus!");
            return;
        }
        // ponytail: the item's cached stats only rebuild from the database, hence the relog
        item->RemoveDynamicValue(ITEM_DYNAMIC_FIELD_BONUS_LIST_IDS, bonusId);
        item->SetState(ITEM_CHANGED, player);
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
        static std::vector<ChatCommand> donateCommandTable =
        {
            { "add",     SEC_ADMINISTRATOR, true, &HandleAdd,     "" },
            { "take",    SEC_ADMINISTRATOR, true, &HandleTake,    "" },
            { "balance", SEC_ADMINISTRATOR, true, &HandleBalance, "" },
            { "itemdump", SEC_ADMINISTRATOR, true, &HandleItemDump, "" },
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
