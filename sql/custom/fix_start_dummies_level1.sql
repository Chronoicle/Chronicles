-- Training dummies in the starting zones are level 1 (owner request 2026-09-29, Claude desktop session).
-- The client showed the Northshire dummy (entry 44548) as level 82: creature_template_scaling gives it 82-90.
-- The other starting-zone dummies were level 3.
-- Undo: undo_start_dummies_level1.sql (uses the backup tables below). Goes live at the next restart (never .reload).
--
-- 1) Entries that are only spawned in their own starting zone: level 3 -> 1 (no scaling row, so minlevel/maxlevel is the level).
--      44389 Coldridge Valley, 44614 Shadowglen, 44703 Ammen Vale, 44794 Deathknell, 44820 Valley of Trials,
--      44848 Camp Narache, 44937 Sunstrider Isle
-- 2) Entry 44548 is shared: 8 spawns in Northshire Valley (area 9) but also 4 on map 870 (area 6619) and 3 on GM Island.
--    Those two keep level 82-90, so Northshire gets its own copy (entry 950300, level 1, no scaling) and only the 8
--    Northshire spawns are moved to it.
-- Left alone on purpose: 44171 / 42328 (Gnomeregan), Acherus dummies (Death Knight quest objects), all higher-level dummies.
-- Quests count the dummy through KilledMonsterCredit(44175) in npc_training_dummy, not through these entries.
CREATE TABLE world.bak_start_dummies_level1 AS
SELECT entry, minlevel, maxlevel FROM world.creature_template
WHERE entry IN (44389, 44614, 44703, 44794, 44820, 44848, 44937);

UPDATE world.creature_template SET minlevel = 1, maxlevel = 1
WHERE entry IN (SELECT entry FROM world.bak_start_dummies_level1);

CREATE TABLE world.bak_dummy_northshire_spawns AS
SELECT guid, id FROM world.creature WHERE id = 44548 AND map = 0 AND areaId = 9;

CREATE TEMPORARY TABLE world.tmp_dummy_ct AS SELECT * FROM world.creature_template WHERE entry = 44548;
UPDATE world.tmp_dummy_ct SET entry = 950300, minlevel = 1, maxlevel = 1;
INSERT INTO world.creature_template SELECT * FROM world.tmp_dummy_ct;

CREATE TEMPORARY TABLE world.tmp_dummy_wdb AS SELECT * FROM world.creature_template_wdb WHERE Entry = 44548;
UPDATE world.tmp_dummy_wdb SET Entry = 950300;
INSERT INTO world.creature_template_wdb SELECT * FROM world.tmp_dummy_wdb;

CREATE TEMPORARY TABLE world.tmp_dummy_addon AS SELECT * FROM world.creature_template_addon WHERE entry = 44548;
UPDATE world.tmp_dummy_addon SET entry = 950300;
INSERT INTO world.creature_template_addon SELECT * FROM world.tmp_dummy_addon;

CREATE TEMPORARY TABLE world.tmp_dummy_loc AS SELECT * FROM world.creature_template_wdb_locale WHERE ID = 44548;
UPDATE world.tmp_dummy_loc SET ID = 950300;
INSERT INTO world.creature_template_wdb_locale SELECT * FROM world.tmp_dummy_loc;

UPDATE world.creature c JOIN world.bak_dummy_northshire_spawns b ON b.guid = c.guid SET c.id = 950300;
