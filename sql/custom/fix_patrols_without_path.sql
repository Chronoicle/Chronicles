-- Claude (dev-owner) 2026-10-04, owner request: 21,710 creatures had MovementType 2 (waypoint) but no path, so they stood.
-- Source for real data: TrinityCore TDB 735.00 (imported as world.tdb735_creature / _creature_addon / _waypoint_data, scratch).
--  A) our spawn matched to a TDB spawn of the same entry on the same map within 10 yd (566):
--     TDB has a path -> copy it (new waypoint ids); TDB wanders -> MovementType 1 + its spawndist; TDB stands -> MovementType 0.
--  B) no match, open world, not an NPC (npcflag), vehicle, C++ script, SmartAI waypoint user, emote / stand state:
--     MovementType 1, 5 yd random wander (no path data exists for them anywhere).
--  C) all others (dungeon/raid trash, NPCs, vehicles, scripted, emoting): MovementType 0 (they stood already; no change in game).
-- Apply once before a restart; undo restores MovementType / spawndist / addon path_id and deletes the new waypoint rows.

DROP TEMPORARY TABLE IF EXISTS world.pp_ours;
CREATE TEMPORARY TABLE world.pp_ours (guid BIGINT PRIMARY KEY, id INT, map INT, x FLOAT, y FLOAT, z FLOAT, KEY (id, map))
SELECT c.guid, c.id, c.map, c.position_x x, c.position_y y, c.position_z z
FROM world.creature c LEFT JOIN world.creature_addon a ON a.guid = c.guid LEFT JOIN world.creature_template_addon ta ON ta.entry = c.id
WHERE c.MovementType = 2 AND IFNULL(a.path_id, 0) = 0 AND IFNULL(ta.path_id, 0) = 0;

-- backup (real table, used by the undo)
CREATE TABLE IF NOT EXISTS world.bak_patrols_without_path (guid BIGINT PRIMARY KEY, MovementType TINYINT, spawndist FLOAT, had_addon TINYINT, path_id INT, new_path INT DEFAULT 0);
INSERT IGNORE INTO world.bak_patrols_without_path (guid, MovementType, spawndist, had_addon, path_id)
SELECT c.guid, c.MovementType, c.spawndist, (a.guid IS NOT NULL), IFNULL(a.path_id, 0)
FROM world.creature c JOIN world.pp_ours o ON o.guid = c.guid LEFT JOIN world.creature_addon a ON a.guid = c.guid;

-- A) nearest TDB spawn of the same entry within 10 yd
DROP TEMPORARY TABLE IF EXISTS world.pp_match;
CREATE TEMPORARY TABLE world.pp_match (guid BIGINT PRIMARY KEY, tguid BIGINT, tmt INT, tdist FLOAT, tpath INT)
SELECT o.guid,
  SUBSTRING_INDEX(GROUP_CONCAT(t.guid ORDER BY POW(o.x - t.position_x, 2) + POW(o.y - t.position_y, 2)), ',', 1) + 0 tguid,
  0 tmt, 0 tdist, 0 tpath
FROM world.pp_ours o JOIN world.tdb735_creature t ON t.id = o.id AND t.map = o.map
WHERE POW(o.x - t.position_x, 2) + POW(o.y - t.position_y, 2) <= 100
GROUP BY o.guid;
UPDATE world.pp_match m JOIN world.tdb735_creature t ON t.guid = m.tguid LEFT JOIN world.tdb735_creature_addon ta ON ta.guid = t.guid
SET m.tmt = t.MovementType, m.tdist = t.spawndist, m.tpath = IFNULL(ta.path_id, 0);
UPDATE world.pp_match m SET m.tpath = 0 WHERE m.tpath <> 0 AND NOT EXISTS (SELECT 1 FROM world.tdb735_waypoint_data w WHERE w.id = m.tpath);

-- A1) copy TDB paths under new ids
SET @pp_base := (SELECT GREATEST(IFNULL(MAX(id), 0), 1) FROM world.waypoint_data) + 1000;
SET @pp_n := 0;
UPDATE world.bak_patrols_without_path b JOIN (SELECT guid FROM world.pp_match WHERE tpath > 0 ORDER BY guid) x ON x.guid = b.guid
SET b.new_path = (@pp_n := @pp_n + 1) + @pp_base;
INSERT INTO world.waypoint_data (id, point, position_x, position_y, position_z, orientation, delay, move_type, action, action_chance)
SELECT b.new_path, w.point, w.position_x, w.position_y, w.position_z, w.orientation, w.delay, w.move_type, w.action, w.action_chance
FROM world.bak_patrols_without_path b JOIN world.pp_match m ON m.guid = b.guid JOIN world.tdb735_waypoint_data w ON w.id = m.tpath
WHERE b.new_path > 0;
-- TDB waypoint actions point to TDB waypoint_scripts we do not have: drop those actions (dev-check)
UPDATE world.waypoint_data w JOIN world.bak_patrols_without_path b ON b.new_path = w.id LEFT JOIN world.waypoint_scripts s ON s.id = w.action
SET w.action = 0, w.action_chance = 100 WHERE b.new_path > 0 AND w.action <> 0 AND s.id IS NULL;
UPDATE world.creature_addon a JOIN world.bak_patrols_without_path b ON b.guid = a.guid SET a.path_id = b.new_path WHERE b.new_path > 0;
INSERT INTO world.creature_addon (guid, path_id) SELECT b.guid, b.new_path FROM world.bak_patrols_without_path b WHERE b.new_path > 0 AND b.had_addon = 0;
-- A2) TDB wanders / stands
UPDATE world.creature c JOIN world.pp_match m ON m.guid = c.guid SET c.MovementType = 1, c.spawndist = IF(m.tdist > 0, m.tdist, 5) WHERE m.tpath = 0 AND m.tmt = 1;
UPDATE world.creature c JOIN world.pp_match m ON m.guid = c.guid SET c.MovementType = 0 WHERE m.tpath = 0 AND m.tmt <> 1;

-- B) safe open-world creatures without any match: 5 yd random wander
UPDATE world.creature c
JOIN world.pp_ours o ON o.guid = c.guid
JOIN world.creature_template t ON t.entry = c.id
LEFT JOIN world.creature_addon a ON a.guid = c.guid
LEFT JOIN world.creature_template_addon ta ON ta.entry = c.id
SET c.MovementType = 1, c.spawndist = 5
WHERE c.MovementType = 2
  AND o.guid NOT IN (SELECT guid FROM world.pp_match)
  AND c.map NOT IN (SELECT map FROM world.instance_template)
  AND IF(c.npcflag, c.npcflag, t.npcflag) = 0 AND t.VehicleId = 0 AND t.ScriptName = ''
  AND IFNULL(a.bytes1, IFNULL(ta.bytes1, 0)) = 0 AND IFNULL(a.emote, IFNULL(ta.emote, 0)) = 0
  AND NOT EXISTS (SELECT 1 FROM world.smart_scripts s WHERE s.entryorguid = c.id AND s.source_type = 0 AND s.action_type IN (53, 113))
  -- dev-check: no triggers / invisible helpers (their visuals and area effects stay put), no formation members, no mounted,
  -- event or phased (quest scene) spawns, no guards at their post
  AND t.flags_extra & 128 = 0 AND IF(c.unit_flags, c.unit_flags, t.unit_flags) & 33554432 = 0
  AND 11686 NOT IN (SELECT w.Displayid1 FROM world.creature_template_wdb w WHERE w.Entry = c.id
                    UNION SELECT w.Displayid2 FROM world.creature_template_wdb w WHERE w.Entry = c.id)
  AND c.guid NOT IN (SELECT memberGUID FROM world.creature_formations) AND c.guid NOT IN (SELECT leaderGUID FROM world.creature_formations)
  AND IFNULL(a.mount, IFNULL(ta.mount, 0)) = 0
  AND c.guid NOT IN (SELECT guid FROM world.game_event_creature)
  AND TRIM(c.PhaseId) IN ('', '0') AND c.phaseMask IN (0, 1)
  AND c.id NOT IN (SELECT w.Entry FROM world.creature_template_wdb w WHERE w.Name1 LIKE '%Guard%' OR w.Name1 LIKE '%Sentinel%');

-- C) the rest stand (as before)
UPDATE world.creature c JOIN world.pp_ours o ON o.guid = c.guid SET c.MovementType = 0 WHERE c.MovementType = 2;
