-- Undo fix_world_boss_avenging_angel.sql (also removes any spawns)
DELETE FROM world.creature WHERE id IN (500002, 500003);
DELETE FROM world.creature_template WHERE entry IN (500002, 500003);
DELETE FROM world.creature_template_wdb WHERE Entry IN (500002, 500003);
DELETE FROM world.creature_equip_template WHERE CreatureID = 500003;
DELETE FROM world.spell_script_names WHERE spell_id = 228029 AND ScriptName = 'spell_avenging_angel_expel_light';
