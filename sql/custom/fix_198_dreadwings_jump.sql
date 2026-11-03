-- #198 item 2 (Claude dev-helper 2026-11-03): the two Dreadwings 119930 (guids 387111, 387146) in the right-hand room never
-- leave it: their only SmartAI row casts 239558 in combat. Now they jump out into the hallway when they first see a
-- hostile player within 30 yd (out of combat, once) and attack that player.
-- The landing point (-526.0, 2392.0, 336.6) is an ESTIMATE (30 yd north of the pair toward the curved hallway), NOT retail:
-- check it in game / on the navmesh before keeping it.
DELETE FROM world.smart_scripts WHERE entryorguid = 119930 AND source_type = 0 AND id IN (10, 11);
INSERT INTO world.smart_scripts (entryorguid, source_type, id, link, Difficulties, event_type, event_phase_mask, event_chance,
 event_flags, event_param1, event_param2, event_param3, event_param4, event_param5, action_type, action_param1, action_param2,
 action_param3, action_param4, action_param5, action_param6, target_type, target_param1, target_param2, target_param3,
 target_param4, target_x, target_y, target_z, target_o, comment) VALUES
(119930, 0, 10, 11, '', 10, 0, 100, 1, 0, 30, 0, 0, 0, 97, 14, 12, 0, 0, 0, 0, 8, 0, 0, 0, 0, -526.0, 2392.0, 336.6, 0, 'Dreadwing: jump out into the hallway when a player is seen (#198, estimated landing)'),
(119930, 0, 11, 0, '', 61, 0, 100, 0, 0, 0, 0, 0, 0, 49, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Dreadwing: attack the player (#198)');
