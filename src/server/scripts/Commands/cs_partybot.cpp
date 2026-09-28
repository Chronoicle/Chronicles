/*
 * .partybot add <character>     a character of another (offline) account joins your group as a party bot
 * .partybot remove [character]  dismiss one bot, or all of yours
 * .partybot list                your bots
 * Staff only while the bots are being built (#65).
 */
#include "ScriptMgr.h"
#include "Chat.h"
#include "PartyBot.h"
#include "Player.h"

class partybot_commandscript : public CommandScript
{
public:
    partybot_commandscript() : CommandScript("partybot_commandscript") { }

    std::vector<ChatCommand> GetCommands() const override
    {
        static std::vector<ChatCommand> partybotCommandTable =
        {
            { "add",    SEC_GAMEMASTER, false, &HandleAddCommand,    "" },
            { "remove", SEC_GAMEMASTER, false, &HandleRemoveCommand, "" },
            { "list",   SEC_GAMEMASTER, false, &HandleListCommand,   "" },
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
            handler->SendSysMessage("Usage: .partybot add <character of another account>");
            return true;
        }

        std::string error = sPartyBotMgr->AddBot(handler->GetSession()->GetPlayer(), args);
        handler->SendSysMessage(error.empty() ? "Party bot is logging in..." : error.c_str());
        return true;
    }

    static bool HandleRemoveCommand(ChatHandler* handler, char const* args)
    {
        std::string error = sPartyBotMgr->RemoveBot(handler->GetSession()->GetPlayer(), args ? args : "");
        handler->SendSysMessage(error.empty() ? "Party bot dismissed." : error.c_str());
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
