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
#include "CharacterPackets.h"
#include "LFGMgr.h"
#include "DatabaseEnv.h"
#include "DB2Stores.h"
#include "SpellMgr.h"
#include "Garrison.h"
#include "ThreatManager.h"
#include "HostileRefManager.h"
#include "SpellInfo.h"
#include "CellImpl.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include "PathGenerator.h"
#include <boost/algorithm/string/predicate.hpp>
#include <sstream>

// ---------------------------------------------------------------- session

PartyBotSession::PartyBotSession(uint32 accountId, std::string&& accountName, ObjectGuid botGuid, ObjectGuid leaderGuid, uint8 questMaxLevel) :
    WorldSession(accountId, std::move(accountName), nullptr, SEC_PLAYER, CURRENT_EXPANSION, 0, "Win", LOCALE_enUS, 0, false,
        AT_AUTH_FLAG_NONE, std::unordered_map<uint8, int64>()),
    _botGuid(botGuid), _leaderGuid(leaderGuid), _questMaxLevel(questMaxLevel)
{
}

static bool GroupInCombat(Player* bot)
{
    if (Group* group = bot->GetGroup())
        for (GroupReference* ref = group->GetFirstMember(); ref; ref = ref->next())
            if (Player* member = ref->getSource())
                if (member->IsAlive() && member->isInCombat())
                    return true;
    return false;
}

bool PartyBotSession::Update(uint32 diff, Map* map)
{
    // logged out (dismissed, kicked at shutdown, or the login failed): removable in this very update. The shutdown runs
    // only one session update after KickAll, and a session left over until ~World wrote to the closed login database
    // (crash at every restart since the bots)
    if (_loginStarted && !GetPlayer() && !PlayerLoading())
        _done = true;

    // once the bot is on a map, the map updates its session (World::UpdateSessions skips it), so the bot steps run in
    // both: on the map for a bot in the world, in the world update while it is loading or between maps
    bool result = WorldSession::Update(diff, map);

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

    if (_dismissRequested && !_dismissed)
        Dismiss();

    if (!_setupDone && !_dismissed)
        Setup(bot);

    // quest test: no leader, no group. Dead: up again where it fell after 10 s (the AI only runs while alive)
    if (IsQuestTest())
    {
        if (_dismissed || !bot->isDead(false))
            _deadTimer = 0;
        else
        {
            if (!_deadTimer)
                TC_LOG_INFO("server.questbot", "QUESTBOT event=died bot=%s level=%u pos=%u:%.1f,%.1f,%.1f", bot->GetName(), bot->getLevel(),
                    bot->GetMapId(), bot->GetPositionX(), bot->GetPositionY(), bot->GetPositionZ());
            if ((_deadTimer += std::max<uint32>(diff, 1)) > 10 * IN_MILLISECONDS)
            {
                _deadTimer = 0;
                bot->ResurrectPlayer(1.0f);
                bot->SpawnCorpseBones();
            }
        }
        return result;
    }

    // dead: come back when the leader is alive and the group out of combat (here, as Player::Update only runs the
    // AI while the bot is alive): go to the leader, then resurrect there
    if (_setupDone && !_dismissed && bot->isDead(false) && !bot->IsBeingTeleported())
        if (Player* leader = ObjectAccessor::FindPlayer(_leaderGuid))
            if (leader->IsInWorld() && leader->IsAlive() && !leader->IsBeingTeleported() && !leader->isInFlight() && !GroupInCombat(bot))
            {
                if (bot->GetMapId() != leader->GetMapId() || !bot->IsWithinDistInMap(leader, 30.0f))
                    bot->TeleportTo(leader->GetMapId(), leader->GetPositionX(), leader->GetPositionY(), leader->GetPositionZ(), leader->GetOrientation());
                else
                {
                    bot->ResurrectPlayer(0.5f);
                    bot->SpawnCorpseBones();
                }
            }

    // the leader logged out: wait a moment (reconnects, loading screens), then go too
    if (!_dismissed)
    {
        if (ObjectAccessor::FindPlayer(_leaderGuid))
            _leaderGoneTimer = 0;
        else if ((_leaderGoneTimer += diff) > 60 * IN_MILLISECONDS)
            Dismiss();

        // kicked from the leader's group, or the group disbanded: go too (owner 2026-09-28)
        Group* group = bot->GetGroup();
        if (!_setupDone || (group && group->IsMember(_leaderGuid)))
            _groupGoneTimer = 0;
        else if ((_groupGoneTimer += diff) > 5 * IN_MILLISECONDS)
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

// .partybot create made this character: level 110, its spec and its gear set (world.gear_npc_items) at the first login
void PartyBotSession::FirstLoginSetup(Player* bot, uint32 specId)
{
    ChrSpecializationEntry const* spec = sChrSpecializationStore.LookupEntry(specId);
    if (!spec || spec->ClassID != bot->getClass())
        return;

    // logged out dead (a ghost): talents are refused and gear can't be equipped while dead, and the gear loop below
    // would destroy the old set with nothing put back
    if (bot->isDead(false))
    {
        bot->ResurrectPlayer(1.0f);
        bot->SpawnCorpseBones();
    }

    if (bot->getLevel() < 110)
        bot->GiveLevel(110);
    if (bot->GetSpecializationId() != specId)
        bot->ActivateTalentGroup(spec);

    // the spec's talent build (world.partybot_talents, generated with the rotations)
    if (QueryResult result = WorldDatabase.PQuery("SELECT talent FROM partybot_talents WHERE spec = %u", specId))
    {
        bot->SetFlag(UNIT_FIELD_FLAGS_2, UNIT_FLAG2_ALLOW_CHANGING_TALENTS);    // replaces an earlier pick in the row
        do
            bot->LearnTalent((*result)[0].GetUInt32());
        while (result->NextRow());
        bot->RemoveFlag(UNIT_FIELD_FLAGS_2, UNIT_FLAG2_ALLOW_CHANGING_TALENTS);
    }

    // the class hall talent for a second legendary first, or the set's second legendary is refused (empty slot)
    if (Garrison* garrison = bot->GetGarrisonPtr())
        garrison->LearnSecondLegendaryTalent();

    // starting gear out, the spec's set in
    for (uint8 slot = EQUIPMENT_SLOT_START; slot < EQUIPMENT_SLOT_END; ++slot)
        if (bot->GetItemByPos(INVENTORY_SLOT_BAG_0, slot))
            bot->DestroyItem(INVENTORY_SLOT_BAG_0, slot, true);

    if (QueryResult result = WorldDatabase.PQuery("SELECT item, bonus FROM gear_npc_items WHERE spec = %u ORDER BY slot = 'artifact' DESC, slot", specId))
    {
        do
        {
            Field* fields = result->Fetch();
            uint32 itemId = fields[0].GetUInt32();
            std::vector<uint32> bonuses;
            std::istringstream tokens(fields[1].GetString());
            uint32 bonus;
            while (tokens >> bonus)
                bonuses.push_back(bonus);

            uint16 dest;
            if (bot->CanEquipNewItem(NULL_SLOT, dest, itemId, false) == EQUIP_ERR_OK)
                bot->EquipNewItem(dest, itemId, true, 0, bonuses);
        } while (result->NextRow());
    }

    FillArtifacts(bot);

    bot->SetFullHealth();
    CharacterDatabase.PExecute("UPDATE partybot_characters SET setup = 1 WHERE guid = %u", bot->GetGUIDLow());
    bot->SaveToDB();
}

// every artifact trait, the second tier with its fourth ranks, Concordance of the Legionfall at 20 (owner 2026-09-28);
// same ranks as tools/fill_character full_rank() except the Concordance
void PartyBotSession::FillArtifacts(Player* bot)
{
    static uint8 const ConcordanceRanks = 20;

    for (uint8 slot : { EQUIPMENT_SLOT_MAINHAND, EQUIPMENT_SLOT_OFFHAND })
    {
        Item* artifact = bot->GetItemByPos(INVENTORY_SLOT_BAG_0, slot);
        if (!artifact || !artifact->GetTemplate()->GetArtifactID())
            continue;
        if (bot->GetItemByGuid(artifact->GetGuidValue(ITEM_FIELD_CREATOR)))
            continue;                   // the second half of a pair (off-hand glaive, shield sword): the parent has the traits

        bot->ApplyArtifactPowers(artifact, false);
        artifact->SetModifier(ITEM_MODIFIER_ARTIFACT_TIER, 1);
        artifact->InitArtifactsTier(artifact->GetTemplate()->GetArtifactID());

        std::vector<ItemDynamicFieldArtifactPowers> powers(artifact->GetArtifactPowers().begin(), artifact->GetArtifactPowers().end());
        for (ItemDynamicFieldArtifactPowers power : powers)
        {
            ArtifactPowerEntry const* entry = sArtifactPowerStore.LookupEntry(power.ArtifactPowerId);
            if (!entry || (entry->Flags & ARTIFACT_POWER_FLAG_RELIC_TALENT) || !entry->MaxPurchasableRank)
                continue;

            uint8 rank = entry->MaxPurchasableRank;
            if (entry->Flags & ARTIFACT_POWER_FLAG_FINAL)
                rank = entry->Tier ? std::min<uint8>(rank, ConcordanceRanks) : 1;   // the first tier's paragon trait stays at 1
            else if (!entry->Tier && (entry->Flags & ARTIFACT_POWER_FLAG_HAS_RANK))
                ++rank;                                                             // fourth rank with the second tier

            if (rank <= power.PurchasedRank)
                continue;
            power.CurrentRankWithBonus += rank - power.PurchasedRank;
            power.PurchasedRank = rank;
            artifact->SetArtifactPower(&power);
        }

        bot->ApplyArtifactPowers(artifact, true);
        artifact->SetState(ITEM_CHANGED, bot);
    }
}

void PartyBotSession::Setup(Player* bot)
{
    _setupDone = true;

    if (IsQuestTest())                  // a fresh level-1 character: no party bot setup, no group
    {
        bot->SetAI(NewQuestBotAI(bot, _leaderGuid, _questMaxLevel));
        bot->IsAIEnabled = true;
        return;
    }

    if (QueryResult result = CharacterDatabase.PQuery("SELECT spec FROM partybot_characters WHERE guid = %u AND setup = 0", bot->GetGUIDLow()))
        FirstLoginSetup(bot, (*result)[0].GetUInt32());

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

    // a bot can log in still in another group (the shutdown logout keeps the group): leave it first, or AddMember
    // only sets the original group and the group check dismisses the bot
    if (Group* oldGroup = bot->GetGroup())
        if (oldGroup != group)
            oldGroup->RemoveMember(bot->GetGUID());

    if (!group->IsMember(bot->GetGUID()))
    {
        if (group->IsFull() || !group->AddMember(bot))
        {
            ChatHandler(leader->GetSession()).PSendSysMessage("Party bot %s: your group is full.", bot->GetName());
            Dismiss();
            return;
        }
    }
    else if (!bot->GetGroup())          // its slot from an earlier add (no group_member row): take it again
    {
        bot->SetGroup(group, group->GetMemberGroup(bot->GetGUID()));
        bot->SetPartyType(group->GetGroupCategory(), GROUP_TYPE_NORMAL);
        group->SendUpdate();
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

    // spread out behind the leader: slots 0..3 at 2.5 yd, left/right behind, the next fours (raids) 1.5 yd further out,
    // at most 7 yd (the follow doesn't move within its distance, even without sight of the leader)
    static float const angles[] = { float(M_PI) * 0.75f, float(M_PI) * 1.25f, float(M_PI) * 0.6f, float(M_PI) * 1.4f };
    me->GetMotionMaster()->MoveFollow(leader, 2.5f + 1.5f * std::min(_slot / 4, 3), angles[_slot % 4]);
}

void PartyBotAI::UpdateAI(uint32 diff)
{
    if (_checkTimer > diff)
    {
        _checkTimer -= diff;
        return;
    }
    _checkTimer = 500;

    // Dungeon Finder: answer the role check with the spec's role and accept the "dungeon ready" proposal
    if (Group* group = me->GetGroup())
    {
        uint8 role = lfg::PLAYER_ROLE_DAMAGE;
        if (ChrSpecializationEntry const* spec = sChrSpecializationStore.LookupEntry(me->GetSpecializationId()))
            role = spec->Role == 0 ? lfg::PLAYER_ROLE_TANK : spec->Role == 1 ? lfg::PLAYER_ROLE_HEALER : lfg::PLAYER_ROLE_DAMAGE;
        sLFGMgr->AnswerForBot(group->GetGUID(), me->GetGUID(), role);
    }

    Player* leader = ObjectAccessor::FindPlayer(_leaderGuid);
    if (!leader || !leader->IsInWorld() || me->IsBeingTeleported())
        return;

    // other map or far away (portals, summons, the leader's hearthstone): teleport to the leader
    if (me->GetMapId() != leader->GetMapId() || !me->IsWithinDistInMap(leader, 100.0f))
    {
        if (!leader->IsBeingTeleported() && !leader->isInFlight())
            me->TeleportTo(leader->GetMapId(), leader->GetPositionX(), leader->GetPositionY(), leader->GetPositionZ(), leader->GetOrientation());
        return;
    }

    // don't move or pick another spell in the middle of a cast or channel
    if (me->IsNonMeleeSpellCast(false))
        return;

    ChrSpecializationEntry const* spec = sChrSpecializationStore.LookupEntry(me->GetSpecializationId());
    bool healer = spec && spec->Role == 1;

    // fight what the leader fights (tanks also pick up what attacks the group)
    if (Unit* target = PickTarget(leader))
    {
        bool newTarget = me->getVictim() != target;
        if (newTarget)
            me->Attack(target, !IsRanged());

        if (healer)
            PositionHealer(leader);
        else if (IsRanged())
            PositionRanged(target, leader);
        else if (newTarget)
            me->GetMotionMaster()->MoveChase(target);

        CastRotation(target);
        return;
    }

    if (me->getVictim())
        me->AttackStop();
    _approachGuid.Clear();
    _approachTicks = 0;

    CastRotation(nullptr);                  // out of combat: heals, buffs, pets
    FollowLeader(leader);
}

// ---------------------------------------------------------------- AI: spells (phase 2)

bool PartyBotAI::IsRanged() const
{
    switch (me->GetSpecializationId())
    {
        case 71: case 72: case 73: case 66: case 70: case 255: case 259: case 260: case 261: case 250: case 251: case 252:
        case 263: case 268: case 269: case 103: case 104: case 577: case 581:
            return false;
        default:
            return true;
    }
}

Unit* PartyBotAI::PickTarget(Player* leader) const
{
    auto valid = [this](Unit* unit)
    {
        return unit && unit->IsAlive() && me->IsValidAttackTarget(unit) && me->IsWithinDistInMap(unit, 60.0f);
    };

    auto isTank = [](Player* player)
    {
        ChrSpecializationEntry const* spec = sChrSpecializationStore.LookupEntry(player->GetSpecializationId());
        return spec && spec->Role == 0;
    };

    // tanks first pick up what hits someone else
    if (isTank(me))
        if (Unit* loose = TauntTarget())
            return loose;

    if (valid(leader->getVictim()))
        return leader->getVictim();

    // the leader has no target (it died, or the leader just heals): keep fighting what the group fights (owner report)
    std::vector<Player*> members;
    if (Group* group = me->GetGroup())
        for (GroupReference* ref = group->GetFirstMember(); ref; ref = ref->next())
            if (Player* member = ref->getSource())
                if (member->IsInWorld() && member->GetMap() == me->GetMap() && member->IsAlive())
                    members.push_back(member);

    // 1. the tank's target
    for (Player* member : members)
        if (member != me && isTank(member) && valid(member->getVictim()))
            return member->getVictim();

    // 2. the bot's own target while still in combat
    if (valid(me->getVictim()) && me->isInCombat())
        return me->getVictim();

    // 3. whatever hits a group member, 4. any enemy in combat with the group (has a member on its threat list)
    for (Player* member : members)
        for (Unit* attacker : *member->getAttackers())
            if (valid(attacker))
                return attacker;
    for (Player* member : members)
        for (HostileReference* ref = member->getHostileRefManager().getFirst(); ref; ref = ref->next())
            if (Unit* enemy = ref->getSource()->getOwner())
                if (valid(enemy))
                    return enemy;

    return nullptr;
}

uint32 PartyBotAI::EnemiesNear(Unit* center, float range) const
{
    std::list<Unit*> units;
    Trinity::AnyUnfriendlyUnitInObjectRangeCheck check(center, me, range);
    Trinity::UnitListSearcher<Trinity::AnyUnfriendlyUnitInObjectRangeCheck> searcher(center, units, check);
    center->VisitNearbyObject(range, searcher);
    uint32 count = 0;
    for (Unit* unit : units)
        if (unit->isInCombat() && me->IsValidAttackTarget(unit))
            ++count;
    return std::max<uint32>(count, 1);  // the center itself
}

// ---------------------------------------------------------------- AI: positioning (owner report: casters stood behind a
// wall or at the top of stairs doing nothing). The chase movement stops as soon as the bot is within its distance, even
// without line of sight, so ranged bots and healers walk towards whoever they cannot see until they can.

// in range and in line of sight
bool PartyBotAI::InSight(Unit* unit, float range) const
{
    return me->IsWithinDistInMap(unit, range) && me->IsWithinLOSInMap(unit);
}

// walk to the unit (pathfinding goes around walls and up stairs). The core's chase only follows the bot's victim
// (ChaseMovementGenerator::HasLostTarget), so anyone else (a healer's patient) gets a pathed point move, renewed
// every tick while the unit stays out of sight. Returns false when the bot gives up: no path (off the navmesh:
// the point move would walk straight through walls) or still out of sight after ~6 s of walking (flying, on a
// boat); it tries again ~14 s later.
bool PartyBotAI::Approach(Unit* unit)
{
    MotionMaster* motion = me->GetMotionMaster();
    bool newUnit = _approachGuid != unit->GetGUID();
    if (newUnit)
    {
        _approachGuid = unit->GetGUID();
        _approachTicks = 0;
    }
    // ticks feared, stunned or rooted don't count
    if (!me->HasUnitState(UNIT_STATE_NOT_MOVE) && motion->GetMotionSlotType(MOTION_SLOT_CONTROLLED) == NULL_MOTION_TYPE)
        if (++_approachTicks > 40)
            _approachTicks = 0;
    if (_approachTicks > 12)
        return false;

    if (unit != me->getVictim())
    {
        PathGenerator path(me);
        path.CalculatePath(unit->GetPositionX(), unit->GetPositionY(), unit->GetPositionZ());
        if (path.GetPathType() & (PATHFIND_NOPATH | PATHFIND_SHORT))
            return false;
        motion->MovePoint(0, unit->GetPositionX(), unit->GetPositionY(), unit->GetPositionZ(), true);
        return true;
    }
    if (newUnit || motion->GetCurrentMovementGeneratorType() != CHASE_MOTION_TYPE)
        motion->MoveChase(unit);
    return true;
}

// stop the bot's own movement (following, chasing, walking to a point). Never while fear, confuse or a jump/charge
// holds the controlled slot: clearing that would end the fear and let the bot cast through it.
void PartyBotAI::StandStill()
{
    MotionMaster* motion = me->GetMotionMaster();
    if (motion->GetMotionSlotType(MOTION_SLOT_CONTROLLED) != NULL_MOTION_TYPE)
        return;
    if (motion->GetCurrentMovementGeneratorType() != IDLE_MOTION_TYPE)
        motion->Clear();
    // also a follow run: a player's follow generator expires on its first update (the core's DoUpdate returns
    // false) and leaves its spline running under IDLE. No packet when nothing moves.
    me->StopMoving();
}

// ranged damage: stand still with the target in sight within 30 yd; move when it is out of sight or beyond 38 yd
// (the gap keeps them from stopping and starting all the time). A target the bot can't reach: stay with the group.
void PartyBotAI::PositionRanged(Unit* target, Player* leader)
{
    MovementGeneratorType type = me->GetMotionMaster()->GetCurrentMovementGeneratorType();
    if (!InSight(target, 38.0f))
    {
        if (!Approach(target))
            FollowLeader(leader);
        return;
    }

    _approachTicks = 0;
    if (type != CHASE_MOTION_TYPE || InSight(target, 30.0f))
        StandStill();
}

// healers: walk to the most hurt group member (not themselves) when they cannot see them, else keep the leader in
// sight, else stand and heal. A more hurt member in sight (or the healer itself) keeps them standing: cast-time
// heals fail while moving.
void PartyBotAI::PositionHealer(Player* leader)
{
    Unit* patient = nullptr;
    if (Group* group = me->GetGroup())
        for (GroupReference* ref = group->GetFirstMember(); ref; ref = ref->next())
        {
            Player* member = ref->getSource();
            if (!member || member == me || !member->IsAlive() || member->GetMap() != me->GetMap() || !me->IsWithinDistInMap(member, 60.0f))
                continue;
            if (member->GetHealthPct() >= 95.0f)
                continue;
            if (!patient || member->GetHealthPct() < patient->GetHealthPct())
                patient = member;
        }

    if (patient && InSight(patient, 38.0f))
        _approachTicks = 0;
    else if (patient && me->GetHealthPct() >= patient->GetHealthPct() && Approach(patient))
        return;
    if (!InSight(leader, 30.0f))
        FollowLeader(leader);
    else
        StandStill();
}

// the group member (bot included) with the lowest health below belowPct within 40 yd (60 yd when sight is not
// required), inSightOnly: in line of sight; withoutAura: skip those with it
Unit* PartyBotAI::LowestGroupMember(int32 belowPct, uint32 withoutAura, bool inSightOnly) const
{
    Unit* lowest = nullptr;
    auto consider = [&](Unit* unit)
    {
        if (!unit || !unit->IsAlive() || unit->GetMap() != me->GetMap())
            return;
        if (inSightOnly ? !InSight(unit, 40.0f) : !me->IsWithinDistInMap(unit, 60.0f))
            return;
        if (unit->GetHealthPct() >= float(belowPct))
            return;
        if (withoutAura && unit->HasAura(withoutAura, me->GetGUID()))
            return;
        if (!lowest || unit->GetHealthPct() < lowest->GetHealthPct())
            lowest = unit;
    };

    consider(me);
    if (Group* group = me->GetGroup())
        for (GroupReference* ref = group->GetFirstMember(); ref; ref = ref->next())
            if (ref->getSource() != me)
                consider(ref->getSource());
    return lowest;
}

uint32 PartyBotAI::GroupMembersBelow(int32 pct) const
{
    uint32 count = 0;
    if (Group* group = me->GetGroup())
        for (GroupReference* ref = group->GetFirstMember(); ref; ref = ref->next())
            if (Player* member = ref->getSource())
                if (member->IsAlive() && member->GetMap() == me->GetMap() && me->IsWithinDistInMap(member, 40.0f) && member->GetHealthPct() < float(pct))
                    ++count;
    return count;
}

// an enemy hitting a group member other than the bot: the tank takes it
Unit* PartyBotAI::TauntTarget() const
{
    if (Group* group = me->GetGroup())
        for (GroupReference* ref = group->GetFirstMember(); ref; ref = ref->next())
        {
            Player* member = ref->getSource();
            if (!member || member == me || member->GetMap() != me->GetMap())
                continue;
            for (Unit* attacker : *member->getAttackers())
                if (attacker->IsAlive() && attacker->getVictim() == member && me->IsValidAttackTarget(attacker) && me->IsWithinDistInMap(attacker, 30.0f))
                    return attacker;
        }
    return nullptr;
}

bool PartyBotAI::CastRotation(Unit* target)
{
    std::vector<PartyBotSpell> const* spells = sPartyBotMgr->GetSpells(me->GetSpecializationId());
    if (!spells)
        return false;

    for (PartyBotSpell const& entry : *spells)
        if (TryCast(entry, target))
            return true;
    return false;
}

bool PartyBotAI::TryCast(PartyBotSpell const& entry, Unit* target)
{
    SpellInfo const* info = sSpellMgr->GetSpellInfo(entry.Spell);
    if (!info || !me->HasSpell(entry.Spell) || me->HasSpellCooldown(entry.Spell) || me->GetGlobalCooldownMgr().HasGlobalCooldown(info))
        return false;

    uint32 aura = entry.Aura ? entry.Aura : entry.Spell;
    Unit* castTarget = target;
    switch (entry.Type)
    {
        case PartyBotSpellType::Damage:
        case PartyBotSpellType::Cooldown:
            if (!target)
                return false;
            break;
        case PartyBotSpellType::Dot:            // param: combo points needed (Rupture, Rip, Nightblade)
            if (!target || target->HasAura(aura, me->GetGUID()) || me->GetPower(POWER_COMBO_POINTS) < entry.Param)
                return false;
            break;
        case PartyBotSpellType::Execute:
            if (!target || target->GetHealthPct() >= float(entry.Param))
                return false;
            break;
        case PartyBotSpellType::Finisher:
            if (!target || me->GetPower(POWER_COMBO_POINTS) < entry.Param)
                return false;
            break;
        case PartyBotSpellType::Aoe:
            if (!target || EnemiesNear(target, 8.0f) < uint32(entry.Param))
                return false;
            break;
        case PartyBotSpellType::Buff:
            if (me->HasAura(aura))
                return false;
            castTarget = me;
            break;
        case PartyBotSpellType::Heal:
            castTarget = LowestGroupMember(entry.Param, 0);
            break;
        case PartyBotSpellType::Hot:
            castTarget = LowestGroupMember(entry.Param, aura);
            break;
        case PartyBotSpellType::AoeHeal:
            castTarget = GroupMembersBelow(entry.Param) >= 3 ? LowestGroupMember(entry.Param, 0) : nullptr;
            break;
        case PartyBotSpellType::SelfHeal:       // strikes that heal the bot (Victory Rush, Death Strike) go at the target
            castTarget = me->GetHealthPct() < float(entry.Param) ? (info->IsPositive() ? me : target) : nullptr;
            break;
        case PartyBotSpellType::Taunt:
            castTarget = TauntTarget();
            break;
        case PartyBotSpellType::Pet:
            castTarget = me->GetPetGUID().IsEmpty() ? me : nullptr;
            break;
    }
    if (!castTarget)
        return false;

    if (castTarget != me)
    {
        me->SetInFront(castTarget);                         // server-side facing (the facing check)
        if (me->IsStopped())
        {
            // clients see the turn; the facing spline sets MOVEMENTFLAG_FORWARD, which would fail every cast-time
            // spell with SPELL_FAILED_MOVING
            me->SetFacingToObject(castTarget);
            me->RemoveUnitMovementFlag(MOVEMENTFLAG_FORWARD);
        }
    }

    // ground-targeted spells (Death and Decay, Flamestrike, ...) go to the target's position
    if (info->GetExplicitTargetMask() & TARGET_FLAG_DEST_LOCATION)
        return me->CastSpell(castTarget->GetPositionX(), castTarget->GetPositionY(), castTarget->GetPositionZ(), entry.Spell, false) == SPELL_CAST_OK;

    return me->CastSpell(castTarget, info, false) == SPELL_CAST_OK;
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

std::vector<PartyBotSpell> const* PartyBotMgr::GetSpells(uint32 specId)
{
    std::call_once(_spellsLoaded, [this]()
    {
        static std::map<std::string, PartyBotSpellType> const types =
        {
            { "damage", PartyBotSpellType::Damage }, { "dot", PartyBotSpellType::Dot }, { "execute", PartyBotSpellType::Execute },
            { "finisher", PartyBotSpellType::Finisher }, { "buff", PartyBotSpellType::Buff }, { "cooldown", PartyBotSpellType::Cooldown },
            { "aoe", PartyBotSpellType::Aoe }, { "heal", PartyBotSpellType::Heal }, { "hot", PartyBotSpellType::Hot },
            { "aoeheal", PartyBotSpellType::AoeHeal }, { "selfheal", PartyBotSpellType::SelfHeal }, { "taunt", PartyBotSpellType::Taunt },
            { "pet", PartyBotSpellType::Pet },
        };

        QueryResult result = WorldDatabase.Query("SELECT spec, spell, type, param, aura FROM partybot_spells ORDER BY spec, prio");
        if (!result)
            return;
        do
        {
            Field* fields = result->Fetch();
            auto type = types.find(fields[2].GetString());
            if (type == types.end() || !sSpellMgr->GetSpellInfo(fields[1].GetUInt32()))
            {
                TC_LOG_ERROR("sql.sql", "partybot_spells: spec %u spell %u type '%s' skipped", fields[0].GetUInt32(), fields[1].GetUInt32(), fields[2].GetString().c_str());
                continue;
            }
            _spells[fields[0].GetUInt32()].push_back({ fields[1].GetUInt32(), type->second, fields[3].GetInt32(), fields[4].GetUInt32() });
        } while (result->NextRow());
    });

    auto itr = _spells.find(specId);
    return itr != _spells.end() ? &itr->second : nullptr;
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

    // a party holds 4 bots; a raid as many as it has free places (owner 2026-09-28)
    Group* group = leader->GetGroup();
    if ((!group || !group->isRaidGroup()) && CountBots(leader->GetGUID()) >= MaxBotsPerLeader)
        return "You already have the maximum of party bots (4 in a party, convert to a raid for more).";
    if (group && group->IsFull())
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
        session->RequestDismiss();
        ++removed;
    }

    if (!removed)
        return name.empty() ? "You have no party bots." : "No party bot named " + name + ".";
    return "";
}

// ---------------------------------------------------------------- bot characters

ChrSpecializationEntry const* PartyBotMgr::FindSpec(std::string const& className, std::string const& specName)
{
    for (uint32 cls = 1; cls < MAX_CLASSES; ++cls)
    {
        ChrClassesEntry const* classEntry = sChrClassesStore.LookupEntry(cls);
        if (!classEntry || !boost::iequals(std::string(classEntry->Name->Str[DEFAULT_LOCALE]), className))
            continue;
        for (uint32 i = 0; i < MAX_SPECIALIZATIONS; ++i)
            if (ChrSpecializationEntry const* spec = sDB2Manager.GetChrSpecializationByIndex(cls, i))
                if (boost::iequals(std::string(spec->Name->Str[DEFAULT_LOCALE]), specName))
                    return spec;
    }
    return nullptr;
}

// a race of the creator's faction that can be this class
static uint8 BotRace(uint8 cls, bool alliance)
{
    if (alliance)
    {
        switch (cls)
        {
            case CLASS_SHAMAN:       return RACE_DRAENEI;
            case CLASS_DRUID:
            case CLASS_DEMON_HUNTER: return RACE_NIGHTELF;
            default:                 return RACE_HUMAN;
        }
    }
    switch (cls)
    {
        case CLASS_PALADIN:
        case CLASS_PRIEST:
        case CLASS_DEMON_HUNTER: return RACE_BLOODELF;
        case CLASS_DRUID:        return RACE_TAUREN;
        default:                 return RACE_ORC;
    }
}

static std::string BotName(std::string const& raw)
{
    // letters of raw (spec + class, e.g. Holypaladin); letters a..z at the end when the name is taken
    std::string base;
    for (char c : raw)
        if (isalpha(c))
            base += char(base.empty() ? toupper(c) : tolower(c));
    if (base.size() > 11)
        base.resize(11);

    std::string name = base;
    for (char suffix = 'a'; suffix <= 'z'; ++suffix)
    {
        if (ObjectMgr::GetPlayerGUIDByName(name).IsEmpty() && sWorld->CheckCharacterName(name))
            return name;
        name = base + suffix;
    }
    return "";
}

// the bot accounts partybot1@bot..partybot50@bot (made by the owner), matched exactly
static char const* const BotAccountPattern = "^PARTYBOT[0-9]+@BOT$";

uint32 PartyBotMgr::FreeBotAccount()
{
    if (QueryResult accounts = LoginDatabase.PQuery("SELECT id FROM account WHERE username REGEXP '%s' ORDER BY id", BotAccountPattern))
    {
        do
        {
            uint32 id = (*accounts)[0].GetUInt32();
            if (!_usedAccounts.count(id) && !CharacterDatabase.PQuery("SELECT 1 FROM characters WHERE account = %u LIMIT 1", id))
                return id;
        } while (accounts->NextRow());
    }
    return 0;
}

// a level-1 character on a bot account, as the character screen makes it (without a client); empty guid on failure
static ObjectGuid NewCharacter(uint32 accountId, uint8 race, uint8 cls, std::string const& name)
{
    std::string accountName;
    AccountMgr::GetName(accountId, accountName);
    PartyBotSession session(accountId, std::move(accountName), ObjectGuid::Empty, ObjectGuid::Empty);

    WorldPackets::Character::CharacterCreateInfo info;
    info.Race = race;
    info.Class = cls;
    info.Sex = urand(0, 1) ? GENDER_MALE : GENDER_FEMALE;
    info.Name = name;
    info.CustomDisplay.fill(0);

    Player newChar(&session);
    newChar.GetMotionMaster()->Initialize();
    if (!newChar.Create(sObjectMgr->GetGenerator<HighGuid::Player>()->Generate(), &info))
    {
        newChar.CleanupsBeforeDelete();
        return ObjectGuid::Empty;
    }

    newChar.setCinematic(1);
    newChar.SaveToDB(true);
    sWorld->AddCharacterInfo(newChar.GetGUID(), accountId, name, newChar.getGender(), newChar.getRace(), newChar.getClass(), newChar.getLevel());
    sWorld->UpdateCharacterAccount(newChar.GetGUID(), accountId);
    newChar.GetAchievementMgr()->ClearMap();
    newChar.CleanupsBeforeDelete();
    return newChar.GetGUID();
}

std::string PartyBotMgr::CreateBot(Player* creator, uint32 specId, std::string& name)
{
    ChrSpecializationEntry const* spec = sChrSpecializationStore.LookupEntry(specId);
    if (!spec || !spec->ClassID || spec->ClassID >= MAX_CLASSES)
        return "Unknown specialization.";

    uint32 accountId = FreeBotAccount();
    if (!accountId)
        return "No free partybot account left (partybotN@bot).";

    name = BotName(std::string(spec->Name->Str[DEFAULT_LOCALE]) + sChrClassesStore.AssertEntry(spec->ClassID)->Name->Str[DEFAULT_LOCALE]);
    if (name.empty())
        return "Could not find a free name.";

    ObjectGuid guid = NewCharacter(accountId, BotRace(spec->ClassID, creator->GetTeam() == ALLIANCE), spec->ClassID, name);
    if (guid.IsEmpty())
        return "The character could not be created.";

    _usedAccounts.insert(accountId);
    CharacterDatabase.PExecute("REPLACE INTO partybot_characters (guid, account, spec, setup) VALUES (%u, %u, %u, 0)", guid.GetCounter(), accountId, specId);

    TC_LOG_INFO("server.partybot", "Party bot character %s (spec %u, account %u) created by %s", name.c_str(), specId, accountId, creator->GetName());
    return "";
}

// quest-test runs at the same time: one per race/class, at most MaxQuestTests (owner 2026-10-01: several starting zones
// at once; each run scans its zone's spawns once at start on its map thread); _lock held
static constexpr uint32 MaxQuestTests = 4;
uint32 PartyBotMgr::QuestTestCount()
{
    Cleanup();
    uint32 count = 0;
    for (auto const& bot : _bots)
        if (std::shared_ptr<PartyBotSession> session = bot.lock())
            if (session->IsQuestTest())
                ++count;
    return count;
}

uint32 PartyBotMgr::StopQuestTests()
{
    std::lock_guard<std::mutex> guard(_lock);
    uint32 stopped = 0;
    for (auto const& bot : _bots)
        if (std::shared_ptr<PartyBotSession> session = bot.lock())
            if (session->IsQuestTest() && !session->IsDismissed())
            {
                session->RequestDismiss();
                ++stopped;
            }
    return stopped;
}

// .partybot questtest <class> [race] [max level] (owner 2026-10-01, #65): a fresh level-1 character of that race and
// class (default: the GM's faction, like .partybot create) plays its starting zone's quests alone (QuestBot.cpp). Up to
// MaxQuestTests runs at a time, one per race/class. Each run starts from level 1: the new character is made first, then the previous quest-test character
// of that race and class is deleted. Only a character named Qt... (case-sensitive) on a partybot account
// (partybotN@bot exactly) that is no party bot (no partybot_characters row) is ever deleted.
std::string PartyBotMgr::StartQuestTest(Player* gm, std::string text)
{
    {
        std::lock_guard<std::mutex> guard(_lock);
        if (QuestTestCount() >= MaxQuestTests)
            return "Already " + std::to_string(MaxQuestTests) + " quest tests running (.partybot questtest stop ends them).";
    }

    uint8 maxLevel = 5;
    size_t space = text.find_last_of(' ');
    if (space != std::string::npos && isdigit(uint8(text[space + 1])))
    {
        maxLevel = uint8(std::min(atoi(text.c_str() + space + 1), int(MAX_LEVEL)));
        text.resize(space);
    }

    // the class name starts the text (death knight, demon hunter have a space), the race is the rest
    ChrClassesEntry const* classEntry = nullptr;
    for (uint32 cls = 1; cls < MAX_CLASSES && !classEntry; ++cls)
        if (ChrClassesEntry const* entry = sChrClassesStore.LookupEntry(cls))
        {
            std::string className = entry->Name->Str[DEFAULT_LOCALE];
            if (boost::istarts_with(text, className) && (text.size() == className.size() || text[className.size()] == ' '))
            {
                classEntry = entry;
                text = text.size() > className.size() ? text.substr(className.size() + 1) : "";
            }
        }
    if (!classEntry || !maxLevel)
        return "Usage: .partybot questtest <class> [race] [max level, default 5]   e.g. .partybot questtest warrior human";

    uint8 cls = classEntry->ID;
    uint8 race = BotRace(cls, gm->GetTeam() == ALLIANCE);
    if (!text.empty())
    {
        race = 0;
        for (ChrRacesEntry const* entry : sChrRacesStore)
            if (boost::iequals(std::string(entry->Name->Str[DEFAULT_LOCALE]), text))
                race = entry->ID;
        if (!race)
            return "Unknown race '" + text + "'.";
    }
    std::string raceName = sChrRacesStore.AssertEntry(race)->Name->Str[DEFAULT_LOCALE];

    // the previous quest-test character of this race and class (a player's Qt... character is skipped)
    uint32 accountId = 0;
    ObjectGuid oldGuid;
    if (QueryResult result = CharacterDatabase.PQuery("SELECT c.guid, c.account, c.name FROM characters c LEFT JOIN partybot_characters p ON p.guid = c.guid "
        "WHERE p.guid IS NULL AND c.name LIKE 'Qt%%' AND c.race = %u AND c.class = %u", race, cls))
        do
        {
            uint32 account = (*result)[1].GetUInt32();
            if ((*result)[2].GetString().compare(0, 2, "Qt") == 0
                && LoginDatabase.PQuery("SELECT 1 FROM account WHERE id = %u AND username REGEXP '%s'", account, BotAccountPattern))
            {
                oldGuid = ObjectGuid::Create<HighGuid::Player>((*result)[0].GetUInt64());
                accountId = account;
                break;
            }
        } while (result->NextRow());

    if (!oldGuid.IsEmpty() && (ObjectAccessor::FindPlayer(oldGuid) || sWorld->FindSession(accountId)))
        return "A quest test of this race and class is running, or its account is in use (.partybot questtest stop).";
    if (!accountId && !(accountId = FreeBotAccount()))
        return "No free partybot account left (partybotN@bot).";

    std::string name = BotName("Qt" + raceName + classEntry->Name->Str[DEFAULT_LOCALE]);   // the old name is still taken
    if (name.empty())
        return "Could not find a free name.";

    // the new character first; the old one goes only once the new one exists
    ObjectGuid guid = NewCharacter(accountId, race, cls, name);
    if (guid.IsEmpty())
        return "The character could not be created (" + raceName + " " + classEntry->Name->Str[DEFAULT_LOCALE] + " allowed?).";
    _usedAccounts.insert(accountId);

    if (!oldGuid.IsEmpty())
    {
        sWorld->DeleteCharacterNameData(oldGuid);
        Player::DeleteFromDB(oldGuid, accountId, true, true);
    }

    std::string accountName;
    AccountMgr::GetName(accountId, accountName);
    std::shared_ptr<PartyBotSession> session = std::make_shared<PartyBotSession>(accountId, std::move(accountName), guid, gm->GetGUID(), maxLevel);
    {
        std::lock_guard<std::mutex> guard(_lock);
        if (QuestTestCount() >= MaxQuestTests)  // other GMs started some meanwhile; the new character is replaced at the next run
            return "Already " + std::to_string(MaxQuestTests) + " quest tests running (.partybot questtest stop ends them).";
        _bots.push_back(session);
    }
    sWorld->AddSession(session);
    TC_LOG_INFO("server.questbot", "QUESTBOT event=create bot=%s race=%u class=%u maxlevel=%u account=%u by=%s", name.c_str(), race, cls, maxLevel, accountId, gm->GetName());
    return "";
}

std::string PartyBotMgr::AddBotByRole(Player* leader, std::string const& what)
{
    // a character name first
    std::string name = what;
    if (normalizePlayerName(name) && !ObjectMgr::GetPlayerGUIDByName(name).IsEmpty())
        return AddBot(leader, name);

    int32 role = -1;
    if (boost::iequals(what, "tank"))
        role = 0;
    else if (boost::iequals(what, "healer") || boost::iequals(what, "heal"))
        role = 1;
    else if (boost::iequals(what, "dps") || boost::iequals(what, "damage"))
        role = 2;

    QueryResult result = CharacterDatabase.Query("SELECT p.guid, p.spec, c.name, c.race FROM partybot_characters p JOIN characters c ON c.guid = p.guid ORDER BY p.guid");
    if (!result)
        return "There are no bot characters yet (.partybot create <class> <spec>).";

    bool alliance = leader->GetTeam() == ALLIANCE;
    do
    {
        Field* fields = result->Fetch();
        ChrSpecializationEntry const* spec = sChrSpecializationStore.LookupEntry(fields[1].GetUInt32());
        if (!spec || (Player::TeamForRace(fields[3].GetUInt8()) == ALLIANCE) != alliance)
            continue;

        bool match = role >= 0 ? spec->Role == role
            : boost::iequals(std::string(spec->Name->Str[DEFAULT_LOCALE]), what)
            || boost::iequals(std::string(sChrClassesStore.AssertEntry(spec->ClassID)->Name->Str[DEFAULT_LOCALE]), what);
        if (!match)
            continue;

        std::string botName = fields[2].GetString();
        ObjectGuid guid = ObjectMgr::GetPlayerGUIDByName(botName);
        if (guid.IsEmpty() || ObjectAccessor::FindPlayer(guid))
            continue;
        if (sWorld->FindSession(ObjectMgr::GetPlayerAccountIdByGUID(guid)))
            continue;
        return AddBot(leader, botName);
    } while (result->NextRow());

    return "No free bot for '" + what + "' on your faction (.partybot create <class> <spec>).";
}
