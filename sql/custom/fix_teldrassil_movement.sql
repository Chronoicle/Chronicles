-- Teldrassil (zone 141), Shadowglen (6450) and Darnassus (1657): wildlife and camp mobs stand still (report by tyrvana,
-- desktop team 2026-09-29). Undo: undo_teldrassil_movement.sql (uses the backup table below). Live after a restart.
--
-- Cause: the spawns came in with MovementType 0 / spawndist 0 (checked against the original LegionCore dump
-- LegionCore_world_735.26972_2024_10_23.sql: same values, not changed by us), although creature_template.MovementType
-- of the same entries is 1 (random). The spawn value wins (Creature::LoadCreatureFromDB), so owls, nightsabers,
-- webwood spiders, timberlings, furbolgs, harpies, sprites and the Darnassus squirrels/toads/wisps never move. Only
-- Deer, Fawn, Young Nightsaber, Small Frog and Spider had random movement (spawndist 5), hence "only Shadowglen works".
--
-- A) template says random, spawn says idle: MovementType 1, spawndist 5 (the value the working Teldrassil spawns use,
--    and the most common one for random spawns in this DB). Darnassus: critters only (creature type 8), the city NPCs
--    stay where they are. Left out: Ancient Protector 2041 (guard), anything with npcflags, a creature_addon row, a
--    stand state / emote / path in creature_template_addon, a formation or a game event.
-- B) ambient critters whose template says idle but which roam in other zones of this DB (Elfin Rabbit 49728,
--    Red-Tailed Chipmunk 49778, Forest Moth 49842): MovementType 1, spawndist 3 (their usual value elsewhere).
-- Not done: patrol paths (Darnassus sentinels etc.) need waypoint data we do not have.
CREATE TABLE world.bak_teldrassil_movement (
  guid BIGINT UNSIGNED NOT NULL PRIMARY KEY,
  MovementType TINYINT UNSIGNED NOT NULL,
  spawndist FLOAT NOT NULL,
  new_spawndist FLOAT NOT NULL
);

INSERT INTO world.bak_teldrassil_movement (guid, MovementType, spawndist, new_spawndist)
SELECT c.guid, c.MovementType, c.spawndist, 5 FROM world.creature c
JOIN world.creature_template t ON t.entry = c.id
LEFT JOIN world.creature_template_wdb w ON w.Entry = c.id
LEFT JOIN world.creature_template_addon ta ON ta.entry = c.id
WHERE c.map = 1 AND c.zoneId IN (141, 6450, 1657) AND c.MovementType = 0 AND c.spawndist = 0
  AND t.MovementType = 1
  AND (c.zoneId <> 1657 OR w.Type = 8)
  AND c.id <> 2041
  AND t.npcflag = 0 AND t.npcflag2 = 0 AND c.npcflag = 0 AND c.npcflag2 = 0
  AND IFNULL(ta.path_id, 0) = 0 AND (IFNULL(ta.bytes1, 0) & 0xFF) = 0 AND IFNULL(ta.emote, 0) = 0
  AND NOT EXISTS (SELECT 1 FROM world.creature_addon a WHERE a.guid = c.guid)
  AND NOT EXISTS (SELECT 1 FROM world.creature_formations f WHERE c.guid IN (f.leaderGUID, f.memberGUID))
  AND NOT EXISTS (SELECT 1 FROM world.game_event_creature g WHERE g.guid = c.guid);

INSERT INTO world.bak_teldrassil_movement (guid, MovementType, spawndist, new_spawndist)
SELECT c.guid, c.MovementType, c.spawndist, 3 FROM world.creature c
WHERE c.map = 1 AND c.zoneId IN (141, 6450, 1657) AND c.MovementType = 0 AND c.spawndist = 0
  AND c.id IN (49728, 49778, 49842)
  AND NOT EXISTS (SELECT 1 FROM world.creature_addon a WHERE a.guid = c.guid)
  AND NOT EXISTS (SELECT 1 FROM world.creature_formations f WHERE c.guid IN (f.leaderGUID, f.memberGUID))
  AND NOT EXISTS (SELECT 1 FROM world.game_event_creature g WHERE g.guid = c.guid);

UPDATE world.creature c JOIN world.bak_teldrassil_movement b ON b.guid = c.guid
SET c.MovementType = 1, c.spawndist = b.new_spawndist;
