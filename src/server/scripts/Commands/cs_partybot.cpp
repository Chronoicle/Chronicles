/*
 * .partybot create <class> <spec> | all   a bot character on a free partybot account (your faction); all = one per spec
 * .partybot add <name|tank|healer|dps|spec|class>   a bot joins your group
 * .partybot remove [character]  dismiss one bot, or all of yours
 * .partybot list                your bots
 * .partybot questtest <class> [race] [max level] | stop   a fresh level-1 bot plays its starting zone's quests and logs
 *                               each quest's result (QUESTBOT lines in Server.log, game/PartyBot/QuestBot.cpp)
 * Staff only while the bots are being built (#65).
 */
#include "ScriptMgr.h"
#include "Chat.h"
#include "PartyBot.h"
#include "Player.h"
#include "DB2Stores.h"
#include "DatabaseEnv.h"
#include <boost/algorithm/string/predicate.hpp>

class partybot_commandscript : public CommandScript
{
public:
    partybot_commandscript() : CommandScript("partybot_commandscript") { }

    std::vector<ChatCommand> GetCommands() const override
    {
        static std::vector<ChatCommand> partybotCommandTable =
        {
            { "add",    SEC_GAMEMASTER, false, &HandleAddCommand,    "" },
            { "create", SEC_GAMEMASTER, false, &HandleCreateCommand, "" },
            { "remove", SEC_GAMEMASTER, false, &HandleRemoveCommand, "" },
            { "list",   SEC_GAMEMASTER, false, &HandleListCommand,   "" },
            { "questtest", SEC_GAMEMASTER, false, &HandleQuestTestCommand, "" },
        };
        static std::vector<ChatCommand> commandTable =
        {
            { "partybot", SEC_GAMEMASTER, false, nullptr, "", partybotCommandTable },
        };
        return commandTable;
    }

    static bool HandleAddCommand(ChatHandler* handler, char const* args)
    {
        if (!*args)
        {
            handler->SendSysMessage("Usage: .partybot add <bot name | tank | healer | dps | spec | class>");
            return true;
        }

        std::string error = sPartyBotMgr->AddBotByRole(handler->GetSession()->GetPlayer(), args);
        handler->SendSysMessage(error.empty() ? "Party bot is logging in..." : error.c_str());
        return true;
    }

    static void CreateOne(ChatHandler* handler, uint32 specId)
    {
        std::string name;
        std::string error = sPartyBotMgr->CreateBot(handler->GetSession()->GetPlayer(), specId, name);
        if (error.empty())
            handler->PSendSysMessage("Party bot character %s created (level 110 and gear at its first login).", name.c_str());
        else
            handler->PSendSysMessage("%s", error.c_str());
    }

    static bool HandleCreateCommand(ChatHandler* handler, char const* args)
    {
        std::string text = args ? args : "";
        if (text.empty())
        {
            handler->SendSysMessage("Usage: .partybot create <class> <spec>   e.g. .partybot create paladin protection, .partybot create death knight blood");
            handler->SendSysMessage("       .partybot create all   one bot per spec of your faction that has none yet");
            return true;
        }

        Player* player = handler->GetSession()->GetPlayer();
        if (boost::iequals(text, "all"))
        {
            bool alliance = player->GetTeam() == ALLIANCE;
            for (uint32 cls = 1; cls < MAX_CLASSES; ++cls)
                for (uint32 i = 0; i < MAX_SPECIALIZATIONS; ++i)
                    if (ChrSpecializationEntry const* spec = sDB2Manager.GetChrSpecializationByIndex(cls, i))
                    {
                        bool have = false;
                        if (QueryResult result = CharacterDatabase.PQuery("SELECT c.race FROM partybot_characters p JOIN characters c ON c.guid = p.guid WHERE p.spec = %u", spec->ID))
                            do
                                if ((Player::TeamForRace((*result)[0].GetUInt8()) == ALLIANCE) == alliance)
                                    have = true;
                            while (result->NextRow());
                        if (!have)
                            CreateOne(handler, spec->ID);
                    }
            return true;
        }

        // "<class> <spec>", the class can have a space (death knight, demon hunter)
        for (uint32 cls = 1; cls < MAX_CLASSES; ++cls)
        {
            ChrClassesEntry const* classEntry = sChrClassesStore.LookupEntry(cls);
            if (!classEntry)
                continue;
            std::string className = classEntry->Name->Str[DEFAULT_LOCALE];
            if (text.size() <= className.size() + 1 || !boost::istarts_with(text, className + " "))
                continue;
            if (ChrSpecializationEntry const* spec = PartyBotMgr::FindSpec(className, text.substr(className.size() + 1)))
            {
                CreateOne(handler, spec->ID);
                return true;
            }
        }

        handler->SendSysMessage("Unknown class/spec. Example: .partybot create priest holy");
        return true;
    }

    static bool HandleRemoveCommand(ChatHandler* handler, char const* args)
    {
        std::string error = sPartyBotMgr->RemoveBot(handler->GetSession()->GetPlayer(), args ? args : "");
        handler->SendSysMessage(error.empty() ? "Party bot dismissed." : error.c_str());
        return true;
    }

    static bool HandleQuestTestCommand(ChatHandler* handler, char const* args)
    {
        std::string text = args ? args : "";
        Player* gm = handler->GetSession()->GetPlayer();
        if (boost::iequals(text, "stop"))
        {
            uint32 stopped = 0;
            for (auto const& session : sPartyBotMgr->GetBots(gm->GetGUID()))
                if (session->IsQuestTest())
                {
                    session->RequestDismiss();
                    ++stopped;
                }
            handler->SendSysMessage(stopped ? "Quest test stopped." : "You have no quest test running.");
            return true;
        }

        std::string error = sPartyBotMgr->StartQuestTest(gm, text);
        handler->SendSysMessage(error.empty() ? "Quest test bot is logging in: QUESTBOT lines in Server.log, .partybot questtest stop to end it." : error.c_str());
        return true;
    }

    static bool HandleListCommand(ChatHandler* handler, char const* /*args*/)
    {
        auto bots = sPartyBotMgr->GetBots(handler->GetSession()->GetPlayer()->GetGUID());
        if (bots.empty())
        {
            handler->SendSysMessage("You have no party bots.");
            return true;
        }
        for (auto const& session : bots)
        {
            Player* bot = session->GetPlayer();
            handler->PSendSysMessage("  %s%s", bot ? bot->GetName() : "(logging in)", bot && bot->isDead() ? " (dead)" : "");
        }
        return true;
    }
};

void AddSC_partybot_commandscript()
{
    new partybot_commandscript();
}
