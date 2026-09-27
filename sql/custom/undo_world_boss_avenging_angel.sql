-- Undo fix_world_boss_avenging_angel.sql (also removes any spawns of it)
DELETE FROM world.creature WHERE id = 500002;
DELETE FROM world.creature_template WHERE entry = 500002;
DELETE FROM world.creature_template_wdb WHERE Entry = 500002;
