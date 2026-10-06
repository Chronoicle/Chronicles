-- Undo for fix_truthguard_poi_189.sql (restores the backed up rows)
DELETE FROM world.quest_poi_points WHERE QuestID IN (42000, 42001, 42002, 42003, 42004, 42005, 42006, 42007, 42017);
DELETE FROM world.quest_poi WHERE QuestID IN (42000, 42001, 42002, 42003, 42004, 42005, 42006, 42007, 42017);
INSERT INTO world.quest_poi SELECT * FROM world.bak_poi189;
INSERT INTO world.quest_poi_points SELECT * FROM world.bak_poi_points189;
