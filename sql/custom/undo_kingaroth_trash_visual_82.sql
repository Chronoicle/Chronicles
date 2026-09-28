-- Undo fix_kingaroth_trash_visual_82.sql
DELETE FROM world.spell_script_names WHERE spell_id = 252743 AND ScriptName = 'spell_kingaroth_annihilation_dmg';
