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
 *
 * Dungeon quests (owner: the bots also do the dungeon's quests): at the start every member gets the quests of the
 * dungeon's zone that fit it (like a GM .quest add, no prerequisite chain) and have a target in the map; after each
 * fight the members take their quest items from the corpses near the tank, and the tank walks a member to its quest
 * objects. At the end a complete quest is rewarded (XP), an incomplete one is logged and abandoned:
 *
 *   DUNGEONBOT event=quests run=<id> dungeon=<id> bot=<member> added=<id,id,...|-> skipped=<n>
 *   DUNGEONBOT quest=<id> "<title>" result=DONE|INCOMPLETE run=<id> dungeon=<id> bot=<member> level=<n> [targets=in_map|not_in_map detail=<obj index>:<type>:<object id>:<have>/<need>,...]
 */
#include "PartyBot.h"
#include "CellImpl.h"
#include "Config.h"
#include "DB2Stores.h"
#include "DisableMgr.h"
#include "GameObject.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include "Group.h"
#include "InstanceScript.h"
#include "LFGMgr.h"
#include "LootMgr.h"
#include "Log.h"
#include "MotionMaster.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "PathGenerator.h"
#include "Player.h"
#include "QuestData.h"
#include "QuestDef.h"
#include <algorithm>
#include <cstdarg>
#include <cstdio>
#include <cstring>
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
    float const LootRange       = 30.0f;                            // corpses around the tank after a fight
    float const ObjectRange     = 40.0f;                            // quest objects the tank walks a member to
    uint32 const ObjectMaxMs    = MINUTE * IN_MILLISECONDS;         // one such detour at most

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

    // a dungeon quest one member got at the start; its state as of the last look (the destructor has no players)
    struct BotQuest
    {
        ObjectGuid Bot;
        std::string BotName;
        Quest const* Info;
        bool InMap;                     // every creature / object target has a spawn in the map
        bool Done;
        std::string Progress;           // the counters summed: "2/6"
        std::string Detail;             // the open objectives: <index>:<type>:<id>:<have>/<need>,...
    };

    char const* ObjectiveType(uint8 type)
    {
        return type == QUEST_OBJECTIVE_MONSTER ? "MONSTER" : type == QUEST_OBJECTIVE_ITEM ? "ITEM" : type == QUEST_OBJECTIVE_GAMEOBJECT ? "GAMEOBJECT" : "OTHER";
    }

    // the quests of a zone (QuestSortID > 0), built once
    // Quest const* of the quest store: valid while the templates aren't reloaded (no .reload on this server, AGENTS.md)
    std::vector<Quest const*> const& ZoneQuests(uint32 zoneId)
    {
        static std::unordered_map<uint32, std::vector<Quest const*>> const zones = []
        {
            std::unordered_map<uint32, std::vector<Quest const*>> index;
            for (auto const& itr : sQuestDataStore->GetQuestTemplates())
                if (itr.second->QuestSortID > 0)
                    index[uint32(itr.second->QuestSortID)].push_back(itr.second);
            return index;
        }();
        static std::vector<Quest const*> const none;
        auto itr = zones.find(zoneId);
        return itr != zones.end() ? itr->second : none;
    }

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

    // creature / object in range that the tank sees and the predicate accepts, the nearest (the searcher keeps the last match)
    template<class T>
    struct NearestCheck
    {
        NearestCheck(Player* bot, float range, std::function<bool(T*)> const& pred) : Bot(bot), Range(range), Pred(pred) { }

        bool operator()(T* object)
        {
            if (!Bot->IsWithinDistInMap(object, Range) || !Pred(object) || !Bot->canSeeOrDetect(object))
                return false;
            Range = Bot->GetDistance(object);
            return true;
        }

        Player* Bot;
        float Range;
        std::function<bool(T*)> const& Pred;
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
    void AddQuests(std::set<uint32> const& spawns);
    void QuestLoot();
    bool QuestObject();
    void UpdateQuest(BotQuest& quest, Player* bot);
    void QuestResults(bool reward);
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
    std::set<uint32> _oddMobs;              // hostile creatures far above the group's level, logged once each

    // dungeon quests
    std::vector<BotQuest> _quests;
    std::set<ObjectGuid> _corpses;          // corpses seen after a fight (counted, looted)
    std::map<uint32, uint32> _kills;        // creature entry (and its kill credit entries) -> corpses seen
    std::set<uint32> _dropped;              // quest items a member took
    std::set<ObjectGuid> _usedObjects;      // quest objects walked to (once each)
    ObjectGuid _objectGuid;                 // the current quest object detour: the object, the member, the time
    ObjectGuid _objectUser;
    uint32 _objectMs = 0;

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
        QuestResults(false);
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
                << ",\"targetHp\":" << (target ? target->GetHealthPct() : 0.0f) << ",\"quests\":[";
            bool firstQuest = true;
            for (BotQuest& quest : _quests)
                if (quest.Bot == bot->GetGUID())
                {
                    UpdateQuest(quest, bot);
                    json << (firstQuest ? "" : ",") << "{\"id\":" << quest.Info->GetQuestId() << ",\"name\":" << JsonString(quest.Info->LogTitle)
                        << ",\"done\":" << (quest.Done ? "true" : "false") << ",\"progress\":\"" << quest.Progress << "\"}";
                    firstQuest = false;
                }
            json << "]}";
            first = false;
        }
    }
    json << "],\"route\":[";             // the tank's planned walk (corridor corners), only while it walks
    if (!ended && !strcmp(_state, "walk"))
        for (size_t i = 0; i < _walkRoute.size(); ++i)
            json << (i ? "," : "") << "[" << _walkRoute[i].x << "," << _walkRoute[i].y << "]";
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
            if (!creature->IsAlive() || creature->IsInEvadeMode() || !me->IsValidAttackTarget(creature) || !me->IsHostileTo(creature)
                || Ignored(creature->GetGUID()) || creature->IsCritter())
                return false;
            // a hostile creature far above the dungeon's level is no trash but wrong data (2026-10-01: Deadmines' level 85
            // "Glubtok Firewall Platter Creature Level 1c" one-shot the level 15 group 6 times): logged once, not pulled
            if (creature->getLevel() > me->getLevel() + 10)
            {
                if (_oddMobs.insert(creature->GetEntry()).second)
                    Log("event=oddmob run=%u dungeon=%u map=%u bot=%s target=%u \"%s\" level=%u at=%.1f,%.1f,%.1f detail=hostile, %u levels above the group: wrong data?",
                        _runId, _dungeonId, _mapId, _name.c_str(), creature->GetEntry(), creature->GetName(), uint32(creature->getLevel()),
                        creature->GetPositionX(), creature->GetPositionY(), creature->GetPositionZ(), uint32(creature->getLevel() - me->getLevel()));
                return false;
            }
            return true;
        }, PullRange))
    {
        Log("event=pull run=%u dungeon=%u map=%u bot=%s target=%u \"%s\" at=%.1f,%.1f,%.1f boss=%u",
            _runId, _dungeonId, _mapId, _name.c_str(), pull->GetEntry(), pull->GetName(), pull->GetPositionX(), pull->GetPositionY(),
            pull->GetPositionZ(), boss->Entry);
        Fight(pull);
        _state = "pull";
        return;
    }

    if (QuestObject())
        return;

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

    std::set<uint32> spawns;            // creature (and kill credit) and object entries spawned in the map: quest targets
    if (CellObjectGuidsMap const* cells = sObjectMgr->GetMapObjectGuids(_mapId, map->GetSpawnMode()))
        for (auto const& cell : *cells)
        {
            for (ObjectGuid::LowType spawnId : cell.second.creatures)
                if (CreatureData const* data = sObjectMgr->GetCreatureData(spawnId))
                {
                    spawns.insert(data->id);
                    if (CreatureTemplate const* info = sObjectMgr->GetCreatureTemplate(data->id))
                        spawns.insert(std::begin(info->KillCredit), std::end(info->KillCredit));
                    for (DungeonBoss& boss : _bosses)
                        if (!boss.HasPos && boss.Entry == data->id)
                        {
                            boss.Pos.Relocate(data->posX, data->posY, data->posZ);
                            boss.HasPos = true;
                        }
                }
            for (ObjectGuid::LowType spawnId : cell.second.gameobjects)
                if (GameObjectData const* data = sObjectMgr->GetGOData(spawnId))
                    spawns.insert(data->id);
        }

    std::ostringstream route;
    for (DungeonBoss const& boss : _bosses)
        route << (route.tellp() ? "," : "") << boss.Entry << (boss.HasPos ? "" : "?") << (BossDone(boss) ? "(done)" : "");
    Log("event=start run=%u dungeon=%u map=%u bot=%s \"%s\" difficulty=%u level=%u members=%u bosses=%u route=%s",
        _runId, _dungeonId, _mapId, _name.c_str(), _dungeonName.c_str(), uint32(map->GetDifficultyID()), me->getLevel(),
        uint32(Members(true).size()), uint32(_bosses.size()), route.str().c_str());
    AddQuests(spawns);

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
    QuestLoot();
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
    QuestResults(true);
    WriteWatch(true);
    DungeonRunEnded(_runId, cleared, reason);
}

// walk (pathfinding) to within dist of pos. Failed: no path, or 60 s without getting closer (QuestBotAI::MoveTo)
DungeonLeaderAI::Move DungeonLeaderAI::MoveTo(Position const& pos, float dist)
{
    float distance = me->GetExactDist(pos);
    if (distance <= dist)
    {
        if (me->GetMotionMaster()->GetCurrentMovementGeneratorType() == POINT_MOTION_TYPE)
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

    if (newDest || me->GetMotionMaster()->GetCurrentMovementGeneratorType() != POINT_MOTION_TYPE)
    {
        if (!WalkTo(pos))
        {
            _moveDest = Position();
            _noPath = true;
            return Move::Failed;
        }
    }
    return Move::Moving;
}

Creature* DungeonLeaderAI::NearestCreature(std::function<bool(Creature*)> const& pred, float range) const
{
    Creature* found = nullptr;
    NearestCheck<Creature> check(me, range, pred);
    Trinity::CreatureLastSearcher<NearestCheck<Creature>> searcher(me, found, check);
    me->VisitNearbyObject(range, searcher);
    return found;
}

// the dungeon's quests for each member (Start): the zone's quests that fit the member (class, race, level; no
// prerequisite chain, like a GM .quest add), not repeatable / daily / weekly / raid / seasonal / disabled, with a
// creature or object target spawned in the map or an item to collect. A dungeon quest still in the log (a stopped
// run) counts as added
void DungeonLeaderAI::AddQuests(std::set<uint32> const& spawns)
{
    std::vector<Quest const*> const& quests = ZoneQuests(me->GetZoneId());
    for (Player* member : Members(false))
    {
        std::ostringstream added;
        uint32 skipped = 0;
        for (Quest const* quest : quests)
        {
            uint32 id = quest->GetQuestId();
            QuestStatus status = member->GetQuestStatus(id);
            bool inLog = status == QUEST_STATUS_INCOMPLETE || status == QUEST_STATUS_COMPLETE;
            bool target = false, inMap = true;
            for (QuestObjective const& obj : quest->GetObjectives())
            {
                bool spawned = spawns.count(uint32(obj.ObjectID)) != 0;
                if (obj.Type == QUEST_OBJECTIVE_ITEM || ((obj.Type == QUEST_OBJECTIVE_MONSTER || obj.Type == QUEST_OBJECTIVE_GAMEOBJECT) && spawned))
                    target = true;
                if ((obj.Type == QUEST_OBJECTIVE_MONSTER || obj.Type == QUEST_OBJECTIVE_GAMEOBJECT) && !spawned)
                    inMap = false;
            }
            if (!inLog && (!target || status != QUEST_STATUS_NONE || member->GetQuestRewardStatus(id)
                || !member->SatisfyQuestClass(quest, false) || !member->SatisfyQuestRace(quest, false) || !member->SatisfyQuestLevel(quest, false)
                || quest->IsRepeatable() || quest->IsDailyOrWeekly() || quest->IsSeasonal() || quest->IsRaidQuest(me->GetMap()->GetDifficultyID())
                || DisableMgr::IsDisabledFor(DISABLE_TYPE_QUEST, id, member) || !member->CanAddQuest(quest, false)))
            {
                ++skipped;
                continue;
            }
            if (!inLog)
                member->AddQuestAndCheckCompletion(quest, nullptr);
            _quests.push_back({ member->GetGUID(), member->GetName(), quest, inMap, false, "", "" });
            added << (added.tellp() ? "," : "") << id;
        }
        Log("event=quests run=%u dungeon=%u bot=%s added=%s skipped=%u", _runId, _dungeonId, member->GetName(),
            added.tellp() ? added.str().c_str() : "-", skipped);
    }
}

// after a fight: count the corpses around the tank (kills without credit in the result), and each member takes its
// quest items from them (as QuestBotAI does from its own kills)
void DungeonLeaderAI::QuestLoot()
{
    std::list<Creature*> corpses;
    Trinity::AllDeadCreaturesInRange check(me, LootRange, ObjectGuid::Empty);
    Trinity::CreatureListSearcher<Trinity::AllDeadCreaturesInRange> searcher(me, corpses, check);
    me->VisitNearbyObject(LootRange, searcher);

    for (Creature* corpse : corpses)
    {
        if (_corpses.insert(corpse->GetGUID()).second)
        {
            ++_kills[corpse->GetEntry()];
            for (uint32 credit : corpse->GetCreatureTemplate()->KillCredit)
                if (credit)
                    ++_kills[credit];
        }
        for (Player* member : Members(true))
        {
            if (!member->IsWithinDistInMap(corpse, LOOT_DISTANCE) || !corpse->loot.hasItemFor(member))
                continue;
            member->SendLoot(corpse->GetGUID(), LOOT_CORPSE);
            std::vector<uint32> items = LootQuestItems(member, corpse->GetGUID(), &corpse->loot, [this, member](uint32 itemId)
                {
                    for (BotQuest const& quest : _quests)
                        if (quest.Bot == member->GetGUID())
                            for (QuestObjective const& obj : quest.Info->GetObjectives())
                                if (obj.Type == QUEST_OBJECTIVE_ITEM && uint32(obj.ObjectID) == itemId)
                                    return true;
                    return false;
                });
            _dropped.insert(items.begin(), items.end());
        }
    }
}

// out of combat: a member's open GAMEOBJECT objective within 40 yd of the tank: the tank walks there (the member
// follows) and the member uses it. Each object once, a minute at most. True while on the detour
bool DungeonLeaderAI::QuestObject()
{
    if (_objectGuid.IsEmpty())
    {
        Player* user = nullptr;
        uint32 questId = 0;
        // a living member with an open objective for go (user / questId: who and for which quest). Asked again for the
        // object found: the searcher also checks canSeeOrDetect after the predicate, so the last accepted call may not
        // be the object it keeps (dev-check)
        auto needs = [&](GameObject* go) -> bool
        {
            if (!go->isSpawned() || _usedObjects.count(go->GetGUID()))
                return false;
            for (BotQuest const& quest : _quests)
                if (Player* member = ObjectAccessor::GetPlayer(*me, quest.Bot))
                    if (member->IsAlive() && member->GetQuestStatus(quest.Info->GetQuestId()) == QUEST_STATUS_INCOMPLETE)
                        for (QuestObjective const& obj : quest.Info->GetObjectives())
                            if (obj.Type == QUEST_OBJECTIVE_GAMEOBJECT && uint32(obj.ObjectID) == go->GetEntry() && !member->HasQuestObjectiveComplete(quest.Info, obj))
                            {
                                user = member;
                                questId = quest.Info->GetQuestId();
                                return true;
                            }
            return false;
        };
        std::function<bool(GameObject*)> pred = needs;
        GameObject* found = nullptr;
        NearestCheck<GameObject> check(me, ObjectRange, pred);
        Trinity::GameObjectLastSearcher<NearestCheck<GameObject>> searcher(me, found, check);
        me->VisitNearbyObject(ObjectRange, searcher);
        if (!found || !needs(found))
            return false;
        _objectGuid = found->GetGUID();
        _objectUser = user->GetGUID();
        _objectMs = 0;
        _usedObjects.insert(_objectGuid);
        Log("event=useobject run=%u dungeon=%u bot=%s object=%u \"%s\" quest=%u", _runId, _dungeonId, user->GetName(), found->GetEntry(),
            found->GetName(), questId);
    }

    GameObject* go = me->GetMap()->GetGameObject(_objectGuid);
    Player* user = ObjectAccessor::GetPlayer(*me, _objectUser);
    if (!go || !user || !user->IsAlive() || (_objectMs += _tick) > ObjectMaxMs)
    {
        if (go && user && _objectMs > ObjectMaxMs)  // the member never came within reach of it (dev-check)
            Log("event=useobject run=%u dungeon=%u bot=%s object=%u \"%s\" result=timeout", _runId, _dungeonId, user->GetName(),
                go->GetEntry(), go->GetName());
        _objectGuid.Clear();
        return false;
    }
    _state = "walk";
    Move move = MoveTo(go->GetPosition(), 2.0f);
    if (move == Move::Failed)
    {
        _objectGuid.Clear();
        return false;
    }
    if (move == Move::Moving || !user->IsWithinDistInMap(go, INTERACTION_DISTANCE))    // wait for the member to follow
        return true;
    if (UseGameObject(user, go))
    {
        std::vector<uint32> items = LootQuestItems(user, go->GetGUID(), &go->loot, [](uint32) { return false; });
        _dropped.insert(items.begin(), items.end());
    }
    _objectGuid.Clear();
    return true;
}

// the quest's state for bot: done, the summed counters, the open objectives (with "killed N, credit M" when the group
// killed more of a target than the quest counted, "never dropped" for an item no member took in a cleared run)
void DungeonLeaderAI::UpdateQuest(BotQuest& quest, Player* bot)
{
    QuestStatus status = bot->GetQuestStatus(quest.Info->GetQuestId());
    quest.Done = status == QUEST_STATUS_COMPLETE || bot->GetQuestRewardStatus(quest.Info->GetQuestId());
    if (quest.Done || status != QUEST_STATUS_INCOMPLETE)
    {
        quest.Progress = quest.Done ? "done" : "-";
        quest.Detail = quest.Done ? "" : "quest status " + std::to_string(int(status)) + " (failed, or removed by a script)";
        return;
    }
    // ponytail: "never dropped" only when every boss died (an item of a boss the run never reached is no bug); a
    // per-item source check needs the loot templates' item lists
    bool cleared = !_bosses.empty() && _killed == _bosses.size();
    int32 have = 0, need = 0;
    std::ostringstream detail;
    QuestObjectives const& objectives = quest.Info->GetObjectives();
    for (size_t i = 0; i < objectives.size(); ++i)
    {
        QuestObjective const& obj = objectives[i];
        if (obj.StorageIndex < 0 || (obj.Flags & QUEST_OBJECTIVE_FLAG_OPTIONAL))
            continue;
        int32 count = bot->GetQuestObjectiveData(quest.Info, obj.StorageIndex);
        have += std::min(count, obj.Amount);
        need += obj.Amount;
        if (bot->HasQuestObjectiveComplete(quest.Info, obj))
            continue;
        detail << (detail.tellp() ? "," : "") << i << ':' << ObjectiveType(obj.Type) << ':' << obj.ObjectID << ':' << count << '/' << obj.Amount;
        auto kills = _kills.find(uint32(obj.ObjectID));
        if (obj.Type == QUEST_OBJECTIVE_MONSTER && kills != _kills.end() && int32(kills->second) > count)
            detail << " (killed " << kills->second << ", credit " << count << ')';
        if (obj.Type == QUEST_OBJECTIVE_ITEM && cleared && !_dropped.count(uint32(obj.ObjectID)))
            detail << " (never dropped)";
    }
    quest.Progress = std::to_string(have) + '/' + std::to_string(need);
    quest.Detail = detail.str();
}

// the run's end: each added quest's result. reward (Finish): a complete quest is turned in (XP, money, items; reward
// choice 0) and an incomplete one abandoned, so the next run starts clean. Without (the destructor; the bots may be
// gone): the last known state, only logged
void DungeonLeaderAI::QuestResults(bool reward)
{
    for (BotQuest& quest : _quests)
    {
        Player* bot = reward ? ObjectAccessor::GetPlayer(*me, quest.Bot) : nullptr;
        if (bot)
            UpdateQuest(quest, bot);
        uint32 id = quest.Info->GetQuestId();
        if (bot && bot->GetQuestStatus(id) == QUEST_STATUS_COMPLETE && bot->CanRewardQuest(quest.Info, false))
            bot->RewardQuest(quest.Info, 0, bot);
        else if (bot && bot->GetQuestStatus(id) != QUEST_STATUS_NONE)
        {
            // abandoned as .quest remove does, without forgetting a reward (a complete quest whose reward the bags
            // can't hold included)
            for (uint8 slot = 0; slot < MAX_QUEST_LOG_SIZE; ++slot)
                if (bot->GetQuestSlotQuestId(slot) == id)
                {
                    bot->SetQuestSlot(slot, 0);
                    bot->TakeQuestSourceItem(id, false);
                }
            bot->RemoveActiveQuest(id);
        }
        if (quest.Done)
            Log("quest=%u \"%s\" result=DONE run=%u dungeon=%u bot=%s level=%u", id, quest.Info->LogTitle.c_str(), _runId, _dungeonId,
                quest.BotName.c_str(), bot ? uint32(bot->getLevel()) : 0);
        else
            Log("quest=%u \"%s\" result=INCOMPLETE run=%u dungeon=%u bot=%s level=%u targets=%s detail=%s", id, quest.Info->LogTitle.c_str(),
                _runId, _dungeonId, quest.BotName.c_str(), bot ? uint32(bot->getLevel()) : 0, quest.InMap ? "in_map" : "not_in_map",
                quest.Detail.empty() ? "-" : quest.Detail.c_str());
    }
}
