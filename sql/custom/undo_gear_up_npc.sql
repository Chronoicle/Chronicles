-- Undo for fix_gear_up_npc.sql (also removes spawns and the gear table)
DELETE FROM world.creature WHERE id = 500010;
DELETE FROM world.creature_template WHERE entry = 500010;
DELETE FROM world.creature_template_wdb WHERE Entry = 500010;
DROP TABLE IF EXISTS world.gear_npc_items;
