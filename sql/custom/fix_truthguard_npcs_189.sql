-- Truthguard chain (#189, gabrielf03d). help-helper (Claude, Pro) 2026-10-06. DRAFT, NOT RUN: run the diagnostics first. Apply right before a restart (no .reload).
-- DIAGNOSTIC (read-only):
--   SELECT guid, id, map, PhaseId, phaseMask, position_x, position_y, position_z, orientation FROM world.creature WHERE id IN (105724, 105727, 105776, 105777, 105691) OR (map = 571 AND ABS(position_x + 52) < 40 AND ABS(position_y + 4832) < 40);
--   SELECT entry, name, npcflag, AIName, ScriptName FROM world.creature_template WHERE entry IN (105724, 105727, 105776, 105777);
--   SELECT guid, id, map, position_x, position_y, position_z, phaseMask, PhaseId FROM world.gameobject WHERE id IN (249044, 249045, 251288);   -- the 3 graves (wowhead: (-100,-4953), (-128,-5044), (-193,-5158) in Howling Fjord)
--   SELECT * FROM world.smart_scripts WHERE entryorguid IN (105724, 105727) AND source_type = 0;
--   SELECT * FROM world.waypoint_data WHERE id IN (10588600, 10620300);   -- the hippogryph paths of the Shrine scenario (entry * 100): empty/short = the "teleports at once" report

-- 1) To Northrend: the two NPCs at Shield Hill are Orik Trueheart 105724 (ender, flag 2) and Tahu Sagewind 105727 (wowhead: both at map percent (56.8, 78.6) of Howling Fjord = about (-52, -4832),
--    the quest POI blob (-55, -4837)). Tahu is added NEXT to Orik's own spawn row (same z/phase, +1.5 yd) when no 105727 spawn exists; if Orik's row itself is missing nothing is inserted
--    (then the positions cannot be sourced: ask for a sniff / take the POI point and the ground z in game).
CREATE TABLE IF NOT EXISTS world.bak_truthguard189 (name VARCHAR(20) PRIMARY KEY, val BIGINT NOT NULL);
SET @TG189 := (SELECT MAX(guid) FROM world.creature);
INSERT IGNORE INTO world.bak_truthguard189 (name, val) VALUES ('base', @TG189);
INSERT INTO world.creature (guid, id, map, zoneId, areaId, spawnMask, phaseMask, PhaseId, modelid, equipment_id, position_x, position_y, position_z, orientation, spawntimesecs, spawndist, currentwaypoint, curhealth, curmana, MovementType, npcflag, npcflag2, unit_flags, dynamicflags)
SELECT @TG189 := @TG189 + 1, 105727, o.map, o.zoneId, o.areaId, o.spawnMask, o.phaseMask, o.PhaseId, 0, 0, o.position_x, o.position_y + 1.5, o.position_z, o.orientation, o.spawntimesecs, 0, 0, 0, 0, 0, 0, 0, 0, 0
FROM world.creature o WHERE o.id = 105724 AND o.map = 571 AND NOT EXISTS (SELECT 1 FROM world.creature t WHERE t.id = 105727) LIMIT 1;

-- 2) credit "Found Orik" 105726 when a player with the quest comes within 25 yd of Orik at Shield Hill (retail: conversation/area; no source here)
INSERT INTO world.smart_scripts (entryorguid, source_type, id, link, Difficulties, event_type, event_phase_mask, event_chance, event_flags, event_param1, event_param2, event_param3, event_param4, event_param5,
 action_type, action_param1, action_param2, action_param3, action_param4, action_param5, action_param6, target_type, target_param1, target_param2, target_param3, target_param4, target_x, target_y, target_z, target_o, comment)
SELECT 105724, 0, x.nid, 0, '', 10, 0, 100, 0, 0, 25, 5000, 5000, 0, 33, 105726, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Orik Trueheart - OOC LOS 25 yd - Quest Credit "Found Orik" (#189)'
FROM (SELECT IFNULL(MAX(id), -1) + 1 AS nid FROM world.smart_scripts WHERE entryorguid = 105724 AND source_type = 0) x
WHERE NOT EXISTS (SELECT 1 FROM world.smart_scripts s WHERE s.entryorguid = 105724 AND s.source_type = 0 AND s.action_type = 33 AND s.action_param1 = 105726);
UPDATE world.creature_template SET AIName = 'SmartAI' WHERE entry = 105724 AND AIName = '' AND ScriptName = '';

-- 3) The End of the Saga: script on the three gravestones (C++ go_sr_gravestone of PR helper/189-truthguard)
UPDATE world.gameobject_template SET ScriptName = 'go_sr_gravestone' WHERE entry IN (249044, 249045, 251288) AND ScriptName = '';
