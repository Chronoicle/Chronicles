-- Undo fix_garothi_annihilator_52.sql
UPDATE world.creature_template SET ScriptName = '' WHERE entry = 123459;
DELETE FROM world.spell_script_names WHERE spell_id = 245810 AND ScriptName = 'spell_worldbreaker_annihilation_dmg';
DELETE FROM world.areatrigger_template WHERE entry = 10793;
DELETE FROM world.areatrigger_data WHERE entry = 10793;
DELETE FROM world.areatrigger_actions WHERE entry = 10793;
