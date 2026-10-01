/*
 * Dungeon bots (#140, docs/dungeon_bots.md), piece C: the run manager. `.partybot dungeontest <dungeon id | name |
 * random> [level]` (GM) starts a run: five bots of the GM's faction, 1 tank, 1 healer and 3 DPS of different specs, at
 * max(15, level, the dungeon's minimum level): idle level bots of that level first, else new ones (CreateLevelBot).
 * Their sessions run in dungeon mode (PartyBotSession::DungeonSetup / DungeonUpdate below):
 *
 *  1. login: the four others follow the tank (PartyBotAI with the tank as leader); the tank has no AI yet.
 *  2. queue: once all five are in, the tank forms the group (leader) and joins the Dungeon Finder as tank; every bot's
 *     session answers the role check and accepts the proposal (LFGMgr::AnswerForBot: the tank has no AI before the
 *     dungeon, and no AI runs while a bot is dead). The Dungeon Finder makes its LFG group and teleports them in.
 *  3. dungeon: the tank gets the leader AI (DungeonBotAI.cpp, a new one per dungeon) until it calls DungeonRunEnded.
 *  4. leave: the AI goes, the bots leave the group (the Dungeon Finder teleports each out), and the same five queue
 *     again for the random dungeon of their level under a new run id (phase 2), until .partybot dungeontest stop.
 *
 * At most MaxDungeonRuns runs at a time. Log category server.questbot (as the quest bot):
 *
 *   DUNGEONBOT event=create run=<id> dungeon=<lfg id> "<name>" level=<n> by=<gm> bots=<name>:<spec>:<role>,...
 *   DUNGEONBOT event=group|queue|enter|requeue run=<id> ...
 *   DUNGEONBOT event=end run=<id> pass=<n> dungeon=<id> "<name>" cleared=<0|1> time=<s> levels=<name>:<level>,... next=requeue|stop reason=<...>
 *
 * The steps run in the tank's session update (on its map, all maps share one thread: MapUpdate.Threads = 1). RunLock
 * guards the registry; recursive, as B's AI may report the end from inside a step.
 */
#include "PartyBot.h"
#include "AccountMgr.h"
#include "Containers.h"
#include "DatabaseEnv.h"
#include "DB2Stores.h"
#include "GameTime.h"
#include "Group.h"
#include "GroupMgr.h"
#include "LFGMgr.h"
#include "Log.h"
#include "Map.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "World.h"
#include <boost/algorithm/string.hpp>
#include <algorithm>
#include <list>
#include <sstream>

namespace
{
    uint32 const MaxDungeonRuns     = 4;                                // all instances share the one map-update thread
    uint8 const MinBotLevel         = 15;
    uint32 const LoginTimeoutMs     = 3 * MINUTE * IN_MILLISECONDS;
    uint32 const QueueTimeoutMs     = 3 * MINUTE * IN_MILLISECONDS;     // role check 45 s + proposal 45 s; a full group matches at once
    uint32 const LeaveTimeoutMs     = 2 * MINUTE * IN_MILLISECONDS;
    uint32 const MaxFailedPasses    = 3;                                // dungeons in a row not cleared: stop, no endless requeue
    time_t const TankGoneSec        = 4 * MINUTE;                       // the tank's session hasn't run the run this long: stop
    uint32 const LeaveForceMs       = 15 * IN_MILLISECONDS;             // still in the dungeon: teleport out without the Dungeon Finder

    enum class Step { Login, Queued, Dungeon, Ending, Leaving };

    struct Member
    {
        ObjectGuid Guid;
        std::string Name;
        uint32 Spec;
        uint8 Role;                                     // lfg::LfgRoles
        std::weak_ptr<PartyBotSession> Session;
        bool Ready;                                     // logged in and set up (its session's DungeonUpdate ran)
    };

    struct DungeonRun
    {
        uint32 Id;                                      // this dungeon's run id (B's runId); a new one for every dungeon
        uint32 Pass;
        uint32 Queue;                                   // the LFG dungeon to queue for (a random one after the first)
        uint32 Dungeon;                                 // the one the Dungeon Finder chose (set at enter)
        uint8 Level;
        std::string By;
        Step State;
        uint32 StepMs;
        uint32 RunMs;
        bool Cleared;
        std::string Reason;
        std::vector<Member> Members;                    // [0] the tank, the group's leader
        uint32 Fails = 0;                               // dungeons in a row not cleared
        time_t TankSeen = 0;                            // the tank's session last ran the run's steps

        Member* Find(ObjectGuid guid)
        {
            for (Member& member : Members)
                if (member.Guid == guid)
                    return &member;
            return nullptr;
        }
    };

    std::recursive_mutex RunLock;
    std::list<DungeonRun> Runs;
    uint32 NextRunId = 0;

    uint8 RoleOf(ChrSpecializationEntry const* spec)
    {
        return spec->Role == 0 ? lfg::PLAYER_ROLE_TANK : spec->Role == 1 ? lfg::PLAYER_ROLE_HEALER : lfg::PLAYER_ROLE_DAMAGE;
    }

    char const* RoleName(uint8 role)
    {
        return role == lfg::PLAYER_ROLE_TANK ? "tank" : role == lfg::PLAYER_ROLE_HEALER ? "healer" : "dps";
    }

    std::string SpecName(uint32 specId)
    {
        ChrSpecializationEntry const* spec = sChrSpecializationStore.LookupEntry(specId);
        if (!spec)
            return std::to_string(specId);
        return std::string(spec->Name->Str[DEFAULT_LOCALE]) + " " + sChrClassesStore.AssertEntry(spec->ClassID)->Name->Str[DEFAULT_LOCALE];
    }

    std::string DungeonName(uint32 id)
    {
        lfg::LFGDungeonData const* dungeon = sLFGMgr->GetLFGDungeon(id);
        return dungeon ? dungeon->name : "?";
    }

    // the specs of a role a character of this level can have, in random order
    // below 30 several tank and healer specs lack their core spells (Ironfur / Ironskin Brew at 20, Holy Paladin no damage
    // spell until 26, Lifebloom 20...): the first runs (2026-10-01) wiped with a Brewmaster and a Holy Paladin at 15.
    // There: Protection Warrior tanks, Holy Priest / Restoration Shaman / Mistweaver heal
    bool StrongAtLevel(uint32 specId, uint8 role, uint8 level)
    {
        return role == lfg::PLAYER_ROLE_DAMAGE || level >= 30 || specId == 73 || specId == 257 || specId == 264 || specId == 270;
    }

    std::vector<uint32> SpecsFor(uint8 role, uint8 level)
    {
        std::vector<uint32> specs;
        for (uint8 cls = CLASS_WARRIOR; cls < MAX_CLASSES; ++cls)
        {
            if ((cls == CLASS_DEATH_KNIGHT && level < 55) || (cls == CLASS_DEMON_HUNTER && level < 98))
                continue;                               // their characters start at 55 / 98
            for (uint32 i = 0; i < MAX_SPECIALIZATIONS; ++i)
                if (ChrSpecializationEntry const* spec = sDB2Manager.GetChrSpecializationByIndex(cls, i))
                    if (RoleOf(spec) == role && StrongAtLevel(spec->ID, role, level))
                        specs.push_back(spec->ID);
        }
        Trinity::Containers::RandomShuffle(specs);
        return specs;
    }

    bool InRun(ObjectGuid guid)
    {
        std::lock_guard<std::recursive_mutex> guard(RunLock);
        for (DungeonRun& run : Runs)
            if (run.Find(guid))
                return true;
        return false;
    }

    // the normal random dungeon of this level, the newest one it fits (60: Lich King before Classic; 100: Legion)
    lfg::LFGDungeonData const* RandomDungeon(uint8 level, uint32 team)
    {
        lfg::LFGDungeonData const* best = nullptr;
        for (LFGDungeonsEntry const* entry : sLfgDungeonsStore)
            if (entry->TypeID == LFG_TYPE_RANDOM && entry->Substruct == LFG_QUEUE_DUNGEON && entry->DifficultyID == DIFFICULTY_NORMAL
                && entry->MinLevel <= level && level <= entry->MaxLevel && entry->FitsTeam(team))
                if (lfg::LFGDungeonData const* dungeon = sLFGMgr->GetLFGDungeon(entry->ID))
                    if (!best || dungeon->minlevel > best->minlevel || (dungeon->minlevel == best->minlevel && dungeon->expansion > best->expansion))
                        best = dungeon;
        return best;
    }

    // a 5-man Dungeon Finder dungeon by LFG id (a random one too) or by name: case-insensitive, a unique part of a name
    // will do; of several with that name (normal, heroic, timewalking) the lowest difficulty
    lfg::LFGDungeonData const* FindDungeon(std::string const& text, uint32 team, std::string& error)
    {
        auto usable = [team](LFGDungeonsEntry const* entry, bool random)
        {
            return entry && (entry->TypeID == LFG_TYPE_DUNGEON || (random && entry->TypeID == LFG_TYPE_RANDOM))
                && entry->Substruct == LFG_QUEUE_DUNGEON && entry->FitsTeam(team);
        };

        lfg::LFGDungeonData const* found = nullptr;
        if (isdigit(uint8(text[0])))
        {
            if (usable(sLfgDungeonsStore.LookupEntry(atoi(text.c_str())), true))
                found = sLFGMgr->GetLFGDungeon(uint32(atoi(text.c_str())));
            if (!found)
                error = "No 5-man Dungeon Finder dungeon with id " + text + " for your faction.";
        }
        else
        {
            std::vector<lfg::LFGDungeonData const*> exact, partial;
            for (LFGDungeonsEntry const* entry : sLfgDungeonsStore)
                if (usable(entry, false))
                    if (lfg::LFGDungeonData const* dungeon = sLFGMgr->GetLFGDungeon(entry->ID))
                    {
                        if (boost::iequals(dungeon->name, text))
                            exact.push_back(dungeon);
                        else if (boost::icontains(dungeon->name, text))
                            partial.push_back(dungeon);
                    }

            std::vector<lfg::LFGDungeonData const*> const& matches = exact.empty() ? partial : exact;
            std::set<std::string> names;
            for (lfg::LFGDungeonData const* dungeon : matches)
            {
                names.insert(dungeon->name);
                if (!found || dungeon->difficulty < found->difficulty || (dungeon->difficulty == found->difficulty && dungeon->id < found->id))
                    found = dungeon;
            }
            if (names.size() != 1)
            {
                found = nullptr;
                error = names.empty() ? "No Dungeon Finder dungeon named '" + text + "'." : "'" + text + "' fits several dungeons:";
                for (std::string const& name : names)
                    error += " " + name + ",";
                error.back() = '.';
            }
        }

        if (found && found->type != LFG_TYPE_RANDOM && !found->x && !found->y && !found->z)
        {
            error = found->name + " (" + std::to_string(found->id) + ") has no entrance position (lfg_entrances / area trigger).";
            found = nullptr;
        }
        return found;
    }

    void SetStep(DungeonRun& run, Step step)
    {
        run.State = step;
        run.StepMs = 0;
    }

    void LogEnd(DungeonRun const& run, char const* next, std::string const& reason)
    {
        std::ostringstream levels;
        for (Member const& member : run.Members)
        {
            Player* player = ObjectAccessor::FindPlayer(member.Guid);
            levels << (levels.tellp() ? "," : "") << member.Name << ':' << (player ? uint32(player->getLevel()) : 0);
        }
        uint32 dungeon = run.Dungeon ? run.Dungeon : run.Queue;
        TC_LOG_INFO("server.questbot", "DUNGEONBOT event=end run=%u pass=%u dungeon=%u \"%s\" cleared=%u time=%u levels=%s next=%s reason=%s",
            run.Id, run.Pass, dungeon, DungeonName(dungeon).c_str(), uint32(run.Cleared), run.RunMs / IN_MILLISECONDS, levels.str().c_str(),
            next, reason.c_str());
    }

    // the run ends for good: its bots log out (their sessions dismiss themselves once the run is gone)
    void StopRun(std::list<DungeonRun>::iterator itr, std::string const& reason)
    {
        LogEnd(*itr, "stop", reason);
        for (Member const& member : itr->Members)
            if (std::shared_ptr<PartyBotSession> session = member.Session.lock())
                session->RequestDismiss();
        Runs.erase(itr);
    }

    // a bot's AI swapped (the tank: the leader AI in the dungeon, none outside); the old one deleted
    void ReplaceAI(Player* bot, PlayerAI* ai)
    {
        bot->IsAIEnabled = false;
        UnitAI* old = bot->GetAI();
        bot->SetAI(ai);
        delete old;
        bot->IsAIEnabled = ai != nullptr;
    }

    // all five in the world, logged in and set up, not between maps
    bool Settled(DungeonRun const& run, std::vector<Player*> const& players)
    {
        for (size_t i = 0; i < players.size(); ++i)
            if (!players[i] || !run.Members[i].Ready || players[i]->IsBeingTeleported())
                return false;
        return true;
    }

    // the group (the tank leads) joins the Dungeon Finder; the role check and the proposal are answered by the bots'
    // sessions, then the Dungeon Finder makes its own LFG group and teleports them in
    void Queue(std::list<DungeonRun>::iterator itr, std::vector<Player*> const& players)
    {
        DungeonRun& run = *itr;
        Player* tank = players[0];
        for (Player* player : players)
        {
            if (player->isDead(false))          // the Dungeon Finder doesn't teleport the dead in
            {
                player->ResurrectPlayer(1.0f);
                player->SpawnCorpseBones();
            }
            player->RemoveAurasDueToSpell(lfg::LFG_SPELL_DUNGEON_COOLDOWN);    // the last random dungeon's: refuses any queue
            player->RemoveAurasDueToSpell(lfg::LFG_SPELL_DUNGEON_DESERTER);
            if (Group* old = player->GetGroup())   // a reused character can come with a group of its own
                old->RemoveMember(player->GetGUID());
        }

        Group* group = new Group;
        if (!group->Create(tank))
        {
            delete group;
            StopRun(itr, "the group could not be created");
            return;
        }
        sGroupMgr->AddGroup(group);
        for (size_t i = 1; i < players.size(); ++i)
            if (!group->AddMember(players[i]))
            {
                StopRun(itr, std::string(players[i]->GetName()) + " could not join the group");
                return;
            }
        TC_LOG_INFO("server.questbot", "DUNGEONBOT event=group run=%u leader=%s members=%u", run.Id, tank->GetName(), group->GetMembersCount());

        lfg::LFGDungeonData const* dungeon = sLFGMgr->GetLFGDungeon(run.Queue);
        lfg::LfgDungeonSet dungeons = { dungeon->dbc->Entry() };
        sLFGMgr->JoinLfg(tank, lfg::PLAYER_ROLE_LEADER | lfg::PLAYER_ROLE_TANK, dungeons);

        // the join result goes to the (absent) client: a refused join leaves the group's state at none. Why: each bot's
        // lock on the dungeon (LfgLockStatusType)
        lfg::LfgState state = sLFGMgr->GetState(group->GetGUID(), 0);
        bool joined = state == lfg::LFG_STATE_ROLECHECK || state == lfg::LFG_STATE_QUEUED;
        std::ostringstream locks;
        if (!joined)
            for (Player* player : players)
            {
                lfg::LfgLockMap lockMap = sLFGMgr->GetLockedDungeons(player->GetGUID());
                auto lock = lockMap.find(dungeon->dbc->Entry());
                if (lock != lockMap.end())
                    locks << (locks.tellp() ? "," : "") << player->GetName() << ':' << lock->second.status;
            }
        TC_LOG_INFO("server.questbot", "DUNGEONBOT event=queue run=%u dungeon=%u \"%s\" level=%u result=%s state=%u locks=%s", run.Id, dungeon->id,
            dungeon->name.c_str(), uint32(run.Level), joined ? "OK" : "REFUSED", uint32(state), locks.tellp() ? locks.str().c_str() : "-");
        if (!joined)
        {
            StopRun(itr, "the Dungeon Finder refused the queue");
            return;
        }
        SetStep(run, Step::Queued);
    }

    // phase 2: the next dungeon, the random one of the bots' (lowest) level, under a new run id
    void Requeue(std::list<DungeonRun>::iterator itr, std::vector<Player*> const& players)
    {
        DungeonRun& run = *itr;
        uint8 level = players[0]->getLevel();
        for (Player* player : players)
            level = std::min(level, player->getLevel());

        lfg::LFGDungeonData const* dungeon = RandomDungeon(level, players[0]->GetTeam());
        if (!dungeon)
        {
            StopRun(itr, "no random dungeon for level " + std::to_string(level));
            return;
        }

        uint32 previous = run.Id;
        run.Id = ++NextRunId;
        ++run.Pass;
        run.Queue = dungeon->id;
        run.Dungeon = 0;
        run.Level = level;
        run.Cleared = false;
        run.Reason.clear();
        run.RunMs = 0;
        TC_LOG_INFO("server.questbot", "DUNGEONBOT event=requeue run=%u previous=%u pass=%u level=%u dungeon=%u \"%s\"", run.Id, previous, run.Pass,
            uint32(level), dungeon->id, dungeon->name.c_str());
        Queue(itr, players);
    }

    // the run's next step, from the tank's session update (RunLock held). Nothing may touch the run after StopRun
    void RunStep(std::list<DungeonRun>::iterator itr, Player* tank, uint32 diff)
    {
        DungeonRun& run = *itr;
        run.StepMs += diff;
        run.RunMs += diff;

        std::vector<Player*> players;           // as run.Members; null: not in the world
        for (Member const& member : run.Members)
        {
            Player* player = ObjectAccessor::FindPlayer(member.Guid);
            players.push_back(player && player->IsInWorld() ? player : nullptr);
        }

        switch (run.State)
        {
            case Step::Login:
                if (Settled(run, players))
                    Queue(itr, players);
                else if (run.StepMs > LoginTimeoutMs)
                    StopRun(itr, "not all five bots logged in within 3 min");
                return;
            case Step::Queued:
            {
                Group* group = tank->GetGroup();
                if (group && group->isLFGGroup() && !tank->IsBeingTeleported() && tank->GetMap()->IsDungeon())
                {
                    run.Dungeon = sLFGMgr->GetDungeon(group->GetGUID());
                    TC_LOG_INFO("server.questbot", "DUNGEONBOT event=enter run=%u dungeon=%u \"%s\" map=%u instance=%u bot=%s wait=%u",
                        run.Id, run.Dungeon, DungeonName(run.Dungeon).c_str(), tank->GetMapId(), tank->GetInstanceId(), tank->GetName(),
                        run.StepMs / IN_MILLISECONDS);
                    ReplaceAI(tank, NewDungeonLeaderAI(tank, run.Id));
                    SetStep(run, Step::Dungeon);
                }
                else if (run.StepMs > QueueTimeoutMs)
                    StopRun(itr, "not in the dungeon 3 min after the queue (Dungeon Finder state " +
                        std::to_string(group ? uint32(sLFGMgr->GetState(group->GetGUID(), 0)) : 0) + ")");
                return;
            }
            case Step::Dungeon:                 // the leader AI runs it and reports the end (DungeonRunEnded)
                if (!tank->IsBeingTeleported() && !tank->GetMap()->IsDungeon())
                {
                    run.Cleared = false;
                    run.Reason = "the tank left the dungeon";
                    SetStep(run, Step::Ending);
                }
                return;
            case Step::Ending:
                // wait until nobody is between maps: the Dungeon Finder's teleport out skips a bot in a teleport
                if (!Settled(run, players) && run.StepMs < LeaveTimeoutMs)
                    return;
                run.Fails = run.Cleared ? 0 : run.Fails + 1;
                if (run.Fails < MaxFailedPasses)        // else StopRun logs the end once everyone is out
                    LogEnd(run, "requeue", run.Reason);
                ReplaceAI(tank, nullptr);
                // leaving the LFG group clears the Dungeon Finder state and teleports each out (LFGGroupScript::OnRemoveMember);
                // the tank (leader) last
                for (size_t i = players.size(); i-- > 0;)
                    if (players[i])
                        if (Group* group = players[i]->GetGroup())
                            group->RemoveMember(players[i]->GetGUID());
                SetStep(run, Step::Leaving);
                return;
            case Step::Leaving:
            {
                bool out = true;
                for (Player* player : players)
                {
                    if (!player || player->IsBeingTeleported())
                        out = false;
                    else if (player->GetMap()->IsDungeon())
                    {
                        out = false;
                        if (run.StepMs > LeaveForceMs)
                            player->TeleportTo(player->GetBattlegroundEntryPoint());    // where the Dungeon Finder took it from
                    }
                }
                if (out && run.Fails >= MaxFailedPasses)    // a dungeon the bots can't do at all: no endless requeue (dev-check)
                    StopRun(itr, run.Reason + "; " + std::to_string(MaxFailedPasses) + " dungeons in a row not cleared");
                else if (out)
                    Requeue(itr, players);
                else if (run.StepMs > LeaveTimeoutMs)
                    StopRun(itr, "not all five bots got out of the dungeon within 2 min");
                return;
            }
        }
    }
}

// B's leader AI: the dungeon is over (all bosses dead, or given up). The tank's next session update leaves and requeues
void DungeonRunEnded(uint32 runId, bool cleared, std::string const& reason)
{
    std::lock_guard<std::recursive_mutex> guard(RunLock);
    for (DungeonRun& run : Runs)
        if (run.Id == runId && run.State == Step::Dungeon)
        {
            run.Cleared = cleared;
            run.Reason = reason;
            SetStep(run, Step::Ending);
        }
}

uint32 DungeonRunDungeonId(uint32 runId)
{
    std::lock_guard<std::recursive_mutex> guard(RunLock);
    for (DungeonRun const& run : Runs)
        if (run.Id == runId)
            return run.Dungeon;
    return 0;
}

// ---------------------------------------------------------------- session (dungeon mode)

// the four others follow the tank; the tank gets its AI in the dungeon (RunStep)
void PartyBotSession::DungeonSetup(Player* bot)
{
    std::lock_guard<std::recursive_mutex> guard(RunLock);
    for (DungeonRun& run : Runs)
        for (size_t i = 0; i < run.Members.size(); ++i)
            if (run.Members[i].Guid == _botGuid)
            {
                if (i)
                {
                    bot->SetAI(new PartyBotAI(bot, _leaderGuid, uint8(i - 1)));
                    bot->IsAIEnabled = true;
                }
                return;
            }
    Dismiss();                                  // the run was stopped while the bot logged in
}

void PartyBotSession::DungeonUpdate(Player* bot, uint32 diff)
{
    bool tank = _botGuid == _leaderGuid;
    if (tank && bot->isDead(false))             // Player::Update runs no AI while dead: B's wipe handling
        DungeonLeaderDeadUpdate(bot, diff);

    // the Dungeon Finder's role check and "dungeon ready" proposal, as a client would answer them
    if (_answerTimer > diff)
        _answerTimer -= diff;
    else
    {
        _answerTimer = IN_MILLISECONDS;
        if (Group* group = bot->GetGroup())
            sLFGMgr->AnswerForBot(group->GetGUID(), _botGuid, _dungeonRole);
    }

    std::lock_guard<std::recursive_mutex> guard(RunLock);
    auto itr = std::find_if(Runs.begin(), Runs.end(), [this](DungeonRun& run) { return run.Find(_botGuid) != nullptr; });
    if (itr == Runs.end())                      // stopped
    {
        Dismiss();
        return;
    }
    itr->Find(_botGuid)->Ready = true;
    if (tank)
    {
        itr->TankSeen = GameTime::GetGameTime();
        RunStep(itr, bot, diff);
    }
    // only the tank's session runs the steps and their timeouts: a tank whose login failed or who was kicked would keep
    // the run (and these bots) up until .partybot dungeontest stop (dev-check)
    else if (GameTime::GetGameTime() - itr->TankSeen > TankGoneSec)
        StopRun(itr, "the tank's session is gone");
}

// ---------------------------------------------------------------- manager

std::string PartyBotMgr::PickDungeonBot(uint8 role, uint8 level, bool alliance, std::set<uint32>& usedSpecs, ObjectGuid& guid, uint32& specId)
{
    // an idle level bot (CreateLevelBot: setup 2 or 3; the level-110 party bots stay for .partybot add) of this level and faction
    if (QueryResult result = CharacterDatabase.PQuery("SELECT c.guid, p.spec, c.race, c.account FROM partybot_characters p "
        "JOIN characters c ON c.guid = p.guid WHERE p.setup >= 2 AND c.level = %u AND c.online = 0", uint32(level)))
        do
        {
            Field* fields = result->Fetch();
            ObjectGuid candidate = ObjectGuid::Create<HighGuid::Player>(fields[0].GetUInt64());
            ChrSpecializationEntry const* spec = sChrSpecializationStore.LookupEntry(fields[1].GetUInt32());
            uint32 account = fields[3].GetUInt32();
            if (!spec || RoleOf(spec) != role || !StrongAtLevel(spec->ID, role, level) || usedSpecs.count(spec->ID)
                || (Player::TeamForRace(fields[2].GetUInt8()) == ALLIANCE) != alliance
                || ObjectAccessor::FindPlayer(candidate) || sWorld->FindSession(account) || InRun(candidate))
                continue;

            bool busy = false;                  // a bot session added this tick (sWorld->FindSession doesn't see it yet)
            {
                std::lock_guard<std::mutex> guard(_lock);
                for (auto const& bot : _bots)
                    if (std::shared_ptr<PartyBotSession> session = bot.lock())
                        busy = busy || session->GetAccountId() == account;
            }
            if (busy)
                continue;

            guid = candidate;
            specId = spec->ID;
            usedSpecs.insert(specId);
            return "";
        } while (result->NextRow());

    for (uint32 id : SpecsFor(role, level))
        if (!usedSpecs.count(id))
        {
            std::string name;
            std::string error = CreateLevelBot(id, level, alliance, name, guid);
            if (!error.empty())
                return error;
            specId = id;
            usedSpecs.insert(id);
            return "";
        }
    return std::string("no ") + RoleName(role) + " spec left";
}

std::shared_ptr<PartyBotSession> PartyBotMgr::StartDungeonBot(ObjectGuid guid, ObjectGuid tankGuid, uint8 role)
{
    uint32 accountId = ObjectMgr::GetPlayerAccountIdByGUID(guid);
    std::string accountName;
    if (!accountId || !AccountMgr::GetName(accountId, accountName))
        return nullptr;

    std::shared_ptr<PartyBotSession> session = std::make_shared<PartyBotSession>(accountId, std::move(accountName), guid, tankGuid, 0, role);
    {
        std::lock_guard<std::mutex> guard(_lock);
        _bots.push_back(session);
    }
    sWorld->AddSession(session);
    return session;
}

std::string PartyBotMgr::StartDungeonTest(Player* gm, std::string text)
{
    static char const* const Usage = "Usage: .partybot dungeontest <dungeon id | name | random> [level] | stop   "
        "e.g. .partybot dungeontest deadmines, .partybot dungeontest random 20";
    // the run steps touch players and groups of other maps (group, resurrect, Dungeon Finder state): only safe while all
    // maps update on one thread (dev-check)
    if (sWorld->getIntConfig(CONFIG_NUMTHREADS) != 1)
        return "Dungeon tests need MapUpdate.Threads = 1 in worldserver.conf.";
    {
        std::lock_guard<std::recursive_mutex> guard(RunLock);
        if (Runs.size() >= MaxDungeonRuns)
            return "Already " + std::to_string(MaxDungeonRuns) + " dungeon tests running (.partybot dungeontest stop ends them).";
    }

    uint32 level = 0;
    boost::trim(text);
    size_t space = text.find_last_of(' ');
    if (space != std::string::npos && text.find_first_not_of("0123456789", space + 1) == std::string::npos)
    {
        level = std::min<uint32>(atoi(text.c_str() + space + 1), 255);
        text.resize(space);
        boost::trim(text);
    }
    if (text.empty())
        return Usage;

    uint32 team = gm->GetTeam();
    uint32 maxLevel = sWorld->getIntConfig(CONFIG_MAX_PLAYER_LEVEL);
    level = std::max<uint32>(level, MinBotLevel);
    lfg::LFGDungeonData const* dungeon;
    if (boost::iequals(text, "random"))
    {
        if (!(dungeon = RandomDungeon(uint8(level), team)))
            return "No random dungeon for level " + std::to_string(level) + ".";
    }
    else
    {
        std::string error;
        if (!(dungeon = FindDungeon(text, team, error)))
            return error;
        level = std::max<uint32>(level, dungeon->minlevel);
        if (dungeon->maxlevel && level > dungeon->maxlevel)
            return dungeon->name + " is for levels " + std::to_string(dungeon->minlevel) + "-" + std::to_string(dungeon->maxlevel) + ".";
    }
    if (level > maxLevel)
        return "Level " + std::to_string(level) + " is above the maximum level " + std::to_string(maxLevel) + ".";

    // the five: tank, healer, 3 different DPS specs
    DungeonRun run = { 0, 1, dungeon->id, 0, uint8(level), gm->GetName(), Step::Login, 0, 0, false, "", { } };
    std::set<uint32> specs;
    for (uint8 role : { lfg::PLAYER_ROLE_TANK, lfg::PLAYER_ROLE_HEALER, lfg::PLAYER_ROLE_DAMAGE, lfg::PLAYER_ROLE_DAMAGE, lfg::PLAYER_ROLE_DAMAGE })
    {
        Member member = { ObjectGuid::Empty, "", 0, role, { }, false };
        std::string error = PickDungeonBot(role, uint8(level), team == ALLIANCE, specs, member.Guid, member.Spec);
        if (!error.empty())     // the characters made so far stay: idle bots of this level for the next try
            return std::string("No ") + RoleName(role) + " bot: " + error;
        ObjectMgr::GetPlayerNameByGUID(member.Guid, member.Name);
        run.Members.push_back(member);
    }

    std::ostringstream bots;
    for (Member const& member : run.Members)
        bots << (bots.tellp() ? "," : "") << member.Name << ':' << SpecName(member.Spec) << ':' << RoleName(member.Role);

    std::lock_guard<std::recursive_mutex> guard(RunLock);
    if (Runs.size() >= MaxDungeonRuns)          // other GMs started some meanwhile
        return "Already " + std::to_string(MaxDungeonRuns) + " dungeon tests running (.partybot dungeontest stop ends them).";
    run.Id = ++NextRunId;
    Runs.push_back(run);
    DungeonRun& added = Runs.back();
    added.TankSeen = GameTime::GetGameTime();
    TC_LOG_INFO("server.questbot", "DUNGEONBOT event=create run=%u dungeon=%u \"%s\" level=%u by=%s bots=%s", added.Id, dungeon->id,
        dungeon->name.c_str(), uint32(level), gm->GetName(), bots.str().c_str());
    for (Member& member : added.Members)
    {
        std::shared_ptr<PartyBotSession> session = StartDungeonBot(member.Guid, added.Members[0].Guid, member.Role);
        if (!session)                           // the run stops at the login timeout
            TC_LOG_INFO("server.questbot", "DUNGEONBOT event=create run=%u bot=%s result=NO_ACCOUNT", added.Id, member.Name.c_str());
        member.Session = session;
    }

    return "Dungeon test run " + std::to_string(added.Id) + ": " + dungeon->name + " (" + std::to_string(dungeon->id) + ") at level " +
        std::to_string(level) + ", bots " + bots.str() + ". Log: DUNGEONBOT lines in Server.log; .partybot dungeontest stop ends it.";
}

uint32 PartyBotMgr::StopDungeonTests()
{
    std::lock_guard<std::recursive_mutex> guard(RunLock);
    uint32 stopped = uint32(Runs.size());
    while (!Runs.empty())
        StopRun(Runs.begin(), "stopped (.partybot dungeontest stop)");
    return stopped;
}
