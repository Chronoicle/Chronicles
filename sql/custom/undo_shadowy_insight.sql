-- Undo fix_shadowy_insight.sql
DELETE FROM world.spell_script_names WHERE spell_id = 124430 AND ScriptName = 'spell_pri_shadowy_insight';
INSERT IGNORE INTO world.spell_script_names (spell_id, ScriptName) VALUES (8092, 'spell_pri_mind_blast');
