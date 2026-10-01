/*
 * Dungeon Finder dungeons without an InstanceScript of their own (found by the dungeon bots, #140, 2026-10-01).
 * Map::UpdateEncounterState keeps the completed-encounter mask in the InstanceScript; without one every boss kill is
 * forgotten at once, so "all bosses dead" never happens and the Dungeon Finder never finishes the dungeon (no reward).
 * This script only keeps (and saves) that mask. instance_template.script names it per map
 * (fix_instance_encounter_memory.sql).
 */
#include "ScriptMgr.h"
#include "InstanceScript.h"

struct instance_encounter_memory : public InstanceScript
{
    instance_encounter_memory(InstanceMap* map) : InstanceScript(map)
    {
        SetHeaders("EM");
    }
};

void AddSC_instance_encounter_memory()
{
    new GenericInstanceMapScript<instance_encounter_memory>("instance_the_stockade", 34);
    new GenericInstanceMapScript<instance_encounter_memory>("instance_the_underbog", 546);
    new GenericInstanceMapScript<instance_encounter_memory>("instance_the_botanica", 553);
    new GenericInstanceMapScript<instance_encounter_memory>("instance_mana_tombs", 557);
    new GenericInstanceMapScript<instance_encounter_memory>("instance_auchenai_crypts", 558);
}
