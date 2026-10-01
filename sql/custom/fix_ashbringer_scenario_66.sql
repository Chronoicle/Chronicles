-- #66 (gabrielf03d, approved reporter; Claude desktop team subagent): Retribution artifact scenario "The Legend of the
-- Ashbringer" (scenario 775, map 1500) and the quest after it. Undo: sql/custom/undo_ashbringer_scenario_66.sql.
-- Live with a worldserver restart (no .reload) together with the broken_shore.cpp change (92907 flight path).

-- 1) Lost after the first fight: the scenario's 7 POIs (one per step) had no points, so the client got an empty area:
--    no map marker and a tracking arrow pointing nowhere near Jailer Zerus. One point per step, like the sniffed POIs
--    of the Demon Hunter scenario on the same map, placed on the spawn the step is about.
DELETE FROM world.scenario_poi_points WHERE criteriaTreeId IN (42546, 42487, 45099, 45146, 49027, 45270, 45278);
INSERT INTO world.scenario_poi_points (criteriaTreeId, id, idx, x, y) VALUES
(42546, 0, 0, -2490,   100), -- Sounding the Charge: the demon front in front of the start
(42487, 0, 0, -2508,    86), -- Crusaders' March: the demon portals
(45099, 0, 0, -2758,   -71), -- Holy Vengeance: Jailer Zerus (91672)
(45146, 0, 0, -2747,  -328), -- The Ashbringer (GO 247318)
(49027, 0, 0, -2747,  -326), -- One Final Blessing: Balnazzar's control, at the Ashbringer
(45270, 0, 0, -2745,  -331), -- Balnazzar the Risen (90981)
(45278, 0, 0, -2749,   -77); -- The Fate of the Highlord: Tirion (92676)
--    The quest's own marker in the scenario was wrong too: The Search for the Highlord (38376) has an old 7.0 POI on
--    map 1500 (BlobIndex 1, turn-in) that shares Idx1 3 with the Light's Hope "Fly to the Broken Shore" POI (the
--    broken quest_poi merge), so inside the scenario it pointed at Light's Hope's coordinates. It gets its own Idx1
--    and a point at the scenario's turn-in, Tyrosus (91144) at Tirion.
UPDATE world.quest_poi SET Idx1 = 7 WHERE QuestID = 38376 AND BlobIndex = 1 AND Idx1 = 3 AND MapID = 1500;
DELETE FROM world.quest_poi_points WHERE QuestID = 38376 AND Idx1 = 7;
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES (38376, 7, 0, -2754, -85, 26972);

-- 2) Two "We Meet at Light's Hope" at the scenario's Tyrosus (91144). 42811 is the scenario version (its text follows
--    Tirion's death, only the optional flight to Light's Hope), 38576 the Dalaran/Holy/Protection one (optional portal
--    to Dalaran Crater). 42811 had no prerequisite, so it showed before the Ashbringer quest was turned in.
--    - 42811 needs The Search for the Highlord (38376) turned in.
--    - 38576 is not offered inside the scenario map (its starter row at 91144 stays, only hidden there).
--    - the three versions share one exclusive group, so holding one hides the others (e.g. 38576 at Light's Hope's
--      Tyrosus 90259 after taking 42811). A United Force (38566) accepts any of them (positive group).
UPDATE world.quest_template_addon SET PrevQuestID = 38376 WHERE ID = 42811 AND PrevQuestID = 0;
UPDATE world.quest_template_addon SET ExclusiveGroup = 38576 WHERE ID IN (38576, 42811, 42812) AND ExclusiveGroup = 0;
DELETE FROM world.conditions WHERE SourceTypeOrReferenceId = 19 AND SourceEntry = 38576 AND ConditionTypeOrReference = 22 AND ConditionValue1 = 1500;
INSERT INTO world.conditions (SourceTypeOrReferenceId, SourceGroup, SourceEntry, SourceId, ElseGroup, ConditionTypeOrReference, ConditionTarget, ConditionValue1, ConditionValue2, ConditionValue3, NegativeCondition, ErrorTextId, ScriptName, Comment)
VALUES (19, 0, 38576, 0, 0, 22, 0, 1500, 0, 0, 1, 0, '', 'We Meet at Light''s Hope (38576) not in the Ashbringer scenario: 42811 is offered there (#66)');

-- 3) Nothing to fly back on. The client data has the way out: Argent Hippogryph 91145 (spellclick 180977 "Fly to
--    Light's Hope Sanctum", already in npc_spellclick_spells) summons the ridden hippogryph 92907, the mirror of the way
--    in (90384 -> 183677 -> 92940). 91145 was never spawned and 92907 had no script. Now: 91145 next to Tirion, where
--    Tyrosus ends up, visible from the last step on (phase 6181, the same as that Tyrosus); 92907 uses the way-in
--    script, flies path 9290700 up and away, gives the "Fly to Light's Hope Chapel" credit and lands the player at
--    Light's Hope Chapel next to the hippogryph that flew them out (broken_shore.cpp).
UPDATE world.creature_template SET ScriptName = 'npc_bs_argent_hippogryph' WHERE entry = 92907 AND ScriptName = '';
DELETE FROM world.waypoint_data_script WHERE id = 9290700;
INSERT INTO world.waypoint_data_script (id, point, position_x, position_y, position_z, orientation, delay, move_type, speed, action, action_chance) VALUES
(9290700, 1, -2740, -90,  60, 0, 0, 1, 20, 0, 100),
(9290700, 2, -2715, -60,  80, 0, 0, 1, 20, 0, 100),
(9290700, 3, -2680, -20, 100, 0, 0, 1, 20, 0, 100),
(9290700, 4, -2640,  20, 115, 0, 0, 1, 20, 0, 100),
(9290700, 5, -2600,  60, 125, 0, 0, 1, 20, 0, 100);
DELETE FROM world.creature WHERE id = 91145 AND map = 1500;
INSERT INTO world.creature (guid, id, map, zoneId, areaId, spawnMask, phaseMask, PhaseId, modelid, equipment_id, position_x, position_y, position_z, orientation, spawntimesecs, spawndist, currentwaypoint, curhealth, curmana, MovementType, npcflag, npcflag2, unit_flags, dynamicflags, AiID, MovementID, MeleeID, isActive, skipClone, personal_size, isTeemingSpawn, unit_flags3)
SELECT MAX(guid) + 1, 91145, 1500, 7796, 7798, 4096, 2, '6181', 0, 0, -2746.5, -97.0, 46.8, 1.70, 604800, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 FROM world.creature;
