-- Druid class hall intro + Guardian artifact scenario (gabrielf03d, desktop team, Claude subagent 2026-10-01).
-- Undo: undo_druid_dreamgrove_guardian.sql
SET NAMES utf8mb4;

-- 1) "The Dreamway" (40644): Nature's Confluence (204542) worked anywhere in Moonglade. Its only DB2 casting requirement
--    is area group 2994 (= all of Moonglade), it has no spell focus, and its channel target (38 NEARBY_ENTRY) had no
--    condition, so it picked the caster. The ritual circle is at Stormrage Barrow Dens: Ritual Bunny 103421 (sniffed
--    at 7565.48 -2926.31 465.43, only in a later quest's phase here) marks its centre, Malfurion 366016 stands 7.8 yd
--    from it facing it. The Dreamway Portal (2) now stands on that centre, so the spell needs the caster within
--    10 yd of it (condition type 30 NEAR_GAMEOBJECT). Outside: "You can't do that yet".
DELETE FROM world.conditions WHERE SourceTypeOrReferenceId = 17 AND SourceGroup = 0 AND SourceEntry = 204542;
INSERT INTO world.conditions (SourceTypeOrReferenceId, SourceGroup, SourceEntry, SourceId, ElseGroup, ConditionTypeOrReference,
    ConditionTarget, ConditionValue1, ConditionValue2, ConditionValue3, NegativeCondition, ErrorTextId, ScriptName, Comment) VALUES
(17, 0, 204542, 0, 0, 30, 0, 248778, 10, 0, 0, 0, '', 'Nature''s Confluence - only inside the ritual circle (Dreamway Portal within 10 yd)');

-- 2) "To The Dreamgrove" (40645, "Go through the portal to the Dreamgrove"): nothing was spawned or wired for the portal
--    (no spawn of Dreamway Portal 248778, nothing casts any Teleport: The Dreamway/Dreamgrove spell, the Emerald Dreamway
--    map 1540 has no exit to the Dreamgrove). Spawn the portal on the circle centre for druids (phase 5931 = has done
--    41106, like Malfurion) and an eventobject (walk-in trigger, radius 3) that casts Teleport: The Dreamgrove 204983
--    (spell_target_position: Val'sharah 4128.25 7309.03, the Dreamgrove entrance) on players who have 40645 (in
--    progress or complete; its objectives all have Amount 0, so it is complete as soon as it is accepted). Retail went
--    through the Dreamway with Remulos first; that escort is not scripted here, so the portal goes straight to the grove.
DELETE FROM world.gameobject WHERE guid = 25683700;
INSERT INTO world.gameobject (guid, id, map, zoneId, areaId, spawnMask, phaseMask, PhaseId, position_x, position_y, position_z,
    orientation, rotation0, rotation1, rotation2, rotation3, spawntimesecs, animprogress, state, isActive, personal_size) VALUES
(25683700, 248778, 1, 493, 2363, 1, 1, '5931', 7565.48, -2926.31, 465.43, 2.4587, 0, 0, 0.94226, 0.33487, 180, 255, 1, 0, 0);

DELETE FROM world.eventobject_template WHERE entry = 2650;
INSERT INTO world.eventobject_template (entry, name, radius, SpellID, WorldSafeLocID, Flags, ScriptName) VALUES
(2650, 'Druid 40645 Dreamway Portal', 3, 0, 0, 0, 'SmartEventObject');
DELETE FROM world.eventobject WHERE guid = 410450;
INSERT INTO world.eventobject (guid, id, map, zoneId, areaId, spawnMask, phaseMask, PhaseId, position_x, position_y, position_z, orientation) VALUES
(410450, 2650, 1, 493, 2363, 1, 1, '', 7565.48, -2926.31, 465.43, 0);

DELETE FROM world.smart_scripts WHERE entryorguid = 2650 AND source_type = 13;
INSERT INTO world.smart_scripts (entryorguid, source_type, id, link, Difficulties, event_type, event_phase_mask, event_chance, event_flags,
    event_param1, event_param2, event_param3, event_param4, event_param5, action_type, action_param1, action_param2, action_param3,
    action_param4, action_param5, action_param6, target_type, target_param1, target_param2, target_param3, target_param4,
    target_x, target_y, target_z, target_o, comment) VALUES
(2650, 13, 0, 0, '', 89, 0, 100, 0, 0, 0, 0, 0, 0, 85, 204983, 2, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0,
 'Dreamway Portal - On enter - Invoker Cast Teleport: The Dreamgrove (40645)');
DELETE FROM world.conditions WHERE SourceTypeOrReferenceId = 22 AND SourceEntry = 2650 AND SourceId = 13;
INSERT INTO world.conditions (SourceTypeOrReferenceId, SourceGroup, SourceEntry, SourceId, ElseGroup, ConditionTypeOrReference,
    ConditionTarget, ConditionValue1, ConditionValue2, ConditionValue3, NegativeCondition, ErrorTextId, ScriptName, Comment) VALUES
(22, 1, 2650, 13, 0, 9, 0, 40645, 0, 0, 0, 0, '', 'Dreamway Portal - player has To The Dreamgrove'),
(22, 1, 2650, 13, 1, 28, 0, 40645, 0, 0, 0, 0, '', 'Dreamway Portal - player has To The Dreamgrove complete');

-- 3) "When Dreams Become Nightmares" (40647): scenario 990 Ursoc's Lair, map 1536 (zone 7974, no phase definitions).
-- 3a) Stage 2 "The Light In The Dark": killing Rothoof Shadowstalker 105294 sends data 1 1 to the closest Lea Stonepaw
--     105243 with the default 100 yd range. Lea follows the player at run speed 1.0 (she only starts when the player
--     comes within 5 yd of her), so a player who ran or used travel form left her more than 100 yd behind (her spawn
--     is 248 yd from the Shadowstalker) and the step never advanced. Reach her anywhere in the lair (300 yd); her
--     step credit to the closest player after the 40 s ritual gets the same range.
UPDATE world.smart_scripts SET target_param2 = 300
WHERE entryorguid = 105294 AND source_type = 0 AND id = 2 AND action_type = 45 AND target_type = 19 AND target_param2 = 0;
UPDATE world.smart_scripts SET target_param1 = 300
WHERE entryorguid = 105243 AND source_type = 0 AND id = 8 AND action_type = 205 AND target_type = 21 AND target_param1 = 100;

-- 3b) The Claws of Ursoc floating over the altar (creature 105331, guid 11296141) were in phase 6202, which nothing
--     activates in this zone, so they were invisible for the whole scenario ("Locate the Claws of Ursoc"). Malithar
--     still despawns them when he takes them (data 1 1) and summons them back on death.
UPDATE world.creature SET PhaseId = '' WHERE guid = 11296141 AND id = 105331 AND PhaseId = '6202';

-- 3c) The Shade of Xavius 101403 casts Tendrils of Agony 208727 on spawn: a 70 s stun (duration 565). He leaves ~35 s
--     later and sends Arch-Desecrator Malithar 101390 data 1 1; Malithar walks to the claws, turns into a bear and
--     attacks ~13 s after that, while the player still had ~22 s of stun left. End the stun when the Shade leaves.
DELETE FROM world.smart_scripts WHERE entryorguid = 101390 AND source_type = 0 AND id = 11;
INSERT INTO world.smart_scripts (entryorguid, source_type, id, link, Difficulties, event_type, event_phase_mask, event_chance, event_flags,
    event_param1, event_param2, event_param3, event_param4, event_param5, action_type, action_param1, action_param2, action_param3,
    action_param4, action_param5, action_param6, target_type, target_param1, target_param2, target_param3, target_param4,
    target_x, target_y, target_z, target_o, comment) VALUES
(101390, 0, 11, 0, '', 38, 0, 100, 1, 1, 1, 0, 0, 0, 28, 208727, 0, 0, 0, 0, 0, 18, 100, 0, 0, 0, 0, 0, 0, 0,
 'Update Data - Remove Tendrils of Agony stun from players (Shade of Xavius left)');

-- 3d) Stage 1 "Locate the Claws of Ursoc" sat on the Generic Bunny entry 59113 (OOC LOS 10 yd -> scenario criteria,
--     Stage 1 conversation 199821, data to the Spirit of Ursoc). 59113 is a shared bunny with ~200 spawns (Pandaria,
--     Broken Isles, Draenor, ...), so every friendly unit passing one of them got the Ursoc's Lair conversation once.
--     Move those three rows to the one bunny in the lair (guid 11296138); the entry keeps its Just Summoned row.
UPDATE world.smart_scripts SET entryorguid = -11296138 WHERE entryorguid = 59113 AND source_type = 0 AND id IN (0, 1, 2);
