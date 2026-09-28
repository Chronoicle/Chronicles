#include "PartyBot.h"
#include "AccountMgr.h"
#include "Group.h"
#include "GroupMgr.h"
#include "Log.h"
#include "MotionMaster.h"
#include "MovementPackets.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "World.h"
#include "Chat.h"
#include "GlobalFunctional.h"
#include <boost/algorithm/string/predicate.hpp>

// ---------------------------------------------------------------- session

PartyBotSession::PartyBotSession(uint32 accountId, std::string&& accountName, ObjectGuid botGuid, ObjectGuid leaderGuid) :
    WorldSession(accountId, std::move(accountName), nullptr, SEC_PLAYER, CURRENT_EXPANSION, 0, "Win", LOCALE_enUS, 0, false,
        AT_AUTH_FLAG_NONE, std::unordered_map<uint8, int64>()),
    _botGuid(botGuid), _leaderGuid(leaderGuid)
{
    SetAddress("partybot");
}

bool PartyBotSession::Update(uint32 diff, Map* map)
{
    bool result = WorldSession::Update(diff, map);
    if (map)                            // map threads only process packets; the bot steps run in the world update
        return result;

    Player* bot = GetPlayer();
    if (!_loginStarted)
    {
        _loginStarted = true;
        LoginAsBot(_botGuid);
        return result;
    }

    if (!bot)
    {
        if (!PlayerLoading())
            _done = true;               // logged out (or the login failed): the world removes the session
        return result;
    }

    AckTeleports(bot);

    if (!bot->IsInWorld())
        return result;

    FinishBotLogin();

    if (!_setupDone && !_dismissed)
        Setup(bot);

    // the leader logged out: wait a moment (reconnects, loading screens), then go too
    if (!_dismissed)
    {
        if (ObjectAccessor::FindPlayer(_leaderGuid))
            _leaderGoneTimer = 0;
        else if ((_leaderGoneTimer += diff) > 60 * IN_MILLISECONDS)
            Dismiss();
    }

    return result;
}

void PartyBotSession::AckTeleports(Player* bot)
{
    if (bot->IsBeingTeleportedFar())
        HandleWorldPortAck();
    else if (bot->IsBeingTeleportedNear())
    {
        WorldPacket data(CMSG_MOVE_TELEPORT_ACK);
        WorldPackets::Movement::MoveTeleportAck ack(std::move(data));
        ack.MoverGUID = bot->GetGUID();
        ack.ClientMoveTime = int32(getMSTime());
        HandleMoveTeleportAck(ack);
    }
}

void PartyBotSession::Setup(Player* bot)
{
    _setupDone = true;

    Player* leader = ObjectAccessor::FindPlayer(_leaderGuid);
    if (!leader)
    {
        Dismiss();
        return;
    }

    Group* group = leader->GetGroup();
    if (!group)
    {
        group = new Group;
        if (!group->Create(leader))
        {
            delete group;
            Dismiss();
            return;
        }
        sGroupMgr->AddGroup(group);
    }

    if (!group->IsMember(bot->GetGUID()))
    {
        if (group->IsFull() || !group->AddMember(bot))
        {
            ChatHandler(leader->GetSession()).PSendSysMessage("Party bot %s: your group is full.", bot->GetName());
            Dismiss();
            return;
        }
    }

    uint8 slot = sPartyBotMgr->CountBots(_leaderGuid);
    bot->SetAI(new PartyBotAI(bot, _leaderGuid, slot));
    bot->IsAIEnabled = true;

    if (bot->GetMapId() != leader->GetMapId() || !bot->IsWithinDistInMap(leader, 30.0f))
        bot->TeleportTo(leader->GetMapId(), leader->GetPositionX(), leader->GetPositionY(), leader->GetPositionZ(), leader->GetOrientation());

    ChatHandler(leader->GetSession()).PSendSysMessage("Party bot %s joined your group.", bot->GetName());
}

void PartyBotSession::Dismiss()
{
    if (_dismissed)
        return;
    _dismissed = true;

    if (Player* bot = GetPlayer())
    {
        if (bot->IsAIEnabled)
        {
            bot->IsAIEnabled = false;
            UnitAI* ai = bot->GetAI();
            bot->SetAI(nullptr);
            delete ai;
        }
        if (Group* group = bot->GetGroup())
            group->RemoveMember(bot->GetGUID());
    }

    LogoutRequest(time(nullptr) - 20);  // WorldSession::Update logs out on the next tick (saves the character)
}

// ---------------------------------------------------------------- AI

void PartyBotAI::FollowLeader(Player* leader)
{
    if (me->GetMotionMaster()->GetCurrentMovementGeneratorType() == FOLLOW_MOTION_TYPE)
        return;

    // spread out behind the leader: slots 0..3 at 2.5 yd, left/right behind
    static float const angles[] = { float(M_PI) * 0.75f, float(M_PI) * 1.25f, float(M_PI) * 0.6f, float(M_PI) * 1.4f };
    me->GetMotionMaster()->MoveFollow(leader, 2.5f, angles[_slot % 4]);
}

void PartyBotAI::UpdateAI(uint32 diff)
{
    if (_checkTimer > diff)
    {
        _checkTimer -= diff;
        return;
    }
    _checkTimer = 500;

    Player* leader = ObjectAccessor::FindPlayer(_leaderGuid);
    if (!leader || !leader->IsInWorld() || me->IsBeingTeleported())
        return;

    // dead: come back when the leader is alive and out of combat
    if (me->isDead())
    {
        if (leader->IsAlive() && !leader->isInCombat())
        {
            me->ResurrectPlayer(0.5f);
            me->SpawnCorpseBones();
            me->TeleportTo(leader->GetMapId(), leader->GetPositionX(), leader->GetPositionY(), leader->GetPositionZ(), leader->GetOrientation());
        }
        return;
    }

    // other map or far away (portals, summons, the leader's hearthstone): teleport to the leader
    if (me->GetMapId() != leader->GetMapId() || !me->IsWithinDistInMap(leader, 100.0f))
    {
        if (!leader->IsBeingTeleported() && !leader->isInFlight())
            me->TeleportTo(leader->GetMapId(), leader->GetPositionX(), leader->GetPositionY(), leader->GetPositionZ(), leader->GetOrientation());
        return;
    }

    // help the leader: attack what the leader attacks
    Unit* target = leader->getVictim();
    if (target && target->IsAlive() && me->IsValidAttackTarget(target) && me->IsWithinDistInMap(target, 60.0f))
    {
        if (me->getVictim() != target)
        {
            me->Attack(target, true);
            me->GetMotionMaster()->MoveChase(target);
        }
        return;
    }

    if (me->getVictim())
        me->AttackStop();

    FollowLeader(leader);
}

// ---------------------------------------------------------------- manager

PartyBotMgr* PartyBotMgr::instance()
{
    static PartyBotMgr instance;
    return &instance;
}

void PartyBotMgr::Cleanup()
{
    _bots.erase(std::remove_if(_bots.begin(), _bots.end(), [](std::weak_ptr<PartyBotSession> const& bot)
    {
        std::shared_ptr<PartyBotSession> session = bot.lock();
        return !session || session->IsDismissed();
    }), _bots.end());
}

std::vector<std::shared_ptr<PartyBotSession>> PartyBotMgr::GetBots(ObjectGuid leaderGuid)
{
    std::lock_guard<std::mutex> guard(_lock);
    Cleanup();
    std::vector<std::shared_ptr<PartyBotSession>> result;
    for (auto const& bot : _bots)
        if (std::shared_ptr<PartyBotSession> session = bot.lock())
            if (session->GetLeaderGuid() == leaderGuid)
                result.push_back(session);
    return result;
}

uint8 PartyBotMgr::CountBots(ObjectGuid leaderGuid)
{
    return uint8(GetBots(leaderGuid).size());
}

std::string PartyBotMgr::AddBot(Player* leader, std::string name)
{
    if (!normalizePlayerName(name))
        return "Unknown character name.";

    ObjectGuid guid = ObjectMgr::GetPlayerGUIDByName(name);
    if (guid.IsEmpty())
        return "No character named " + name + ".";
    if (ObjectAccessor::FindPlayer(guid))
        return name + " is already online.";

    uint32 accountId = ObjectMgr::GetPlayerAccountIdByGUID(guid);
    if (!accountId)
        return "No account for " + name + ".";
    if (accountId == leader->GetSession()->GetAccountId())
        return name + " is on your own account; party bots need a character of another account.";
    if (sWorld->FindSession(accountId))
        return "The account of " + name + " is in use (logged in, or already a bot).";

    if (CountBots(leader->GetGUID()) >= MaxBotsPerLeader)
        return "You already have the maximum of party bots.";
    if (Group* group = leader->GetGroup())
        if (group->IsFull())
            return "Your group is full.";

    std::string accountName;
    if (!AccountMgr::GetName(accountId, accountName))
        return "No account for " + name + ".";

    std::shared_ptr<PartyBotSession> session = std::make_shared<PartyBotSession>(accountId, std::move(accountName), guid, leader->GetGUID());
    {
        std::lock_guard<std::mutex> guard(_lock);
        _bots.push_back(session);
    }
    sWorld->AddSession(session);
    TC_LOG_INFO("server.partybot", "Party bot %s (account %u) for %s", name.c_str(), accountId, leader->GetName());
    return "";
}

std::string PartyBotMgr::RemoveBot(Player* leader, std::string const& name)
{
    uint32 removed = 0;
    for (std::shared_ptr<PartyBotSession> const& session : GetBots(leader->GetGUID()))
    {
        Player* bot = session->GetPlayer();
        if (!name.empty() && (!bot || !boost::iequals(std::string(bot->GetName()), name)))
            continue;
        session->Dismiss();
        ++removed;
    }

    if (!removed)
        return name.empty() ? "You have no party bots." : "No party bot named " + name + ".";
    return "";
}
