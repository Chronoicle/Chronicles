-- Undo for fix_druid_dreamgrove_guardian.sql (state before, 2026-10-01: no spell/eventobject conditions, no portal,
-- eventobject 2650 or Malithar row 11; Shadowstalker range 0 = 100 yd, Lea credit range 100, claws in phase 6202,
-- the Locate-the-Claws rows on Generic Bunny entry 59113).
SET NAMES utf8mb4;

DELETE FROM world.conditions WHERE SourceTypeOrReferenceId = 17 AND SourceGroup = 0 AND SourceEntry = 204542;

DELETE FROM world.gameobject WHERE guid = 25683700 AND id = 248778;
DELETE FROM world.eventobject WHERE guid = 410450 AND id = 2650;
DELETE FROM world.eventobject_template WHERE entry = 2650;
DELETE FROM world.smart_scripts WHERE entryorguid = 2650 AND source_type = 13;
DELETE FROM world.conditions WHERE SourceTypeOrReferenceId = 22 AND SourceEntry = 2650 AND SourceId = 13;

UPDATE world.smart_scripts SET target_param2 = 0
WHERE entryorguid = 105294 AND source_type = 0 AND id = 2 AND action_type = 45 AND target_type = 19 AND target_param2 = 300;
UPDATE world.smart_scripts SET target_param1 = 100
WHERE entryorguid = 105243 AND source_type = 0 AND id = 8 AND action_type = 205 AND target_type = 21 AND target_param1 = 300;

UPDATE world.creature SET PhaseId = '6202' WHERE guid = 11296141 AND id = 105331 AND PhaseId = '';

DELETE FROM world.smart_scripts WHERE entryorguid = 101390 AND source_type = 0 AND id = 11;

UPDATE world.smart_scripts SET entryorguid = 59113 WHERE entryorguid = -11296138 AND source_type = 0 AND id IN (0, 1, 2);
