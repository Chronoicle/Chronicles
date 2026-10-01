/*
 * Quest-test bot (owner 2026-10-01, #65): a GM-only mode of the party bots that catches broken quests. A fresh level-1
 * character (.partybot questtest, PartyBotMgr::StartQuestTest) plays its starting zone's quests alone and logs the
 * outcome of every quest (category server.questbot, every line starts with QUESTBOT):
 *
 *   QUESTBOT quest=<id> "<title>" result=DONE|STUCK|UNSUPPORTED|NOT_OFFERED time=<s> level=<n> bot=<name> detail=<...>
 *   QUESTBOT run=end bot=<name> reason=<...> time=<s> level=<n> done=<n> stuck=<n> unsupported=<n> not_offered=<n>
 *
 * Deliberately simple and deterministic: one quest at a time, the nearest quest giver of the start zone first, one try
 * per quest. A quest the bot cannot finish is the useful result: it is logged with the state, position and objective
 * counts, abandoned, and the bot goes on with the next one. Handled objectives: kill (MONSTER, also creatures whose
 * kill credit counts for it), collect (ITEM: kill the creatures / open the objects whose loot has a quest drop for the
 * bot, take the quest items) and use (GAMEOBJECT). The quest's own item (given on accept or a quest drop) is used on
 * kill targets the bot cannot attack, on the creatures its spell is limited to when the objective is an unspawned
 * credit bunny, and on objective objects its spell targets (#138). Everything else (talk to, spells to learn or cast,
 * items used at a place, area triggers, escorts, currencies...) is UNSUPPORTED. Accepting, turning in, using objects
 * and items and looting go through the client's packet handlers, so quest scripts fire as for a player. Runs in
 * Player::Update on the bot's map thread.
 */
#include "PartyBot.h"
#include "CellImpl.h"
#include "ConditionMgr.h"
#include "DB2Stores.h"
#include "DisableMgr.h"
#include "GameObject.h"
#include "GameObjectPackets.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include "Log.h"
#include "LootMgr.h"
#include "LootPackets.h"
#include "MotionMaster.h"
#include "ObjectMgr.h"
#include "PathGenerator.h"
#include "Player.h"
#include "QuestData.h"
#include "QuestDef.h"
#include "QuestPackets.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellPackets.h"
#include <algorithm>
#include <cmath>
#include <functional>
#include <iomanip>
#include <sstream>

namespace
{
    uint32 const TickMs             = 500;
    uint32 const ObjectiveTimeoutMs = 5 * MINUTE * IN_MILLISECONDS;     // no progress on the quest's objectives
    uint32 const QuestTimeoutMs     = 15 * MINUTE * IN_MILLISECONDS;
    uint32 const RunTimeoutMs       = 3 * HOUR * IN_MILLISECONDS;
    uint32 const MoveStuckMs        = 15 * IN_MILLISECONDS;             // walking without getting closer
    uint32 const TargetGiveUpMs     = 30 * IN_MILLISECONDS;             // a target taking no damage (evading, out of reach)
    uint32 const IgnoreMs           = 60 * IN_MILLISECONDS;             // given-up targets, used objects, looted corpses
    float const SpawnRadius         = 1500.0f;                          // spawns indexed around the start (targets, enders)
    float const SearchRange         = 50.0f;                            // live creatures and objects
    float const InteractDist        = 4.0f;                             // center distance for quest givers, objects, loot

    // #138: below level 10 a character has its class's recommended spec (ChrSpecialization flag 0x40) without having
    // picked it, and that spec's party-bot rotation is made of level 10+ spells. These are the spells a level 1-9
    // character really has (the class skill line + that spec's SpecializationSpells, SpellLevels.SpellLevel <= 9; all
    // on the default action bars, playercreateinfo_action), in priority order, the filler last. Types as in
    // world.partybot_spells: heal / hot = the bot itself below param % health, dot aura = the DoT's aura id when the
    // spell applies it through another spell (0 = the spell itself), finisher param = combo points.
    using T = PartyBotSpellType;
    std::unordered_map<uint8, std::vector<PartyBotSpell>> const StarterSpells =
    {
        { CLASS_WARRIOR, { { 34428, T::SelfHeal, 80, 0 },       // Victory Rush (5, Arms), after a kill
                           { 100, T::Damage, 0, 0 },            // Charge (3), 8-25 yd opener, rage
                           { 163201, T::Execute, 20, 0 },       // Execute (8, Arms)
                           { 1464, T::Damage, 0, 0 } } },       // Slam (1, Arms)
        { CLASS_PALADIN, { { 19750, T::Heal, 50, 0 },           // Flash of Light (5, Retribution)
                           { 20271, T::Damage, 0, 0 },          // Judgment (3)
                           { 35395, T::Damage, 0, 0 } } },      // Crusader Strike (1)
        { CLASS_HUNTER,  { { 193455, T::Damage, 0, 0 } } },     // Cobra Shot (1, Beast Mastery); no pet (none tamed)
        { CLASS_ROGUE,   { { 196819, T::Finisher, 3, 0 },       // Eviscerate (3, Assassination)
                           { 1752, T::Damage, 0, 0 } } },       // Sinister Strike (1, Assassination)
        { CLASS_PRIEST,  { { 17, T::Hot, 50, 0 },               // Power Word: Shield (8, Discipline), when not shielded
                           { 2061, T::Heal, 50, 0 },            // Flash Heal (5, Discipline)
                           { 589, T::Dot, 0, 0 },               // Shadow Word: Pain (3, Discipline)
                           { 585, T::Damage, 0, 0 } } },        // Smite (1)
        { CLASS_SHAMAN,  { { 8004, T::Heal, 50, 0 },            // Healing Surge (5, Elemental)
                           { 188389, T::Dot, 0, 0 },            // Flame Shock (3, Elemental)
                           { 188196, T::Damage, 0, 0 } } },     // Lightning Bolt (1, Elemental)
        { CLASS_MAGE,    { { 108853, T::Damage, 0, 0 },         // Fire Blast (3, Frost), instant, 12 s cooldown
                           { 116, T::Damage, 0, 0 } } },        // Frostbolt (1, Frost)
        { CLASS_WARLOCK, { { 688, T::Pet, 0, 0 },               // Summon Imp (5), out of combat, a soul shard
                           { 172, T::Dot, 0, 146739 },          // Corruption (3, Affliction), aura from 146739
                           { 232670, T::Damage, 0, 0 } } },     // Shadow Bolt (1, Affliction)
        { CLASS_MONK,    { { 116694, T::Heal, 50, 0 },          // Effuse (8, Windwalker)
                           { 100784, T::Damage, 0, 0 },         // Blackout Kick (3), chi
                           { 100780, T::Damage, 0, 0 } } },     // Tiger Palm (1)
        { CLASS_DRUID,   { { 8936, T::Heal, 50, 0 },            // Regrowth (5)
                           { 8921, T::Dot, 0, 164812 },         // Moonfire (3), aura 164812 (spell_dummy_trigger)
                           { 190984, T::Damage, 0, 0 } } },     // Solar Wrath (1, Balance)
    };

    enum Result { RESULT_DONE, RESULT_STUCK, RESULT_UNSUPPORTED, RESULT_NOT_OFFERED, MAX_RESULT };
    char const* const ResultNames[MAX_RESULT] = { "DONE", "STUCK", "UNSUPPORTED", "NOT_OFFERED" };

    char const* TypeName(uint8 type)
    {
        static char const* const names[] = { "MONSTER", "ITEM", "GAMEOBJECT", "TALKTO", "CURRENCY", "LEARNSPELL",
            "MIN_REPUTATION", "MAX_REPUTATION", "MONEY", "PLAYERKILLS", "AREATRIGGER", "PET_TRAINER_DEFEAT", "DEFEATBATTLEPET",
            "PET_BATTLE_VICTORIES", "CRITERIA_TREE", "TASK_IN_ZONE", "HAVE_CURRENCY", "OBTAIN_CURRENCY" };
        return type < sizeof(names) / sizeof(names[0]) ? names[type] : "UNKNOWN";
    }

    struct Spawn
    {
        uint32 Entry;
        bool GO;
        uint32 Zone;
        Position Pos;
    };

    // the quests this creature or object spawn starts
    std::vector<Quest const*> StartedBy(Spawn const& spawn)
    {
        QuestRelationBounds bounds = spawn.GO ? sQuestDataStore->GetGOQuestRelationBounds(spawn.Entry) : sQuestDataStore->GetCreatureQuestRelationBounds(spawn.Entry);
        std::vector<Quest const*> quests;
        for (auto itr = bounds.first; itr != bounds.second; ++itr)
            if (Quest const* quest = sQuestDataStore->GetQuestTemplate(itr->second))
                quests.push_back(quest);
        return quests;
    }

    // the nearest creature / object in range that the bot sees and the predicate accepts (the searcher keeps the last match)
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

class QuestBotAI : public PartyBotAI
{
public:
    QuestBotAI(Player* bot, ObjectGuid gmGuid, uint8 maxLevel) : PartyBotAI(bot, gmGuid, 0), _maxLevel(maxLevel), _name(bot->GetName()) { }
    ~QuestBotAI() override;

    void UpdateAI(uint32 diff) override;

private:
    enum class Step { Start, Pick, Giver, Objective, Ender };
    enum class Move { Arrived, Moving, Failed };

    void Start();
    void Pick();
    void TakeQuest(Quest const* quest, Spawn const* giver);
    void GoToGiver();
    void WorkObjective();
    bool SetupObjective(QuestObjective const& objective);
    void Hunt(QuestObjective const& objective);
    void TurnIn();
    void EndQuest(Result result, std::string const& detail);
    void Finish(std::string const& reason);
    std::string State() const;
    std::string WhyNotTaken(Quest const* quest, std::string const& runEnd);
    bool ForOtherCharacter(Quest const* quest, uint8 depth);

    Move MoveTo(Position const& pos, float dist);
    std::string MoveFailed() const { return _noPath ? "no path to the " : "not getting closer for 15 s to the "; }
    void Fight(Unit* target);
    bool CastStarter(Unit* target);     // target null: out of combat
    bool CanPay(SpellInfo const* info) const;
    void CastFailed(uint32 spell, SpellCastResult result);
    void UseObject(GameObject* go);
    Item* QuestItem(SpellInfo const*& spell) const;
    bool UseItem(WorldObject* target);
    void TakeQuestLoot(ObjectGuid guid, Loot* loot);
    uint32 RewardChoice() const;
    bool IsObjectiveItem(uint32 itemId) const;
    Creature* NearestCreature(std::function<bool(Creature*)> const& pred, float range = SearchRange) const;
    GameObject* NearestObject(std::function<bool(GameObject*)> const& pred, float range = SearchRange) const;
    bool Ignored(ObjectGuid guid) const { auto itr = _ignore.find(guid); return itr != _ignore.end() && itr->second > _runMs; }
    void Ignore(ObjectGuid guid) { _ignore[guid] = _runMs + IgnoreMs; }
    uint32 QuestId() const { return _quest ? _quest->GetQuestId() : 0; }

    uint8 _maxLevel;
    std::string _name;
    bool _finished = false;
    Step _step = Step::Start;
    uint32 _elapsed = 0;
    uint32 _tick = 0;
    uint32 _runMs = 0;
    uint32 _questMs = 0;
    uint32 _objectiveMs = 0;            // since the last objective progress
    uint32 _startZone = 0;
    uint32 _startMap = 0;
    Position _startPos;
    std::vector<Spawn> _spawns;        // creatures and objects around the start (world DB, read once)
    std::set<uint32> _tried;            // quests with a result: one try each
    uint32 _counts[MAX_RESULT] = { };
    std::map<ObjectGuid, uint32> _ignore;   // guid -> until (_runMs)

    // the current quest
    Quest const* _quest = nullptr;
    Spawn _giver = { };
    int32 _objective = -1;              // index in the quest's objectives
    int32 _progress = 0;                // sum of the objective counters
    std::set<uint32> _killEntries;      // creatures to kill for the objective
    std::set<uint32> _useEntries;       // objects to use / open for the objective
    std::set<uint32> _itemEntries;      // creatures to use the quest item on (its spell's target conditions)
    std::vector<Position> _points;      // where to look when nothing is in range
    uint32 _pointIndex = 0;
    uint8 _turnInTries = 0;

    Position _moveDest;
    float _moveBest = 0.0f;
    uint32 _moveMs = 0;
    bool _noPath = false;                   // the last failed MoveTo: no navmesh path (else not getting closer for 15 s)
    ObjectGuid _fightGuid;
    uint64 _fightHealth = 0;
    uint32 _fightMs = 0;
    bool _resting = false;
    std::map<uint32, uint32> _castFails;    // spell -> failures that are not the moment's (range, power, cooldown)
};

PlayerAI* NewQuestBotAI(Player* bot, ObjectGuid gmGuid, uint8 maxLevel)
{
    return new QuestBotAI(bot, gmGuid, maxLevel);
}

QuestBotAI::~QuestBotAI()
{
    // stopped (.partybot questtest stop / .partybot remove); a shutdown ends the run without this line.
    // No `me` here: only the AI's own fields
    if (!_finished)
        TC_LOG_INFO("server.questbot", "QUESTBOT run=end bot=%s reason=stopped time=%u quest=%u done=%u stuck=%u unsupported=%u not_offered=%u",
            _name.c_str(), _runMs / IN_MILLISECONDS, QuestId(), _counts[RESULT_DONE], _counts[RESULT_STUCK], _counts[RESULT_UNSUPPORTED], _counts[RESULT_NOT_OFFERED]);
}

void QuestBotAI::UpdateAI(uint32 diff)
{
    _elapsed += diff;
    if (_finished || _elapsed < TickMs)
        return;
    _tick = _elapsed;
    _elapsed = 0;
    _runMs += _tick;
    _questMs += _tick;
    _objectiveMs += _tick;

    if (!me->IsInWorld() || me->IsBeingTeleported() || me->IsNonMeleeSpellCast(false))
        return;

    if (_step == Step::Start)
    {
        Start();
        return;
    }

    if (_runMs > RunTimeoutMs)
    {
        if (_quest)
            EndQuest(RESULT_STUCK, "run timeout");
        Finish("run timeout (3 h)");
        return;
    }
    if (_quest && _questMs > QuestTimeoutMs)
    {
        EndQuest(RESULT_STUCK, "quest timeout (15 min)");
        return;
    }
    if (_quest && _objectiveMs > ObjectiveTimeoutMs)
    {
        EndQuest(RESULT_STUCK, "no progress for 5 min");
        return;
    }

    // a quest or script took the bot to another map: the spawn index is the start map's, go back
    if (me->GetMapId() != _startMap)
    {
        if (_quest)
            EndQuest(RESULT_STUCK, "the bot was taken to map " + std::to_string(me->GetMapId()));
        me->TeleportTo(_startMap, _startPos.GetPositionX(), _startPos.GetPositionY(), _startPos.GetPositionZ(), _startPos.GetOrientation());
        return;
    }

    // fight: the current target, else the nearest attacker
    Unit* target = me->getVictim();
    if (target && (!target->IsAlive() || !me->IsValidAttackTarget(target) || Ignored(target->GetGUID())))
    {
        me->AttackStop();
        target = nullptr;
    }
    if (!target)
        for (Unit* attacker : *me->getAttackers())
            if (attacker->IsAlive() && me->IsValidAttackTarget(attacker) && !Ignored(attacker->GetGUID())
                && (!target || me->GetDistance(attacker) < me->GetDistance(target)))
                target = attacker;
    if (target)
    {
        Fight(target);
        return;
    }

    // out of combat: summon the pet and heal itself below 80% (CastStarter), rest below 40% health, mana users below
    // 60% health or 30% mana, up to 90% health and 80% mana (no food, the out-of-combat regeneration)
    if (!me->isInCombat())
    {
        if (CastStarter(nullptr))
            return;
        bool mana = me->GetMaxPower(POWER_MANA) > 0;
        if (me->GetHealthPct() < (_resting ? 90.0f : mana ? 60.0f : 40.0f) || (mana && me->GetPowerPct(POWER_MANA) < (_resting ? 80.0f : 30.0f)))
        {
            _resting = true;
            StandStill();
            return;
        }
    }
    _resting = false;

    // the quest items of the bot's kills
    if (Creature* corpse = NearestCreature([this](Creature* creature) { return !creature->IsAlive() && !Ignored(creature->GetGUID()) && creature->loot.hasItemFor(me); }, LOOT_DISTANCE))
    {
        Move move = MoveTo(corpse->GetPosition(), InteractDist);
        if (move == Move::Moving)
            return;
        if (move == Move::Arrived)
        {
            me->SendLoot(corpse->GetGUID(), LOOT_CORPSE);
            TakeQuestLoot(corpse->GetGUID(), &corpse->loot);
        }
        Ignore(corpse->GetGUID());
        return;
    }

    switch (_step)
    {
        case Step::Pick:      Pick(); break;
        case Step::Giver:     GoToGiver(); break;
        case Step::Objective: WorkObjective(); break;
        case Step::Ender:     TurnIn(); break;
        default: break;
    }
}

// index the creature and object spawns around the start, then pick the first quest. In memory, from the per-cell spawn
// index the grid loader reads too (no world DB query on the map thread, dev-check)
void QuestBotAI::Start()
{
    _startZone = me->GetZoneId();
    _startMap = me->GetMapId();
    _startPos = me->GetPosition();
    uint32 map = _startMap;
    float x = me->GetPositionX(), y = me->GetPositionY();
    CellCoord low = Trinity::ComputeCellCoord(x - SpawnRadius, y - SpawnRadius);
    CellCoord high = Trinity::ComputeCellCoord(x + SpawnRadius, y + SpawnRadius);
    auto inBox = [x, y](float spawnX, float spawnY) { return std::fabs(spawnX - x) <= SpawnRadius && std::fabs(spawnY - y) <= SpawnRadius; };
    for (uint32 cellX = low.x_coord; cellX <= high.x_coord && cellX < TOTAL_NUMBER_OF_CELLS_PER_MAP; ++cellX)
        for (uint32 cellY = low.y_coord; cellY <= high.y_coord && cellY < TOTAL_NUMBER_OF_CELLS_PER_MAP; ++cellY)
            if (CellObjectGuids const* cell = sObjectMgr->GetCellObjectGuids(map, me->GetMap()->GetSpawnMode(), CellCoord(cellX, cellY).GetId()))
            {
                for (ObjectGuid::LowType guid : cell->creatures)
                    if (CreatureData const* data = sObjectMgr->GetCreatureData(guid))
                        if (data->mapid == map && inBox(data->posX, data->posY))
                            _spawns.push_back({ data->id, false, data->zoneId, Position(data->posX, data->posY, data->posZ) });
                for (ObjectGuid::LowType guid : cell->gameobjects)
                    if (GameObjectData const* data = sObjectMgr->GetGOData(guid))
                        if (data->mapid == map && inBox(data->posX, data->posY))
                            _spawns.push_back({ data->id, true, data->zoneId, Position(data->posX, data->posY, data->posZ) });
            }

    TC_LOG_INFO("server.questbot", "QUESTBOT event=start bot=%s race=%u class=%u level=%u maxlevel=%u zone=%u pos=%u:%.1f,%.1f,%.1f spawns=%u",
        _name.c_str(), me->getRace(), me->getClass(), me->getLevel(), _maxLevel, _startZone, map, x, y, me->GetPositionZ(), uint32(_spawns.size()));
    _step = Step::Pick;
}

void QuestBotAI::Pick()
{
    // a quest already in the log first (a follow-up the turn-in accepted, a quest a script or an item gave)
    for (uint16 slot = 0; slot < MAX_QUEST_LOG_SIZE; ++slot)
        if (uint32 questId = me->GetQuestSlotQuestId(slot))
            if (!_tried.count(questId))
                if (Quest const* quest = sQuestDataStore->GetQuestTemplate(questId))
                {
                    TakeQuest(quest, nullptr);
                    return;
                }

    if (me->getLevel() > _maxLevel)
    {
        Finish("level " + std::to_string(me->getLevel()) + " above the max level");
        return;
    }

    // the nearest quest giver of the start zone with a quest the bot can take (equal distance: the lowest quest id)
    Spawn const* giver = nullptr;
    Quest const* best = nullptr;
    float bestDist = 0.0f;
    for (Spawn const& spawn : _spawns)
    {
        if (spawn.Zone != _startZone)
            continue;
        float dist = me->GetExactDist(spawn.Pos);
        if (best && dist > bestDist)
            continue;
        for (Quest const* quest : StartedBy(spawn))
            if (!_tried.count(quest->GetQuestId()) && me->CanTakeQuest(quest, false) && me->CanAddQuest(quest, false)
                && (!best || dist < bestDist || quest->GetQuestId() < best->GetQuestId()))
            {
                giver = &spawn;
                best = quest;
                bestDist = dist;
            }
    }

    if (!best)
    {
        Finish("no quest left in the zone");
        return;
    }
    TakeQuest(best, giver);
}

void QuestBotAI::TakeQuest(Quest const* quest, Spawn const* giver)
{
    _quest = quest;
    _giver = giver ? *giver : Spawn{ };
    _questMs = 0;
    _objectiveMs = 0;
    _objective = -1;
    _progress = 0;
    _turnInTries = 0;
    _step = giver ? Step::Giver : Step::Objective;

    if (giver)
        TC_LOG_INFO("server.questbot", "QUESTBOT event=pick bot=%s quest=%u \"%s\" giver=%s:%u at=%.1f,%.1f,%.1f", _name.c_str(), quest->GetQuestId(),
            quest->LogTitle.c_str(), giver->GO ? "object" : "creature", giver->Entry, giver->Pos.GetPositionX(), giver->Pos.GetPositionY(), giver->Pos.GetPositionZ());
    else
        TC_LOG_INFO("server.questbot", "QUESTBOT event=pick bot=%s quest=%u \"%s\" giver=questlog", _name.c_str(), quest->GetQuestId(), quest->LogTitle.c_str());
}

void QuestBotAI::GoToGiver()
{
    uint32 entry = _giver.Entry;
    WorldObject* giver = nullptr;
    if (_giver.GO)
        giver = NearestObject([entry](GameObject* go) { return go->GetEntry() == entry; });
    else
        giver = NearestCreature([entry](Creature* creature) { return creature->GetEntry() == entry && creature->IsAlive(); });

    if (!giver)
    {
        Move move = MoveTo(_giver.Pos, 5.0f);
        if (move == Move::Failed)
            EndQuest(RESULT_NOT_OFFERED, MoveFailed() + "quest giver " + std::to_string(entry));
        else if (move == Move::Arrived)
            EndQuest(RESULT_NOT_OFFERED, "quest giver " + std::to_string(entry) + " not at its spawn (not spawned, dead or phased away)");
        return;
    }

    Move move = MoveTo(giver->GetPosition(), InteractDist);
    if (move == Move::Failed)
        EndQuest(RESULT_NOT_OFFERED, MoveFailed() + "quest giver " + std::to_string(entry));
    if (move != Move::Arrived)
        return;

    WorldPacket data(CMSG_QUEST_GIVER_ACCEPT_QUEST);
    WorldPackets::Quest::QuestGiverAcceptQuest packet(std::move(data));
    packet.QuestGiverGUID = giver->GetGUID();
    packet.QuestID = _quest->GetQuestId();
    me->GetSession()->HandleQuestGiverAcceptQuest(packet);

    if (me->GetQuestStatus(_quest->GetQuestId()) == QUEST_STATUS_NONE)
    {
        EndQuest(RESULT_NOT_OFFERED, me->CanInteractWithQuestGiver(giver) ? "the quest giver " + std::to_string(entry) + " refused the quest"
            : "the quest giver " + std::to_string(entry) + " cannot be talked to (npc flag, faction or distance)");
        return;
    }

    TC_LOG_INFO("server.questbot", "QUESTBOT event=accept bot=%s quest=%u giver=%u", _name.c_str(), _quest->GetQuestId(), entry);
    _step = Step::Objective;
}

void QuestBotAI::WorkObjective()
{
    QuestStatus status = me->GetQuestStatus(_quest->GetQuestId());
    if (status == QUEST_STATUS_COMPLETE)
    {
        TC_LOG_INFO("server.questbot", "QUESTBOT event=complete bot=%s quest=%u", _name.c_str(), _quest->GetQuestId());
        _step = Step::Ender;
        _objectiveMs = 0;
        return;
    }
    if (status != QUEST_STATUS_INCOMPLETE)
    {
        EndQuest(RESULT_STUCK, "quest status " + std::to_string(int(status)) + " (failed, or removed by a script)");
        return;
    }

    // any counter going up is progress
    int32 progress = 0;
    for (QuestObjective const& obj : _quest->GetObjectives())
        if (obj.StorageIndex >= 0)
            progress += me->GetQuestObjectiveData(_quest, obj.StorageIndex);
    if (progress > _progress)
    {
        _progress = progress;
        _objectiveMs = 0;
        TC_LOG_INFO("server.questbot", "QUESTBOT event=progress bot=%s quest=%u %s", _name.c_str(), _quest->GetQuestId(), State().c_str());
    }

    // the first objective still open that the quest needs (the ones CanCompleteQuest checks)
    QuestObjectives const& objectives = _quest->GetObjectives();
    int32 index = -1;
    for (uint32 i = 0; i < objectives.size() && index < 0; ++i)
        if (!(objectives[i].Flags & (QUEST_OBJECTIVE_FLAG_OPTIONAL | QUEST_OBJECTIVE_FLAG_HIDE_ITEM_GAINS | QUEST_OBJECTIVE_FLAG_PART_OF_PROGRESS_BAR))
            && !me->HasQuestObjectiveComplete(_quest, objectives[i]))
            index = int32(i);

    if (index < 0)
    {
        // every objective done, the quest not complete: it waits for something the bot does not do (event, script)
        if (_objectiveMs > 10 * IN_MILLISECONDS)
            EndQuest(RESULT_STUCK, "all objectives done but the quest did not complete");
        else
            StandStill();
        return;
    }

    if (index != _objective)
    {
        _objective = index;
        _objectiveMs = 0;
        if (!SetupObjective(objectives[index]))
            return;
    }
    Hunt(objectives[index]);
}

// what to kill or use for this objective and where to look for it; false: UNSUPPORTED (the quest ended)
bool QuestBotAI::SetupObjective(QuestObjective const& objective)
{
    _killEntries.clear();
    _useEntries.clear();
    _itemEntries.clear();
    _points.clear();
    _pointIndex = 0;

    std::string what = std::string(TypeName(objective.Type)) + " " + std::to_string(objective.ObjectID) + " x" + std::to_string(objective.Amount);
    std::set<uint32> checked;
    switch (objective.Type)
    {
        case QUEST_OBJECTIVE_MONSTER:   // the creature, and creatures whose kill credit counts for it
            _killEntries.insert(uint32(objective.ObjectID));
            for (Spawn const& spawn : _spawns)
                if (!spawn.GO && checked.insert(spawn.Entry).second)
                    if (CreatureTemplate const* info = sObjectMgr->GetCreatureTemplate(spawn.Entry))
                        for (uint32 credit : info->KillCredit)
                            if (credit == uint32(objective.ObjectID))
                                _killEntries.insert(spawn.Entry);
            // an unspawned credit bunny: the creatures the quest item's spell is limited to (conditions on its targets)
            // get the item instead (24471 "Aid for the Wounded", 9303 "Inoculation")
            if (std::none_of(_spawns.begin(), _spawns.end(), [this](Spawn const& spawn) { return !spawn.GO && _killEntries.count(spawn.Entry); }))
            {
                SpellInfo const* spell = nullptr;
                if (QuestItem(spell))
                    for (SpellEffectInfo const* effect : spell->Effects)
                        if (effect->ImplicitTargetConditions)
                            for (Condition const* cond : *effect->ImplicitTargetConditions)
                                if (cond->ConditionType == CONDITION_OBJECT_ENTRY && cond->ConditionValue1 == TYPEID_UNIT && cond->ConditionValue2 && !cond->NegativeCondition)
                                    _itemEntries.insert(cond->ConditionValue2);
            }
            break;
        case QUEST_OBJECTIVE_ITEM:      // creatures and objects whose loot has a quest drop for the bot (its only quest)
            for (Spawn const& spawn : _spawns)
            {
                if (!checked.insert(spawn.Entry | (spawn.GO ? 0x80000000 : 0)).second)
                    continue;
                if (spawn.GO)
                {
                    GameObjectTemplate const* info = sObjectMgr->GetGameObjectTemplate(spawn.Entry);
                    if (info && info->GetLootId() && LootTemplates_Gameobject.HaveQuestLootForPlayer(info->GetLootId(), me))
                        _useEntries.insert(spawn.Entry);
                }
                else
                {
                    CreatureTemplate const* info = sObjectMgr->GetCreatureTemplate(spawn.Entry);
                    if (info && info->lootid && LootTemplates_Creature.HaveQuestLootForPlayer(info->lootid, me))
                        _killEntries.insert(spawn.Entry);
                }
            }
            if (_killEntries.empty() && _useEntries.empty())
            {
                EndQuest(RESULT_UNSUPPORTED, what + ": no creature or object near the zone drops it (from a spell, an item or a script?)");
                return false;
            }
            break;
        case QUEST_OBJECTIVE_GAMEOBJECT:
            _useEntries.insert(uint32(objective.ObjectID));
            break;
        default:
            EndQuest(RESULT_UNSUPPORTED, "objective " + what);
            return false;
    }

    // where to look: the spawns of the targets, nearest first, else the quest's map POI for the objective
    std::vector<std::pair<float, Position>> spawns;
    for (Spawn const& spawn : _spawns)
        if (spawn.GO ? _useEntries.count(spawn.Entry) != 0 : (_killEntries.count(spawn.Entry) || _itemEntries.count(spawn.Entry)))
            spawns.emplace_back(me->GetExactDist(spawn.Pos), spawn.Pos);
    std::sort(spawns.begin(), spawns.end(), [](std::pair<float, Position> const& a, std::pair<float, Position> const& b) { return a.first < b.first; });
    for (uint32 i = 0; i < spawns.size() && i < 10; ++i)
        _points.push_back(spawns[i].second);

    if (_points.empty())
        if (QuestPOIVector const* pois = sQuestDataStore->GetQuestPOIVector(_quest->GetQuestId()))
            for (QuestPOI const& poi : *pois)
                if (poi.MapID == int32(me->GetMapId()) && !poi.points.empty() && (poi.QuestObjectiveID == int32(objective.ID) || poi.ObjectiveIndex == objective.StorageIndex))
                {
                    float x = 0.0f, y = 0.0f;
                    for (QuestPOIPoint const& point : poi.points)
                    {
                        x += point.X;
                        y += point.Y;
                    }
                    x /= poi.points.size();
                    y /= poi.points.size();
                    float z = me->GetMap()->GetHeight(x, y, MAX_HEIGHT);
                    _points.push_back(Position(x, y, z > INVALID_HEIGHT ? z : me->GetPositionZ()));
                }

    if (_points.empty())
    {
        EndQuest(RESULT_UNSUPPORTED, what + ": no spawn near the zone and no map POI (credit from a spell or a script?)");
        return false;
    }

    TC_LOG_INFO("server.questbot", "QUESTBOT event=objective bot=%s quest=%u index=%d %s kill=%u use=%u item=%u points=%u", _name.c_str(), _quest->GetQuestId(),
        _objective, what.c_str(), uint32(_killEntries.size()), uint32(_useEntries.size()), uint32(_itemEntries.size()), uint32(_points.size()));
    return true;
}

void QuestBotAI::Hunt(QuestObjective const& objective)
{
    if (!_useEntries.empty())
        if (GameObject* go = NearestObject([this](GameObject* go) { return _useEntries.count(go->GetEntry()) && go->isSpawned() && !Ignored(go->GetGUID()); }))
        {
            // an objective object the quest item's spell targets gets the item (6395 "Marla's Last Wish"), else a click
            SpellInfo const* spell = nullptr;
            if (objective.Type != QUEST_OBJECTIVE_GAMEOBJECT || !QuestItem(spell) || !(spell->GetExplicitTargetMask() & TARGET_FLAG_GAMEOBJECT_MASK))
                UseObject(go);
            else
                UseItem(go);
            return;
        }

    // creatures nobody else has tapped
    if (!_killEntries.empty())
        if (Creature* creature = NearestCreature([this](Creature* creature) { return _killEntries.count(creature->GetEntry()) && creature->IsAlive()
            && !Ignored(creature->GetGUID()) && me->IsValidAttackTarget(creature) && (!creature->hasLootRecipient() || creature->isTappedBy(me)); }))
        {
            Fight(creature);
            return;
        }

    // ones the bot cannot attack (the credit comes from a spell, an item or gossip) and the quest item's targets: the
    // quest item on them (26391 "Extinguishing Hope": the extinguisher on the vineyard fires)
    if (objective.Type == QUEST_OBJECTIVE_MONSTER)
        if (Creature* creature = NearestCreature([this](Creature* creature) { return creature->IsAlive() && !Ignored(creature->GetGUID())
            && (_itemEntries.count(creature->GetEntry()) || (_killEntries.count(creature->GetEntry()) && !me->IsValidAttackTarget(creature))); }))
        {
            if (!UseItem(creature))
                EndQuest(RESULT_UNSUPPORTED, "kill target " + std::to_string(creature->GetEntry()) + " cannot be attacked and the bot has no quest item to use on it (credit from a spell or gossip?)");
            return;
        }

    // nothing in range: walk the spawn points (or POIs) in turn until something respawns
    if (MoveTo(_points[_pointIndex], 5.0f) != Move::Moving)
        _pointIndex = (_pointIndex + 1) % _points.size();
}

void QuestBotAI::TurnIn()
{
    uint32 questId = _quest->GetQuestId();
    Object* ender = me;                 // QUEST_FLAGS_AUTOCOMPLETE: turned in from the quest log
    if (!_quest->HasFlag(QUEST_FLAGS_AUTOCOMPLETE))
    {
        std::set<uint32> creatures, objects;
        QuestRelationBounds bounds = sQuestDataStore->GetCreatureQuestInvolvedRelationBoundsByQuest(questId);
        for (auto itr = bounds.first; itr != bounds.second; ++itr)
            creatures.insert(itr->second);
        bounds = sQuestDataStore->GetGOQuestInvolvedRelationBoundsByQuest(questId);
        for (auto itr = bounds.first; itr != bounds.second; ++itr)
            objects.insert(itr->second);

        WorldObject* found = NearestCreature([&creatures](Creature* creature) { return creatures.count(creature->GetEntry()) && creature->IsAlive(); });
        if (!found)
            found = NearestObject([&objects](GameObject* go) { return objects.count(go->GetEntry()) != 0; });
        if (!found)
        {
            Spawn const* spawn = nullptr;
            for (Spawn const& s : _spawns)
                if ((s.GO ? objects : creatures).count(s.Entry) && (!spawn || me->GetExactDist(s.Pos) < me->GetExactDist(spawn->Pos)))
                    spawn = &s;
            if (!spawn)
            {
                EndQuest(RESULT_STUCK, creatures.empty() && objects.empty() ? "the quest has no ender" : "no spawn of the quest ender near the zone");
                return;
            }
            Move move = MoveTo(spawn->Pos, 5.0f);
            if (move == Move::Failed)
                EndQuest(RESULT_STUCK, MoveFailed() + "quest ender " + std::to_string(spawn->Entry));
            else if (move == Move::Arrived)
                EndQuest(RESULT_STUCK, "quest ender " + std::to_string(spawn->Entry) + " not at its spawn (not spawned, dead or phased away)");
            return;
        }

        Move move = MoveTo(found->GetPosition(), InteractDist);
        if (move == Move::Failed)
            EndQuest(RESULT_STUCK, MoveFailed() + "quest ender " + std::to_string(found->GetEntry()));
        if (move != Move::Arrived)
            return;
        ender = found;
    }

    WorldPacket requestData(CMSG_QUEST_GIVER_REQUEST_REWARD);
    WorldPackets::Quest::QuestGiverRequestReward request(std::move(requestData));
    request.QuestGiverGUID = ender->GetGUID();
    request.QuestID = questId;
    me->GetSession()->HandleQuestGiverRequestReward(request);

    WorldPacket chooseData(CMSG_QUEST_GIVER_CHOOSE_REWARD);
    WorldPackets::Quest::QuestGiverChooseReward choose(std::move(chooseData));
    choose.QuestGiverGUID = ender->GetGUID();
    choose.QuestID = questId;
    choose.ItemChoiceID = int32(RewardChoice());
    me->GetSession()->HandleQuestGiverChooseReward(choose);

    if (me->GetQuestStatus(questId) != QUEST_STATUS_COMPLETE)
        EndQuest(RESULT_DONE, "");
    else if (++_turnInTries >= 3)
        EndQuest(RESULT_STUCK, !me->CanRewardQuest(_quest, false) ? "turn-in refused (reward does not fit in the bags?)"
            : ender != me && !me->CanInteractWithQuestGiver(ender) ? "the quest ender cannot be talked to (npc flag, faction or distance)"
            : "turn-in refused");
}

// the first choice item, else the first package item for the bot's class/spec, else none
uint32 QuestBotAI::RewardChoice() const
{
    for (uint32 i = 0; i < QUEST_REWARD_CHOICES_COUNT; ++i)
        if (_quest->RewardChoiceItemId[i])
            return _quest->RewardChoiceItemId[i];
    if (_quest->PackageID)
        if (std::vector<QuestPackageItemEntry const*> const* items = sDB2Manager.GetQuestPackageItems(_quest->PackageID))
            for (QuestPackageItemEntry const* item : *items)
                if (me->CanSelectQuestPackageItem(item))
                    return uint32(item->ItemID);
    return 0;
}

void QuestBotAI::EndQuest(Result result, std::string const& detail)
{
    uint32 questId = _quest->GetQuestId();
    TC_LOG_INFO("server.questbot", "QUESTBOT quest=%u \"%s\" result=%s time=%u level=%u bot=%s detail=%s", questId, _quest->LogTitle.c_str(), ResultNames[result],
        _questMs / IN_MILLISECONDS, me->getLevel(), _name.c_str(), result == RESULT_DONE ? "-" : (detail + " | " + State()).c_str());
    ++_counts[result];
    _tried.insert(questId);

    // still in the log: abandon it, as with the quest log's Abandon
    uint16 slot = me->FindQuestSlot(questId);
    if (slot < MAX_QUEST_LOG_SIZE)
    {
        WorldPacket data(CMSG_QUEST_LOG_REMOVE_QUEST);
        WorldPackets::Quest::QuestLogRemoveQuest packet(std::move(data));
        packet.Entry = uint8(slot);
        me->GetSession()->HandleQuestLogRemoveQuest(packet);
    }

    _quest = nullptr;
    _step = Step::Pick;
    if (me->getVictim())
        me->AttackStop();
    StandStill();
}

void QuestBotAI::Finish(std::string const& reason)
{
    // the start zone's quests for this race and class that the bot never got, with the first requirement it misses
    std::set<uint32> seen;
    for (Spawn const& spawn : _spawns)
        if (spawn.Zone == _startZone)
            for (Quest const* quest : StartedBy(spawn))
                if (seen.insert(quest->GetQuestId()).second && !_tried.count(quest->GetQuestId()) && me->GetQuestStatus(quest->GetQuestId()) == QUEST_STATUS_NONE
                    && quest->MinLevel <= _maxLevel && !ForOtherCharacter(quest, 0))
                {
                    ++_counts[RESULT_NOT_OFFERED];
                    TC_LOG_INFO("server.questbot", "QUESTBOT quest=%u \"%s\" result=NOT_OFFERED time=0 level=%u bot=%s detail=%s", quest->GetQuestId(),
                        quest->LogTitle.c_str(), me->getLevel(), _name.c_str(), WhyNotTaken(quest, reason).c_str());
                }

    // only logged: a chat line to the GM from this map thread could hit a GM logging out (dev-check)
    TC_LOG_INFO("server.questbot", "QUESTBOT run=end bot=%s reason=%s time=%u level=%u done=%u stuck=%u unsupported=%u not_offered=%u", _name.c_str(),
        reason.c_str(), _runMs / IN_MILLISECONDS, me->getLevel(), _counts[RESULT_DONE], _counts[RESULT_STUCK], _counts[RESULT_UNSUPPORTED], _counts[RESULT_NOT_OFFERED]);
    _finished = true;

    static_cast<PartyBotSession*>(me->GetSession())->RequestDismiss();   // logs out on the session's next update
}

// a quest only another class's or race's chain leads to: none of its previous quests is for this character (the
// start zones have one chain variant per class, all sharing the zone's quest givers)
bool QuestBotAI::ForOtherCharacter(Quest const* quest, uint8 depth)
{
    if (!me->SatisfyQuestClass(quest, false) || !me->SatisfyQuestRace(quest, false))
        return true;
    if (quest->prevQuests.empty() || depth >= 10)
        return false;
    for (int32 prevId : quest->prevQuests)
    {
        Quest const* prev = sQuestDataStore->GetQuestTemplate(uint32(std::abs(prevId)));
        if (!prev || !ForOtherCharacter(prev, depth + 1))   // a missing previous quest is this character's problem too
            return false;
    }
    return true;
}

std::string QuestBotAI::WhyNotTaken(Quest const* quest, std::string const& runEnd)
{
    if (DisableMgr::IsDisabledFor(DISABLE_TYPE_QUEST, quest->GetQuestId(), me))
        return "disabled (disables table)";
    if (!me->SatisfyQuestLevel(quest, false))
        return "needs level " + std::to_string(quest->MinLevel);
    if (!me->SatisfyQuestPreviousQuest(quest, false))
    {
        std::string ids;
        for (int32 prevId : quest->prevQuests)
            ids += (ids.empty() ? "" : ",") + std::to_string(prevId);
        return "previous quest " + ids + " not done (negative: must be active)";
    }
    if (!me->SatisfyQuestPrevChain(quest, false))
        return "an earlier quest of its chain not done";
    if (!me->SatisfyQuestExclusiveGroup(quest, false))
        return "exclusive group " + std::to_string(quest->ExclusiveGroup) + ": another quest of the group was taken";
    if (!me->SatisfyQuestNextChain(quest, false))
        return "a later quest of its chain was taken";
    if (!me->SatisfyQuestReputation(quest, false))
        return "reputation";
    if (!me->SatisfyQuestSkill(quest, false))
        return "skill";
    if (!me->SatisfyQuestConditions(quest, false))
        return "conditions table";
    if (!me->CanTakeQuest(quest, false))
        return "not takeable (daily/weekly/seasonal)";
    return "takeable, the run ended first (" + runEnd + ")";
}

// step, position and every objective's counter, for STUCK/UNSUPPORTED lines
std::string QuestBotAI::State() const
{
    static char const* const steps[] = { "start", "pick", "giver", "objective", "ender" };
    std::ostringstream text;
    text << std::fixed << std::setprecision(1) << "step=" << steps[int(_step)] << " pos=" << me->GetMapId() << ':' << me->GetPositionX() << ','
        << me->GetPositionY() << ',' << me->GetPositionZ() << " objective=" << _objective;
    if (_quest)
        for (QuestObjective const& obj : _quest->GetObjectives())
            text << " obj" << int32(obj.StorageIndex) << '=' << TypeName(obj.Type) << ':' << obj.ObjectID << ':'
                << (obj.StorageIndex >= 0 ? me->GetQuestObjectiveData(_quest, obj.StorageIndex) : 0) << '/' << obj.Amount;
    return text.str();
}

// walk (pathfinding) to within dist of pos. Failed: no path, or ~15 s without getting closer
QuestBotAI::Move QuestBotAI::MoveTo(Position const& pos, float dist)
{
    MotionMaster* motion = me->GetMotionMaster();
    float distance = me->GetExactDist(pos);
    if (distance <= dist)
    {
        if (motion->GetCurrentMovementGeneratorType() == POINT_MOTION_TYPE)
            StandStill();
        return Move::Arrived;
    }

    // progress = getting closer; a fight (chase) in between starts the measure again
    bool newDest = _moveDest.GetExactDist(pos) > 1.0f;
    if (newDest || distance < _moveBest - 1.0f || motion->GetCurrentMovementGeneratorType() == CHASE_MOTION_TYPE)
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

    // a new destination, or the last walk ended (partial path, a fight): walk again
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

// attack + spells; a target taking no damage for 30 s is left alone for a minute. Casters and hunters (a ranged filler
// they can pay for) stand where they see the target within 30 yd, the others (and a caster out of mana) chase it into
// melee. Spells: below level 10 the starter spells, later the spec's party bot rotation, the starter spells when it
// casts nothing
void QuestBotAI::Fight(Unit* target)
{
    // the walk measure (MoveTo) starts again after a fight: a ranged bot stands still (no chase) and may end it further
    // away, which read as "not getting closer" (priests and mages STUCK on their way to the quest ender)
    _moveDest = Position();

    if (_fightGuid != target->GetGUID() || target->GetHealth() < _fightHealth)
    {
        _fightGuid = target->GetGUID();
        _fightHealth = target->GetHealth();
        _fightMs = 0;
    }
    else if ((_fightMs += _tick) > TargetGiveUpMs)
    {
        TC_LOG_INFO("server.questbot", "QUESTBOT event=giveup bot=%s quest=%u target=%u reason=no damage for 30 s", _name.c_str(), QuestId(), target->GetEntry());
        Ignore(target->GetGUID());
        me->AttackStop();
        StandStill();
        return;
    }

    if (me->getVictim() != target)
        me->Attack(target, true);
    PetAttack(target);

    auto spells = StarterSpells.find(me->getClass());
    SpellInfo const* filler = spells != StarterSpells.end() ? sSpellMgr->GetSpellInfo(spells->second.back().Spell) : nullptr;
    if (filler && filler->GetMaxRange() > NOMINAL_MELEE_RANGE && me->HasSpell(filler->Id) && CanPay(filler) && InSight(target, 30.0f))
        StandStill();
    else if (me->GetMotionMaster()->GetCurrentMovementGeneratorType() != CHASE_MOTION_TYPE)
        me->GetMotionMaster()->MoveChase(target);
    me->SetInFront(target);

    if (me->getLevel() < 10 || !CastRotation(target))
        CastStarter(target);
}

// the class's starter spell of the highest priority that the bot knows, can pay for and the spell code accepts (the
// normal, untriggered cast: cast times, costs, cooldowns, range and sight apply). In a fight: heals and the shield on
// itself below their health %, a missing DoT, the finisher, the filler. Out of combat (target null): the pet, heals below
// 80%. True when a cast started
bool QuestBotAI::CastStarter(Unit* target)
{
    auto spells = StarterSpells.find(me->getClass());
    if (spells == StarterSpells.end())
        return false;

    for (PartyBotSpell entry : spells->second)
    {
        if (!target)
        {
            if (entry.Type == PartyBotSpellType::Heal)
                entry.Param = 80;
            else if (entry.Type != PartyBotSpellType::Pet)
                continue;
        }
        else if (entry.Type == PartyBotSpellType::Pet)          // no summon cast in a fight
            continue;

        SpellInfo const* info = sSpellMgr->GetSpellInfo(entry.Spell);
        if (!info || !me->HasSpell(entry.Spell))
        {
            if (!info || info->SpellLevel <= me->getLevel())   // a wrong id, or a spell this level should have taught
                CastFailed(entry.Spell, SPELL_FAILED_NOT_KNOWN);
            continue;
        }
        if (!CanPay(info))
            continue;

        // a heal or summon has a cast time: stop (chasing, walking), then cast. Not for attacks: a caster walking to a
        // target out of sight would stop for every try (Fight stands it still once it sees the target)
        bool cast = TryCast(entry, target);
        if (!cast && _castResult == SPELL_FAILED_MOVING && (entry.Type == PartyBotSpellType::Heal || entry.Type == PartyBotSpellType::Pet))
        {
            StandStill();
            if (me->IsStopped())
                me->RemoveUnitMovementFlag(MOVEMENTFLAG_FORWARD);
            cast = TryCast(entry, target);
        }
        if (cast)
            return true;
        CastFailed(entry.Spell, _castResult);
    }
    return false;
}

// the bot has the power the spell costs (mana, rage, energy, focus, combo points, chi, soul shards...)
bool QuestBotAI::CanPay(SpellInfo const* info) const
{
    SpellPowerCost cost;
    info->CalcPowerCost(me, info->GetSchoolMask(), cost);
    for (uint8 power = 0; power < MAX_POWERS; ++power)
        if (cost[power] > 0 && me->GetPower(Powers(power)) < cost[power])
            return false;
    return true;
}

// a starter spell failing again and again (or unknown at its level): a wrong spell id or a missing requirement in the
// log, once per spell and run. Failures of the moment (range, sight, facing, power, cooldown, a proc) don't count
void QuestBotAI::CastFailed(uint32 spell, SpellCastResult result)
{
    switch (result)
    {
        case SPELL_FAILED_DONT_REPORT:      // not tried (its condition, cooldown or global cooldown)
        case SPELL_FAILED_MOVING:
        case SPELL_FAILED_OUT_OF_RANGE:
        case SPELL_FAILED_TOO_CLOSE:
        case SPELL_FAILED_LINE_OF_SIGHT:
        case SPELL_FAILED_UNIT_NOT_INFRONT:
        case SPELL_FAILED_NOT_READY:
        case SPELL_FAILED_NO_POWER:
        case SPELL_FAILED_NO_COMBO_POINTS:
        case SPELL_FAILED_NO_CHARGES_REMAIN:  // Crusader Strike, Judgment
        case SPELL_FAILED_CASTER_AURASTATE: // Victory Rush without a kill
        case SPELL_FAILED_TARGET_AURASTATE:
        case SPELL_FAILED_BAD_TARGETS:      // Power Word: Shield on a shielded bot (dev-check)
        case SPELL_FAILED_SPELL_IN_PROGRESS:
            return;
        default:
            break;
    }
    if (++_castFails[spell] == 5)
        TC_LOG_INFO("server.questbot", "QUESTBOT event=castfail bot=%s spell=%u result=%u class=%u level=%u quest=%u", _name.c_str(), spell, uint32(result),
            me->getClass(), me->getLevel(), QuestId());
}

void QuestBotAI::UseObject(GameObject* go)
{
    Move move = MoveTo(go->GetPosition(), InteractDist);
    if (move == Move::Moving)
        return;
    Ignore(go->GetGUID());              // one use per object; the next tick takes the next one
    if (move == Move::Failed)
        return;

    uint32 entry = go->GetEntry();
    WorldPacket data(CMSG_GAME_OBJ_USE);
    WorldPackets::GameObject::GameObjectUse packet(std::move(data));
    packet.Guid = go->GetGUID();
    me->GetSession()->HandleGameObjectUse(packet);      // goobers, buttons, quest objects: scripts and credit

    // chests and gathering nodes: the client opens them with the lock's opening spell (Spell::SendLoot).
    // ponytail: looted directly instead, so a chest's triggered event and linked trap do not fire; cast the lock's
    // open spell here if a quest turns out to depend on them
    if (me->GetLootGUID() != go->GetGUID() && go->GetGOInfo()->GetLootId())
        me->SendLoot(go->GetGUID(), LOOT_CORPSE);
    if (me->GetLootGUID() == go->GetGUID())
        TakeQuestLoot(go->GetGUID(), &go->loot);
    TC_LOG_INFO("server.questbot", "QUESTBOT event=use bot=%s quest=%u object=%u", _name.c_str(), QuestId(), entry);
}

// the quest's own item the bot carries (given on accept, or a quest drop) with a use spell.
// ponytail: the first one; match the spell to the target (kill credit, conditions, SmartAI spell hit) if a quest has two
Item* QuestBotAI::QuestItem(SpellInfo const*& spell) const
{
    uint32 const ids[] = { _quest->SourceItemId, _quest->ItemDrop[0], _quest->ItemDrop[1], _quest->ItemDrop[2], _quest->ItemDrop[3] };
    for (uint32 id : ids)
        if (Item* item = id ? me->GetItemByEntry(id) : nullptr)
            for (ItemEffectEntry const* effect : item->GetTemplate()->Effects)
                if (effect->TriggerType == ITEM_SPELLTRIGGER_ON_USE && (spell = sSpellMgr->GetSpellInfo(effect->SpellID)))
                    return item;
    return nullptr;
}

// the quest item on the target as a client uses it (CMSG_USE_ITEM: item scripts, cooldowns, charges and the spell's
// checks apply): walk next to it (any spell range), wait out the item's cooldown and the combat for a spell not usable in
// one, stand still facing it (cones, channels), use. Once per target. False: the bot has no quest item to use
bool QuestBotAI::UseItem(WorldObject* target)
{
    SpellInfo const* spell = nullptr;
    Item* item = QuestItem(spell);
    if (!item)
        return false;

    Move move = MoveTo(target->GetPosition(), InteractDist);
    if (move == Move::Failed)
        Ignore(target->GetGUID());
    if (move != Move::Arrived || me->HasSpellCooldown(spell->Id) || (me->isInCombat() && !spell->CanBeUsedInCombat()))
        return true;

    StandStill();
    me->SetFacingToObject(target);
    me->RemoveUnitMovementFlag(MOVEMENTFLAG_FORWARD);   // set by the facing spline: fails cast-time and channeled spells

    // the item can be used up: what the log needs first
    uint32 itemId = item->GetEntry(), entry = target->GetEntry();
    Ignore(target->GetGUID());
    WorldPacket data(CMSG_USE_ITEM);
    WorldPackets::Spells::ItemUse packet(std::move(data));
    packet.bagIndex = item->GetBagSlot();
    packet.slot = item->GetSlot();
    packet.itemGUID = item->GetGUID();
    packet.Cast.SpellID = int32(spell->Id);
    packet.Cast.Target.Flags = target->IsUnit() ? TARGET_FLAG_UNIT : TARGET_FLAG_GAMEOBJECT;  // dropped by spells without one
    packet.Cast.Target.Unit = target->GetGUID();
    me->GetSession()->HandleUseItemOpcode(packet);
    TC_LOG_INFO("server.questbot", "QUESTBOT event=useitem bot=%s quest=%u item=%u spell=%u target=%u", _name.c_str(), QuestId(), itemId, spell->Id, entry);
    return true;
}

// take the quest items (and the items the quest asks for) and release the loot, as a player looting
void QuestBotAI::TakeQuestLoot(ObjectGuid guid, Loot* loot)
{
    WorldPacket data(CMSG_LOOT_ITEM);
    WorldPackets::Loot::AutoStoreLootItem packet(std::move(data));
    for (uint32 slot = 0; slot < loot->GetMaxSlotInLootFor(me) && slot < 255; ++slot)
        if (LootItem* item = loot->LootItemInSlot(slot, me))
            if (slot >= loot->items.size() || item->needs_quest || IsObjectiveItem(item->item.ItemID))
                packet.Loot.push_back({ guid, uint8(slot + 1) });

    if (!packet.Loot.empty())
    {
        me->GetSession()->HandleAutostoreLootItemOpcode(packet);
        TC_LOG_INFO("server.questbot", "QUESTBOT event=loot bot=%s quest=%u from=%u items=%u", _name.c_str(), QuestId(), guid.GetEntry(), uint32(packet.Loot.size()));
    }
    me->GetSession()->DoLootRelease(guid);
}

bool QuestBotAI::IsObjectiveItem(uint32 itemId) const
{
    if (_quest)
        for (QuestObjective const& obj : _quest->GetObjectives())
            if (obj.Type == QUEST_OBJECTIVE_ITEM && uint32(obj.ObjectID) == itemId)
                return true;
    return false;
}

Creature* QuestBotAI::NearestCreature(std::function<bool(Creature*)> const& pred, float range) const
{
    Creature* found = nullptr;
    NearestCheck<Creature> check(me, range, pred);
    Trinity::CreatureLastSearcher<NearestCheck<Creature>> searcher(me, found, check);
    me->VisitNearbyObject(range, searcher);
    return found;
}

GameObject* QuestBotAI::NearestObject(std::function<bool(GameObject*)> const& pred, float range) const
{
    GameObject* found = nullptr;
    NearestCheck<GameObject> check(me, range, pred);
    Trinity::GameObjectLastSearcher<NearestCheck<GameObject>> searcher(me, found, check);
    me->VisitNearbyObject(range, searcher);
    return found;
}
