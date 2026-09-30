-- Undo for fix_mm_scenario_still_alive_shadow_mania.sql (values as they were on live 2026-09-30).
DELETE FROM world.conditions WHERE SourceTypeOrReferenceId = 22 AND SourceGroup = 4 AND SourceEntry = 100398 AND SourceId = 0;
DELETE FROM world.smart_scripts WHERE (entryorguid = 100398 AND source_type = 0 AND id = 5)
    OR (entryorguid = 100749 AND source_type = 0 AND id = 6) OR (entryorguid = 10074900 AND source_type = 9);
UPDATE world.smart_scripts SET link = 0 WHERE entryorguid = 100398 AND source_type = 0 AND id = 4 AND link = 5;
UPDATE world.smart_scripts SET target_param1 = 50 WHERE entryorguid = 100398 AND source_type = 9 AND id = 0;
UPDATE world.waypoint_data_script SET speed = 0 WHERE id = 107995;
