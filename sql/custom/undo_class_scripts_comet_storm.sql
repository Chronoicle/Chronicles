-- Undo fix_class_scripts_comet_storm.sql
DELETE FROM world.spell_script_names WHERE spell_id IN (153595, 228601) AND ScriptName IN ('spell_mage_comet_storm', 'spell_mage_comet_storm_damage');
INSERT IGNORE INTO world.spell_script_names (spell_id, ScriptName) VALUES (153595, 'spell_monk_comet_storm');
