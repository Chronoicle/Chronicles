/*
 * Dungeon bots (#140, docs/dungeon_bots.md), piece B: the tank's AI in a dungeon run. The tank leads a group of five
 * bots through the dungeon on its own: the four others keep PartyBotAI with the tank as their leader (they follow it,
 * fight its target, heal, and their sessions resurrect them next to it after a fight). Log category server.questbot,
 * every line starts with DUNGEONBOT:
 *
 *   DUNGEONBOT event=<start|pull|giveup|wipe|resurrect|...> run=<id> dungeon=<lfg id> map=<id> bot=<tank name> ...
 *   DUNGEONBOT run=<id> dungeon=<id> "<name>" boss=<entry> "<name>" result=KILLED|WIPE|EVADE|STUCK|NO_PATH|NOT_FOUND time=<s> level=<n> wipes=<n> detail=<...>
 *   DUNGEONBOT run=end run=<id> dungeon=<id> cleared=<0|1> bosses=<killed>/<total> wipes=<n> time=<s> reason=<...>
 *
 * Route = the map's instance_encounters (kill-creature credit) in DungeonEncounter.db2 order, each boss at its spawn
 * point (world.creature) or where its creature stands. Walk to the next boss with pathfinding, pull what is hostile
 * within 20 yd of the tank on the way, one pack at a time, rest between pulls. A boss is dead when its encounter bit is
 * in the instance's completed mask (or its creature is dead). Runs in Player::Update on the tank's map thread; while the
 * tank is dead Player::Update doesn't run the AI, so the run manager calls DungeonLeaderDeadUpdate from the session.
 *
 * Watch export (owner: a website to watch the runs, tools/website/botwatch.php): with PartyBot.WatchDir set, every 2 s
 * the run's state goes to <dir>/run_<id>.json (written to .tmp, then renamed): bosses, bots, the tank's trail, the last
 * 25 DUNGEONBOT lines.
 */
#include "PartyBot.h"
#include "CellImpl.h"
#include "Config.h"
#include "DB2Stores.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include "Group.h"
#include "InstanceScript.h"
#include "LFGMgr.h"
#include "Log.h"
#include "MotionMaster.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "PathGenerator.h"
#include "Player.h"
#include <algorithm>
#include <cstdarg>
#include <cstdio>
#include <ctime>
#include <deque>
#include <fstream>
#include <iomanip>
#include <sstream>

namespace
{
    uint32 const TickMs         = 500;
    uint32 const GatherMaxMs    = 2 * MINUTE * IN_MILLISECONDS;     // waiting for the group at the start, before giving up
    uint32 const RunTimeoutMs   = 2 * HOUR * IN_MILLISECONDS;
    uint32 const MoveStuckMs    = MINUTE * IN_MILLISECONDS;         // walking without getting closer (doc: 60 s)
    uint32 const RestMaxMs      = 90 * IN_MILLISECONDS;             // resting / waiting for the group, then go on anyway
    uint32 const TargetGiveUpMs = 45 * IN_MILLISECONDS;             // a target taking no damage (can't be damaged, out of reach)
    uint32 const IgnoreMs       = 2 * MINUTE * IN_MILLISECONDS;     // given-up targets
    uint32 const BossWaitMs     = MINUTE * IN_MILLISECONDS;         // at the boss spot without a boss (an event spawns it)
    uint32 const WipeResMs      = 10 * IN_MILLISECONDS;             // all dead this long: back to the entrance
    uint32 const TankResMs      = 5 * IN_MILLISECONDS;              // the tank alone dead after the fight: up where it lies
    uint8 const MaxWipes        = 3;
    float const PullRange       = 20.0f;
    float const GroupRange      = 30.0f;                            // wait for members further away
    float const BossDist        = 8.0f;                             // close enough to the boss spot
    uint32 const WatchMs        = 2 * IN_MILLISECONDS;              // watch export interval
    size_t const WatchEvents    = 25;
    size_t const WatchTrail     = 120;

    enum Result { RESULT_KILLED, RESULT_WIPE, RESULT_EVADE, RESULT_STUCK, RESULT_NO_PATH, RESULT_NOT_FOUND, MAX_RESULT };
    char const* const ResultNames[MAX_RESULT] = { "KILLED", "WIPE", "EVADE", "STUCK", "NO_PATH", "NOT_FOUND" };

    struct DungeonBoss
    {
        uint32 Entry;
        uint8 Bit;
        int32 Order;
        std::string Name;
        Position Pos;
        bool HasPos;
        uint8 Wipes;
        char const* Status;             // watch export: killed / alive / current, kept for the export after the run
        float Hp;
    };

    // PartyBot.WatchDir (worldserver.conf), read once: "" = no watch export
    std::string const& WatchDir()
    {
        static std::string const dir = sConfigMgr->GetStringDefault("PartyBot.WatchDir", "");
        return dir;
    }

    std::string JsonString(std::string const& text)
    {
        std::string out = "\"";
        for (unsigned char c : text)
        {
            if (c == '"' || c == '\\')
                out += '\\', out += char(c);
            else if (c < 0x20)
            {
                char buf[8];
                snprintf(buf, sizeof(buf), "\\u%04x", c);
                out += buf;
            }
            else
                out += char(c);
        }
        return out + '"';
    }

    char const* PowerName(Powers power)
    {
        switch (power)
        {
            case POWER_MANA: return "mana";
            case POWER_RAGE: return "rage";
            case POWER_FOCUS: return "focus";
            case POWER_ENERGY: return "energy";
            case POWER_RUNIC_POWER: return "runic power";
            case POWER_LUNAR_POWER: return "astral power";
            case POWER_MAELSTROM: return "maelstrom";
            case POWER_INSANITY: return "insanity";
            case POWER_FURY: return "fury";
            case POWER_PAIN: return "pain";
            default: return "other";
        }
    }

    // creature in range that the tank sees and the predicate accepts, the nearest (the searcher keeps the last match)
    struct NearestCheck
    {
        NearestCheck(Player* bot, float range, std::function<bool(Creature*)> const& pred) : Bot(bot), Range(range), Pred(pred) { }

        bool operator()(Creature* creature)
        {
            if (!Bot->IsWithinDistInMap(creature, Range) || !Pred(creature) || !Bot->canSeeOrDetect(creature))
                return false;
            Range = Bot->GetDistance(creature);
            return true;
        }

        Player* Bot;
        float Range;
        std::function<bool(Creature*)> const& Pred;
    };
}

class DungeonLeaderAI : public PartyBotAI
{
public:
    DungeonLeaderAI(Player* tank, uint32 runId) : PartyBotAI(tank, tank->GetGUID(), 0), _runId(runId), _name(tank->GetName()) { }
    ~DungeonLeaderAI() override;

    void UpdateAI(uint32 diff) override;
    void DeadUpdate(uint32 diff);

private:
    enum class Move { Arrived, Moving, Failed };

    bool Tick(uint32 diff);
    void Log(char const* format, ...);
    void WriteWatch(bool ended);
    void Start();
    std::vector<Player*> Members(bool aliveOnly) const;
    bool GroupInCombat() const;
    void Fight(Unit* target);
    void AfterFight();
    bool BossDone(DungeonBoss const& boss) const;
    Creature* BossCreature(DungeonBoss const& boss) const;
    void BossResult(Result result, std::string const& detail);
    void Finish(std::string const& reason);
    Move MoveTo(Position const& pos, float dist);
    Creature* NearestCreature(std::function<bool(Creature*)> const& pred, float range) const;
    bool Ignored(ObjectGuid guid) const { auto itr = _ignore.find(guid); return itr != _ignore.end() && itr->second > _runMs; }
    void Ignore(ObjectGuid guid) { _ignore[guid] = _runMs + IgnoreMs; }
    DungeonBoss* CurrentBoss() { return _bossIndex < _bosses.size() ? &_bosses[_bossIndex] : nullptr; }

    uint32 _runId;
    std::string _name;
    bool _started = false;
    bool _finished = false;
    uint32 _elapsed = 0;
    uint32 _tick = 0;
    uint32 _runMs = 0;
    uint32 _deadElapsed = 0;
    uint32 _deadMs = 0;                 // the tank dead this long
    uint32 _dungeonId = 0;
    std::string _dungeonName;
    uint32 _mapId = 0;
    Position _entrance;                 // where the group gathered: the wipe goes back here

    std::vector<DungeonBoss> _bosses;   // the route, in encounter order
    size_t _bossIndex = 0;
    uint32 _bossMs = 0;                 // time on the current boss (log)
    uint32 _bossWaitMs = 0;             // at its spot without a boss creature
    uint32 _killed = 0;
    uint32 _wipes = 0;

    bool _fighting = false;             // a fight is on (to see its end)
    bool _bossEngaged = false;          // the current boss was in this fight
    ObjectGuid _bossGuid;
    float _bossPct = 100.0f;            // its health at the last look (it resets on an evade)
    std::string _firstDead;             // who died first in this fight
    bool _wiped = false;                // all dead, waiting for the tank's resurrection at the entrance
    uint32 _restMs = 0;

    ObjectGuid _targetGuid;             // the fight's current target, for "takes no damage"
    uint64 _targetHealth = 0;
    uint32 _targetMs = 0;
    std::map<ObjectGuid, uint32> _ignore;   // guid -> until (_runMs)

    Position _moveDest;
    float _moveBest = 0.0f;
    uint32 _moveMs = 0;
    bool _noPath = false;

    // watch export
    char const* _state = "gather";      // gather / walk / pull / fight / rest / wipe / ended
    uint32 _watchMs = 0;
    std::deque<std::pair<std::string, std::string>> _events;  // UTC hh:mm:ss, line without "DUNGEONBOT "
    std::deque<Position> _trail;        // the tank, one point per export
};

PlayerAI* NewDungeonLeaderAI(Player* tank, uint32 runId)
{
    return new DungeonLeaderAI(tank, runId);
}

// the run manager calls this from the tank's session while the tank is dead (Player::Update runs no AI then)
void DungeonLeaderDeadUpdate(Player* tank, uint32 diff)
{
    if (DungeonLeaderAI* ai = dynamic_cast<DungeonLeaderAI*>(tank->GetAI()))
        ai->DeadUpdate(diff);
}

DungeonLeaderAI::~DungeonLeaderAI()
{
    // stopped (.partybot dungeontest stop); no `me` here: only the AI's own fields
    if (_started && !_finished)
    {
        Log("run=end run=%u dungeon=%u cleared=0 bosses=%u/%u wipes=%u time=%u reason=stopped",
            _runId, _dungeonId, _killed, uint32(_bosses.size()), _wipes, _runMs / IN_MILLISECONDS);
        WriteWatch(true);
    }
}

bool DungeonLeaderAI::Tick(uint32 diff)
{
    _elapsed += diff;
    if (_elapsed < TickMs)
        return false;
    _tick = _elapsed;
    _elapsed = 0;
    _runMs += _tick;
    if ((_watchMs += _tick) >= WatchMs)
    {
        _watchMs = 0;
        WriteWatch(false);
    }
    return true;
}

// a DUNGEONBOT log line, also kept for the watch export (the last 25)
void DungeonLeaderAI::Log(char const* format, ...)
{
    char text[1024];
    va_list args;
    va_start(args, format);
    vsnprintf(text, sizeof(text), format, args);
    va_end(args);
    TC_LOG_INFO("server.questbot", "DUNGEONBOT %s", text);

    if (WatchDir().empty())
        return;
    uint32 secs = uint32(time(nullptr) % DAY);
    char clock[16];
    snprintf(clock, sizeof(clock), "%02u:%02u:%02u", secs / HOUR, secs % HOUR / MINUTE, secs % MINUTE);
    _events.emplace_back(clock, text);
    if (_events.size() > WatchEvents)
        _events.pop_front();
}

// <dir>/run_<id>.json for tools/website/botwatch.php. ended: the last write (Finish, or the destructor: no `me` there,
// the bosses keep their last status and there are no bots)
void DungeonLeaderAI::WriteWatch(bool ended)
{
    std::string const& dir = WatchDir();
    if (dir.empty())
        return;

    if (ended)
        _state = "ended";
    else if (!me->IsInWorld())          // between maps: next time
        return;
    else
    {
        _trail.push_back(me->GetPosition());
        if (_trail.size() > WatchTrail)
            _trail.pop_front();
        InstanceScript* instance = me->GetInstanceScript();
        for (size_t i = 0; i < _bosses.size(); ++i)
        {
            DungeonBoss& boss = _bosses[i];
            Creature* creature = instance ? instance->GetCreatureByEntry(boss.Entry) : nullptr;
            bool done = BossDone(boss) || (creature && !creature->IsAlive());
            boss.Status = done ? "killed" : i == _bossIndex ? "current" : "alive";
            boss.Hp = done ? 0.0f : creature ? creature->GetHealthPct() : 100.0f;
        }
    }

    std::ostringstream json;
    json << std::fixed << std::setprecision(1) << "{\"run\":" << _runId << ",\"dungeon\":" << _dungeonId << ",\"name\":" << JsonString(_dungeonName)
        << ",\"map\":" << _mapId << ",\"instance\":" << (ended ? 0 : me->GetInstanceId()) << ",\"level\":" << (ended ? 0 : uint32(me->getLevel()))
        << ",\"state\":\"" << _state << "\",\"updated\":" << uint64(time(nullptr)) << ",\"elapsed\":" << _runMs / IN_MILLISECONDS
        << ",\"wipes\":" << _wipes << ",\"killed\":" << _killed << ",\"total\":" << _bosses.size() << ",\"bosses\":[";
    for (size_t i = 0; i < _bosses.size(); ++i)
    {
        DungeonBoss const& boss = _bosses[i];
        json << (i ? "," : "") << "{\"entry\":" << boss.Entry << ",\"name\":" << JsonString(boss.Name) << ",\"x\":" << boss.Pos.GetPositionX()
            << ",\"y\":" << boss.Pos.GetPositionY() << ",\"z\":" << boss.Pos.GetPositionZ() << ",\"status\":\"" << boss.Status
            << "\",\"hp\":" << boss.Hp << "}";
    }
    json << "],\"bots\":[";
    if (!ended)
    {
        bool first = true;
        for (Player* bot : Members(false))
        {
            ChrClassesEntry const* classEntry = sChrClassesStore.LookupEntry(bot->getClass());
            ChrSpecializationEntry const* spec = sChrSpecializationStore.LookupEntry(bot->GetSpecializationId());
            char const* className = classEntry && classEntry->Name ? classEntry->Name->Str[DEFAULT_LOCALE] : nullptr;
            char const* specName = spec && spec->Name ? spec->Name->Str[DEFAULT_LOCALE] : nullptr;
            Unit* target = bot->getVictim();
            json << (first ? "" : ",") << "{\"name\":" << JsonString(bot->GetName()) << ",\"class\":" << JsonString(className ? className : "")
                << ",\"spec\":" << JsonString(specName ? specName : "") << ",\"role\":\""
                << (!spec ? "dps" : spec->Role == 0 ? "tank" : spec->Role == 1 ? "healer" : "dps") << "\",\"level\":" << uint32(bot->getLevel())
                << ",\"hp\":" << bot->GetHealth() << ",\"maxhp\":" << bot->GetMaxHealth() << ",\"power\":" << bot->GetPowerPct(bot->GetPowerType())
                << ",\"powerType\":\"" << PowerName(bot->GetPowerType()) << "\",\"alive\":" << (bot->IsAlive() ? "true" : "false")
                << ",\"x\":" << bot->GetPositionX() << ",\"y\":" << bot->GetPositionY() << ",\"z\":" << bot->GetPositionZ()
                << ",\"o\":" << bot->GetOrientation() << ",\"target\":" << JsonString(target ? target->GetName() : "")
                << ",\"targetHp\":" << (target ? target->GetHealthPct() : 0.0f) << "}";
            first = false;
        }
    }
    json << "],\"trail\":[";
    for (size_t i = 0; i < _trail.size(); ++i)
        json << (i ? "," : "") << "[" << _trail[i].GetPositionX() << "," << _trail[i].GetPositionY() << "]";
    json << "],\"events\":[";
    for (size_t i = 0; i < _events.size(); ++i)
        json << (i ? "," : "") << "{\"t\":\"" << _events[i].first << "\",\"text\":" << JsonString(_events[i].second) << "}";
    json << "]}\n";

    std::string path = dir + "/run_" + std::to_string(_runId) + ".json";
    {
        std::ofstream out(path + ".tmp", std::ios::trunc);
        if (!out)
            return;
        out << json.str();
    }
    std::rename((path + ".tmp").c_str(), path.c_str());
}

std::vector<Player*> DungeonLeaderAI::Members(bool aliveOnly) const
{
    std::vector<Player*> members;
    if (Group* group = me->GetGroup())
        for (GroupReference* ref = group->GetFirstMember(); ref; ref = ref->next())
            if (Player* member = ref->getSource())
                if (member->IsInWorld() && member->GetMap() == me->GetMap() && (!aliveOnly || member->IsAlive()))
                    members.push_back(member);
    return members;
}

bool DungeonLeaderAI::GroupInCombat() const
{
    for (Player* member : Members(true))
        if (member->isInCombat())
            return true;
    return false;
}

void DungeonLeaderAI::UpdateAI(uint32 diff)
{
    if (_finished || !Tick(diff))
        return;
    _deadMs = 0;
    if (!me->IsInWorld() || me->IsBeingTeleported())
        return;

    if (!_started)
    {
        // wait at the entrance until the five are in the map and alive (after the Dungeon Finder teleport)
        std::vector<Player*> alive = Members(true);
        Group* group = me->GetGroup();
        if (!group)
        {
            if (_runMs > GatherMaxMs)       // the group never formed (dev-check)
                Finish("no group");
            return;
        }
        if (alive.size() < group->GetMembersCount() && _runMs < GatherMaxMs)
            return;
        Start();
        return;
    }

    if (_runMs > RunTimeoutMs)
    {
        Finish("run timeout (2 h)");
        return;
    }
    if (_wiped)                         // up again after a wipe: the members follow the session's resurrection
    {
        _wiped = false;
        Log("event=resurrect run=%u dungeon=%u map=%u bot=%s at=entrance", _runId, _dungeonId, _mapId, _name.c_str());
    }

    if (me->IsNonMeleeSpellCast(false))
        return;

    _bossMs += _tick;

    // fight: the group's enemies (PartyBotAI: what hits the group, the tank's own target)
    if (Unit* target = PickTarget(me))
    {
        Fight(target);
        return;
    }
    if (_fighting)
        AfterFight();
    if (_finished)
        return;
    DungeonBoss* boss = CurrentBoss();

    if (!boss)
    {
        Finish(_killed == _bosses.size() ? "all bosses dead" : "no boss left on the route");
        return;
    }
    if (BossDone(*boss))
    {
        BossResult(RESULT_KILLED, "");
        return;
    }

    // rest: everyone above 70% health, the healers above 70% mana, the dead resurrected (their sessions do that next to
    // the tank once the group is out of combat). Not forever: a member that can't get up is left behind
    bool rest = Members(true).size() < Members(false).size();
    for (Player* member : Members(true))
    {
        ChrSpecializationEntry const* spec = sChrSpecializationStore.LookupEntry(member->GetSpecializationId());
        if (member->GetHealthPct() < 70.0f || (spec && spec->Role == 1 && member->GetPowerPct(POWER_MANA) < 70.0f)
            || !me->IsWithinDistInMap(member, GroupRange))
            rest = true;
    }
    if (!rest)
        _restMs = 0;
    else if ((_restMs += _tick) < RestMaxMs)
    {
        _state = "rest";
        StandStill();
        CastRotation(nullptr);
        return;
    }
    // (rested 90 s: go on without waiting until the next fight, which starts the measure again)

    // pull: the nearest hostile creature within 20 yd (the tank walks the path, so this is the path ahead), one at a time
    if (Creature* pull = NearestCreature([this](Creature* creature)
        {
            return creature->IsAlive() && !creature->IsInEvadeMode() && me->IsValidAttackTarget(creature) && me->IsHostileTo(creature)
                && !Ignored(creature->GetGUID()) && !creature->IsCritter();
        }, PullRange))
    {
        Log("event=pull run=%u dungeon=%u map=%u bot=%s target=%u \"%s\" at=%.1f,%.1f,%.1f boss=%u",
            _runId, _dungeonId, _mapId, _name.c_str(), pull->GetEntry(), pull->GetName(), pull->GetPositionX(), pull->GetPositionY(),
            pull->GetPositionZ(), boss->Entry);
        Fight(pull);
        _state = "pull";
        return;
    }

    // walk to the boss; at its spot, wait a minute for a boss an event spawns
    Creature* creature = BossCreature(*boss);
    if (!boss->HasPos && creature)
    {
        boss->Pos = creature->GetPosition();
        boss->HasPos = true;
    }
    if (!boss->HasPos)
    {
        BossResult(RESULT_NOT_FOUND, "no spawn in world.creature and no " + std::to_string(boss->Entry) + " in the map");
        return;
    }
    switch (MoveTo(creature && creature->IsAlive() ? creature->GetPosition() : boss->Pos, BossDist))
    {
        case Move::Moving:
            _state = "walk";
            return;
        case Move::Failed:
        {
            std::ostringstream detail;
            detail << (_noPath ? "no path" : "no progress for 60 s") << " from " << me->GetPositionX() << ',' << me->GetPositionY() << ','
                << me->GetPositionZ() << " to " << boss->Pos.GetPositionX() << ',' << boss->Pos.GetPositionY() << ',' << boss->Pos.GetPositionZ()
                << " (a closed door or a missing bridge?)";
            BossResult(_noPath ? RESULT_NO_PATH : RESULT_STUCK, detail.str());
            return;
        }
        case Move::Arrived:
            break;
    }
    if (creature && creature->IsAlive() && me->IsValidAttackTarget(creature))
    {
        Log("event=pull run=%u dungeon=%u map=%u bot=%s target=%u \"%s\" boss=%u",
            _runId, _dungeonId, _mapId, _name.c_str(), creature->GetEntry(), creature->GetName(), boss->Entry);
        Fight(creature);
        return;
    }
    if ((_bossWaitMs += _tick) > BossWaitMs)
        BossResult(RESULT_NOT_FOUND, creature ? "the boss can't be attacked (friendly / not selectable)" : "the boss never appeared at its spot");
}

void DungeonLeaderAI::Start()
{
    _started = true;
    _runMs = 0;
    _mapId = me->GetMapId();
    _entrance = me->GetPosition();
    Map* map = me->GetMap();
    _dungeonName = map->GetMapName();
    // the run's queued dungeon (DungeonRun.cpp); the map's entry only when unknown (it ignores the difficulty)
    lfg::LFGDungeonData const* dungeon = nullptr;
    if (uint32 queued = DungeonRunDungeonId(_runId))
        dungeon = sLFGMgr->GetLFGDungeon(queued);
    if (!dungeon)
        dungeon = sLFGMgr->GetLFGDungeon(_mapId, map->GetDifficultyID(), me->GetTeam());
    if (dungeon)
    {
        _dungeonId = dungeon->id;
        _dungeonName = dungeon->name;
    }

    // the route: the bosses of the map's encounters (kill credit), in encounter order, at their spawn points
    if (DungeonEncounterList const* encounters = sObjectMgr->GetDungeonEncounterList(_mapId, map->GetDifficultyID()))
        for (DungeonEncounter const* encounter : *encounters)
            if (encounter->creditType == ENCOUNTER_CREDIT_KILL_CREATURE && encounter->dbcEntry)
            {
                char const* name = encounter->dbcEntry->Name ? encounter->dbcEntry->Name->Str[sObjectMgr->GetDBCLocaleIndex()] : nullptr;
                _bosses.push_back({ encounter->creditEntry, encounter->dbcEntry->Bit, encounter->dbcEntry->OrderIndex,
                    name ? name : "", Position(), false, 0, "alive", 100.0f });
            }
    std::stable_sort(_bosses.begin(), _bosses.end(), [](DungeonBoss const& a, DungeonBoss const& b) { return a.Order < b.Order; });

    if (CellObjectGuidsMap const* cells = sObjectMgr->GetMapObjectGuids(_mapId, map->GetSpawnMode()))
        for (auto const& cell : *cells)
            for (ObjectGuid::LowType spawnId : cell.second.creatures)
                if (CreatureData const* data = sObjectMgr->GetCreatureData(spawnId))
                    for (DungeonBoss& boss : _bosses)
                        if (!boss.HasPos && boss.Entry == data->id)
                        {
                            boss.Pos.Relocate(data->posX, data->posY, data->posZ);
                            boss.HasPos = true;
                        }

    std::ostringstream route;
    for (DungeonBoss const& boss : _bosses)
        route << (route.tellp() ? "," : "") << boss.Entry << (boss.HasPos ? "" : "?") << (BossDone(boss) ? "(done)" : "");
    Log("event=start run=%u dungeon=%u map=%u bot=%s \"%s\" difficulty=%u level=%u members=%u bosses=%u route=%s",
        _runId, _dungeonId, _mapId, _name.c_str(), _dungeonName.c_str(), uint32(map->GetDifficultyID()), me->getLevel(),
        uint32(Members(true).size()), uint32(_bosses.size()), route.str().c_str());

    // bosses already dead (a reused instance) don't count as kills of this run
    while (_bossIndex < _bosses.size() && BossDone(_bosses[_bossIndex]))
        ++_bossIndex;
    _bossMs = 0;
}

void DungeonLeaderAI::Fight(Unit* target)
{
    _fighting = true;
    _state = "fight";
    _moveDest = Position();             // the walk measure starts again after a fight
    _restMs = 0;

    DungeonBoss* boss = CurrentBoss();
    if (boss && target->GetEntry() == boss->Entry)
    {
        _bossEngaged = true;
        _bossGuid = target->GetGUID();
    }
    if (_bossEngaged)
        if (Unit* bossUnit = ObjectAccessor::GetUnit(*me, _bossGuid))
            if (bossUnit->IsAlive())
                _bossPct = bossUnit->GetHealthPct();
    if (_firstDead.empty())
        for (Player* member : Members(false))
            if (!member->IsAlive())
                _firstDead = member->GetName();

    // a target that takes no damage is left alone for two minutes (likely a bug: can't be damaged, out of reach)
    if (_targetGuid != target->GetGUID() || target->GetHealth() < _targetHealth)
    {
        _targetGuid = target->GetGUID();
        _targetHealth = target->GetHealth();
        _targetMs = 0;
    }
    else if ((_targetMs += _tick) > TargetGiveUpMs)
    {
        Log("event=giveup run=%u dungeon=%u map=%u bot=%s target=%u \"%s\" health=%.0f%% reason=no damage for 45 s",
            _runId, _dungeonId, _mapId, _name.c_str(), target->GetEntry(), target->GetName(), target->GetHealthPct());
        Ignore(target->GetGUID());
        me->AttackStop();
        StandStill();
        return;
    }

    bool newTarget = me->getVictim() != target;
    if (newTarget)
        me->Attack(target, true);
    PetAttack(target);
    if (newTarget || me->GetMotionMaster()->GetCurrentMovementGeneratorType() != CHASE_MOTION_TYPE)
        me->GetMotionMaster()->MoveChase(target);
    CastRotation(target);
}

// the fight is over and the tank lives: the boss died, or it evaded (reset at full health while the group stood)
void DungeonLeaderAI::AfterFight()
{
    _fighting = false;
    if (me->getVictim())
        me->AttackStop();
    DungeonBoss* boss = CurrentBoss();
    if (_bossEngaged && boss)
    {
        _bossEngaged = false;
        if (BossDone(*boss))
            BossResult(RESULT_KILLED, "");
        else if (Creature* creature = BossCreature(*boss))
        {
            // only a real reset counts (evading, or back at full health): a boss in an untargetable phase or out of
            // reach is engaged again on the next walk (dev-check)
            if (creature->IsAlive() && (creature->IsInEvadeMode() || creature->IsFullHealth()))
            {
                std::ostringstream detail;
                detail << "boss reset at " << std::fixed << std::setprecision(0) << _bossPct << "% with "
                    << Members(true).size() << '/' << Members(false).size() << " alive (evades every pull?)";
                if (++boss->Wipes >= MaxWipes)
                    BossResult(RESULT_EVADE, detail.str() + ", 3rd time: end");
                else
                    Log("event=evade run=%u dungeon=%u map=%u bot=%s boss=%u detail=%s",
                        _runId, _dungeonId, _mapId, _name.c_str(), boss->Entry, detail.str().c_str());
            }
            else if (!creature->IsAlive())
                BossResult(RESULT_KILLED, "the boss died but its encounter is not DONE (encounter bit " + std::to_string(boss->Bit) + " not set)");
        }
    }
    _bossGuid.Clear();
    _bossPct = 100.0f;
    _firstDead.clear();
}

void DungeonLeaderAI::DeadUpdate(uint32 diff)
{
    if (!_started || _finished || !Tick(diff) || me->IsBeingTeleported())
        return;
    _deadMs += _tick;

    std::vector<Player*> alive = Members(true);
    if (!alive.empty())
    {
        // the tank alone (or with some) dead: up where it lies once the others are out of the fight
        if (!GroupInCombat() && _deadMs > TankResMs)
        {
            me->ResurrectPlayer(0.5f);
            me->SpawnCorpseBones();
        }
        return;
    }

    // everyone dead: a wipe. Log it once, then the tank back to the entrance and up; the members' sessions take them to
    // the tank and resurrect them there (PartyBotSession: leader alive, group out of combat)
    _state = "wipe";
    if (!_wiped)
    {
        _wiped = true;
        _fighting = false;
        ++_wipes;
        DungeonBoss* boss = CurrentBoss();
        uint8 wipes = boss ? ++boss->Wipes : 0;
        if (_firstDead.empty())
            _firstDead = _name;
        std::ostringstream detail;
        detail << (_bossEngaged ? "boss at " : "trash, boss not engaged; boss at ") << std::fixed << std::setprecision(0) << _bossPct
            << "%, first dead " << _firstDead;
        Log("event=wipe run=%u dungeon=%u map=%u bot=%s boss=%u wipes=%u detail=%s",
            _runId, _dungeonId, _mapId, _name.c_str(), boss ? boss->Entry : 0, uint32(wipes), detail.str().c_str());
        _bossEngaged = false;
        _bossGuid.Clear();
        _bossPct = 100.0f;
        _firstDead.clear();
        if (boss && wipes >= MaxWipes)
        {
            BossResult(RESULT_WIPE, detail.str() + ", 3rd wipe: end");
            Finish("3 wipes on boss " + std::to_string(boss->Entry));
            return;
        }
    }
    if (_deadMs < WipeResMs)
        return;

    if (me->GetExactDist(_entrance) > 5.0f)
    {
        me->TeleportTo(_mapId, _entrance.GetPositionX(), _entrance.GetPositionY(), _entrance.GetPositionZ(), _entrance.GetOrientation());
        return;
    }
    me->ResurrectPlayer(1.0f);
    me->SpawnCorpseBones();
}

bool DungeonLeaderAI::BossDone(DungeonBoss const& boss) const
{
    if (InstanceScript* instance = me->GetInstanceScript())
        if (instance->GetCompletedEncounterMask() & (1u << boss.Bit))
            return true;
    return false;
}

Creature* DungeonLeaderAI::BossCreature(DungeonBoss const& boss) const
{
    if (InstanceScript* instance = me->GetInstanceScript())
        if (Creature* creature = instance->GetCreatureByEntry(boss.Entry))
            return creature;
    return NearestCreature([&boss](Creature* creature) { return creature->GetEntry() == boss.Entry; }, 100.0f);
}

// the result of the current boss, then on to the next one
void DungeonLeaderAI::BossResult(Result result, std::string const& detail)
{
    DungeonBoss* boss = CurrentBoss();
    if (!boss)
        return;
    if (result == RESULT_KILLED)
        ++_killed;
    Log("run=%u dungeon=%u \"%s\" boss=%u \"%s\" result=%s time=%u level=%u wipes=%u detail=%s",
        _runId, _dungeonId, _dungeonName.c_str(), boss->Entry, boss->Name.c_str(), ResultNames[result], _bossMs / IN_MILLISECONDS,
        me->getLevel(), uint32(boss->Wipes), detail.empty() ? "-" : detail.c_str());

    ++_bossIndex;
    _bossMs = 0;
    _bossWaitMs = 0;
    _bossEngaged = false;
    _moveDest = Position();
    // a boss the group can't get past (3 wipes or evades) ends the run (the ones after it are likely behind its door)
    if ((result == RESULT_WIPE || result == RESULT_EVADE) && !_finished)
        Finish(std::string("3 ") + (result == RESULT_WIPE ? "wipes" : "resets") + " on boss " + std::to_string(boss->Entry));
}

void DungeonLeaderAI::Finish(std::string const& reason)
{
    if (_finished)
        return;
    _finished = true;
    bool cleared = !_bosses.empty() && _killed == _bosses.size();
    Log("run=end run=%u dungeon=%u cleared=%u bosses=%u/%u wipes=%u time=%u reason=%s",
        _runId, _dungeonId, uint32(cleared), _killed, uint32(_bosses.size()), _wipes, _runMs / IN_MILLISECONDS, reason.c_str());
    me->AttackStop();
    StandStill();
    WriteWatch(true);
    DungeonRunEnded(_runId, cleared, reason);
}

// walk (pathfinding) to within dist of pos. Failed: no path, or 60 s without getting closer (QuestBotAI::MoveTo)
DungeonLeaderAI::Move DungeonLeaderAI::MoveTo(Position const& pos, float dist)
{
    MotionMaster* motion = me->GetMotionMaster();
    float distance = me->GetExactDist(pos);
    if (distance <= dist)
    {
        if (motion->GetCurrentMovementGeneratorType() == POINT_MOTION_TYPE)
            StandStill();
        return Move::Arrived;
    }

    bool newDest = _moveDest.GetExactDist(pos) > 1.0f;
    if (newDest || distance < _moveBest - 1.0f)
    {
        _moveDest = pos;
        _moveBest = distance;
        _moveMs = 0;
    }
    else if ((_moveMs += _tick) > MoveStuckMs)
    {
        _moveDest = Position();
        _noPath = false;
        return Move::Failed;
    }

    if (newDest || motion->GetCurrentMovementGeneratorType() != POINT_MOTION_TYPE)
    {
        me->GetMap()->LoadGrid(pos.GetPositionX(), pos.GetPositionY());     // the path needs the destination's navmesh tile
        PathGenerator path(me);
        path.CalculatePath(pos.GetPositionX(), pos.GetPositionY(), pos.GetPositionZ());
        if (path.GetPathType() & PATHFIND_NOPATH)
        {
            _moveDest = Position();
            _noPath = true;
            return Move::Failed;
        }
        motion->MovePoint(0, pos.GetPositionX(), pos.GetPositionY(), pos.GetPositionZ(), true);
    }
    return Move::Moving;
}

Creature* DungeonLeaderAI::NearestCreature(std::function<bool(Creature*)> const& pred, float range) const
{
    Creature* found = nullptr;
    NearestCheck check(me, range, pred);
    Trinity::CreatureLastSearcher<NearestCheck> searcher(me, found, check);
    me->VisitNearbyObject(range, searcher);
    return found;
}
