/*
 * This file is part of the TrinityCore Project. See AUTHORS file for Copyright information
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation; either version 2 of the License, or (at your
 * option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

#include "Containers.h"
#include "InstanceScript.h"
#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "ragefire_chasm.h"

enum SlagmawSpells
{
    SPELL_LAVA_SPIT             = 119434,
    SPELL_MAGNAW_SUBMERGE       = 120384,
    SPELL_MAGNAW_TELEPORT_NORTH = 119424, // Serverside
    SPELL_MAGNAW_TELEPORT_EAST  = 119425, // Serverside
    SPELL_MAGNAW_TELEPORT_SOUTH = 119426, // Serverside
    SPELL_MAGNAW_TELEPORT_WEST  = 119428  // Serverside
};

enum SlagmawEvents
{
    EVENT_LAVA_SPIT       = 1,
    EVENT_TELEPORT,
    EVENT_EMERGE,
    EVENT_BOUNDARY_CHECK,
};

std::array<uint32, 4> const SlagmawTeleportSpells =
{
    SPELL_MAGNAW_TELEPORT_NORTH,
    SPELL_MAGNAW_TELEPORT_EAST,
    SPELL_MAGNAW_TELEPORT_SOUTH,
    SPELL_MAGNAW_TELEPORT_WEST
};

// The teleports are serverside spells this core does not have (TrinityCore: serverside_spell + spell_target_position),
// so the casts did nothing and Slagmaw chased players through the floor (#174): same holes, NearTeleportTo.
Position const SlagmawTeleportPositions[4] =
{
    { -222.94f,  165.703f, -19.721f, 3.797819f  }, // North
    { -226.477f, 135.704f, -19.721f, 2.330294f  }, // East
    { -263.212f, 136.244f, -19.721f, 0.7556769f }, // South
    { -256.389f, 172.884f, -19.721f, 5.577933f  }  // West
};

// 61463 - Slagmaw
struct boss_slagmaw : public BossAI
{
    boss_slagmaw(Creature* creature) : BossAI(creature, BOSS_SLAGMAW), _lavaSpitCounter(0), _lastTeleportSpell(SPELL_MAGNAW_TELEPORT_WEST)
    {
        SetCombatMovement(false); // stays in his lava hole, only moves by the teleports (#174)
    }

    void Reset() override
    {
        _Reset();
        _lavaSpitCounter = 0;
        _lastTeleportSpell = SPELL_MAGNAW_TELEPORT_WEST;
    }

    void JustDied(Unit* /*killer*/) override
    {
        _JustDied();
        instance->SendEncounterUnit(ENCOUNTER_FRAME_DISENGAGE, me);
    }

    void EnterEvadeMode() override
    {
        BossAI::EnterEvadeMode();
        _DespawnAtEvade();
        instance->SendEncounterUnit(ENCOUNTER_FRAME_DISENGAGE, me);
    }

    void EnterCombat(Unit* who) override
    {
        BossAI::EnterCombat(who);

        instance->SendEncounterUnit(ENCOUNTER_FRAME_ENGAGE, me, 1);

        events.ScheduleEvent(EVENT_LAVA_SPIT, 1s);
        events.ScheduleEvent(EVENT_BOUNDARY_CHECK, 2500ms);
    }

    void HandleSubmergePhase()
    {
        DoCastSelf(SPELL_MAGNAW_SUBMERGE);
        _lavaSpitCounter = 0;

        events.ScheduleEvent(EVENT_TELEPORT, 3s);
    }

    uint32 GetNextTeleportSpell()
    {
        std::array<uint32, 3> teleportSpells = { };
        std::ranges::remove_copy(SlagmawTeleportSpells, teleportSpells.begin(), _lastTeleportSpell);
        _lastTeleportSpell = Trinity::Containers::SelectRandomContainerElement(teleportSpells);
        return _lastTeleportSpell;
    }

    void UpdateAI(uint32 diff) override
    {
        if (!UpdateVictim())
            return;

        events.Update(diff);

        if (me->HasUnitState(UNIT_STATE_CASTING))
            return;

        switch (events.ExecuteEvent())
        {
            case EVENT_LAVA_SPIT:
            {
                if (_lavaSpitCounter < 5)
                {
                    if (Unit* target = SelectTarget(SELECT_TARGET_RANDOM, 0))
                    {
                        DoCast(target, SPELL_LAVA_SPIT);
                        _lavaSpitCounter++;
                    }
                    events.Repeat(1s);
                    break;
                }
                else if (_lavaSpitCounter == 5)
                {
                    HandleSubmergePhase();
                    break;
                }
                break;
            }
            case EVENT_TELEPORT:
            {
                uint32 spell = GetNextTeleportSpell();
                for (uint8 i = 0; i < SlagmawTeleportSpells.size(); ++i)
                    if (SlagmawTeleportSpells[i] == spell)
                        me->NearTeleportTo(SlagmawTeleportPositions[i]);
                events.ScheduleEvent(EVENT_EMERGE, 1s);
                break;
            }
            case EVENT_EMERGE:
            {
                me->RemoveAurasDueToSpell(SPELL_MAGNAW_SUBMERGE);
                events.ScheduleEvent(EVENT_LAVA_SPIT, 1s);
                break;
            }
            case EVENT_BOUNDARY_CHECK:
            {
                if (me->getVictim()->GetDistance(me) > 50.0f)
                    EnterEvadeMode();
                events.ScheduleEvent(EVENT_BOUNDARY_CHECK, 2500ms);
                break;
            }
            default:
                break;
        }

        DoMeleeAttackIfReady();
    }

private:
    uint8 _lavaSpitCounter;
    uint32 _lastTeleportSpell;
};

void AddSC_boss_slagmaw()
{
    RegisterRagefireChasmCreatureAI(boss_slagmaw);
}
