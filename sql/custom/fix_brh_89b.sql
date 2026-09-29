-- Black Rook Hold #89 round 2 (Pi team Claude 2026-09-29). Undo: undo_brh_89b.sql
-- Goes with the C++ change (Illysanna evade, tricksters, bat event gate, Guile images).

-- 1) Wyrmtongue Trickster retreat yell (broadcast 120215), said once by one of the pair at the top of the second
--    staircase when the group reaches the top (npc_brh_wyrmtongue_trickster Talk(1)). Before: no group 1.
INSERT INTO world.creature_text (CreatureID, GroupID, ID, Text, Type, Language, Probability, Emote, Duration, Sound, BroadcastTextID, MinTimer, MaxTimer, SpellID, comment)
VALUES (98900, 1, 0, 'Ahh! They coming! RUN!', 14, 0, 100, 0, 0, 0, 120215, 0, 0, 0, 'Wyrmtongue Trickster - retreat (#89)');

-- 2) Soul-Torn Champion + 2 Risen Archers on the ledge before Illysanna (guids 11565649, 11565658, 11565659): hidden,
--    passive and unselectable until the event object at the bottom step (2607) sets data 1 1; then they appear and
--    jump to the platform (existing rows id 0). Their spawn points have no walkable ground (navmesh: nothing at z 89,
--    only 65.9 below / 185.8 roof above), which is why the champion showed on the roof. The jump rows now fire once
--    per life (0x101 = NOT_REPEATABLE | DONT_RESET) so a player crossing the step again mid-fight no longer re-jumps them.
UPDATE world.smart_scripts SET event_flags = 257 WHERE entryorguid IN (-11565649, -11565658, -11565659) AND source_type = 0 AND id = 0 AND event_type = 38 AND event_flags = 1;
INSERT INTO world.smart_scripts (entryorguid, source_type, id, link, Difficulties, event_type, event_phase_mask, event_chance, event_flags, event_param1, event_param2, event_param3, event_param4, event_param5, action_type, action_param1, action_param2, action_param3, action_param4, action_param5, action_param6, target_type, target_param1, target_param2, target_param3, target_param4, target_x, target_y, target_z, target_o, comment) VALUES
(-11565649, 0, 10, 0, '', 63, 0, 100, 0,   0, 0, 0, 0, 0, 47, 0, 0, 0, 0, 0, 0,        1, 0, 0, 0, 0, 0, 0, 0, 0, 'BRH #89, hidden until the bottom step'),
(-11565649, 0, 11, 0, '', 63, 0, 100, 0,   0, 0, 0, 0, 0,  8, 0, 0, 0, 0, 0, 0,        1, 0, 0, 0, 0, 0, 0, 0, 0, 'BRH #89, passive until the bottom step'),
(-11565649, 0, 12, 0, '', 63, 0, 100, 0,   0, 0, 0, 0, 0, 18, 33554688, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'BRH #89, not selectable + immune to pc until the bottom step'),
(-11565649, 0, 13, 0, '', 38, 0, 100, 257, 1, 1, 0, 0, 0, 47, 1, 0, 0, 0, 0, 0,        1, 0, 0, 0, 0, 0, 0, 0, 0, 'BRH #89, appear'),
(-11565649, 0, 14, 0, '', 38, 0, 100, 257, 1, 1, 0, 0, 0, 19, 33554688, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'BRH #89, attackable'),
(-11565649, 0, 15, 0, '', 38, 0, 100, 257, 1, 1, 0, 0, 0,  8, 2, 0, 0, 0, 0, 0,        1, 0, 0, 0, 0, 0, 0, 0, 0, 'BRH #89, aggressive'),
(-11565658, 0, 10, 0, '', 63, 0, 100, 0,   0, 0, 0, 0, 0, 47, 0, 0, 0, 0, 0, 0,        1, 0, 0, 0, 0, 0, 0, 0, 0, 'BRH #89, hidden until the bottom step'),
(-11565658, 0, 11, 0, '', 63, 0, 100, 0,   0, 0, 0, 0, 0,  8, 0, 0, 0, 0, 0, 0,        1, 0, 0, 0, 0, 0, 0, 0, 0, 'BRH #89, passive until the bottom step'),
(-11565658, 0, 12, 0, '', 63, 0, 100, 0,   0, 0, 0, 0, 0, 18, 33554688, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'BRH #89, not selectable + immune to pc until the bottom step'),
(-11565658, 0, 13, 0, '', 38, 0, 100, 257, 1, 1, 0, 0, 0, 47, 1, 0, 0, 0, 0, 0,        1, 0, 0, 0, 0, 0, 0, 0, 0, 'BRH #89, appear'),
(-11565658, 0, 14, 0, '', 38, 0, 100, 257, 1, 1, 0, 0, 0, 19, 33554688, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'BRH #89, attackable'),
(-11565658, 0, 15, 0, '', 38, 0, 100, 257, 1, 1, 0, 0, 0,  8, 2, 0, 0, 0, 0, 0,        1, 0, 0, 0, 0, 0, 0, 0, 0, 'BRH #89, aggressive'),
(-11565659, 0, 10, 0, '', 63, 0, 100, 0,   0, 0, 0, 0, 0, 47, 0, 0, 0, 0, 0, 0,        1, 0, 0, 0, 0, 0, 0, 0, 0, 'BRH #89, hidden until the bottom step'),
(-11565659, 0, 11, 0, '', 63, 0, 100, 0,   0, 0, 0, 0, 0,  8, 0, 0, 0, 0, 0, 0,        1, 0, 0, 0, 0, 0, 0, 0, 0, 'BRH #89, passive until the bottom step'),
(-11565659, 0, 12, 0, '', 63, 0, 100, 0,   0, 0, 0, 0, 0, 18, 33554688, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'BRH #89, not selectable + immune to pc until the bottom step'),
(-11565659, 0, 13, 0, '', 38, 0, 100, 257, 1, 1, 0, 0, 0, 47, 1, 0, 0, 0, 0, 0,        1, 0, 0, 0, 0, 0, 0, 0, 0, 'BRH #89, appear'),
(-11565659, 0, 14, 0, '', 38, 0, 100, 257, 1, 1, 0, 0, 0, 19, 33554688, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'BRH #89, attackable'),
(-11565659, 0, 15, 0, '', 38, 0, 100, 257, 1, 1, 0, 0, 0,  8, 2, 0, 0, 0, 0, 0,        1, 0, 0, 0, 0, 0, 0, 0, 0, 'BRH #89, aggressive');

-- 3) Fel bats before Smashspite: npc_brh_fel_bat walks path 10278100, which did not exist (bats idled at the gate).
--    Gate -> Felspite Dominators -> down the rampart (ground z from the navmesh), run.
INSERT INTO world.waypoint_data (id, point, position_x, position_y, position_z, orientation, delay, delay_chance, move_type, speed, action, action_chance, entry, wpguid) VALUES
(10278100, 1, 3230.58, 7338.00, 227.0, 0, 0, 0, 1, 0, 0, 100, 102781, 0),
(10278100, 2, 3215.00, 7345.00, 226.0, 0, 0, 0, 1, 0, 0, 100, 102781, 0),
(10278100, 3, 3200.43, 7352.45, 225.7, 0, 0, 0, 1, 0, 0, 100, 102781, 0);

-- 4) Risen Scout 14507227 + Risen Companion (dog) 14507226 after the first boss had two separate paths (12909861 /
--    12909860), so the dog ran off on its own: the dog now follows the scout in a formation.
--    Before: dog MovementType 2, creature_addon.path_id 12909860; no formation rows.
UPDATE world.creature SET MovementType = 0 WHERE guid = 14507226 AND MovementType = 2;
UPDATE world.creature_addon SET path_id = 0 WHERE guid = 14507226 AND path_id = 12909860;
INSERT INTO world.creature_formations (leaderGUID, memberGUID, dist, angle, groupAI) VALUES
(14507227, 14507227, 0, 0, 515),
(14507227, 14507226, 2, 90, 515);
