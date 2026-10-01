/*
 * .partybot create <class> <spec> | all   a bot character on a free partybot account (your faction); all = one per spec
 * .partybot add <name|tank|healer|dps|spec|class>   a bot joins your group
 * .partybot remove [character]  dismiss one bot, or all of yours
 * .partybot list                your bots
 * .partybot questtest <class> [race] [max level] | random [race] [count] [max level] | stop   a fresh level-1 bot plays its starting zone's quests and logs
 *                               each quest's result (QUESTBOT lines in Server.log, game/PartyBot/QuestBot.cpp)
 * Staff only while the bots are being built (#65).
 */
#include "ScriptMgr.h"
#include "Chat.h"
#include "PartyBot.h"
#include "Player.h"
#include "DB2Stores.h"
#include "DatabaseEnv.h"
#include "ObjectMgr.h"
#include "Containers.h"
#include <boost/algorithm/string/predicate.hpp>
#include <sstream>

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

    // .partybot questtest random [race] [count=1] [max level=5] (owner 2026-10-01): count runs of the level-1 classes of
    // that race (no race: each class's race of your faction), in random order, every class once before any repeats.
    // Stops at the first run that can't start (cap, no free account).
    static bool HandleQuestTestRandom(ChatHandler* handler, std::string const& text)
    {
        std::istringstream in(text);
        std::vector<std::string> words;     // "random", the race (may have a space), [count] [max level]
        for (std::string word; in >> word;)
            words.push_back(word);
        std::vector<uint32> numbers;
        while (words.size() > 1 && numbers.size() < 2 && isdigit(uint8(words.back()[0])))
        {
            numbers.insert(numbers.begin(), uint32(atoi(words.back().c_str())));
            words.pop_back();
        }
        uint32 count = numbers.empty() ? 1 : numbers[0];
        std::string maxLevel = numbers.size() > 1 ? " " + std::to_string(numbers[1]) : "";

        std::string raceName;
        for (size_t i = 1; i < words.size(); ++i)
            raceName += (raceName.empty() ? "" : " ") + words[i];
        uint8 race = 0;
        if (!raceName.empty())
        {
            for (ChrRacesEntry const* entry : sChrRacesStore)
                if (boost::iequals(std::string(entry->Name->Str[DEFAULT_LOCALE]), raceName))
                    race = entry->ID;
            if (!race)
            {
                handler->PSendSysMessage("Unknown race '%s'.", raceName.c_str());
                return true;
            }
        }

        // death knights and demon hunters don't start at level 1 in the race's zone
        std::vector<std::string> classes;
        for (uint8 cls = CLASS_WARRIOR; cls < MAX_CLASSES; ++cls)
            if (cls != CLASS_DEATH_KNIGHT && cls != CLASS_DEMON_HUNTER && (!race || sObjectMgr->GetPlayerInfo(race, cls)))
                if (ChrClassesEntry const* entry = sChrClassesStore.LookupEntry(cls))
                    classes.push_back(entry->Name->Str[DEFAULT_LOCALE]);
        if (classes.empty())
        {
            handler->PSendSysMessage("No level-1 class for race '%s'.", raceName.c_str());
            return true;
        }
        Trinity::Containers::RandomShuffle(classes);

        uint32 started = 0;
        std::string error;
        while (started < count)
        {
            error = sPartyBotMgr->StartQuestTest(handler->GetSession()->GetPlayer(), classes[started % classes.size()] + (race ? " " + raceName : "") + maxLevel);
            if (!error.empty())
                break;
            ++started;
        }
        handler->PSendSysMessage("Started %u of %u quest-test bots. Results: QUESTBOT lines in Server.log; .partybot questtest stop ends them.%s%s",
            started, count, error.empty() ? "" : " Stopped: ", error.c_str());
        return true;
    }

    static bool HandleQuestTestCommand(ChatHandler* handler, char const* args)
    {
        std::string text = args ? args : "";
        if (boost::iequals(text, "stop"))
        {
            handler->SendSysMessage(sPartyBotMgr->StopQuestTests() ? "Quest test stopped." : "No quest test is running.");
            return true;
        }
        if (boost::istarts_with(text, "random") && (text.size() == 6 || text[6] == ' '))
            return HandleQuestTestRandom(handler, text);

        std::string error = sPartyBotMgr->StartQuestTest(handler->GetSession()->GetPlayer(), text);
        handler->SendSysMessage(error.empty() ? "Quest test bot is logging in. Results: QUESTBOT lines in Server.log (run=end is the summary); "
            ".partybot questtest stop ends it." : error.c_str());
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
