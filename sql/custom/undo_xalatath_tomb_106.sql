-- Undo for fix_xalatath_tomb_106.sql (restores the rows exactly as they were on 2026-09-29)
UPDATE world.smart_scripts SET target_type = 21, target_param1 = 50
WHERE entryorguid = 102693 AND source_type = 0 AND id = 4;

UPDATE world.smart_scripts SET event_type = 61, event_flags = 0
WHERE entryorguid = 101897 AND source_type = 0 AND id = 3;
DELETE FROM world.smart_scripts WHERE entryorguid = 101897 AND source_type = 0 AND id = 2;
INSERT INTO world.smart_scripts (entryorguid, source_type, id, link, Difficulties, event_type, event_phase_mask, event_chance, event_flags,
  event_param1, event_param2, event_param3, event_param4, event_param5, action_type, action_param1, action_param2, action_param3,
  action_param4, action_param5, action_param6, target_type, target_param1, target_param2, target_param3, target_param4,
  target_x, target_y, target_z, target_o, comment) VALUES
(101897, 0, 2, 3, '', 6, 0, 100, 1, 0, 0, 0, 0, 0, 9, 0, 0, 0, 0, 0, 0, 15, 251349, 70, 0, 0, 0, 0, 0, 0, 'On Death - Activate GO');

DELETE FROM world.smart_scripts WHERE entryorguid = -369668 AND source_type = 0;
DELETE FROM world.conditions WHERE SourceTypeOrReferenceId = 22 AND SourceGroup = 1 AND SourceEntry = -369668 AND SourceId = 0;

DELETE FROM world.smart_scripts WHERE entryorguid = 101875 AND source_type = 0 AND id IN (7, 8, 9);
DELETE FROM world.conditions WHERE SourceTypeOrReferenceId = 22 AND SourceGroup = 8 AND SourceEntry = 101875 AND SourceId = 0;
