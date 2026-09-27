-- Undo fix_eonar_30.sql
UPDATE world.gameobject_template SET flags = 0 WHERE entry = 273687;
UPDATE world.creature SET position_x = -4207.34, position_y = -10700.3 WHERE guid = 14568233;
DELETE FROM world.creature WHERE guid IN (146929295, 146929296, 146929297);
