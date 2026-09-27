/*
 * Avenging Angel (500002): custom world boss, owner request 2026-09-27.
 * 2.147 billion health, plus PER_EXTRA_ATTACKER for every further player who damages it, so 10 players
 * need roughly 3-4 minutes. All its damage is doubled by Frenzy (+100% damage done).
 * Uses NPC spell versions where the player spell has no visual for a creature caster
 * (player Consecration only has player-only visuals).
 * Every 60 sec it calls two Monkes (500003, Hyrja from the Odyn fight) with Expel Light and Shield of Light.
 */

#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "Player.h"
#include "Spell.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "SpellAuraEffects.h"

namespace avenging_angel
{

enum Spells : uint32
{
    SPELL_FRENZY                = 111730,   // all-school damage done aura, amount set to DAMAGE_DONE_PCT
    SPELL_CONSECRATION          = 43429,    // NPC Consecration: glowing ground, damage every 2 sec for 20 sec
    SPELL_SHIELD_OF_RIGHTEOUS   = 53600,
    SPELL_JUDGMENT              = 66005,    // NPC Judgement (Trial of the Crusader champions)
    SPELL_SACRED_GROUND         = 227789,   // Maiden of Virtue (Karazhan): holy pool at a player, damage over time while standing in it
    SPELL_WITNESS_THE_VOID      = 207720,   // Thing That Should Not Be (Nighthold): 4 sec cast, damages everyone, fears those facing it
    SPELL_CRUSADER_STRIKE       = 210370,   // tank hit + 20% damage taken per stack (5 stacks, 30 sec)

    // Monke (Hyrja, Trial of Valor)
    SPELL_EXPEL_LIGHT           = 228029,   // 3 sec, then the marked player blasts nearby allies (228030)
    SPELL_EXPEL_LIGHT_DAMAGE    = 228030,
    SPELL_SHIELD_OF_LIGHT_MARK  = 228270,
    SPELL_SHIELD_OF_LIGHT       = 228162,   // 4 sec cast, beam split among players between Monke and the target
};

enum Misc : uint32
{
    NPC_MONKE = 500003,
};

enum Events : uint32
{
    EVENT_JUDGMENT = 1,
    EVENT_SHIELD_OF_RIGHTEOUS,
    EVENT_CONSECRATION,
    EVENT_WITNESS_THE_VOID,
    EVENT_SACRED_GROUND,
    EVENT_CRUSADER_STRIKE,
    EVENT_SUMMON_MONKES,

    EVENT_EXPEL_LIGHT,
    EVENT_SHIELD_OF_LIGHT,
};

// Tuning knobs (spell and melee values before Frenzy doubles them)
uint64 const BASE_HEALTH            = 2147000000;
uint64 const PER_EXTRA_ATTACKER     = 150000000;   // 10 players: 3.5 billion
float const DAMAGE_DONE_PCT         = 100.0f;      // "all damage 2x"
float const MELEE_MIN               = 400000.0f;
float const MELEE_MAX               = 480000.0f;
float const JUDGMENT_DAMAGE         = 800000.0f;
float const SHIELD_DAMAGE           = 1200000.0f;
float const CONSECRATION_TICK       = 300000.0f;   // every 2 sec
float const CRUSADER_STRIKE_PCT     = 35.0f;       // % weapon damage (137 in the spell); holy weapon strikes get Frenzy twice (weapon + spell), ~1.2M
uint8 const MONKES_PER_WAVE         = 2;
uint64 const MONKE_HEALTH           = 150000000;
float const MONKE_MELEE_MIN         = 150000.0f;
float const MONKE_MELEE_MAX         = 200000.0f;

void SetHealthTo(Creature* creature, uint64 health)
{
    creature->SetModifierValue(UNIT_MOD_HEALTH, BASE_VALUE, float(health));
    creature->UpdateMaxHealth();
}

void SetMelee(Creature* creature, float min, float max)
{
    creature->SetBaseWeaponDamage(BASE_ATTACK, MINDAMAGE, min);
    creature->SetBaseWeaponDamage(BASE_ATTACK, MAXDAMAGE, max);
    creature->UpdateDamagePhysical(BASE_ATTACK);
}

// Casts and logs the result (temporary server.angel log while the boss is being tuned)
void Cast(Creature* caster, uint32 spellId, Unit* target, bool triggered = true, float const* bp0 = nullptr)
{
    SpellInfo const* spellInfo = sSpellMgr->GetSpellInfo(spellId);
    if (!spellInfo || !target)
        return;

    SpellCastTargets targets;
    targets.SetCaster(caster);
    targets.SetUnitTarget(target);

    CustomSpellValues values;
    if (bp0)
        values.AddSpellMod(SPELLVALUE_BASE_POINT0, *bp0);

    SpellCastResult result = caster->CastSpell(targets, spellInfo, &values, triggered ? TRIGGERED_FULL_MASK : TRIGGERED_NONE);
    TC_LOG_INFO("server.angel", "%s: spell %u at %s, result %u", caster->GetName(), spellId, target->GetName(), uint32(result));
}

struct boss_avenging_angel : public ScriptedAI
{
    boss_avenging_angel(Creature* creature) : ScriptedAI(creature), summons(creature) { }

    EventMap events;
    SummonList summons;
    std::set<ObjectGuid> attackers;

    void Reset() override
    {
        events.Reset();
        summons.DespawnAll();
        attackers.clear();
        SetHealthTo(me, BASE_HEALTH);
        me->SetFullHealth();
        SetMelee(me, MELEE_MIN, MELEE_MAX);
        me->CastCustomSpell(me, SPELL_FRENZY, &DAMAGE_DONE_PCT, nullptr, nullptr, true);
    }

    // Every new player (or their pet) that deals damage adds a fresh chunk of health
    void DamageTaken(Unit* attacker, uint32& /*damage*/, DamageEffectType /*dmgType*/) override
    {
        Player* player = attacker ? attacker->GetCharmerOrOwnerPlayerOrPlayerItself() : nullptr;
        if (!player || !attackers.insert(player->GetGUID()).second || attackers.size() == 1)
            return;

        uint64 health = me->GetHealth();
        SetHealthTo(me, BASE_HEALTH + PER_EXTRA_ATTACKER * (attackers.size() - 1));
        me->SetHealth(std::min(health + PER_EXTRA_ATTACKER, me->GetMaxHealth()));
    }

    void EnterCombat(Unit* who) override
    {
        TC_LOG_INFO("server.angel", "Avenging Angel: combat with %s", who ? who->GetName() : "nobody");
        events.RescheduleEvent(EVENT_CRUSADER_STRIKE, 5000);
        events.RescheduleEvent(EVENT_JUDGMENT, 8000);
        events.RescheduleEvent(EVENT_SHIELD_OF_RIGHTEOUS, 12000);
        events.RescheduleEvent(EVENT_CONSECRATION, 15000);
        events.RescheduleEvent(EVENT_SACRED_GROUND, 20000);
        events.RescheduleEvent(EVENT_WITNESS_THE_VOID, 35000);
        events.RescheduleEvent(EVENT_SUMMON_MONKES, 60000);
    }

    void JustSummoned(Creature* summon) override
    {
        summons.Summon(summon);
        if (Unit* target = SelectTarget(SELECT_TARGET_RANDOM, 0, 60.0f, true))
            summon->AI()->AttackStart(target);
    }

    void JustDied(Unit* /*killer*/) override
    {
        summons.DespawnAll();
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
                case EVENT_CRUSADER_STRIKE:
                    Cast(me, SPELL_CRUSADER_STRIKE, me->getVictim(), true, &CRUSADER_STRIKE_PCT);
                    events.RescheduleEvent(EVENT_CRUSADER_STRIKE, 8000);
                    break;
                case EVENT_JUDGMENT:
                    Cast(me, SPELL_JUDGMENT, SelectTarget(SELECT_TARGET_RANDOM, 0, 30.0f, true), true, &JUDGMENT_DAMAGE);
                    events.RescheduleEvent(EVENT_JUDGMENT, 12000);
                    break;
                case EVENT_SHIELD_OF_RIGHTEOUS:
                    Cast(me, SPELL_SHIELD_OF_RIGHTEOUS, me->getVictim(), true, &SHIELD_DAMAGE);
                    events.RescheduleEvent(EVENT_SHIELD_OF_RIGHTEOUS, 15000);
                    break;
                case EVENT_CONSECRATION:
                    Cast(me, SPELL_CONSECRATION, me, true, &CONSECRATION_TICK);
                    events.RescheduleEvent(EVENT_CONSECRATION, 25000);
                    break;
                case EVENT_SACRED_GROUND:
                    // with cast bars, like the original bosses
                    Cast(me, SPELL_SACRED_GROUND, SelectTarget(SELECT_TARGET_RANDOM, 0, 60.0f, true), false);
                    events.RescheduleEvent(EVENT_SACRED_GROUND, 23000);
                    return;
                case EVENT_WITNESS_THE_VOID:
                    Cast(me, SPELL_WITNESS_THE_VOID, me, false);
                    events.RescheduleEvent(EVENT_WITNESS_THE_VOID, 40000);
                    return;
                case EVENT_SUMMON_MONKES:
                    for (uint8 i = 0; i < MONKES_PER_WAVE; ++i)
                    {
                        Position pos = me->GetPosition();
                        me->MovePosition(pos, float(urand(10, 15)), frand(0.0f, 2 * float(M_PI)));
                        me->SummonCreature(NPC_MONKE, pos, TEMPSUMMON_CORPSE_TIMED_DESPAWN, 10000);
                    }
                    events.RescheduleEvent(EVENT_SUMMON_MONKES, 60000);
                    break;
                default:
                    break;
            }
        }

        DoMeleeAttackIfReady();
    }
};

// 500003 - Monke: Hyrja from the Odyn fight, only Expel Light and Shield of Light (no Valarjar's Bond, no Revivify)
struct npc_avenging_angel_monke : public ScriptedAI
{
    npc_avenging_angel_monke(Creature* creature) : ScriptedAI(creature) { }

    EventMap events;

    void Reset() override
    {
        events.Reset();
        SetHealthTo(me, MONKE_HEALTH);
        me->SetFullHealth();
        SetMelee(me, MONKE_MELEE_MIN, MONKE_MELEE_MAX);
        me->SetReactState(REACT_AGGRESSIVE);
    }

    void EnterCombat(Unit* /*who*/) override
    {
        events.RescheduleEvent(EVENT_EXPEL_LIGHT, 8000);
        events.RescheduleEvent(EVENT_SHIELD_OF_LIGHT, 15000);
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
            case EVENT_EXPEL_LIGHT:
                Cast(me, SPELL_EXPEL_LIGHT, SelectTarget(SELECT_TARGET_RANDOM, 0, 60.0f, true));
                events.RescheduleEvent(EVENT_EXPEL_LIGHT, 20000);
                break;
            case EVENT_SHIELD_OF_LIGHT:
            {
                // like Hyrja: a random player other than the tank, then the 4 sec beam cast
                Unit* target = SelectTarget(SELECT_TARGET_RANDOM, 1, 60.0f, true);
                if (!target)
                    target = me->getVictim();
                Cast(me, SPELL_SHIELD_OF_LIGHT_MARK, target);
                Cast(me, SPELL_SHIELD_OF_LIGHT, target, false);
                events.RescheduleEvent(EVENT_SHIELD_OF_LIGHT, 30000);
                return;
            }
            default:
                break;
        }

        DoMeleeAttackIfReady();
    }
};

// 228029 - Expel Light: when it ticks, the marked player blasts the allies around them.
// Nothing on this server linked the mark to the blast, so Hyrja's Expel Light did nothing.
class spell_avenging_angel_expel_light : public AuraScript
{
    PrepareAuraScript(spell_avenging_angel_expel_light);

    void Tick(AuraEffect const* aurEff)
    {
        if (Unit* target = GetTarget())
            target->CastSpell(target, SPELL_EXPEL_LIGHT_DAMAGE, true, nullptr, aurEff);
    }

    void Register() override
    {
        OnEffectPeriodic += AuraEffectPeriodicFn(spell_avenging_angel_expel_light::Tick, EFFECT_0, SPELL_AURA_PERIODIC_DUMMY);
    }
};

} // namespace avenging_angel

void AddSC_world_boss_avenging_angel()
{
    using namespace avenging_angel;
    RegisterCreatureAI(boss_avenging_angel);
    RegisterCreatureAI(npc_avenging_angel_monke);
    RegisterAuraScript(spell_avenging_angel_expel_light);
}
