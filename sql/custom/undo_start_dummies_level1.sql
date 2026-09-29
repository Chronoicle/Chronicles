-- Undo fix_start_dummies_level1.sql: levels back to 3, Northshire spawns back on entry 44548, copy 950300 removed.
UPDATE world.creature_template t JOIN world.bak_start_dummies_level1 b ON b.entry = t.entry
SET t.minlevel = b.minlevel, t.maxlevel = b.maxlevel;
UPDATE world.creature c JOIN world.bak_dummy_northshire_spawns b ON b.guid = c.guid SET c.id = b.id WHERE c.id = 950300;
DELETE FROM world.creature_template_wdb_locale WHERE ID = 950300;
DELETE FROM world.creature_template_addon WHERE entry = 950300;
DELETE FROM world.creature_template_wdb WHERE Entry = 950300;
DELETE FROM world.creature_template WHERE entry = 950300;
DROP TABLE world.bak_start_dummies_level1;
DROP TABLE world.bak_dummy_northshire_spawns;
