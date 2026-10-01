#include "PartyBot.h"
#include "AccountMgr.h"
#include "Group.h"
#include "GroupMgr.h"
#include "Log.h"
#include "MotionMaster.h"
#include "MovementPackets.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "CharmInfo.h"
#include "Pet.h"
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
#include "GameObject.h"
#include "GameObjectPackets.h"
#include "LootMgr.h"
#include "LootPackets.h"
#include <boost/algorithm/string/predicate.hpp>
#include <sstream>

// ---------------------------------------------------------------- session

PartyBotSession::PartyBotSession(uint32 accountId, std::string&& accountName, ObjectGuid botGuid, ObjectGuid leaderGuid, uint8 questMaxLevel, uint8 dungeonRole) :
    WorldSession(accountId, std::move(accountName), nullptr, SEC_PLAYER, CURRENT_EXPANSION, 0, "Win", LOCALE_enUS, 0, false,
        AT_AUTH_FLAG_NONE, std::unordered_map<uint8, int64>()),
    _botGuid(botGuid), _leaderGuid(leaderGuid), _questMaxLevel(questMaxLevel), _dungeonRole(dungeonRole)
{
}

static bool IsTankSpec(Player* player)
{
    ChrSpecializationEntry const* spec = sChrSpecializationStore.LookupEntry(player->GetSpecializationId());
    return spec && spec->Role == 0;
}

static bool IsHealerSpec(Player* player)
{
    ChrSpecializationEntry const* spec = sChrSpecializationStore.LookupEntry(player->GetSpecializationId());
    return spec && spec->Role == 1;
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

    // #140 A: a bot that leveled (dungeon run, quest test) learns the talent row that opened once it is out of combat
    // (talents are refused in combat or dead). Player::GiveLevel already taught the new class and spec spells.
    if (_setupDone && !_dismissed && bot->getLevel() != _talentLevel && bot->IsAlive() && !bot->isInCombat())
    {
        if (_talentLevel)               // the first time just notes the level (the first login set the talents)
            PartyBotMgr::OnBotLevelUp(bot);
        _talentLevel = bot->getLevel();
    }

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

    // dungeon run (DungeonRun.cpp): the run's steps; the tank's AI handles its own death (DungeonLeaderDeadUpdate there)
    if (IsDungeonBot() && !_dismissed)
    {
        DungeonUpdate(bot, diff);
        if (_botGuid == _leaderGuid)
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

    if (IsDungeonBot())                 // the run forms and leaves the group and dismisses its bots
        return result;

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

// the spec's talent build (world.partybot_talents, generated with the rotations): the picks of the rows the bot's level
// has unlocked (Player::CalculateTalentsPoints: 15, 30, 45, 60, 75, 90, 100; Death Knights 56.., Demon Hunters 99..)
// that it doesn't have yet. LearnTalent refuses the locked rows anyway; skipping them spares the refusal packets.
static void LearnBotTalents(Player* bot, uint32 specId)
{
    QueryResult result = WorldDatabase.PQuery("SELECT talent FROM partybot_talents WHERE spec = %u", specId);
    if (!result)
        return;

    bot->SetFlag(UNIT_FIELD_FLAGS_2, UNIT_FLAG2_ALLOW_CHANGING_TALENTS);    // replaces an earlier pick in the row
    do
    {
        uint32 talentId = (*result)[0].GetUInt32();
        TalentEntry const* talent = sTalentStore.LookupEntry(talentId);
        if (talent && talent->TierID < bot->GetUInt32Value(PLAYER_FIELD_MAX_TALENT_TIERS) && !bot->HasTalent(talentId, bot->GetActiveTalentGroup()))
            bot->LearnTalent(talentId);
    } while (result->NextRow());
    bot->RemoveFlag(UNIT_FIELD_FLAGS_2, UNIT_FLAG2_ALLOW_CHANGING_TALENTS);
}

void PartyBotMgr::OnBotLevelUp(Player* bot)
{
    LearnBotTalents(bot, bot->GetSpecializationId());
}

// level-scaling gear for a level bot (#140): heirlooms. Their item level follows the owner's level through their
// ScalingStatDistribution (Item::GetItemLevel; Player::GiveLevel re-applies the stats at each level), by themselves up
// to level 60, with the level-110 upgrade (bonus list 3592: ScalingStatDistribution 1059, same curve 956) up to 110:
// item level 20 at 15, 45 at 40, ~85 at 60, 605 at 100, 800 at 110. No heirloom gloves, wrists, belt or boots:
// the starting gear stays there.
static void EquipHeirlooms(Player* bot, ChrSpecializationEntry const* spec)
{
    // head, shoulders, chest, legs per armor type (strength or agility / intellect: the spec's primary stat counts)
    static uint32 const armor[4][4] =
    {
        { 122245, 122355, 122381, 122251 },     // plate: Polished ... of Valor
        { 122246, 122356, 122379, 122252 },     // mail
        { 122248, 122358, 122383, 122254 },     // leather: Stained Shadowcraft
        { 122250, 122360, 122384, 122256 },     // cloth: Tattered Dreadmist
    };
    // back, neck, ring, trinket, trinket per primary stat
    static uint32 const stat[3][5] =
    {
        { 122260, 122667, 128172, 122361, 122530 },     // strength
        { 122261, 122668, 128173, 122361, 122530 },     // agility
        { 122262, 122664, 128169, 122362, 122361 },     // intellect
    };

    // the best armor the class wears; ChrSpecialization.PrimaryStatPriority: 5 strength, 2-3 agility, 0-1 intellect
    uint8 armorType = bot->HasSkill(SKILL_PLATE_MAIL) ? 0 : bot->HasSkill(SKILL_MAIL) ? 1 : bot->HasSkill(SKILL_LEATHER) ? 2 : 3;
    uint8 statType = spec->PrimaryStatPriority >= 4 ? 0 : spec->PrimaryStatPriority >= 2 ? 1 : 2;

    // main hand, off hand (0: none). The off hand needs Dual Wield / Titan's Grip; without it the core refuses it
    std::pair<uint32, uint32> weapons;
    switch (spec->ID)
    {
        case 73: case 66:               weapons = { 122389, 122391 }; break;   // tanks: one-hand sword and shield
        case 65: case 262: case 264:    weapons = { 122354, 122392 }; break;   // intellect mace and shield
        case 72:                        weapons = { 122349, 122365 }; break;   // Fury: two two-handers
        case 253: case 254:             weapons = { 122352, 0 }; break;        // bow
        case 255:                       weapons = { 140773, 0 }; break;        // Survival: polearm
        case 259: case 260: case 261:   weapons = { 122350, 122364 }; break;   // daggers
        case 263: case 269:             weapons = { 122385, 122396 }; break;   // agility mace and fist weapon
        case 577: case 581:             weapons = { 122351, 122396 }; break;   // no heirloom warglaives: sword and fist weapon
        case 268: case 103: case 104:   weapons = { 122363, 0 }; break;        // agility staff
        case 71: case 70: case 250: case 251: case 252: weapons = { 122349, 0 }; break;   // strength two-hander
        default:                        weapons = { 122353, 0 }; break;        // intellect staff
    }

    for (uint8 slot : { EQUIPMENT_SLOT_HEAD, EQUIPMENT_SLOT_NECK, EQUIPMENT_SLOT_SHOULDERS, EQUIPMENT_SLOT_CHEST, EQUIPMENT_SLOT_LEGS,
        EQUIPMENT_SLOT_BACK, EQUIPMENT_SLOT_FINGER1, EQUIPMENT_SLOT_FINGER2, EQUIPMENT_SLOT_TRINKET1, EQUIPMENT_SLOT_TRINKET2,
        EQUIPMENT_SLOT_MAINHAND, EQUIPMENT_SLOT_OFFHAND })
        if (bot->GetItemByPos(INVENTORY_SLOT_BAG_0, slot))
            bot->DestroyItem(INVENTORY_SLOT_BAG_0, slot, true);

    std::vector<uint32> const upgrade110 = { 3592 };
    std::vector<uint32> items(std::begin(armor[armorType]), std::end(armor[armorType]));
    items.insert(items.end(), std::begin(stat[statType]), std::end(stat[statType]));
    items.push_back(122529);            // Dread Pirate Ring (no primary stat) in the second ring slot
    items.push_back(weapons.first);
    items.push_back(weapons.second);
    for (uint32 itemId : items)
    {
        uint16 dest;
        if (itemId && bot->CanEquipNewItem(NULL_SLOT, dest, itemId, false) == EQUIP_ERR_OK)
            bot->EquipNewItem(dest, itemId, true, 0, upgrade110);
    }
}

// .partybot create made this character: level 110, its spec and its gear set (world.gear_npc_items) at the first login.
// A level bot (CreateLevelBot, setup 2) keeps the level it was made with and gets heirlooms instead.
void PartyBotSession::FirstLoginSetup(Player* bot, uint32 specId, bool levelBot)
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

    if (!levelBot && bot->getLevel() < 110)
        bot->GiveLevel(110);
    if (bot->GetSpecializationId() != specId)
        bot->ActivateTalentGroup(spec);     // also teaches the spec's spells of the bot's level

    LearnBotTalents(bot, specId);

    // a level bot: heirlooms instead of the level-110 set, no class hall or artifact
    if (levelBot)
    {
        EquipHeirlooms(bot, spec);
        bot->SetFullHealth();
        CharacterDatabase.PExecute("UPDATE partybot_characters SET setup = 3 WHERE guid = %u", bot->GetGUIDLow());
        bot->SaveToDB();
        return;
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

    // setup 0: a .partybot create bot, 2: a level bot (CreateLevelBot); 1 and 3: done
    if (QueryResult result = CharacterDatabase.PQuery("SELECT spec, setup FROM partybot_characters WHERE guid = %u AND setup IN (0, 2)", bot->GetGUIDLow()))
        FirstLoginSetup(bot, (*result)[0].GetUInt32(), (*result)[1].GetUInt8() == 2);

    if (IsDungeonBot())                 // no group to join: the run forms it once all five are in
    {
        DungeonSetup(bot);
        return;
    }

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
        // dead (a wipe, a quest-test death): up first, or the logout leaves a corpse where it logs out (4 dungeon bots'
        // corpses lay at Northshire Abbey, 2026-10-01)
        if (bot->IsInWorld() && !bot->IsAlive())
        {
            bot->ResurrectPlayer(1.0f);
            bot->SpawnCorpseBones();
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
        if (WaitForThreat(leader, target))
        {
            if (me->getVictim())
                me->AttackStop();
            FollowLeader(leader);
            return;
        }

        bool newTarget = me->getVictim() != target;
        if (newTarget)
            me->Attack(target, !IsRanged());
        PetAttack(target);

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

// owner 2026-10-01: the bots' pets (warlock imp) stayed passive. Like the pet bar's Attack (PetHandler COMMAND_ATTACK):
// the pet's AI starts on the bot's target; once per target
void PartyBotAI::PetAttack(Unit* target)
{
    Pet* pet = me->GetPet();
    CharmInfo* charmInfo = pet ? pet->GetCharmInfo() : nullptr;
    if (!charmInfo || !pet->IsAlive() || !pet->IsAIEnabled || (pet->getVictim() == target && charmInfo->IsCommandAttack()))
        return;

    if (pet->getVictim())
        pet->AttackStop();
    pet->ClearUnitState(UNIT_STATE_FOLLOW);
    charmInfo->SetIsCommandAttack(true);
    charmInfo->SetIsAtStay(false);
    charmInfo->SetIsFollowing(false);
    charmInfo->SetIsReturning(false);
    pet->AI()->AttackStart(target);
}

// walk toward pos in legs of up to WalkLegLength along the navmesh corridor (call again once a leg ended). MovePoint's
// smooth path gives up past ~300 yd (74 points of 4 yd) and read as "no path" for a quest NPC or a spawn point further
// away (quest bots 2026-10-01: Kurtok 300 yd from Northshire Abbey, Goldshire's innkeeper). The corridor's corners
// (straight path) only pick the leg's end; the leg itself is the normal point movement (dev-check: a spline through
// sparse corners cuts wall corners). False: no path at all
bool PartyBotAI::WalkTo(Position const& pos)
{
    static float const WalkLegLength = 250.0f;
    me->GetMap()->LoadGrid(pos.GetPositionX(), pos.GetPositionY());     // the path needs the destination's navmesh tile
    PathGenerator path(me);
    path.SetUseStraightPath(true);
    path.CalculatePath(pos.GetPositionX(), pos.GetPositionY(), pos.GetPositionZ());
    Movement::PointsArray const& corners = path.GetPath();
    if ((path.GetPathType() & (PATHFIND_NOPATH | PATHFIND_SHORT)) || corners.empty())
    {
        _walkRoute.clear();
        return false;
    }
    _walkRoute = corners;

    // the farthest corner within the leg length along the path (the corridor's end when it is shorter); a first corner
    // beyond it: the point at that length on the straight segment to it
    G3D::Vector3 leg = corners.back();
    G3D::Vector3 last(me->GetPositionX(), me->GetPositionY(), me->GetPositionZ());
    float length = 0.0f;
    for (G3D::Vector3 const& corner : corners)
    {
        float step = (corner - last).length();
        if (length + step > WalkLegLength)
        {
            leg = length > 1.0f ? last : last + (corner - last) * ((WalkLegLength - length) / step);    // corner 0 = the start
            break;
        }
        length += step;
        last = corner;
    }
    me->GetMotionMaster()->MovePoint(0, leg.x, leg.y, leg.z, true);
    return true;
}

// user uses the object as a client does (CMSG_GAME_OBJ_USE: goobers, buttons, quest objects: scripts and credit).
// True: its loot is open for user (LootQuestItems takes it)
bool PartyBotAI::UseGameObject(Player* user, GameObject* go)
{
    WorldPacket data(CMSG_GAME_OBJ_USE);
    WorldPackets::GameObject::GameObjectUse packet(std::move(data));
    packet.Guid = go->GetGUID();
    user->GetSession()->HandleGameObjectUse(packet);

    // chests and gathering nodes: the client opens them with the lock's opening spell (Spell::SendLoot).
    // ponytail: looted directly instead, so a chest's triggered event and linked trap do not fire; cast the lock's
    // open spell here if a quest turns out to depend on them
    if (user->GetLootGUID() != go->GetGUID() && go->GetGOInfo()->GetLootId())
        user->SendLoot(go->GetGUID(), LOOT_CORPSE);
    return user->GetLootGUID() == go->GetGUID();
}

// looter takes the quest items (and the items wanted() asks for) and releases the loot, as a player looting.
// Returns the item ids taken
std::vector<uint32> PartyBotAI::LootQuestItems(Player* looter, ObjectGuid guid, Loot* loot, std::function<bool(uint32)> const& wanted)
{
    std::vector<uint32> items;
    WorldPacket data(CMSG_LOOT_ITEM);
    WorldPackets::Loot::AutoStoreLootItem packet(std::move(data));
    for (uint32 slot = 0; slot < loot->GetMaxSlotInLootFor(looter) && slot < 255; ++slot)
        if (LootItem* item = loot->LootItemInSlot(slot, looter))
            if (slot >= loot->items.size() || item->needs_quest || wanted(item->item.ItemID))
            {
                packet.Loot.push_back({ guid, uint8(slot + 1) });
                items.push_back(item->item.ItemID);
            }

    if (!packet.Loot.empty())
        looter->GetSession()->HandleAutostoreLootItemOpcode(packet);
    looter->GetSession()->DoLootRelease(guid);
    return items;
}

// owner 2026-10-01: "they all run in headless" before the tank. Damage dealers attack the tank's target once it has hit
// the tank for ThreatLeadMs (the mob still walking up or not yet aggroed: wait behind the tank); a mob on anyone else
// is loose and helped at once. Only when the leader is a tank (a bot of a dungeon run, or a player in a tank spec)
bool PartyBotAI::WaitForThreat(Player* leader, Unit* target)
{
    static uint32 const ThreatLeadMs = 2500;
    static uint32 const WalkUpMaxMs = 20 * IN_MILLISECONDS;
    if (leader == me || !IsTankSpec(leader) || IsTankSpec(me) || IsHealerSpec(me) || leader->getVictim() != target)
        return false;
    Unit* victim = target->getVictim();
    if (victim && victim != leader)
        return false;
    // times from getMSTime: UpdateAI's body runs every 500 ms but diff is only the last frame's (dev-check)
    uint32 now = getMSTime();
    if (_leadGuid != target->GetGUID())
    {
        _leadGuid = target->GetGUID();
        _leadStartMs = 0;
        _walkUpStartMs = now;
    }
    if (!victim && !target->isInCombat())   // the tank still walking up to it (an unreachable one: not forever)
    {
        _leadStartMs = 0;
        return getMSTimeDiff(_walkUpStartMs, now) < WalkUpMaxMs;
    }
    if (!_leadStartMs)
        _leadStartMs = now ? now : 1;
    // in combat without a victim (a turret, a boss between phases): a longer wait, not forever
    return getMSTimeDiff(_leadStartMs, now) < (victim ? ThreatLeadMs : 3 * ThreatLeadMs);
}

// owner 2026-10-01: tanks lost aggro. Each tank spec's +900% threat spell is a passive (Defensive Stance 71, Righteous
// Fury 25780, 115069 Brewmaster, 48263 Blood, 189926 Vengeance): applied again if it is missing; a Guardian fights in
// Bear Form (it has no threat passive of its own in this data)
void PartyBotAI::TankStance()
{
    static uint32 const ThreatPassives[] = { 71, 25780, 115069, 48263, 189926 };
    // at most every 10 s per spell; still missing 10 s after a cast: logged once (a passive that works through another
    // spell id or a script would else be cast every tick, dev-check)
    uint32 now = getMSTime();
    auto apply = [&](uint32 spell, bool triggered)
    {
        auto itr = _stanceTry.find(spell);
        if (me->HasAura(spell))
        {
            if (itr != _stanceTry.end())
                _stanceTry.erase(itr);
            return;
        }
        if (itr != _stanceTry.end())
        {
            if (getMSTimeDiff(itr->second, now) < 10 * IN_MILLISECONDS)
                return;
            if (_stanceFailLogged.insert(spell).second)
                TC_LOG_INFO("server.questbot", "BOT event=stancefail bot=%s spell=%u spec=%u", me->GetName(), spell, me->GetSpecializationId());
        }
        _stanceTry[spell] = now;
        me->CastSpell(me, spell, triggered);
    };
    for (uint32 spell : ThreatPassives)
        if (me->HasSpell(spell))
            apply(spell, true);
    if (me->GetSpecializationId() == 104 && me->HasSpell(5487) && !me->IsNonMeleeSpellCast(false))
        apply(5487, false);
}

bool PartyBotAI::CastRotation(Unit* target)
{
    if (IsTankSpec(me))                 // also out of combat: the stance is there before the first hit
        TankStance();
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
    _castResult = SPELL_FAILED_DONT_REPORT;
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
        return (_castResult = me->CastSpell(castTarget->GetPositionX(), castTarget->GetPositionY(), castTarget->GetPositionZ(), entry.Spell, false)) == SPELL_CAST_OK;

    return (_castResult = me->CastSpell(castTarget, info, false)) == SPELL_CAST_OK;
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

// the bot accounts partybot1@bot..partybot94@bot (1-50 made by the owner, 51-94 fix_partybot_accounts_51_94.sql), matched exactly
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

// commands run on the GM's map thread: two GMs creating bots at once must not pick the same free account (dev-check)
uint32 PartyBotMgr::ReserveBotAccount()
{
    std::lock_guard<std::mutex> guard(_lock);
    uint32 accountId = FreeBotAccount();
    if (accountId)
        _usedAccounts.insert(accountId);
    return accountId;
}

void PartyBotMgr::ReleaseBotAccount(uint32 accountId)
{
    std::lock_guard<std::mutex> guard(_lock);
    _usedAccounts.erase(accountId);
}

// a level-1 character on a bot account, as the character screen makes it (without a client); empty guid on failure.
// level: a level bot's level, set before the first save like .character level does for an offline character (the
// login then teaches the class and spec spells of that level, Player::LoadFromDB)
static ObjectGuid NewCharacter(uint32 accountId, uint8 race, uint8 cls, std::string const& name, uint8 level = 0)
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

    if (level > newChar.getLevel())
        newChar.SetUInt32Value(UNIT_FIELD_LEVEL, level);
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

    uint32 accountId = ReserveBotAccount();
    if (!accountId)
        return "No free partybot account left (partybotN@bot).";

    name = BotName(std::string(spec->Name->Str[DEFAULT_LOCALE]) + sChrClassesStore.AssertEntry(spec->ClassID)->Name->Str[DEFAULT_LOCALE]);
    if (name.empty())
    {
        ReleaseBotAccount(accountId);
        return "Could not find a free name.";
    }

    ObjectGuid guid = NewCharacter(accountId, BotRace(spec->ClassID, creator->GetTeam() == ALLIANCE), spec->ClassID, name);
    if (guid.IsEmpty())
    {
        ReleaseBotAccount(accountId);
        return "The character could not be created.";
    }

    CharacterDatabase.PExecute("REPLACE INTO partybot_characters (guid, account, spec, setup) VALUES (%u, %u, %u, 0)", guid.GetCounter(), accountId, specId);

    TC_LOG_INFO("server.partybot", "Party bot character %s (spec %u, account %u) created by %s", name.c_str(), specId, accountId, creator->GetName());
    return "";
}

// #140 A: like CreateBot, at a level (setup 2: FirstLoginSetup keeps the level and gives heirlooms)
std::string PartyBotMgr::CreateLevelBot(uint32 specId, uint8 level, bool alliance, std::string& name, ObjectGuid& guid)
{
    ChrSpecializationEntry const* spec = sChrSpecializationStore.LookupEntry(specId);
    if (!spec || !spec->ClassID || spec->ClassID >= MAX_CLASSES)
        return "Unknown specialization.";

    // a spec from 10; Death Knights start at 55, Demon Hunters at 98
    ChrClassesEntry const* classEntry = sChrClassesStore.AssertEntry(spec->ClassID);
    uint32 minLevel = std::max<int32>(10, classEntry->StartingLevel);
    if (level < minLevel || level > sWorld->getIntConfig(CONFIG_MAX_PLAYER_LEVEL))
        return std::string(classEntry->Name->Str[DEFAULT_LOCALE]) + " bots need a level from " + std::to_string(minLevel) + " to "
            + std::to_string(sWorld->getIntConfig(CONFIG_MAX_PLAYER_LEVEL)) + ".";

    uint32 accountId = ReserveBotAccount();
    if (!accountId)
        return "No free partybot account left (partybotN@bot).";

    name = BotName(std::string(spec->Name->Str[DEFAULT_LOCALE]) + classEntry->Name->Str[DEFAULT_LOCALE]);
    if (name.empty())
    {
        ReleaseBotAccount(accountId);
        return "Could not find a free name.";
    }

    guid = NewCharacter(accountId, BotRace(spec->ClassID, alliance), spec->ClassID, name, level);
    if (guid.IsEmpty())
    {
        ReleaseBotAccount(accountId);
        return "The character could not be created.";
    }

    CharacterDatabase.PExecute("REPLACE INTO partybot_characters (guid, account, spec, setup) VALUES (%u, %u, %u, 2)", guid.GetCounter(), accountId, specId);

    TC_LOG_INFO("server.partybot", "Level bot character %s (spec %u, level %u, account %u) created", name.c_str(), specId, level, accountId);
    return "";
}

// quest-test runs at the same time: one per race/class, at most MaxQuestTests (owner 2026-10-01: several starting zones
// at once; each run scans its zone's spawns once at start on its map thread); _lock held
static constexpr uint32 MaxQuestTests = 50;  // owner 2026-10-01; all runs share the one map-update thread (MapUpdate.Threads = 1)
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
// MaxQuestTests runs at a time, several of one race/class allowed (owner 2026-10-01: .partybot questtest random). Each run starts from level 1: the new
// character is made first, then an idle previous quest-test character of that race and class is deleted. Only a character named Qt... (case-sensitive) on
// a partybot account (partybotN@bot exactly) that is no party bot (no partybot_characters row) is ever deleted.
std::string PartyBotMgr::StartQuestTest(Player* gm, std::string text)
{
    // an account one of our bot sessions uses: sWorld->FindSession misses a session added this tick (AddSession queues
    // it), e.g. the runs .partybot questtest random starts in one go
    auto accountBusy = [this](uint32 account)
    {
        std::lock_guard<std::mutex> guard(_lock);
        for (auto const& bot : _bots)
            if (std::shared_ptr<PartyBotSession> session = bot.lock())
                if (session->GetAccountId() == account)
                    return true;
        return false;
    };

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
        return "Usage: .partybot questtest <class> [race] [max level, default 5]   e.g. .partybot questtest warrior human\n"
            "       .partybot questtest random [race] [count] [max level]   e.g. .partybot questtest random human 50";

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

    // an idle previous quest-test character of this race and class (a player's Qt... character, a running one is skipped)
    uint32 accountId = 0;
    ObjectGuid oldGuid;
    if (QueryResult result = CharacterDatabase.PQuery("SELECT c.guid, c.account, c.name FROM characters c LEFT JOIN partybot_characters p ON p.guid = c.guid "
        "WHERE p.guid IS NULL AND c.name LIKE 'Qt%%' AND c.race = %u AND c.class = %u", race, cls))
        do
        {
            ObjectGuid candidate = ObjectGuid::Create<HighGuid::Player>((*result)[0].GetUInt64());
            uint32 account = (*result)[1].GetUInt32();
            if ((*result)[2].GetString().compare(0, 2, "Qt") == 0 && !ObjectAccessor::FindPlayer(candidate) && !sWorld->FindSession(account) && !accountBusy(account)
                && LoginDatabase.PQuery("SELECT 1 FROM account WHERE id = %u AND username REGEXP '%s'", account, BotAccountPattern))
            {
                oldGuid = candidate;
                accountId = account;
                break;
            }
        } while (result->NextRow());

    bool reserved = false;
    if (!accountId)
        reserved = (accountId = ReserveBotAccount()) != 0;
    // no free account left: reuse the account of the longest-unused other quest-test character, which is then deleted
    // like the old one (same guard: Qt..., no party bot, partybotN@bot, not online, no session)
    if (!accountId)
        if (QueryResult result = CharacterDatabase.PQuery("SELECT c.guid, c.account, c.name FROM characters c LEFT JOIN partybot_characters p ON p.guid = c.guid "
            "WHERE p.guid IS NULL AND c.name LIKE 'Qt%%' AND c.online = 0 ORDER BY c.logout_time"))
            do
            {
                ObjectGuid candidate = ObjectGuid::Create<HighGuid::Player>((*result)[0].GetUInt64());
                uint32 account = (*result)[1].GetUInt32();
                if ((*result)[2].GetString().compare(0, 2, "Qt") == 0 && !ObjectAccessor::FindPlayer(candidate) && !sWorld->FindSession(account) && !accountBusy(account)
                    && LoginDatabase.PQuery("SELECT 1 FROM account WHERE id = %u AND username REGEXP '%s'", account, BotAccountPattern))
                {
                    oldGuid = candidate;
                    accountId = account;
                    break;
                }
            } while (result->NextRow());
    if (!accountId)
        return "No free partybot account left (partybotN@bot) and no idle quest-test character to replace.";

    std::string name = BotName("Qt" + raceName + classEntry->Name->Str[DEFAULT_LOCALE]);   // the old name is still taken
    if (name.empty())
    {
        if (reserved)
            ReleaseBotAccount(accountId);
        return "Could not find a free name.";
    }

    // the new character first; the old one goes only once the new one exists
    ObjectGuid guid = NewCharacter(accountId, race, cls, name);
    if (guid.IsEmpty())
    {
        if (reserved)
            ReleaseBotAccount(accountId);
        return "The character could not be created (" + raceName + " " + classEntry->Name->Str[DEFAULT_LOCALE] + " allowed?).";
    }
    if (!reserved)      // reused or same race/class account: mark it too (asynchronous character save)
    {
        std::lock_guard<std::mutex> guard(_lock);
        _usedAccounts.insert(accountId);
    }

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

    // level bots (setup 2, 3: dungeon bots, #140) aren't picked by role
    QueryResult result = CharacterDatabase.Query("SELECT p.guid, p.spec, c.name, c.race FROM partybot_characters p JOIN characters c ON c.guid = p.guid WHERE p.setup < 2 ORDER BY p.guid");
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
