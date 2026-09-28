/*
 * Premium accounts: bought in the in-game shop (30/90/180 days), stored in auth.account_premium.
 * Passive benefits live in the core (search "premium:"). This script has the active ones:
 *
 * .premium / .prem opens the premium menu: transmog, bank, mail, auction house, repair and teleports.
 * With the PremiumMenu client addon it shows as a custom window (addon messages, prefix "PREM"),
 * without the addon it falls back to a normal gossip menu.
 *
 * The windows belong to a hidden helper NPC summoned next to the player that follows them. It has the
 * transmogrifier, banker, mailbox and auctioneer flags, so every window goes through the normal NPC checks.
 *
 * Addon protocol (space separated)
 *   client -> server: HELLO | OPEN | TRANSMOG | BANK | MAIL | AUCTION | REPAIR | TELE <id>
 *   server -> client: OPEN <seconds left> (show the window) | STATE <seconds left> | ERR <text>
 */
#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "ScriptedGossip.h"
#include "Chat.h"
#include "ChatPackets.h"
#include "Player.h"
#include "WorldSession.h"
#include "ObjectMgr.h"
#include "ObjectAccessor.h"
#include "TemporarySummon.h"
#include "BattlePayMgr.h"
#include "DatabaseEnv.h"
#include <mutex>

enum PremiumMenu
{
    NPC_PREMIUM_HELPER   = 230040,
    HELPER_LIFETIME      = 5 * MINUTE * IN_MILLISECONDS,

    TELE_CAPITALS        = 1,
    TELE_DUNGEONS        = 2,
    TELE_RAIDS           = 3,

    // gossip fallback actions (teleports use 1000 + teleport id, categories 2000 + category)
    ACTION_TRANSMOG      = 1,
    ACTION_BANK,
    ACTION_MAIL,
    ACTION_AUCTION,
    ACTION_REPAIR,
    ACTION_TELEPORTS,
    ACTION_MAIN,
    ACTION_TELE          = 1000,
    ACTION_TELE_CATEGORY = 2000,
};

struct PremiumTeleport
{
    uint32 Id;
    uint8 Category;
    char const* Name;
    char const* GameTele;   // use this game_tele row instead of the coordinates
    uint32 Map;
    float X, Y, Z, O;
};

// ids must match the PremiumMenu addon. Dungeons/raids: Dungeon Finder entrances (lfg_entrances) or the
// instance's entrance graveyard (WorldSafeLocs), i.e. the start of the instance.
static PremiumTeleport const Teleports[] =
{
    {  1, TELE_CAPITALS, "Orgrimmar",                   "Orgrimmar",  0, 0, 0, 0, 0 },
    {  2, TELE_CAPITALS, "Stormwind",                   "Stormwind",  0, 0, 0, 0, 0 },
    {  3, TELE_CAPITALS, "Dalaran (Broken Isles)",      nullptr, 1220,   -828.40f,  4371.40f,  738.70f, 1.90f },
    {  4, TELE_CAPITALS, "Dalaran (Northrend)",         "Dalaran",    0, 0, 0, 0, 0 },
    {  5, TELE_CAPITALS, "Shattrath",                   "Shattrath",  0, 0, 0, 0, 0 },
    { 10, TELE_DUNGEONS, "Black Rook Hold",             nullptr, 1501,   3484.26f,  7645.71f,   -9.68f, 3.35f },
    { 11, TELE_DUNGEONS, "Cathedral of Eternal Night",  nullptr, 1677,   -689.74f,  2528.21f,  332.06f, 0.01f },
    { 12, TELE_DUNGEONS, "Court of Stars",              nullptr, 1571,   1014.58f,  3814.68f,   11.23f, 4.50f },
    { 13, TELE_DUNGEONS, "Darkheart Thicket",           nullptr, 1466,   3247.98f,  1828.70f,  236.77f, 3.17f },
    { 14, TELE_DUNGEONS, "Everbloom",                   nullptr, 1279,    429.43f,  1327.47f,  125.02f, 0.65f },
    { 15, TELE_DUNGEONS, "Eye of Azshara",              nullptr, 1456,  -3919.99f,  4525.86f,   88.57f, 6.27f },
    { 16, TELE_DUNGEONS, "Grimrail Depot",              nullptr, 1208,   1738.38f,  1681.08f,    7.68f, 3.14f },
    { 17, TELE_DUNGEONS, "Halls of Valor",              nullptr, 1477,   3787.76f,   529.10f,  604.02f, 3.14f },
    { 18, TELE_DUNGEONS, "Maw of Souls",                nullptr, 1492,   7211.21f,  7307.77f,   22.36f, 5.85f },
    { 19, TELE_DUNGEONS, "Neltharion's Lair",           nullptr, 1458,   2975.45f,   987.24f,  374.00f, 2.69f },
    { 20, TELE_DUNGEONS, "Return to Karazhan",          nullptr, 1651, -11055.90f, -1977.38f,  102.00f, 0.00f },
    { 21, TELE_DUNGEONS, "Seat of the Triumvirate",     nullptr, 1753,   5424.53f, 10818.10f,   20.15f, 6.08f },
    { 22, TELE_DUNGEONS, "Shadowmoon Burial Grounds",   nullptr, 1176,   1719.15f,   239.79f,  324.54f, 5.54f },
    { 23, TELE_DUNGEONS, "The Arcway",                  nullptr, 1516,   3514.95f,  4803.39f,  590.07f, 3.10f },
    { 24, TELE_DUNGEONS, "Vault of the Wardens",        nullptr, 1493,   4184.46f,  -756.43f,  269.65f, 1.53f },
    { 30, TELE_RAIDS,    "The Emerald Nightmare",       nullptr, 1520,   1810.12f,  1424.19f,  355.17f, 5.93f },
    { 31, TELE_RAIDS,    "Trial of Valor",              nullptr, 1648,   3207.87f,   529.28f,  633.15f, 3.12f },
    { 32, TELE_RAIDS,    "The Nighthold",               nullptr, 1530,   -149.19f,  3531.72f, -253.88f, 5.49f },
    { 33, TELE_RAIDS,    "Tomb of Sargeras",            nullptr, 1676,   5859.02f,  -795.79f, 2953.09f, 6.25f },
    { 34, TELE_RAIDS,    "Antorus, the Burning Throne", nullptr, 1712,  -3412.46f,  9527.83f,    7.56f, 0.23f },
};

static std::set<ObjectGuid> PlayersWithAddon;   // sent HELLO this login
static std::mutex PlayersWithAddonLock;         // used from the players' map threads

static bool HasAddon(Player* player)
{
    std::lock_guard<std::mutex> guard(PlayersWithAddonLock);
    return PlayersWithAddon.count(player->GetGUID()) != 0;
}

static uint32 PremiumSecondsLeft(Player* player)
{
    uint32 now = uint32(time(nullptr));
    uint32 expires = player->GetSession()->GetPremiumExpires();
    return expires > now ? expires - now : 0;
}

static void SendAddon(Player* player, std::string const& text)
{
    // not Player::WhisperAddon: that one leaves the prefix out, so addons never see the message
    WorldPackets::Chat::Chat packet;
    packet.Initialize(CHAT_MSG_WHISPER, LANG_ADDON, player, player, text, 0, "", DEFAULT_LOCALE, "PREM");
    player->SendDirectMessage(packet.Write());
}

static void Notify(Player* player, std::string const& text)
{
    ChatHandler(player->GetSession()).SendSysMessage(text.c_str());
    if (HasAddon(player))
        SendAddon(player, "ERR " + text);
}

static bool CheckPremium(Player* player)
{
    if (player->GetSession()->IsPremium())
        return true;
    Notify(player, "You need a premium account for this. You can buy it in the shop (Premium).");
    return false;
}

// the player's helper nearby; summons a new one if needed (justSummoned: the client does not know it yet)
static Creature* GetHelper(Player* player, bool* justSummoned = nullptr)
{
    std::list<Creature*> helpers;
    player->GetCreatureListWithEntryInGrid(helpers, NPC_PREMIUM_HELPER, 10.0f);
    for (Creature* creature : helpers)
        if (TempSummon* summon = creature->ToTempSummon())
            if (summon->GetSummonerGUID() == player->GetGUID())
                return creature;

    if (justSummoned)
        *justSummoned = true;
    return player->SummonCreature(NPC_PREMIUM_HELPER, player->GetPosition(), TEMPSUMMON_TIMED_DESPAWN, HELPER_LIFETIME);
}

static void OpenWindow(Player* player, Creature* helper, std::string const& action)
{
    WorldSession* session = player->GetSession();
    if (action == "TRANSMOG")
        session->SendOpenTransmogrifier(helper->GetGUID());
    else if (action == "BANK")
        session->SendShowBank(helper->GetGUID());
    else if (action == "MAIL")
        session->SendShowMailBox(helper->GetGUID());
    else if (action == "AUCTION")
        session->SendAuctionHello(helper->GetGUID(), helper);
}

static void Teleport(Player* player, uint32 id)
{
    PremiumTeleport const* tele = nullptr;
    for (PremiumTeleport const& t : Teleports)
        if (t.Id == id)
            tele = &t;
    if (!tele)
        return;

    if (player->isInCombat())
    {
        Notify(player, "You can't teleport while in combat.");
        return;
    }

    if (tele->GameTele)
    {
        if (GameTele const* gameTele = sObjectMgr->GetGameTele(tele->GameTele))
            player->TeleportTo(gameTele->mapId, gameTele->position_x, gameTele->position_y, gameTele->position_z, gameTele->orientation);
    }
    else
        player->TeleportTo(tele->Map, tele->X, tele->Y, tele->Z, tele->O);
}

// every premium action, from the addon or the gossip fallback. Returns false for an unknown action.
static bool DoPremiumAction(Player* player, std::string const& action, uint32 teleportId = 0)
{
    if (!CheckPremium(player))
        return true;

    if (action == "REPAIR")
    {
        player->DurabilityRepairAll(false, 0.0f, false);
        Notify(player, "All your items have been repaired.");
        return true;
    }
    if (action == "TELE")
    {
        Teleport(player, teleportId);
        return true;
    }

    if (action != "TRANSMOG" && action != "BANK" && action != "MAIL" && action != "AUCTION")
        return false;

    bool justSummoned = false;
    Creature* helper = GetHelper(player, &justSummoned);
    TC_LOG_INFO("scripts", "premium: %s asks %s, helper %s%s", player->GetName(), action.c_str(),
        helper ? helper->GetGUID().ToString().c_str() : "NOT SUMMONED", justSummoned ? " (new)" : "");
    if (!helper)
        return true;

    if (!justSummoned)
    {
        OpenWindow(player, helper, action);
        return true;
    }

    // a new helper reaches the client with the next visibility update: open the window a little later
    ObjectGuid playerGuid = player->GetGUID(), helperGuid = helper->GetGUID();
    player->AddDelayedEvent(600, [playerGuid, helperGuid, action]() -> void
    {
        Player* p = ObjectAccessor::FindPlayer(playerGuid);
        Creature* h = p ? ObjectAccessor::GetCreature(*p, helperGuid) : nullptr;
        if (p && h)
            OpenWindow(p, h, action);
    });
    return true;
}

// ---- gossip fallback (no addon) ----

static void ShowGossipMain(Player* player, Creature* helper)
{
    player->PlayerTalkClass->ClearMenus();
    player->ADD_GOSSIP_ITEM(GossipOptionNpc::Transmogrify, "Transmogrification", GOSSIP_SENDER_MAIN, ACTION_TRANSMOG);
    player->ADD_GOSSIP_ITEM(GossipOptionNpc::Banker, "Bank", GOSSIP_SENDER_MAIN, ACTION_BANK);
    player->ADD_GOSSIP_ITEM(GossipOptionNpc::Mailbox, "Mail", GOSSIP_SENDER_MAIN, ACTION_MAIL);
    player->ADD_GOSSIP_ITEM(GossipOptionNpc::Auctioneer, "Auction House", GOSSIP_SENDER_MAIN, ACTION_AUCTION);
    player->ADD_GOSSIP_ITEM(GossipOptionNpc::Vendor, "Repair all items", GOSSIP_SENDER_MAIN, ACTION_REPAIR);
    player->ADD_GOSSIP_ITEM(GossipOptionNpc::TaxiNode, "Teleportation", GOSSIP_SENDER_MAIN, ACTION_TELEPORTS);
    player->SEND_GOSSIP_MENU(DEFAULT_GOSSIP_MESSAGE, helper->GetGUID());
}

static void ShowGossipTeleports(Player* player, Creature* helper, uint32 category)
{
    player->PlayerTalkClass->ClearMenus();
    if (!category)
    {
        player->ADD_GOSSIP_ITEM(GossipOptionNpc::TaxiNode, "Capitals", GOSSIP_SENDER_MAIN, ACTION_TELE_CATEGORY + TELE_CAPITALS);
        player->ADD_GOSSIP_ITEM(GossipOptionNpc::TaxiNode, "Dungeons", GOSSIP_SENDER_MAIN, ACTION_TELE_CATEGORY + TELE_DUNGEONS);
        player->ADD_GOSSIP_ITEM(GossipOptionNpc::TaxiNode, "Raids", GOSSIP_SENDER_MAIN, ACTION_TELE_CATEGORY + TELE_RAIDS);
        player->ADD_GOSSIP_ITEM(GossipOptionNpc::None, "<< Back", GOSSIP_SENDER_MAIN, ACTION_MAIN);
    }
    else
    {
        for (PremiumTeleport const& t : Teleports)
            if (t.Category == category)
                player->ADD_GOSSIP_ITEM(GossipOptionNpc::TaxiNode, t.Name, GOSSIP_SENDER_MAIN, ACTION_TELE + t.Id);
        player->ADD_GOSSIP_ITEM(GossipOptionNpc::None, "<< Back", GOSSIP_SENDER_MAIN, ACTION_TELEPORTS);
    }
    player->SEND_GOSSIP_MENU(DEFAULT_GOSSIP_MESSAGE, helper->GetGUID());
}

class npc_premium_helper : public CreatureScript
{
public:
    npc_premium_helper() : CreatureScript("npc_premium_helper") { }

    struct npc_premium_helperAI : public ScriptedAI
    {
        npc_premium_helperAI(Creature* creature) : ScriptedAI(creature) { }

        void IsSummonedBy(Unit* summoner) override
        {
            // the player's own faction: friendly to them, and the auction window opens their faction's auction house
            me->setFaction(summoner->getFaction());
            me->GetMotionMaster()->MoveFollow(summoner, 1.0f, 0.0f);
        }
    };

    CreatureAI* GetAI(Creature* creature) const override
    {
        return new npc_premium_helperAI(creature);
    }

    bool OnGossipSelect(Player* player, Creature* helper, uint32 /*sender*/, uint32 action) override
    {
        TempSummon* summon = helper->ToTempSummon();
        if (!summon || summon->GetSummonerGUID() != player->GetGUID())   // only its own player
        {
            player->CLOSE_GOSSIP_MENU();
            return true;
        }

        switch (action)
        {
            case ACTION_MAIN:      ShowGossipMain(player, helper); return true;
            case ACTION_TELEPORTS: ShowGossipTeleports(player, helper, 0); return true;
            default: break;
        }
        if (action > ACTION_TELE_CATEGORY)
        {
            ShowGossipTeleports(player, helper, action - ACTION_TELE_CATEGORY);
            return true;
        }

        player->CLOSE_GOSSIP_MENU();
        if (action > ACTION_TELE)
            DoPremiumAction(player, "TELE", action - ACTION_TELE);
        else
        {
            static char const* const names[] = { "", "TRANSMOG", "BANK", "MAIL", "AUCTION", "REPAIR" };
            if (action >= ACTION_TRANSMOG && action <= ACTION_REPAIR)
                DoPremiumAction(player, names[action]);
        }
        return true;
    }
};

// ---- addon messages (the core passes prefix "PREM" messages here as "PREM:<text>") ----

class premium_addon_playerscript : public PlayerScript
{
public:
    premium_addon_playerscript() : PlayerScript("premium_addon_playerscript") { }

    void OnChat(Player* player, uint32 type, uint32 lang, std::string& msg) override
    {
        if (type != CHAT_MSG_ADDON || lang != LANG_ADDON || msg.compare(0, 5, "PREM:") != 0)
            return;

        std::string command = msg.substr(5);
        uint32 id = 0;
        std::string::size_type space = command.find(' ');
        if (space != std::string::npos)
        {
            id = uint32(atoi(command.c_str() + space + 1));
            command.resize(space);
        }

        if (command == "HELLO")
        {
            {
                std::lock_guard<std::mutex> guard(PlayersWithAddonLock);
                PlayersWithAddon.insert(player->GetGUID());
            }
            SendAddon(player, "STATE " + std::to_string(PremiumSecondsLeft(player)));
        }
        else if (command == "OPEN")
            SendAddon(player, "OPEN " + std::to_string(PremiumSecondsLeft(player)));
        else
            DoPremiumAction(player, command, id);
    }

    void OnLogout(Player* player) override
    {
        std::lock_guard<std::mutex> guard(PlayersWithAddonLock);
        PlayersWithAddon.erase(player->GetGUID());
    }
};

// ---- shop products (battlepay_product.ScriptName) ----

class battlepay_premium : public BattlePayProductScript
{
public:
    battlepay_premium(char const* name, uint32 days) : BattlePayProductScript(name), _days(days) { }

    void OnProductDelivery(WorldSession* session, Battlepay::Product const* /*product*/) override
    {
        // extends a running premium, otherwise starts from now
        uint32 now = uint32(time(nullptr));
        uint32 expires = std::max(now, session->GetPremiumExpires()) + _days * DAY;
        LoginDatabase.PExecute("REPLACE INTO account_premium (account_id, expires) VALUES (%u, %u)", session->GetAccountId(), expires);
        session->SetPremiumExpires(expires);

        if (Player* player = session->GetPlayer())
        {
            ChatHandler(session).PSendSysMessage("Premium activated: %u days added. Type .prem to open the premium menu.", _days);
            if (HasAddon(player))
                SendAddon(player, "STATE " + std::to_string(PremiumSecondsLeft(player)));
        }
    }

private:
    uint32 _days;
};

class premium_commandscript : public CommandScript
{
public:
    premium_commandscript() : CommandScript("premium_commandscript") { }

    std::vector<ChatCommand> GetCommands() const override
    {
        static std::vector<ChatCommand> commandTable =
        {
            { "premium", SEC_PLAYER, false, &HandlePremiumCommand, "" },
            { "prem",    SEC_PLAYER, false, &HandlePremiumCommand, "" },
        };
        return commandTable;
    }

    static bool HandlePremiumCommand(ChatHandler* handler, char const* /*args*/)
    {
        Player* player = handler->GetSession()->GetPlayer();

        // the addon window also shows non-premium players the benefits and a Buy Premium button
        if (HasAddon(player))
        {
            SendAddon(player, "OPEN " + std::to_string(PremiumSecondsLeft(player)));
            return true;
        }

        if (!CheckPremium(player))
            return true;

        if (!player->IsAlive() || player->isInFlight())
        {
            handler->SendSysMessage("You can't open the premium menu right now.");
            return true;
        }

        if (Creature* helper = GetHelper(player))
            ShowGossipMain(player, helper);
        return true;
    }
};

void AddSC_premium_menu()
{
    new npc_premium_helper();
    new premium_addon_playerscript();
    new battlepay_premium("battlepay_premium_30", 30);
    new battlepay_premium("battlepay_premium_90", 90);
    new battlepay_premium("battlepay_premium_180", 180);
    new premium_commandscript();
}
