-- The Arcway (map 1516), issue #40 (reporter gabrielf03d). Desktop team (Claude subagent) 2026-09-30.
-- Apply right before a worldserver restart (no .reload). Undo: undo_vault_arcway_39_40_arcway.sql (before-state checked on live).

-- 1) Forgotten Spirit 113699 (reporter: "should have more casts of Torment") had no AI. The default AI treats Torment 226269
--    (2.5 s cast, 60 yd, shadow damage + stacking -10% healing for 12 s) as an area spell with a 15 s cooldown and cast it
--    every 15-30 s, so the healing debuff ran out between casts and never stacked as its spell text says. SmartAI: Torment
--    every 8-10 s on Mythic / Mythic Keystone (the only difficulties with the spell in its list; Normal/Heroic stay melee
--    only, as now). The default AI also self-cast Celerity Zone 211064, the haste buff of standing in a Nightborne
--    Reclaimer's field, not a spirit spell: dropped. Patrol paths are unchanged (SmartAI keeps creature_addon paths).
--    ponytail: 4-6 s / 8-10 s timers are estimates (no retail log); tune from one.
UPDATE world.creature_template SET AIName = 'SmartAI' WHERE entry = 113699 AND AIName = '' AND ScriptName = '';
DELETE FROM world.smart_scripts WHERE entryorguid = 113699 AND source_type = 0;
INSERT INTO world.smart_scripts (entryorguid, source_type, id, link, Difficulties, event_type, event_phase_mask, event_chance,
 event_flags, event_param1, event_param2, event_param3, event_param4, event_param5, action_type, action_param1, action_param2,
 action_param3, action_param4, action_param5, action_param6, target_type, target_param1, target_param2, target_param3,
 target_param4, target_x, target_y, target_z, target_o, comment) VALUES
(113699, 0, 0, 0, '8,23', 0, 0, 100, 0, 4000, 6000, 8000, 10000, 0, 11, 226269, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Forgotten Spirit - IC - cast Torment (Mythic) #40');

-- 2) Withered Manawraiths 11566143 + 11566141 (the pair at ~3280, 4900) walked two separate 2-point paths in opposite
--    directions, so they never moved together. 11566141 now follows 11566143 in a formation (same values as the
--    11566146/11566145 manawraith pair); its own path is switched off (waypoint_data 12909877 kept, unused).
DELETE FROM world.creature_formations WHERE leaderGUID = 11566143 OR memberGUID IN (11566143, 11566141);
INSERT INTO world.creature_formations (leaderGUID, memberGUID, dist, angle, groupAI) VALUES
(11566143, 11566143, 0, 0, 515),
(11566143, 11566141, 3, 90, 515);
UPDATE world.creature SET MovementType = 0 WHERE guid = 11566141 AND id = 105952;
UPDATE world.creature_addon SET path_id = 0 WHERE guid = 11566141;
