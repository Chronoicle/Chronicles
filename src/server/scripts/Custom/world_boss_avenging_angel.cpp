/*
 * Avenging Angel (500002): custom world boss, owner request 2026-09-27.
 * 2 billion health, plus PER_EXTRA_ATTACKER for every further player who damages it, so 10 players
 * need roughly 3-4 minutes. Casts paladin-style spells with fixed damage (a creature has no spell/attack power).
 * NPC versions where the player spell has no visual for a creature caster (player Consecration only has player-only visuals).
 */

#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "Player.h"
#include "Spell.h"
#include "SpellMgr.h"

namespace avenging_angel
{

enum Spells : uint32
{
    SPELL_CONSECRATION          = 43429,    // NPC Consecration: glowing ground, damage every 2 sec for 20 sec
    SPELL_SHIELD_OF_RIGHTEOUS   = 53600,
    SPELL_BLINDING_LIGHT_FLASH  = 33009,    // NPC Blinding Light: holy flash + damage around the caster
    SPELL_BLINDING_LIGHT        = 105421,   // paladin Blinding Light disorient on nearby enemies
    SPELL_JUDGMENT              = 66005,    // NPC Judgement (Trial of the Crusader champions)
};

enum Events : uint32
{
    EVENT_JUDGMENT = 1,
    EVENT_SHIELD_OF_RIGHTEOUS,
    EVENT_CONSECRATION,
    EVENT_BLINDING_LIGHT,
};

// Tuning knobs
uint64 const BASE_HEALTH            = 2000000000;
uint64 const PER_EXTRA_ATTACKER     = 150000000;   // 10 players: 3.35 billion
float const MELEE_MIN               = 400000.0f;
float const MELEE_MAX               = 480000.0f;
float const JUDGMENT_DAMAGE         = 800000.0f;
float const SHIELD_DAMAGE           = 1200000.0f;
float const CONSECRATION_TICK       = 300000.0f;   // every 2 sec
float const BLINDING_LIGHT_DAMAGE   = 250000.0f;

struct boss_avenging_angel : public ScriptedAI
{
    boss_avenging_angel(Creature* creature) : ScriptedAI(creature) { }

    EventMap events;
    std::set<ObjectGuid> attackers;

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

    // Casts with fixed base points and logs the result (temporary server.angel log: the boss cast nothing in the first test)
    void Cast(uint32 spellId, Unit* target, Position const* dest = nullptr, float const* bp0 = nullptr)
    {
        SpellInfo const* spellInfo = sSpellMgr->GetSpellInfo(spellId);
        if (!spellInfo)
            return;

        SpellCastTargets targets;
        targets.SetCaster(me);
        if (target)
            targets.SetUnitTarget(target);
        if (dest)
            targets.SetDst(*dest);

        CustomSpellValues values;
        if (bp0)
            values.AddSpellMod(SPELLVALUE_BASE_POINT0, *bp0);

        SpellCastResult result = me->CastSpell(targets, spellInfo, &values, TRIGGERED_FULL_MASK);
        TC_LOG_INFO("server.angel", "Avenging Angel: spell %u at %s, result %u", spellId, target ? target->GetName() : "a point", uint32(result));
    }

    void EnterCombat(Unit* who) override
    {
        TC_LOG_INFO("server.angel", "Avenging Angel: combat with %s", who ? who->GetName() : "nobody");
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
                        Cast(SPELL_JUDGMENT, target, nullptr, &JUDGMENT_DAMAGE);
                    events.RescheduleEvent(EVENT_JUDGMENT, 12000);
                    break;
                case EVENT_SHIELD_OF_RIGHTEOUS:
                    if (Unit* victim = me->getVictim())
                        Cast(SPELL_SHIELD_OF_RIGHTEOUS, victim, nullptr, &SHIELD_DAMAGE);
                    events.RescheduleEvent(EVENT_SHIELD_OF_RIGHTEOUS, 15000);
                    break;
                case EVENT_CONSECRATION:
                    Cast(SPELL_CONSECRATION, me, nullptr, &CONSECRATION_TICK);
                    events.RescheduleEvent(EVENT_CONSECRATION, 25000);
                    break;
                case EVENT_BLINDING_LIGHT:
                    Cast(SPELL_BLINDING_LIGHT_FLASH, me, nullptr, &BLINDING_LIGHT_DAMAGE);
                    Cast(SPELL_BLINDING_LIGHT, me);
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
