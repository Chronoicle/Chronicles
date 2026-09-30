-- Undo for fix_thasdorah_scenario_136b.sql (values as they were on live 2026-10-01; no 100397 row had flag 256 before).
SET NAMES utf8mb4;
DELETE FROM world.smart_scripts WHERE (entryorguid = 100397 AND source_type = 0 AND id BETWEEN 59 AND 65)
    OR (entryorguid = 10039706 AND source_type = 9) OR (entryorguid = 101269 AND source_type = 0 AND id BETWEEN 13 AND 15);
UPDATE world.smart_scripts SET event_flags = event_flags & ~256 WHERE entryorguid = 100397 AND source_type = 0 AND id <= 58;
UPDATE world.smart_scripts SET link = 0 WHERE entryorguid = 100397 AND source_type = 0 AND id IN (20, 33);
UPDATE world.smart_scripts SET action_param6 = 0 WHERE entryorguid = 100397 AND source_type = 0 AND id = 23;
UPDATE world.smart_scripts SET action_type = 53, action_param1 = 1, action_param2 = 10039703, comment = 'Update Data - Start WP'
    WHERE entryorguid = 100397 AND source_type = 0 AND id = 30;
UPDATE world.smart_scripts SET target_param2 = 50 WHERE entryorguid = 100397 AND source_type = 0 AND id = 37;
UPDATE world.smart_scripts SET link = 0 WHERE entryorguid = 101269 AND source_type = 0 AND id = 1;
UPDATE world.creature SET MovementType = 2 WHERE guid = 370739;
UPDATE world.smart_scripts SET target_type = 7, target_param1 = 0
    WHERE (entryorguid = 100836 AND source_type = 0 AND id IN (3, 6, 8)) OR (entryorguid = 100749 AND source_type = 0 AND id = 4)
       OR (entryorguid = 101269 AND source_type = 0 AND id = 10);
UPDATE world.creature SET modelid = 0 WHERE guid IN (370756, 11546505, 11546526, 11546527, 11546528);
UPDATE world.gameobject_template SET name = 'Тасдора, наследие Ветрокрылых', castBarCaption = 'Извлечение' WHERE entry = 248419;
