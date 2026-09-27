/*
 * Artifact abilities and allied race racials ported from DestinyCore (github.com/slash-design/DestinyCore)
 * for spells LegionCore doesn't handle anywhere (no script, no spell_trigger/proc/linked/aura_dummy row, no core code).
 * Extracted with port_destiny_spells.py, then adapted by hand to LegionCore's API.
 */

#include "ScriptMgr.h"
#include "Player.h"
#include "Pet.h"
#include "ScriptedCreature.h"
#include "ScriptedGossip.h"
#include "SpellAuraEffects.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "ObjectAccessor.h"
#include "TemporarySummon.h"

namespace destiny_port_extra
{

enum DestinyExtraSpells : uint32
{
    SPELL_HUNTER_TITANS_THUNDER_AURA        = 207094,
    SPELL_MAGE_PHOENIX_FLAMES               = 194466,
    SPELL_MAGE_PHOENIX_FLAMES_TRIGGER       = 224637,
    SPELL_PALADIN_TYR_DELIVERANCE_HEAL      = 200654,
    SPELL_PRIEST_CALL_OF_THE_VOID           = 193371,
    SPELL_PRIEST_CALL_OF_THE_VOID_SUMMON    = 193470,
    SPELL_PRIEST_MIND_FLAY                  = 15407,    // the priest's Mind Flay: what Call to the Void procs from
    SPELL_PRIEST_TENDRIL_MIND_FLAY          = 193473,   // the Void Tendril's own Mind Flay
    SPELL_SHAMAN_REINCARNATION              = 20608,
    SPELL_WARLOCK_TEAR_CHAOS_BARRAGE        = 187394,
    SPELL_WARLOCK_TEAR_CHAOS_BOLT           = 215279,
    SPELL_WARLOCK_TEAR_SHADOW_BOLT          = 196657,

    NPC_PRIEST_VOID_TENDRIL                 = 98167,
};

// 193371 - Call to the Void
// DestinyCore checked for the tendril's Mind Flay (193473), which a priest never casts, so it could never proc.
// The summon itself (193470) comes from the spell_trigger row; this script only filters and caps. It used to cast
// the summon too, so every proc made two tendrils (#41).
class spell_arti_pri_call_of_the_void : public AuraScript
{
    PrepareAuraScript(spell_arti_pri_call_of_the_void);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        if (!eventInfo.GetSpellInfo() || eventInfo.GetSpellInfo()->Id != SPELL_PRIEST_MIND_FLAY)
            return false;

        // At most 3 tendrils at once (#41)
        Unit* caster = GetCaster();
        if (!caster)
            return false;

        std::list<Creature*> tendrils;
        caster->GetCreatureListWithEntryInGrid(tendrils, NPC_PRIEST_VOID_TENDRIL, 100.0f);
        uint32 count = 0;
        for (Creature* tendril : tendrils)
            if (tendril->IsAlive() && tendril->ToTempSummon() && tendril->ToTempSummon()->GetSummonerGUID() == caster->GetGUID())
                ++count;

        return count < 3;
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_arti_pri_call_of_the_void::CheckProc);
    }
};

// 98167 - Void Tendril: channels Mind Flay on the priest's target, scaled by the priest's spell power
struct npc_arti_priest_void_tendril : public Scripted_NoMovementAI
{
    npc_arti_priest_void_tendril(Creature* creature) : Scripted_NoMovementAI(creature) { }

    ObjectGuid targetGuid;
    uint32 flayTimer = 0;

    void IsSummonedBy(Unit* summoner) override
    {
        Unit* target = summoner->getVictim();
        if (!target)
            if (Player* player = summoner->ToPlayer())
                target = player->GetSelectedUnit();

        if (!target)
        {
            me->DespawnOrUnsummon();
            return;
        }

        targetGuid = target->GetGUID();
        AttackStart(target);
    }

    void UpdateAI(uint32 diff) override
    {
        if (flayTimer > diff)
        {
            flayTimer -= diff;
            return;
        }
        flayTimer = 250;

        if (me->HasUnitState(UNIT_STATE_CASTING))
            return;

        // The tendril is summoned with the totem mask, which never sets an owner GUID, so GetOwner() was
        // always null and the tendril never cast anything (#41). The summoner is the priest.
        Unit* owner = me->GetAnyOwner();
        Unit* target = ObjectAccessor::GetUnit(*me, targetGuid);
        if (!owner || !target || !target->IsAlive())
            return;

        me->CastCustomSpell(SPELL_PRIEST_TENDRIL_MIND_FLAY, SPELLVALUE_BASE_POINT0, owner->GetSpellPowerDamage(SPELL_SCHOOL_MASK_SHADOW), target);
    }
};

// 196586 - Dimensional Rift: opens one of three rifts that attack the target for the warlock
class spell_arti_warl_dimensional_rift : public SpellScript
{
    PrepareSpellScript(spell_arti_warl_dimensional_rift);

    void HandleHit(SpellEffIndex /*effIndex*/)
    {
        Unit* caster = GetCaster();
        Unit* target = GetHitUnit();
        if (!caster || !target)
            return;

        //                                          green   green   purple
        std::vector<uint32> spellVisualIds = { 219117, 219117, 219107 };
        //                                  Chaos Tear  Chaos Portal  Shadowy Tear
        std::vector<uint32> summonIds = {   108493,     108493,       99887 };
        // longer than the attack itself: a rift despawned before its last projectile lands deals no damage
        std::vector<uint32> durations = { 7000, 4500, 16000 };
        uint32 id = urand(0, 2);
        Position pos = caster->GetPosition();
        caster->MovePosition(pos, float(urand(4, 8)), frand(0.0f, 2 * float(M_PI)));
        if (TempSummon* rift = caster->SummonCreature(summonIds[id], pos.GetPositionX(), pos.GetPositionY(), pos.GetPositionZ(), 0, TEMPSUMMON_TIMED_DESPAWN, durations[id]))
        {
            rift->CastSpell(rift, spellVisualIds[id], true);
            rift->SetOwnerGUID(caster->GetGUID());
            rift->SetTarget(target->GetGUID());
            // Chaos Tear and Chaos Portal share an NPC; the armor value tells npc_warl_chaos_tear which one it is
            rift->SetArmor(id);
        }
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_arti_warl_dimensional_rift::HandleHit, EFFECT_0, SPELL_EFFECT_SCRIPT_EFFECT);
    }
};

// 108493 - Chaos Tear (armor 0: Chaos Barrage) / Chaos Portal (armor 1: one Chaos Bolt)
struct npc_warl_chaos_tear : public ScriptedAI
{
    npc_warl_chaos_tear(Creature* creature) : ScriptedAI(creature) { }

    int32 timer = 0;
    int32 counter = 0;

    void UpdateAI(uint32 diff) override
    {
        timer += diff;
        switch (me->GetArmor())
        {
            case 0:
                if (counter >= 22 || timer < 250)
                    return;
                timer -= 250;
                if (CastAtTarget(SPELL_WARLOCK_TEAR_CHAOS_BARRAGE))
                    counter++;
                break;
            case 1:
                if (timer < 1500)
                    return;
                timer -= 9000; // one bolt: the portal despawns before the next
                CastAtTarget(SPELL_WARLOCK_TEAR_CHAOS_BOLT);
                break;
            default:
                break;
        }
    }

    bool CastAtTarget(uint32 spellId)
    {
        Unit* caster = ObjectAccessor::GetUnit(*me, me->GetOwnerGUID());
        Unit* target = ObjectAccessor::GetUnit(*me, me->GetTargetGUID());
        if (!caster || !target)
            return false;

        me->CastSpell(target, spellId, true, nullptr, nullptr, caster->GetGUID());
        return true;
    }
};

// 99887 - Shadowy Tear: 7 Shadow Bolts
struct npc_warl_shadowy_tear : public ScriptedAI
{
    npc_warl_shadowy_tear(Creature* creature) : ScriptedAI(creature) { }

    int32 timer = 0;
    int32 counter = 0;

    void UpdateAI(uint32 diff) override
    {
        if (counter >= 7)
            return;

        timer += diff;
        if (timer < 2000)
            return;
        timer -= 2000;

        Unit* caster = ObjectAccessor::GetUnit(*me, me->GetOwnerGUID());
        Unit* target = ObjectAccessor::GetUnit(*me, me->GetTargetGUID());
        if (!caster || !target)
            return;

        me->CastSpell(target, SPELL_WARLOCK_TEAR_SHADOW_BOLT, true, nullptr, nullptr, caster->GetGUID());
        counter++;
    }
};

// 200653 - Tyr's Deliverance
class spell_arti_pal_tyr_deliverance : public SpellScript
{
    PrepareSpellScript(spell_arti_pal_tyr_deliverance);

    void HandleDummy(SpellEffIndex /*effIndex*/)
    {
        if (Unit* target = GetHitUnit())
            GetCaster()->CastSpell(target, SPELL_PALADIN_TYR_DELIVERANCE_HEAL, true);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_arti_pal_tyr_deliverance::HandleDummy, EFFECT_0, SPELL_EFFECT_DUMMY);
    }
};

// 207068 - Titan's Thunder: the pet and Hati get the lightning aura
class spell_arti_hun_titans_thunder : public SpellScript
{
    PrepareSpellScript(spell_arti_hun_titans_thunder);

    void HandleAfterCast()
    {
        if (Player* player = GetCaster()->ToPlayer())
        {
            if (Pet* pet = player->GetPet())
                pet->CastSpell(pet, SPELL_HUNTER_TITANS_THUNDER_AURA, true);

            if (Unit* hati = player->GetHati())
                hati->CastSpell(hati, SPELL_HUNTER_TITANS_THUNDER_AURA, true);
        }
    }

    void Register() override
    {
        AfterCast += SpellCastFn(spell_arti_hun_titans_thunder::HandleAfterCast);
    }
};

// 207357 - Servant of the Queen: procs only from Reincarnation
class spell_arti_sha_servant_of_the_queen : public AuraScript
{
    PrepareAuraScript(spell_arti_sha_servant_of_the_queen);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        return eventInfo.GetSpellInfo() && eventInfo.GetSpellInfo()->Id == SPELL_SHAMAN_REINCARNATION;
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_arti_sha_servant_of_the_queen::CheckProc);
    }
};

// 224637 - Phoenix Flames splash: no splash damage on the primary target
class spell_arti_mage_phoenix_flames_trigger : public SpellScript
{
    PrepareSpellScript(spell_arti_mage_phoenix_flames_trigger);

    void HandleHit(SpellEffIndex /*effIndex*/)
    {
        Unit* target = GetHitUnit();
        Unit* originalTarget = GetExplTargetUnit();
        if (target && originalTarget && target == originalTarget)
            SetHitDamage(0);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_arti_mage_phoenix_flames_trigger::HandleHit, EFFECT_1, SPELL_EFFECT_SCHOOL_DAMAGE);
    }
};

// 256893 - Light's Judgment (Lightforged Draenei racial)
class spell_light_judgement : public SpellScript
{
    PrepareSpellScript(spell_light_judgement);

    void HandleDamage(SpellEffIndex /*effIndex*/)
    {
        if (Unit* caster = GetCaster())
            SetHitDamage(int32(6.25f * caster->GetTotalAttackPowerValue(BASE_ATTACK)));
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_light_judgement::HandleDamage, EFFECT_0, SPELL_EFFECT_SCHOOL_DAMAGE);
    }
};

// 260364 - Arcane Pulse (Nightborne racial): 2x attack power, or 0.75x spell power for casters
class spell_arcane_pulse : public SpellScript
{
    PrepareSpellScript(spell_arcane_pulse);

    void HandleDamage(SpellEffIndex /*effIndex*/)
    {
        float damage = GetCaster()->GetTotalAttackPowerValue(BASE_ATTACK) * 2.f;
        if (!damage)
            damage = float(GetCaster()->GetSpellPowerDamage(SPELL_SCHOOL_MASK_ARCANE)) * 0.75f;

        SetHitDamage(int32(damage));
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_arcane_pulse::HandleDamage, EFFECT_0, SPELL_EFFECT_SCHOOL_DAMAGE);
    }
};

} // namespace destiny_port_extra

void AddSC_destiny_extra_spells()
{
    using namespace destiny_port_extra;
    RegisterAuraScript(spell_arti_pri_call_of_the_void);
    RegisterCreatureAI(npc_arti_priest_void_tendril);
    RegisterSpellScript(spell_arti_warl_dimensional_rift);
    RegisterCreatureAI(npc_warl_chaos_tear);
    RegisterCreatureAI(npc_warl_shadowy_tear);
    RegisterSpellScript(spell_arti_pal_tyr_deliverance);
    RegisterSpellScript(spell_arti_hun_titans_thunder);
    RegisterAuraScript(spell_arti_sha_servant_of_the_queen);
    RegisterSpellScript(spell_arti_mage_phoenix_flames_trigger);
    RegisterSpellScript(spell_light_judgement);
    RegisterSpellScript(spell_arcane_pulse);
}
