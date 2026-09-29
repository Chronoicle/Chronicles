/*
 * .challenge <player>   challenge an online player to a 1v1 arena
 * .challenge accept     accept your pending challenge: both players get the normal "Enter Arena" invite
 * .challenge decline    decline it
 * The match is a war game (BattlegroundMgr::InitWargame path with one player per side): unrated, no honor,
 * conquest, rating, deserter or rewards; Principles of War applies like in every arena. Requests expire after 60 s (#57).
 */
#include "ScriptMgr.h"
#include "Chat.h"
#include "Player.h"
#include "Group.h"
#include "Map.h"
#include "ObjectAccessor.h"
#include "GlobalFunctional.h"
#include "GameTime.h"
#include "DB2Stores.h"
#include "DisableMgr.h"
#include "BattlegroundMgr.h"
#include <boost/algorithm/string/predicate.hpp>

namespace
{
    struct ChallengeRequest
    {
        ObjectGuid Challenger;
        time_t Expires;
    };

    std::map<ObjectGuid, ChallengeRequest> PendingChallenges; // challenged player -> request
    std::map<ObjectGuid, time_t> ChallengeCooldowns;          // challenger -> earliest next challenge

    time_t const ChallengeTimeout = 60;
    time_t const ChallengeCooldown = 30;
}

class challenge_commandscript : public CommandScript
{
public:
    challenge_commandscript() : CommandScript("challenge_commandscript") { }

    std::vector<ChatCommand> GetCommands() const override
    {
        static std::vector<ChatCommand> commandTable =
        {
            { "challenge", SEC_PLAYER, false, &HandleChallengeCommand, "" },
        };
        return commandTable;
    }

    // nullptr when the player may start or join a challenge, otherwise the reason
    static char const* CannotFight(Player* player)
    {
        if (!player->IsAlive())
            return "dead";
        if (player->isInCombat())
            return "in combat";
        if (player->duel)
            return "in a duel";
        if (player->isInFlight())
            return "on a flight";
        if (player->InBattleground() || player->InBattlegroundQueue() || player->isUsingLfg())
            return "in a battleground, arena or queue";
        if (player->GetMap()->Instanceable())
            return "in an instance";
        if (Group* group = player->GetGroup())
            if (!group->GetMaxCountOfRolesForArenaQueue(ROLES_HEALER) || !group->GetMaxCountOfRolesForArenaQueue(ROLES_TANK))
                return "in a group with more than one healer or tank";
        return nullptr;
    }

    static bool CheckBoth(ChatHandler* handler, Player* player, Player* other)
    {
        if (char const* reason = CannotFight(player))
        {
            handler->PSendSysMessage("You can't fight a challenge now (%s).", reason);
            return false;
        }
        if (char const* reason = CannotFight(other))
        {
            handler->PSendSysMessage("%s can't fight a challenge now (%s).", other->GetName(), reason);
            return false;
        }
        if (player->GetGroup() && player->GetGroup() == other->GetGroup())
        {
            handler->SendSysMessage("You can't challenge a member of your own group.");
            return false;
        }
        return true;
    }

    // Same steps as BattlegroundMgr::InitWargame, with one player instead of a group per side
    static char const* StartChallengeArena(Player* challenger, Player* target)
    {
        uint16 const bgTypeId = MS::Battlegrounds::BattlegroundTypeId::ArenaAll;
        uint8 const joinType = MS::Battlegrounds::JoinType::Arena2v2; // Arena1v1 refuses healer and tank specs at the port

        if (DisableMgr::IsDisabledFor(DISABLE_TYPE_BATTLEGROUND, bgTypeId, nullptr))
            return "Arenas are disabled.";

        Battleground* bgTemplate = sBattlegroundMgr->GetBattlegroundTemplate(bgTypeId);
        if (!bgTemplate)
            return "No arena is available.";

        PVPDifficultyEntry const* bracketEntry = sDB2Manager.GetBattlegroundBracketByLevel(bgTemplate->GetMapId(), challenger->getLevel());
        if (!bracketEntry || bracketEntry != sDB2Manager.GetBattlegroundBracketByLevel(bgTemplate->GetMapId(), target->getLevel()))
            return "Both players must be in the same arena level bracket.";

        uint8 const bgQueueTypeId = MS::Battlegrounds::GetBgQueueTypeIdByBgTypeID(bgTypeId, joinType);
        BattlegroundQueue& bgQueue = sBattlegroundMgr->GetBattlegroundQueue(bgQueueTypeId);

        Battleground* bg = sBattlegroundMgr->CreateNewBattleground(bgTypeId, bracketEntry, joinType, false, bgQueue.GenerateRandomMap(bgTypeId), false, true);
        if (!bg)
            return "The arena could not be created.";

        auto invite = [&](Player* player, uint32 team) -> void
        {
            GroupQueueInfo* ginfo = bgQueue.AddGroup(player, nullptr, bgTypeId, bracketEntry, joinType, false, false, WorldPackets::Battleground::IgnorMapInfo(), 0, team);

            WorldPackets::Battleground::BattlefieldStatusQueued battlefieldStatus;
            sBattlegroundMgr->BuildBattlegroundStatusQueued(&battlefieldStatus, bg, player, player->AddBattlegroundQueueId(bgQueueTypeId), ginfo->JoinTime, bgQueue.GetAverageQueueWaitTime(ginfo, bracketEntry->RangeIndex), ginfo->JoinType, false);
            player->SendDirectMessage(battlefieldStatus.Write());

            bgQueue.InviteGroupToBG(ginfo, bg, team);
        };

        invite(challenger, HORDE);
        invite(target, ALLIANCE);

        bg->StartBattleground();
        return nullptr;
    }

    static bool HandleChallengeCommand(ChatHandler* handler, char const* args)
    {
        char* arg = strtok((char*)args, " ");
        if (!arg)
        {
            handler->SendSysMessage("Usage: .challenge <player>   challenge an online player to an unrated 1v1 arena");
            handler->SendSysMessage("       .challenge accept | decline   answer a challenge");
            return true;
        }

        Player* player = handler->GetSession()->GetPlayer();
        time_t now = GameTime::GetGameTime();

        // drop expired requests
        for (auto itr = PendingChallenges.begin(); itr != PendingChallenges.end();)
        {
            if (itr->second.Expires <= now)
                itr = PendingChallenges.erase(itr);
            else
                ++itr;
        }

        if (boost::iequals(arg, "accept") || boost::iequals(arg, "decline"))
        {
            auto itr = PendingChallenges.find(player->GetGUID());
            if (itr == PendingChallenges.end())
            {
                handler->SendSysMessage("You have no pending challenge.");
                return true;
            }

            ObjectGuid challengerGuid = itr->second.Challenger;
            PendingChallenges.erase(itr);

            Player* challenger = ObjectAccessor::FindPlayer(challengerGuid);
            if (!challenger)
            {
                handler->SendSysMessage("The player who challenged you is no longer online.");
                return true;
            }

            if (boost::iequals(arg, "decline"))
            {
                handler->PSendSysMessage("You declined the challenge from %s.", challenger->GetName());
                ChatHandler(challenger).PSendSysMessage("%s declined your challenge.", player->GetName());
                return true;
            }

            if (!CheckBoth(handler, player, challenger))
            {
                ChatHandler(challenger).PSendSysMessage("%s accepted your challenge, but it could not start.", player->GetName());
                return true;
            }

            if (char const* error = StartChallengeArena(challenger, player))
            {
                handler->SendSysMessage(error);
                ChatHandler(challenger).SendSysMessage(error);
                return true;
            }

            handler->PSendSysMessage("Challenge accepted. Enter the arena to fight %s.", challenger->GetName());
            ChatHandler(challenger).PSendSysMessage("%s accepted your challenge. Enter the arena to fight.", player->GetName());
            return true;
        }

        std::string name = arg;
        Player* target = normalizePlayerName(name) ? ObjectAccessor::FindPlayerByName(name) : nullptr;
        if (!target || !target->IsInWorld() || !target->IsVisibleGloballyFor(player))
        {
            handler->SendSysMessage("That player is not online.");
            return true;
        }

        if (target == player)
        {
            handler->SendSysMessage("You can't challenge yourself.");
            return true;
        }

        auto cooldown = ChallengeCooldowns.find(player->GetGUID());
        if (cooldown != ChallengeCooldowns.end() && cooldown->second > now)
        {
            handler->PSendSysMessage("You can challenge again in %u seconds.", uint32(cooldown->second - now));
            return true;
        }

        for (auto const& itr : PendingChallenges)
        {
            if (itr.second.Challenger == player->GetGUID())
            {
                handler->SendSysMessage("You already have a pending challenge. Wait until it is answered or expires.");
                return true;
            }
        }

        if (PendingChallenges.find(target->GetGUID()) != PendingChallenges.end())
        {
            handler->PSendSysMessage("%s already has a pending challenge.", target->GetName());
            return true;
        }

        if (!CheckBoth(handler, player, target))
            return true;

        PendingChallenges[target->GetGUID()] = { player->GetGUID(), now + ChallengeTimeout };
        ChallengeCooldowns[player->GetGUID()] = now + ChallengeCooldown;

        ChatHandler(target).PSendSysMessage("%s challenges you to a 1v1 arena (unrated, no rewards). Type .challenge accept or .challenge decline within %u seconds.", player->GetName(), uint32(ChallengeTimeout));
        handler->PSendSysMessage("Challenge sent to %s. It expires in %u seconds.", target->GetName(), uint32(ChallengeTimeout));
        return true;
    }
};

void AddSC_challenge_commandscript()
{
    new challenge_commandscript();
}
