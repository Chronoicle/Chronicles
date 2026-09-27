-- Undo fix_priest_scenario_balnazzar.sql
DELETE FROM world.smart_scripts WHERE entryorguid = 111247 AND source_type = 9 AND id IN (35, 36);
