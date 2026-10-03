#include "ScriptedGossip.h"
#include "ScriptedCreature.h"
#include "ScriptMgr.h"
#include "InstanceScript.h"
#include "deadmines.h"
#include "Spell.h"

#define GOSSIP_SENDER_DEADMINES_PORT 36

Position deadmines_locs[] = {
    { -64.1528f, -385.99f, 53.192f, 1.85005f },
    { -305.321f, -491.292f, 49.232f, 0.488691f },
    { -201.096f, -606.05f, 19.3022f, 2.74016f },
    { -129.915f, -788.898f, 17.3409f, 0.366518f },
};

enum Adds
{
    // quest
    NPC_EDWIN_CANCLEEF_1    = 42697, 
    NPC_ALLIANCE_ROGUE      = 42700,
    NPC_VANESSA_VANCLEEF_1  = 42371, // little
};

// 47404 (#176: no script existed, the Watchers only stood there). TrinityCore/CPP: at 30 % health the Watcher stops fighting, turns
// "controllable", catches fire (91737: explodes at the end, 91738) and energizes the Foe Reaper 5000 (89132) - four of them power it on.
enum DefiasWatcher
{
    SPELL_WATCHER_ON_FIRE           = 91737,
    SPELL_WATCHER_ENERGIZE          = 89132,
    SPELL_WATCHER_CLEAVE            = 90980,

    FACTION_WATCHER_CONTROLLABLE    = 1816,

    EVENT_WATCHER_CLEAVE    = 1
};

class npc_deadmines_defias_watcher : public CreatureScript
{
    public:
        npc_deadmines_defias_watcher() : CreatureScript("npc_deadmines_defias_watcher") { }

        CreatureAI* GetAI(Creature* creature) const override
        {
            return new npc_deadmines_defias_watcherAI(creature);
        }

        struct npc_deadmines_defias_watcherAI : public ScriptedAI
        {
            npc_deadmines_defias_watcherAI(Creature* creature) : ScriptedAI(creature), _isOnFire(false), _faction(creature->getFaction()) { }

            void Reset() override
            {
                _events.Reset();
                if (_isOnFire)
                {
                    _isOnFire = false;
                    me->setFaction(_faction);
                    me->setRegeneratingHealth(true);
                }
                me->SetFullHealth();
            }

            void EnterCombat(Unit* /*who*/) override
            {
                _events.RescheduleEvent(EVENT_WATCHER_CLEAVE, 3500);
            }

            void DamageTaken(Unit* /*attacker*/, uint32& damage, DamageEffectType /*dmgType*/) override
            {
                if (!_isOnFire && me->HealthBelowPctDamaged(30, damage))
                {
                    _isOnFire = true;
                    _events.Reset();
                    me->DeleteThreatList();
                    me->CombatStop();
                    me->setFaction(FACTION_WATCHER_CONTROLLABLE);
                    me->setRegeneratingHealth(false);
                    DoCast(me, SPELL_WATCHER_ON_FIRE, true);
                    DoCastAOE(SPELL_WATCHER_ENERGIZE, true);
                }
            }

            void UpdateAI(uint32 diff) override
            {
                if (!UpdateVictim())
                    return;

                _events.Update(diff);

                if (me->HasUnitState(UNIT_STATE_CASTING))
                    return;

                if (uint32 eventId = _events.ExecuteEvent())
                {
                    if (eventId == EVENT_WATCHER_CLEAVE)
                    {
                        DoCastVictim(SPELL_WATCHER_CLEAVE);
                        _events.RescheduleEvent(EVENT_WATCHER_CLEAVE, urand(4000, 5000));
                    }
                }

                DoMeleeAttackIfReady();
            }

        private:
            EventMap _events;
            bool _isOnFire;
            uint32 _faction;
        };
};

class go_defias_cannon : public GameObjectScript
{
    public:
        go_defias_cannon() : GameObjectScript("go_defias_cannon") { }

        bool OnGossipHello(Player* pPlayer, GameObject* pGo)
        {
            InstanceScript* instance = pGo->GetInstanceScript();
            if (!instance)
                return false;
            //if (instance->GetData(DATA_CANNON_EVENT) != CANNON_NOT_USED)
                //return false ;

            instance->SetData(DATA_CANNON_EVENT, CANNON_BLAST_INITIATED);
            return false;
        }
};

class deadmines_teleport : public GameObjectScript
{
    public:
        deadmines_teleport() : GameObjectScript("deadmines_teleport") { }

        bool OnGossipHello(Player* player, GameObject* go)
        {
            bool ru = player->GetSession()->GetSessionDbLocaleIndex() == LOCALE_ruRU;

            if (InstanceScript* instance = go->GetInstanceScript())
            {
                if (instance->GetBossState(DATA_GLUBTOK) == DONE)
                    player->ADD_GOSSIP_ITEM(GossipOptionNpc::None, ru ? "Teleport to entrance." : "Teleport to entrance.", GOSSIP_SENDER_DEADMINES_PORT, 0);

                if (instance->GetBossState(DATA_ADMIRAL) == DONE)
                    player->ADD_GOSSIP_ITEM(GossipOptionNpc::None, ru ? "Teleport to Ironclad Cove." : "Teleport to Ironclad Cove.", GOSSIP_SENDER_DEADMINES_PORT, 3);
                else if (instance->GetBossState(DATA_FOEREAPER) == DONE)
                    player->ADD_GOSSIP_ITEM(GossipOptionNpc::None, ru ? "Teleport to The Foundry." : "Teleport to The Foundry.", GOSSIP_SENDER_DEADMINES_PORT, 2);
                else if (instance->GetBossState(DATA_HELIX) == DONE)
                    player->ADD_GOSSIP_ITEM(GossipOptionNpc::None, ru ? "Teleport to The Mast Room." : "Teleport to The Mast Room.", GOSSIP_SENDER_DEADMINES_PORT, 1);
            }

            player->SEND_GOSSIP_MENU(player->GetGossipTextId(go), go->GetGUID());
            return true;
        }

        bool OnGossipSelect(Player* player, GameObject* /*go*/, uint32 sender, uint32 action)
        {
            player->PlayerTalkClass->ClearMenus();
            player->CLOSE_GOSSIP_MENU();

            if (action >= 4)
                return false;

            Position loc = deadmines_locs[action];
            if (!player->isInCombat())
                player->NearTeleportTo(loc.GetPositionX(), loc.GetPositionY(), loc.GetPositionZ(), loc.GetOrientation(), false);
            return true;
        }
};

void AddSC_deadmines()
{
    new go_defias_cannon();
    new npc_deadmines_defias_watcher();
    new deadmines_teleport();
}