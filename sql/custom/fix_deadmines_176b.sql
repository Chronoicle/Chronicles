-- Deadmines (map 36), issue #176 retest (tyrvana). help-helper (Claude, Pro) 2026-10-04. DRAFT, NOT RUN: read the diagnostics first, test on a copy.
-- Apply right before a worldserver restart (no .reload). Undo: undo_deadmines_176b.sql. Data source: CPP TrinityCore sql/old/4.3.4/world/11_2016_08_28/2016_06_09_00_world.sql.
--
-- DIAGNOSTICS (read-only):
--  a) the 11 Deadmines MovementType-2 creatures without a path and the nearest CPP patrol of the same entry (needs the staging part below):
--     SELECT c.guid, c.id, c.position_x, c.position_y, c.position_z FROM world.creature c WHERE c.map = 36 AND c.MovementType = 2 AND NOT EXISTS (SELECT 1 FROM world.creature_addon a JOIN world.waypoint_data w ON w.id = a.path_id WHERE a.guid = c.guid AND a.path_id <> 0);
--  b) Mine Rats: are there static spawns? SELECT guid, position_x, position_y, position_z, MovementType, spawndist FROM world.creature WHERE map = 36 AND id = 51462;   (CPP: 9 static rats at -291..-287, -482..-487, z 49.9, MovementType 0, all at the same spot; the Oaf script ALSO summons 7 per smash at the same spot)
--  c) addon/emote of the monkeys: SELECT entry, bytes1, bytes2, emote FROM world.creature_template_addon WHERE entry IN (48440, 48441, 48442, 48823, 48826, 48827, 3586, 598);   (CPP: 48441 emote 233 = EMOTE_STATE_WORK_MINING; 48440 and 48442 emote 0)
--  d) AI of the Overseer/Monkey (smart_scripts exist but the template must say SmartAI): SELECT entry, AIName, ScriptName FROM world.creature_template WHERE entry IN (48279, 48819, 48442, 48827, 48440, 48441);
--  e) Oaf Guard: SELECT entry, auras FROM world.creature_template_addon WHERE entry IN (47296, 48940);  (CPP: 47296 "90546"; the C++ now removes it when the Oaf dies)

-- 1) SmartAI never ran for the Goblin Overseer 48279 (Threatening Shout 91034, Motivate 91036) and the Mining Monkey 48442 (Throw 91038, flee at 15 %): the rows exist but the template has AIName ''.
CREATE TABLE IF NOT EXISTS world.bak_dm176b_template (entry INT PRIMARY KEY, AIName VARCHAR(64));
INSERT IGNORE INTO world.bak_dm176b_template (entry, AIName) SELECT entry, AIName FROM world.creature_template WHERE entry IN (48279, 48442, 48819, 48827) AND AIName = '' AND ScriptName = '';
UPDATE world.creature_template t JOIN world.bak_dm176b_template b ON b.entry = t.entry SET t.AIName = 'SmartAI';

-- 2) the Mining Monkey 48442 SmartAI has every event twice (ids 12, 13, 16-23 repeat 0, 1, 4-11): Throw/flee/emote ran double. Backup, then delete the copies.
CREATE TABLE IF NOT EXISTS world.bak_dm176b_smart LIKE world.smart_scripts;
INSERT INTO world.bak_dm176b_smart SELECT * FROM world.smart_scripts WHERE entryorguid = 48442 AND source_type = 0 AND id IN (12, 13, 16, 17, 18, 19, 20, 21, 22, 23)
  AND NOT EXISTS (SELECT 1 FROM world.bak_dm176b_smart x WHERE x.entryorguid = 48442 AND x.source_type = 0 AND x.id IN (12, 13, 16, 17, 18, 19, 20, 21, 22, 23));
DELETE FROM world.smart_scripts WHERE entryorguid = 48442 AND source_type = 0 AND id IN (12, 13, 16, 17, 18, 19, 20, 21, 22, 23);

-- 3) mining animation: CPP gives the Mining Monkey 48441 (and its heroic twin 48823) emote state 233 (WORK_MINING), bytes2 1. Only where the row exists with emote 0.
CREATE TABLE IF NOT EXISTS world.bak_dm176b_addon (entry INT PRIMARY KEY, emote INT);
INSERT IGNORE INTO world.bak_dm176b_addon (entry, emote) SELECT entry, emote FROM world.creature_template_addon WHERE entry IN (48441, 48823) AND emote = 0;
UPDATE world.creature_template_addon a JOIN world.bak_dm176b_addon b ON b.entry = a.entry SET a.emote = 233;
-- if diagnostic c shows no row for 48441: INSERT INTO world.creature_template_addon (entry, path_id, mount, bytes1, bytes2, emote, auras) VALUES (48441, 0, 0, 0, 1, 233, '');   (then add 48441 to the undo by hand)

-- 4) Miner Johnson 3586 "[UNUSED 4.x ]Miner Johnson": CPP has NO spawn of 3586 (nor of 598) in the Deadmines; at that spot (-151.3, -532.3, 49.6) CPP has Mining Powder 48284, a Goblin Overseer and Mining Monkeys.
--    The spawn guid 246468 is a leftover of the unused entry. OWNER DECISION (deleting data): uncomment to delete it.
-- CREATE TABLE IF NOT EXISTS world.bak_dm176b_creature LIKE world.creature;
-- INSERT INTO world.bak_dm176b_creature SELECT * FROM world.creature WHERE guid = 246468 AND id = 3586;
-- DELETE FROM world.creature WHERE guid = 246468 AND id = 3586;
-- (creature_addon / smart_scripts of that guid, if any: SELECT * FROM world.creature_addon WHERE guid = 246468;)

-- dev-owner: part 5 (wandering rats) left out: CPP/retail have them static at that spot; part 6 (second patrol pass) matched 0 of our creatures on the live DB, left out.

-- 7) CPP random movers (MovementType 1 + spawndist, 10 creatures: Ogre Henchman 48230 x3 dist 5, Defias Envoker 48418 x3 dist 5, Ogre/Goblin 48447 x3 dist 8, 48450 x1 dist 8): matched to our static spawn (<= 8 yd, same entry, MovementType 0, no path).
DROP TEMPORARY TABLE IF EXISTS world.dm176b_mover;
CREATE TEMPORARY TABLE world.dm176b_mover (cpp_n INT PRIMARY KEY, id INT, x FLOAT, y FLOAT, z FLOAT, dist FLOAT, our_guid BIGINT NULL);
INSERT INTO world.dm176b_mover (cpp_n, id, x, y, z, dist) VALUES
(44, 48230, -115.373, -431.387, 54.9933, 5.0),
(91, 48418, -304.667, -587.62, 47.665, 5.0),
(118, 48230, -135.946, -405.498, 58.1496, 5.0),
(121, 48230, -97.5538, -398.875, 58.4307, 5.0),
(160, 48418, -289.589, -562.243, 49.0151, 5.0),
(165, 48418, -283.961, -595.05, 49.7824, 5.0),
(198, 48450, -4.68842, -746.402, 8.80825, 8.0),
(229, 48447, -102.604, -720.311, 8.58634, 8.0),
(270, 48447, -92.6043, -693.693, 8.39226, 8.0),
(280, 48447, -0.889659, -757.723, 9.19812, 8.0);
UPDATE world.dm176b_mover m SET m.our_guid = (SELECT c.guid FROM world.creature c WHERE c.map = 36 AND c.id = m.id AND c.MovementType = 0
    AND NOT EXISTS (SELECT 1 FROM world.creature_addon a WHERE a.guid = c.guid AND a.path_id <> 0)
    AND POW(c.position_x - m.x, 2) + POW(c.position_y - m.y, 2) + POW(c.position_z - m.z, 2) <= 64
    ORDER BY POW(c.position_x - m.x, 2) + POW(c.position_y - m.y, 2) + POW(c.position_z - m.z, 2) LIMIT 1);
CREATE TABLE IF NOT EXISTS world.bak_dm176b_movers (guid BIGINT PRIMARY KEY, MovementType TINYINT, spawndist FLOAT);
INSERT IGNORE INTO world.bak_dm176b_movers (guid, MovementType, spawndist) SELECT c.guid, c.MovementType, c.spawndist FROM world.creature c JOIN world.dm176b_mover m ON m.our_guid = c.guid;
UPDATE world.creature c JOIN world.dm176b_mover m ON m.our_guid = c.guid SET c.MovementType = 1, c.spawndist = m.dist;
