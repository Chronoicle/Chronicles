/*
    Dungeon : Neltharions Lair 100-110
    Encounter: Ularogg Cragshaper
    Normal: 100%, Heroic: 100%, Mythic: 100%
*/

#include "neltharions_lair.h"
#include "MoveSplineInit.h"

enum Says
{
    SAY_AGGRO           = 0,
    SAY_STANCE_EMOTE    = 1,
    SAY_DEATH           = 2,
};

enum Spells
{
    SPELL_SUNDER                    = 198496,
    SPELL_SUNDER_CALL               = 198823, //Conversation
    SPELL_STRIKE_MOUNTAIN           = 198428,
    SPELL_STRIKE_MOUNTAIN_2         = 216290,
    SPELL_STRIKE_MOUNTAIN_AT        = 216292,
    SPELL_MOUNTAIN_CALL             = 198825, //Conversation
    SPELL_BELLOW_DEEPS_1            = 193375,
    SPELL_BELLOW_DEEPS_2            = 193376,
    SPELL_BELLOW_DEEPS_CALL         = 198824,
    //SPELL_CALL                    = 198826, //Conversation
    SPELL_STANCE_MOUNTAIN_JUMP      = 198509,
    SPELL_STANCE_MOUNTAIN_SUM_1     = 198564,
    SPELL_STANCE_MOUNTAIN_SUM_2     = 198565,
    SPELL_STANCE_MOUNTAIN_SUM_3     = 216249, //Heroic+
    SPELL_STANCE_MOUNTAIN_SUM_4     = 216250, //Heroic+
    SPELL_STANCE_MOUNTAIN_MORPH     = 198510,
    SPELL_STANCE_MOUNTAIN_TICK      = 198617,
    SPELL_STANCE_MOUNTAIN_FILTER    = 198619,
    SPELL_STANCE_MOUNTAIN_TELEPORT  = 198630,
    SPELL_FALLING_DEBRIS_ULAROGG    = 198719, //boss
    SPELL_STANCE_MOUNTAIN_END       = 198631,

    SPELL_FALLING_DEBRIS            = 193267, //npc 98081
    SPELL_FALLING_DEBRIS_2          = 198717, //npc 100818
    SPELL_STANCE_MOUNTAIN_MOVE      = 198616,
};

enum eEvents
{
    EVENT_SUNDER                = 1,
    EVENT_STRIKE_MOUNTAIN       = 2,
    EVENT_BELLOW_DEEPS_1        = 3,
    EVENT_BELLOW_DEEPS_2        = 4,
    EVENT_STANCE_MOUNTAIN_1     = 5,
    EVENT_STANCE_MOUNTAIN_2     = 6,
    EVENT_STANCE_MOUNTAIN_3     = 7,
    EVENT_STANCE_MOUNTAIN_4     = 8,
    EVENT_STANCE_SUMMON         = 9,
};

//91004
struct boss_ularogg_cragshaper : public BossAI
{
    boss_ularogg_cragshaper(Creature* creature) : BossAI(creature, DATA_ULAROGG), platformHome(creature->GetHomePosition()) {}

    std::map<uint32, std::list<ObjectGuid>> listGuid;
    ObjectGuid stanceGUID;
    bool intro = true;
    bool firstIdolSummoned = false; // the jump casts the first summon on landing
    Position platformHome;
    std::vector<Position> usedSpots; // idol spots taken in the current shuffle tick
    uint32 lastShuffleHit = 0;

    // The pull moves his home to the room centre. On a wipe he despawns and comes back on his platform (his spawn
    // point) 5 s later instead of walking up there, and jumps down again on the next pull (#13)
    void EnterEvadeMode() override
    {
        bool const pulled = !intro;
        if (pulled)
        {
            intro = true;
            me->SetHomePosition(platformHome);
        }
        BossAI::EnterEvadeMode();
        if (pulled && me->IsAlive())
            me->DespawnOrUnsummon(0, Seconds(5));
    }

    void Reset() override
    {
        _Reset();
        me->SetReactState(intro ? REACT_PASSIVE : REACT_AGGRESSIVE);
        me->RemoveAurasDueToSpell(SPELL_STANCE_MOUNTAIN_MORPH);
        me->RemoveAurasDueToSpell(SPELL_STANCE_MOUNTAIN_TICK);
    }

    void EnterCombat(Unit* /*who*/) override
    {
        Talk(SAY_AGGRO); //Pay attention, Navarogg. I want you to see your heroes die.
        _EnterCombat();
        DefaultEvent(true);

        if (intro)
        {
            intro = false;
            me->SetHomePosition(2838.71f, 1668.18f, -40.64f, 3.75f);
            me->GetMotionMaster()->MoveJump(2838.71f, 1668.18f, -40.64f, 0.0f, 30.0f, 10.0f);
            me->SetReactState(REACT_AGGRESSIVE, 3000);
        }
    }

    void DefaultEvent(bool enterCombat)
    {
        events.RescheduleEvent(EVENT_SUNDER, 8000);
        events.RescheduleEvent(EVENT_STRIKE_MOUNTAIN, 16000);
        events.RescheduleEvent(EVENT_BELLOW_DEEPS_1, 20000);
        events.RescheduleEvent(EVENT_STANCE_MOUNTAIN_1, enterCombat ? 50000 : 120000);
    }

    void JustDied(Unit* /*killer*/) override
    {
        Talk(SAY_DEATH);
        _JustDied();
    }

    bool GetObjectData(ObjectGuid const& guid, uint32 type) override
    {
        bool find = false;

        for (auto targetGuid : listGuid[type])
        {
            if (targetGuid == guid)
                find = true;
        }

        if (!find)
            listGuid[type].push_back(guid);

        return find;
    }

    void SpellFinishCast(const SpellInfo* spell)
    {
        switch (spell->Id)
        {
            case SPELL_STANCE_MOUNTAIN_SUM_1:
                firstIdolSummoned = true; // the rest is driven by EVENT_STANCE_SUMMON (the cast chain left him standing)
                break;
        }
    }

    void SpellHitTarget(Unit* target, const SpellInfo* spell) override
    {
        switch (spell->Id)
        {
            case SPELL_STANCE_MOUNTAIN_FILTER:
            {
                // The idols move to random spots inside the darker ring around the middle circle, never onto the middle
                // circle or the outer floor (James, #13; the 5 fixed spots kept them in the middle). Ring 11-20 yd from the
                // room centre: the idols spawn 7-9 yd out and DestinyCore's (sniffed-looking) idol spots reach 20 yd.
                // Spots of one tick stay 6 yd apart.
                if (getMSTimeDiff(lastShuffleHit, getMSTime()) > 1000)
                    usedSpots.clear();
                lastShuffleHit = getMSTime();

                Position const centre = { 2838.15f, 1667.87f, -40.82f };
                Position spot = centre;
                for (uint8 attempt = 0; attempt < 10; ++attempt)
                {
                    float const angle = frand(0.0f, 2.0f * float(M_PI));
                    float const dist = std::sqrt(frand(11.0f * 11.0f, 20.0f * 20.0f)); // uniform over the ring's area
                    spot.Relocate(centre.GetPositionX() + dist * std::cos(angle), centre.GetPositionY() + dist * std::sin(angle), centre.GetPositionZ());
                    if (std::none_of(usedSpots.begin(), usedSpots.end(), [&spot](Position const& used) { return used.GetExactDist2d(&spot) < 6.0f; }))
                        break;
                }
                me->UpdateGroundPositionZ(spot.GetPositionX(), spot.GetPositionY(), spot.m_positionZ);
                usedSpots.push_back(spot);
                target->CastSpell(spot, SPELL_STANCE_MOUNTAIN_MOVE, true);
                break;
            }
            case SPELL_STRIKE_MOUNTAIN_2:
            {
                Position pos;
                float angle = float(M_PI);
                for (uint8 i = 0; i < 4; ++i)
                {
                    pos = target->GetNearPosition(5.0f, angle);
                    target->CastSpell(pos, SPELL_STRIKE_MOUNTAIN_AT, true);
                    angle += float(M_PI / 2.0f);
                }
                break;
            }
        }
    }

    void SummonedCreatureDies(Creature* summon, Unit* /*killer*/) override
    {
        if (summon->GetGUID() == stanceGUID)
        {
            me->CastSpell(summon->GetPosition(), SPELL_STANCE_MOUNTAIN_TELEPORT, true);
            me->RemoveAurasDueToSpell(SPELL_STANCE_MOUNTAIN_MORPH);
            me->RemoveFlag(UNIT_FIELD_FLAGS, UNIT_FLAG_NOT_SELECTABLE | UNIT_FLAG_IMMUNE_TO_PC | UNIT_FLAG_NOT_ATTACKABLE_1);
            me->SetReactState(REACT_AGGRESSIVE);
            DoCast(me, SPELL_STANCE_MOUNTAIN_END, true);
            DefaultEvent(false);
        }
    }

    void UpdateAI(uint32 diff) override
    {
        if (!UpdateVictim())
            return;

        events.Update(diff);

        if (me->HasUnitState(UNIT_STATE_CASTING))
            return;

        if (CheckHomeDistToEvade(diff, 40.0f))
            return;

        if (uint32 eventId = events.ExecuteEvent())
        {
            switch (eventId)
            {
                case EVENT_SUNDER:
                    if (me->getVictim())
                    {
                        DoCast(me, SPELL_SUNDER_CALL, true);
                        DoCastVictim(SPELL_SUNDER);
                    }
                    events.RescheduleEvent(EVENT_SUNDER, 10000);
                    break;
                case EVENT_STRIKE_MOUNTAIN:
                    listGuid.clear();
                    DoCast(SPELL_STRIKE_MOUNTAIN);        
                    events.RescheduleEvent(EVENT_STRIKE_MOUNTAIN, 16000);
                    break;
                case EVENT_BELLOW_DEEPS_1:
                    DoCast(SPELL_BELLOW_DEEPS_1);
                    events.RescheduleEvent(EVENT_BELLOW_DEEPS_1, 32000);
                    events.RescheduleEvent(EVENT_BELLOW_DEEPS_2, 3000);
                    break;
                case EVENT_BELLOW_DEEPS_2:
                    DoCast(me, SPELL_BELLOW_DEEPS_CALL, true);
                    DoCast(SPELL_BELLOW_DEEPS_2);
                    break;
                case EVENT_STANCE_MOUNTAIN_1:
                    events.Reset();
                    me->StopAttack();
                    me->GetMotionMaster()->Clear();
                    me->CastSpell(me, SPELL_STANCE_MOUNTAIN_JUMP, TriggerCastFlags(TRIGGERED_IGNORE_POWER_AND_REAGENT_COST));
                    Talk(SAY_STANCE_EMOTE);
                    firstIdolSummoned = false;
                    events.RescheduleEvent(EVENT_STANCE_SUMMON, 3000);
                    TC_LOG_INFO("server.nl", "Ularogg %s: Stance of the Mountain started", me->GetGUID().ToString().c_str());
                    break;
                case EVENT_STANCE_SUMMON:
                    if (!firstIdolSummoned)
                        DoCast(me, SPELL_STANCE_MOUNTAIN_SUM_1, true);
                    DoCast(me, SPELL_STANCE_MOUNTAIN_SUM_2, true);
                    if (GetDifficultyID() != DIFFICULTY_LFR && GetDifficultyID() != DIFFICULTY_NORMAL)
                    {
                        DoCast(me, SPELL_STANCE_MOUNTAIN_SUM_3, true);
                        DoCast(me, SPELL_STANCE_MOUNTAIN_SUM_4, true);
                    }
                    events.RescheduleEvent(EVENT_STANCE_MOUNTAIN_2, 2000);
                    TC_LOG_INFO("server.nl", "Ularogg: idols summoned (landing summon %s)", firstIdolSummoned ? "yes" : "no");
                    break;
                case EVENT_STANCE_MOUNTAIN_2:
                    me->RemoveAurasAllDots();
                    me->SetFlag(UNIT_FIELD_FLAGS, UNIT_FLAG_NOT_SELECTABLE | UNIT_FLAG_IMMUNE_TO_PC | UNIT_FLAG_NOT_ATTACKABLE_1);
                    DoCast(SPELL_STANCE_MOUNTAIN_MORPH);
                    if (auto summon = me->SummonCreature(NPC_BELLOWING_IDOL_2, me->GetPosition()))
                        stanceGUID = summon->GetGUID();
                    TC_LOG_INFO("server.nl", "Ularogg: transformed, boss idol %s", stanceGUID.ToString().c_str());
                    events.RescheduleEvent(EVENT_STANCE_MOUNTAIN_3, 2000);
                    break;
                case EVENT_STANCE_MOUNTAIN_3:
                    me->AddAura(SPELL_STANCE_MOUNTAIN_TICK, me);
                    events.RescheduleEvent(EVENT_STANCE_MOUNTAIN_4, 10000);
                    break;
                case EVENT_STANCE_MOUNTAIN_4:
                {
                    EntryCheckPredicate pred(NPC_BELLOWING_IDOL_2);
                    summons.DoAction(ACTION_1, pred);
                    me->AddAura(SPELL_FALLING_DEBRIS_ULAROGG, me);
                    break;
                }
            }
        }
        DoMeleeAttackIfReady();
    }
};

//98081, 100818
struct npc_ularogg_bellowing_idols : public ScriptedAI
{
    npc_ularogg_bellowing_idols(Creature* creature) : ScriptedAI(creature) 
    {
        me->SetReactState(REACT_PASSIVE);
        me->ApplySpellImmune(0, IMMUNITY_MECHANIC, MECHANIC_GRIP, true);
        me->ApplySpellImmune(0, IMMUNITY_MECHANIC, MECHANIC_STUN, true);
        me->ApplySpellImmune(0, IMMUNITY_MECHANIC, MECHANIC_FEAR, true);
        me->ApplySpellImmune(0, IMMUNITY_MECHANIC, MECHANIC_ROOT, true);
        me->ApplySpellImmune(0, IMMUNITY_MECHANIC, MECHANIC_FREEZE, true);
        me->ApplySpellImmune(0, IMMUNITY_MECHANIC, MECHANIC_POLYMORPH, true);
        me->ApplySpellImmune(0, IMMUNITY_MECHANIC, MECHANIC_HORROR, true);
        me->ApplySpellImmune(0, IMMUNITY_MECHANIC, MECHANIC_SAPPED, true);
        me->ApplySpellImmune(0, IMMUNITY_MECHANIC, MECHANIC_CHARM, true);
        me->ApplySpellImmune(0, IMMUNITY_MECHANIC, MECHANIC_DISTRACT, true);
        me->ApplySpellImmune(0, IMMUNITY_MECHANIC, MECHANIC_DISORIENTED, true);
        me->ApplySpellImmune(0, IMMUNITY_STATE, SPELL_AURA_MOD_CONFUSE, true);
        me->ApplySpellImmune(0, IMMUNITY_EFFECT, SPELL_EFFECT_KNOCK_BACK, true);
    }

    void Reset() override {}

    void IsSummonedBy(Unit* summoner) override
    {
        if (me->GetEntry() == NPC_BELLOWING_IDOL)
            DoCast(me, SPELL_FALLING_DEBRIS_2, true);
        else
        {
            me->SetFlag(UNIT_FIELD_FLAGS, UNIT_FLAG_NOT_SELECTABLE | UNIT_FLAG_IMMUNE_TO_PC | UNIT_FLAG_NOT_ATTACKABLE_1);
            DoCast(me, 198569, true); //Visual Spawn
        }
    }

    void DoAction(int32 const action) override
    {
        me->RemoveFlag(UNIT_FIELD_FLAGS, UNIT_FLAG_NOT_SELECTABLE | UNIT_FLAG_IMMUNE_TO_PC | UNIT_FLAG_NOT_ATTACKABLE_1);
        DoCast(me, SPELL_FALLING_DEBRIS_2, true);
    }

    void UpdateAI(uint32 diff) override {}
};

//102228
struct npc_stonedark_slave : public ScriptedAI
{
    npc_stonedark_slave(Creature* creature) : ScriptedAI(creature) {}

    bool _endBarrel = false;
    bool _intro = false;

    void MoveInLineOfSight(Unit* who) override
    {  
        if (!who->IsPlayer())
            return;

        if (!_endBarrel && me->IsWithinDistInMap(who, 90.0f))
        {
            // who->CastSpell(who, 209531, true);  пока офф до 7.0.3, крашит
            _endBarrel = true;
        }

        if (!_intro && me->IsWithinDistInMap(who, 40.0f))
        {
            who->CastSpell(who, 209536, true);
            _intro = true;
        }
    }
};

//92473
struct npc_ularogg_empty_barrel : public ScriptedAI
{
    npc_ularogg_empty_barrel(Creature* creature) : ScriptedAI(creature) 
    {
        me->SetReactState(REACT_PASSIVE);
    }

    void Reset() override {}

    void OnSpellClick(Unit* clicker) override
    {
        //Start WP player
        if (!clicker->HasAura(183213))
            clicker->CastSpell(clicker, 183213, true);
    }

    void UpdateAI(uint32 diff) override {}
};

//92610
struct npc_nl_understone_drummer : public ScriptedAI
{
    npc_nl_understone_drummer(Creature* creature) : ScriptedAI(creature) {}

    EventMap events;
    bool drumsMove = true;
    bool drumsCast = true;
    Position pos;

    void EnterEvadeMode()
    {
        ScriptedAI::EnterEvadeMode();
    }

    void Reset() override
    {
        drumsMove = true;
        drumsCast = true;
        pos.Relocate(0.0f, 0.0f, 0.0f);
        events.Reset();
    }

    void EnterCombat(Unit* /*who*/) override
    {
        if (Creature* drums = me->FindNearestCreature(92387, 40.0f, true))
        {
            if (drums->IsAlive())
                events.RescheduleEvent(EVENT_1, 500);
            else
                events.Reset();
        }
    }

    void UpdateAI(uint32 diff) override
    {
        if (!UpdateVictim())
            return;

        events.Update(diff);

        if (me->HasUnitState(UNIT_STATE_CASTING))
            return;
        else
            me->SetReactState(REACT_AGGRESSIVE);

        if (drumsMove)
        {
            if (Creature* drums = me->FindNearestCreature(92387, 40.0f, true))
            {
                if (drums->IsAlive())
                {
                    events.RescheduleEvent(EVENT_1, 1000);
                    drumsMove = false;
                }
            }
        }

        // pos is set once EVENT_1 sent him to his drum
        if (drumsCast && !drumsMove && pos.GetPositionX() != 0.0f && me->GetExactDist2d(&pos) < 2.0f)
        {
            events.RescheduleEvent(EVENT_2, 1000);
            drumsCast = false;
        }

        if (uint32 eventId = events.ExecuteEvent())
        {
            switch (eventId)
            {
                case EVENT_1:
                {
                    // Out of combat he stays at his own spot; for War Drums he runs to his drum and plays it from the side
                    // facing his spawn point, 3 yd away. Was drum x - 3, behind or beside one of the drums (#13)
                    if (Creature* drums = me->FindNearestCreature(92387, 40.0f, true))
                    {
                        if (drums->IsAlive())
                        {
                            float const angle = drums->GetAngle(&me->GetHomePosition());
                            pos.Relocate(drums->GetPositionX() + 3.0f * std::cos(angle), drums->GetPositionY() + 3.0f * std::sin(angle), drums->GetPositionZ());
                            me->GetMotionMaster()->MovePoint(1, pos);
                        }
                    }
                    break;
                }
                case EVENT_2:
                {
                    // face the drum (was a fixed 0.5 rad, wrong for one of the two drums) (#13)
                    if (Creature* drums = me->FindNearestCreature(92387, 5.0f, true))
                        me->SetFacingToObject(drums);
                    me->SetReactState(REACT_AGGRESSIVE, 24000);
                    me->StopAttack(true);
                    DoCast(183526);
                    break;
                }
            }
        }
        DoMeleeAttackIfReady();
    }
};

//183213
class spell_barrel_ride_plr_move : public AuraScript
{
    PrepareAuraScript(spell_barrel_ride_plr_move);

    void OnApply(AuraEffect const* aurEff, AuraEffectHandleModes /*mode*/)
    {
        if (Player* player = GetTarget()->ToPlayer())
        {
            // path 9100400 (waypoint_data_script, speed 25) as one smooth spline like the entrance slide: point by point
            // it was snappy (#13). Its last point removed this aura (waypoint script 335).
            static G3D::Vector3 const ride[] =
            {
                {2820.56f, 1325.45f, -4.546f}, {2802.25f, 1316.70f, -4.298f}, {2795.72f, 1301.30f, -4.298f},
                {2778.16f, 1288.85f, -4.324f}, {2768.90f, 1267.93f, -4.298f}, {2744.28f, 1259.70f, -4.781f},
                {2735.45f, 1246.16f, -4.783f}, {2717.75f, 1251.40f, -4.783f}, {2695.62f, 1251.58f, -4.783f},
                {2677.29f, 1259.60f, -4.782f}, {2660.60f, 1268.23f, -4.782f}, {2655.97f, 1281.47f, -4.782f},
                {2642.57f, 1294.07f, -4.783f}, {2635.10f, 1313.17f, -4.783f}, {2625.24f, 1329.53f, -4.783f},
                {2622.05f, 1348.13f, -4.783f}, {2614.58f, 1355.12f, -4.783f}, {2605.50f, 1377.67f, -4.783f},
                {2595.58f, 1381.25f, -4.783f}, {2575.87f, 1396.24f, -4.783f}, {2556.38f, 1397.96f, -4.783f},
                {2545.27f, 1408.56f, -4.783f}, {2549.71f, 1449.33f, -51.0f}
            };
            Movement::PointsArray path;
            path.push_back(G3D::Vector3(player->GetPositionX(), player->GetPositionY(), player->GetPositionZ())); // replaced by the real start
            // The recorded points zigzag 5-10 yd left and right of the river's course, so the smooth curve swung back and
            // forth (James, #13). One 1-2-1 smoothing pass over x/y halves that. Heights stay, and the first point, the
            // drop (last) and the edge before it are kept as recorded.
            size_t const count = std::end(ride) - std::begin(ride);
            for (size_t i = 0; i < count; ++i)
            {
                G3D::Vector3 p = ride[i];
                if (i > 0 && i + 2 < count)
                {
                    p.x = (ride[i - 1].x + 2.0f * ride[i].x + ride[i + 1].x) * 0.25f;
                    p.y = (ride[i - 1].y + 2.0f * ride[i].y + ride[i + 1].y) * 0.25f;
                }
                path.push_back(p);
            }
            player->GetMotionMaster()->MoveIdle();
            Movement::MoveSplineInit init(*player);
            init.MovebyPath(path);
            init.SetSmooth();
            init.SetUncompressed();
            init.SetVelocity(25.0f);
            int32 duration = init.Launch();
            player->AddDelayedEvent(uint64(std::max(duration, 0) + 200), [player] { player->RemoveAurasDueToSpell(183213); });
        }
    }

    void Register() override
    {
        OnEffectApply += AuraEffectApplyFn(spell_barrel_ride_plr_move::OnApply, EFFECT_2, SPELL_AURA_MOD_NO_ACTIONS, AURA_EFFECT_HANDLE_REAL);
    }
};

//198719
class spell_ularogg_falling_debris : public AuraScript
{
    PrepareAuraScript(spell_ularogg_falling_debris);

    uint8 tickTrigger = 6;
    uint8 tickSwitch = 0;

    void OnTick(AuraEffect const* aurEff)
    {
        if (tickTrigger > 0)
        {
            if (aurEff->GetTickNumber() % tickTrigger)
                PreventDefaultAction();
            else if (++tickSwitch == 6)
            {
                tickSwitch = 0;
                tickTrigger -= 2;
            }
        }
    }

    void Register() override
    {
        OnEffectPeriodic += AuraEffectPeriodicFn(spell_ularogg_falling_debris::OnTick, EFFECT_0, SPELL_AURA_PERIODIC_DUMMY);
    }
};

//183088
class spell_nl_avalanche : public SpellScript
{
    PrepareSpellScript(spell_nl_avalanche);
    
    void HandleScript(SpellEffIndex effIndex)
    {
        if (!GetCaster())
            return;

        std::list<Player*> playerList;
        GetPlayerListInGrid(playerList, GetCaster(), 40);
        Trinity::Containers::RandomResizeList(playerList, 2);
        for (auto player : playerList)
            GetCaster()->CastSpell(player, 183095, true);                 
    }

    void Register() override
    {
        OnEffectHit += SpellEffectFn(spell_nl_avalanche::HandleScript, EFFECT_0, SPELL_EFFECT_SCHOOL_DAMAGE);
    }
};

//198475
class spell_ularogg_strike_mountain : public SpellScript
{
    PrepareSpellScript(spell_ularogg_strike_mountain);

    void HandleScript(SpellEffIndex effectIndex)
    {
        if (!GetCaster() || !GetHitUnit())
            return;

        if (auto instance = GetCaster()->GetInstanceScript())
            if (auto ularogg = instance->instance->GetCreature(instance->GetGuidData(NPC_ULAROGG_CRAGSHAPER)))
                if (ularogg->AI()->GetObjectData(GetHitUnit()->GetGUID(), effectIndex))
                {
                    if (effectIndex == EFFECT_0)
                        SetHitDamage(0);
                    else
                        PreventHitDefaultEffect(effectIndex);
                }
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_ularogg_strike_mountain::HandleScript, EFFECT_0, SPELL_EFFECT_SCHOOL_DAMAGE);
        OnEffectHitTarget += SpellEffectFn(spell_ularogg_strike_mountain::HandleScript, EFFECT_1, SPELL_EFFECT_KNOCK_BACK);
    }
};

void AddSC_boss_ularogg_cragshaper()
{
    RegisterCreatureAI(boss_ularogg_cragshaper);
    RegisterCreatureAI(npc_ularogg_bellowing_idols);
    RegisterCreatureAI(npc_stonedark_slave);
    RegisterCreatureAI(npc_ularogg_empty_barrel);
    RegisterCreatureAI(npc_nl_understone_drummer);
    RegisterAuraScript(spell_barrel_ride_plr_move);
    RegisterAuraScript(spell_ularogg_falling_debris);
    RegisterSpellScript(spell_nl_avalanche);
    RegisterSpellScript(spell_ularogg_strike_mountain);
}