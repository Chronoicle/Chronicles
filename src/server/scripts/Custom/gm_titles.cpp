/*
 * Title Master (npc 230041), Game Masters only: create custom titles and give them to players.
 *
 * (The hotfix database connection is closed after startup, so this goes through the world connection.)
 * A new title is a hotfixes.char_titles row plus a hotfix_data row, so the server sends it to clients the same way as
 * the custom items. Titles only load at startup: a new title can be given after the next restart.
 * Characters store titles as bits below MAX_TITLE_INDEX (384) and the client already uses most of them,
 * so only the free bit numbers can be used (15 when this was written).
 */
#include "ScriptMgr.h"
#include "ScriptedGossip.h"
#include "Chat.h"
#include "DatabaseEnv.h"
#include "DB2Stores.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "WorldSession.h"

enum GmTitles
{
    FIRST_CUSTOM_TITLE_ID   = 523,          // the client's own titles end at 522
    CHAR_TITLES_TABLE_HASH  = 2246024846u,  // CharTitles.db2
    ACTION_CREATE           = 1,
    ACTION_GIVE_LIST        = 2,
    ACTION_GIVE             = 1000,         // + title ID
};

static bool IsGm(Player* player)
{
    return player->GetSession()->GetSecurity() >= SEC_GAMEMASTER;
}

static char const* TitleName(CharTitlesEntry const* title)
{
    return title->Name->Str[sObjectMgr->GetDBCLocaleIndex()];
}

class npc_gm_titles : public CreatureScript
{
public:
    npc_gm_titles() : CreatureScript("npc_gm_titles") { }

    bool OnGossipHello(Player* player, Creature* creature) override
    {
        if (!IsGm(player))
        {
            ChatHandler(player->GetSession()).SendSysMessage("The Title Master only serves Game Masters.");
            player->CLOSE_GOSSIP_MENU();
            return true;
        }
        player->PlayerTalkClass->ClearMenus();
        player->ADD_GOSSIP_ITEM_EXTENDED(GossipOptionNpc::None, "Create a new title", GOSSIP_SENDER_MAIN, ACTION_CREATE,
            "Type the title. %s is the character's name, e.g. \"%s the Brave\" or \"Champion %s\".", 0, true);
        player->ADD_GOSSIP_ITEM(GossipOptionNpc::None, "Give a custom title to my target (or me)", GOSSIP_SENDER_MAIN, ACTION_GIVE_LIST);
        player->SEND_GOSSIP_MENU(DEFAULT_GOSSIP_MESSAGE, creature->GetGUID());
        return true;
    }

    bool OnGossipSelect(Player* player, Creature* creature, uint32 /*sender*/, uint32 action) override
    {
        if (!IsGm(player))
        {
            player->CLOSE_GOSSIP_MENU();
            return true;
        }

        if (action == ACTION_GIVE_LIST)
        {
            player->PlayerTalkClass->ClearMenus();
            for (uint32 id = FIRST_CUSTOM_TITLE_ID; id < sCharTitlesStore.GetNumRows(); ++id)
                if (CharTitlesEntry const* title = sCharTitlesStore.LookupEntry(id))
                    player->ADD_GOSSIP_ITEM(GossipOptionNpc::None, std::string("Give: ") + TitleName(title), GOSSIP_SENDER_MAIN, ACTION_GIVE + id);
            player->SEND_GOSSIP_MENU(DEFAULT_GOSSIP_MESSAGE, creature->GetGUID());
            return true;
        }

        player->CLOSE_GOSSIP_MENU();
        if (action > ACTION_GIVE)
        {
            CharTitlesEntry const* title = sCharTitlesStore.LookupEntry(action - ACTION_GIVE);
            Player* target = player->GetSelectedPlayer();
            if (!target)
                target = player;
            if (title)
            {
                target->SetTitle(title);
                ChatHandler(player->GetSession()).PSendSysMessage("Gave \"%s\" to %s.", TitleName(title), target->GetName());
            }
        }
        return true;
    }

    bool OnGossipSelectCode(Player* player, Creature* /*creature*/, uint32 /*sender*/, uint32 action, char const* code) override
    {
        player->CLOSE_GOSSIP_MENU();
        ChatHandler chat(player->GetSession());
        if (!IsGm(player) || action != ACTION_CREATE || !code)
            return true;

        std::string name = code;
        size_t placeholder = name.find("%s");
        if (name.empty() || name.size() > 60 || placeholder == std::string::npos || name.find('%', placeholder + 1) != std::string::npos)
        {
            chat.SendSysMessage("A title needs %s exactly once (the character's name) and at most 60 characters, e.g. \"%s the Brave\".");
            return true;
        }

        // bit numbers in use: the client's titles (loaded) and every custom row, also the ones made since the last restart
        std::set<uint32> used;
        uint32 lastId = sCharTitlesStore.GetNumRows();
        for (uint32 id = 0; id < sCharTitlesStore.GetNumRows(); ++id)
            if (CharTitlesEntry const* title = sCharTitlesStore.LookupEntry(id))
                used.insert(title->MaskID);
        if (QueryResult result = WorldDatabase.Query("SELECT ID, MaskID FROM hotfixes.char_titles"))
        {
            do
            {
                Field* f = result->Fetch();
                lastId = std::max(lastId, f[0].GetUInt32() + 1);
                used.insert(f[1].GetUInt16());
            } while (result->NextRow());
        }
        uint32 mask = 1;
        while (mask < MAX_TITLE_INDEX && used.count(mask))
            ++mask;
        if (mask >= MAX_TITLE_INDEX)
        {
            chat.SendSysMessage("No free title slots left: characters can only hold a limited number of titles.");
            return true;
        }

        uint32 id = std::max<uint32>(lastId, FIRST_CUSTOM_TITLE_ID);
        std::string escaped = name;
        WorldDatabase.EscapeString(escaped);
        WorldDatabase.PExecute("INSERT INTO hotfixes.char_titles (ID, Name, Name1, MaskID, Flags, VerifiedBuild) VALUES (%u, '%s', '%s', %u, 0, 0)",
            id, escaped.c_str(), escaped.c_str(), mask);
        WorldDatabase.PExecute("INSERT INTO hotfixes.hotfix_data (Id, TableHash, RecordID, Timestamp, Deleted) VALUES (%u, %u, %u, 0, 0)",
            id, uint32(CHAR_TITLES_TABLE_HASH), id);
        chat.PSendSysMessage("Title \"%s\" created (ID %u). It can be given after the next server restart: with this NPC, or .title add %u.",
            name.c_str(), id, id);
        return true;
    }
};

void AddSC_gm_titles()
{
    new npc_gm_titles();
}
