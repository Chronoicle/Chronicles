-- Desktop team (Claude subagent, 2026-09-30), gabrielf03d reports. Undo: undo_mm_scenario_still_alive_shadow_mania.sql
-- (Shadow Mania, eru.01: no change needed, the 2-target threshold matches the 7.3.5 talent data.)

-- 1) Marksmanship artifact scenario 972 (map 1489), stage 3 "Search for Your Allies" (criteria event 49592).
-- Ranger Orestes (100398) event 3 = OOC_LOS 5 yd, not repeatable, fired for ANY non-hostile unit. The two Felmaw
-- Devourers guarding him (369662/369663, faction 16 is not hostile to his faction 35) stand 3.5 yd away, so it fired
-- on them when they spawned, with no player near: the stage-3 credit went nowhere and the event never fired again.
-- Now it only fires for a player who is on stage 3 (step index 2).
DELETE FROM world.conditions WHERE SourceTypeOrReferenceId = 22 AND SourceGroup = 4 AND SourceEntry = 100398 AND SourceId = 0;
INSERT INTO world.conditions (SourceTypeOrReferenceId, SourceGroup, SourceEntry, SourceId, ElseGroup, ConditionTypeOrReference,
       ConditionTarget, ConditionValue1, ConditionValue2, ConditionValue3, NegativeCondition, ErrorTextId, ScriptName, Comment) VALUES
(22, 4, 100398, 0, 0, 31, 0, 4,   0, 0, 0, 0, '', 'Orestes stage-3 trigger: invoker must be a player'),
(22, 4, 100398, 0, 0, 44, 0, 972, 2, 0, 0, 0, '', 'Orestes stage-3 trigger: scenario 972 stage 3');

-- Stage 4: Mistress Torvis (100749) comes for the player once the Orestes/Torvis conversation starts (5 s in),
-- instead of waiting at her spawn.
UPDATE world.smart_scripts SET link = 5 WHERE entryorguid = 100398 AND source_type = 0 AND id = 4 AND link = 0;
DELETE FROM world.smart_scripts WHERE (entryorguid = 100398 AND source_type = 0 AND id = 5)
    OR (entryorguid = 100749 AND source_type = 0 AND id = 6) OR (entryorguid = 10074900 AND source_type = 9);
INSERT INTO world.smart_scripts (entryorguid, source_type, id, link, event_type, event_flags, event_param1, event_param2,
       action_type, action_param1, action_param2, action_param3, target_type, target_param1, target_param2, comment) VALUES
(100398,   0, 5, 0, 61, 0, 0,    0,    45, 2,        2, 0, 19, 100749, 100, 'Link - Send Data to Mistress Torvis (stage 4)'),
(100749,   0, 6, 0, 38, 1, 2,    2,    80, 10074900, 0, 0, 1,  0,      0,   'Data Set 2 2 - Run TS (stage 4)'),
(10074900, 9, 0, 0, 0,  1, 5000, 5000, 49, 0,        0, 0, 21, 100,    0,   'TS - Attack closest player');

-- Stage 4 -> 5: the credit 10 s after Torvis dies went to the closest player within 50 yd of Orestes; Torvis stands
-- 47 yd away, so a player still near her body could miss it. Same 100 yd as the other credits in this scenario.
UPDATE world.smart_scripts SET target_param1 = 100 WHERE entryorguid = 100398 AND source_type = 9 AND id = 0;

-- 2) Still Alive (37862): Stellagosa (107995) flies path 107995 (waypoint_data_script) with move_type 0 (walk) and no
-- speed, so the spline took the creature's current speed: she starts on the ground (gravity back on), so the first
-- leg ran at her walk speed (0.94 x 2.5 = 2.4 yd/s, ~26 s for 61 yd), the rest at flight speed 14 yd/s (~80 s).
-- Fixed 20 yd/s for the whole ~1100 yd ride (~55 s), still leaves room between her four voice lines.
UPDATE world.waypoint_data_script SET speed = 20 WHERE id = 107995;
