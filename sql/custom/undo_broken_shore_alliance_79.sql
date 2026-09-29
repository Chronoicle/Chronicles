-- Undo fix_broken_shore_alliance_79.sql (before: 225150 had no spell_script_names row).
DELETE FROM world.spell_script_names WHERE spell_id = 225150 AND ScriptName = 'spell_bi_intro_scene';
