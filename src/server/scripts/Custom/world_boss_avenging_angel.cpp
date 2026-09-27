/*
 * Avenging Angel (500002): custom world boss, owner request 2026-09-27.
 * 2 billion health, plus PER_EXTRA_ATTACKER for every further player who damages it, so 10 players
 * need roughly 3-4 minutes. Casts paladin spells with fixed damage (a creature has no spell/attack power).
 */

#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "Player.h"

namespace avenging_angel
{

enum Spells : uint32
{
    SPELL_CONSECRATION          = 26573,    // ground visual
    SPELL_CONSECRATION_DAMAGE   = 81297,    // 8 yd around a point
    SPELL_SHIELD_OF_RIGHTEOUS   = 53600,
    SPELL_BLINDING_LIGHT        = 115750,   // disorients nearby players (105421 via spell_linked_spell)
    SPELL_JUDGMENT              = 20271,
};

enum Events : uint32
{
    EVENT_JUDGMENT = 1,
    EVENT_SHIELD_OF_RIGHTEOUS,
    EVENT_CONSECRATION,
    EVENT_CONSECRATION_TICK,
    EVENT_BLINDING_LIGHT,
};

// Tuning knobs
uint64 const BASE_HEALTH            = 2000000000;
uint64 const PER_EXTRA_ATTACKER     = 150000000;   // 10 players: 3.35 billion
float const MELEE_MIN               = 400000.0f;
float const MELEE_MAX               = 480000.0f;
float const JUDGMENT_DAMAGE         = 800000.0f;
float const SHIELD_DAMAGE           = 1200000.0f;
float const CONSECRATION_TICK       = 150000.0f;
uint8 const CONSECRATION_TICKS      = 12;

struct boss_avenging_angel : public ScriptedAI
{
    boss_avenging_angel(Creature* creature) : ScriptedAI(creature) { }

    std::set<ObjectGuid> attackers;
    Position consecrationPos;
    uint8 consecrationTicks = 0;

    void Reset() override
    {
        events.Reset();
        attackers.clear();
        SetMaxHealthFor(0);
        me->SetFullHealth();

        me->SetBaseWeaponDamage(BASE_ATTACK, MINDAMAGE, MELEE_MIN);
        me->SetBaseWeaponDamage(BASE_ATTACK, MAXDAMAGE, MELEE_MAX);
        me->UpdateDamagePhysical(BASE_ATTACK);
    }

    void SetMaxHealthFor(uint64 extraAttackers)
    {
        me->SetModifierValue(UNIT_MOD_HEALTH, BASE_VALUE, float(BASE_HEALTH + PER_EXTRA_ATTACKER * extraAttackers));
        me->UpdateMaxHealth();
    }

    // Every new player (or their pet) that deals damage adds a fresh chunk of health
    void DamageTaken(Unit* attacker, uint32& /*damage*/, DamageEffectType /*dmgType*/) override
    {
        Player* player = attacker ? attacker->GetCharmerOrOwnerPlayerOrPlayerItself() : nullptr;
        if (!player || !attackers.insert(player->GetGUID()).second || attackers.size() == 1)
            return;

        uint64 health = me->GetHealth();
        SetMaxHealthFor(attackers.size() - 1);
        me->SetHealth(std::min(health + PER_EXTRA_ATTACKER, me->GetMaxHealth()));
    }

    void EnterCombat(Unit* /*who*/) override
    {
        events.RescheduleEvent(EVENT_JUDGMENT, 8000);
        events.RescheduleEvent(EVENT_SHIELD_OF_RIGHTEOUS, 12000);
        events.RescheduleEvent(EVENT_CONSECRATION, 15000);
        events.RescheduleEvent(EVENT_BLINDING_LIGHT, 35000);
    }

    void UpdateAI(uint32 diff) override
    {
        if (!UpdateVictim())
            return;

        events.Update(diff);

        if (me->HasUnitState(UNIT_STATE_CASTING))
            return;

        while (uint32 eventId = events.ExecuteEvent())
        {
            switch (eventId)
            {
                case EVENT_JUDGMENT:
                    if (Unit* target = SelectTarget(SELECT_TARGET_RANDOM, 0, 30.0f, true))
                        me->CastCustomSpell(target, SPELL_JUDGMENT, &JUDGMENT_DAMAGE, nullptr, nullptr, true);
                    events.RescheduleEvent(EVENT_JUDGMENT, 12000);
                    break;
                case EVENT_SHIELD_OF_RIGHTEOUS:
                    if (Unit* victim = me->getVictim())
                        me->CastCustomSpell(victim, SPELL_SHIELD_OF_RIGHTEOUS, &SHIELD_DAMAGE, nullptr, nullptr, true);
                    events.RescheduleEvent(EVENT_SHIELD_OF_RIGHTEOUS, 15000);
                    break;
                case EVENT_CONSECRATION:
                    me->CastSpell(me, SPELL_CONSECRATION, true);
                    consecrationPos = me->GetPosition();
                    consecrationTicks = CONSECRATION_TICKS;
                    events.RescheduleEvent(EVENT_CONSECRATION_TICK, 1000);
                    events.RescheduleEvent(EVENT_CONSECRATION, 25000);
                    break;
                case EVENT_CONSECRATION_TICK:
                    me->CastCustomSpell(consecrationPos.GetPositionX(), consecrationPos.GetPositionY(), consecrationPos.GetPositionZ(),
                        SPELL_CONSECRATION_DAMAGE, &CONSECRATION_TICK, nullptr, nullptr, TRIGGERED_FULL_MASK);
                    if (--consecrationTicks)
                        events.RescheduleEvent(EVENT_CONSECRATION_TICK, 1000);
                    break;
                case EVENT_BLINDING_LIGHT:
                    me->CastSpell(me, SPELL_BLINDING_LIGHT, true);
                    events.RescheduleEvent(EVENT_BLINDING_LIGHT, 40000);
                    break;
                default:
                    break;
            }
        }

        DoMeleeAttackIfReady();
    }
};

} // namespace avenging_angel

void AddSC_world_boss_avenging_angel()
{
    using namespace avenging_angel;
    RegisterCreatureAI(boss_avenging_angel);
}
