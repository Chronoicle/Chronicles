-- Undo fix_broken_shore_79_80.sql (both rows did not exist before)
DELETE FROM world.spell_script_names WHERE spell_id = 199357 AND ScriptName = 'spell_bi_intro_scene';
DELETE FROM world.creature_movement_override WHERE SpawnId = 344522;
