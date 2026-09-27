-- Priest class hall scenario (Netherlight Temple, map 1629), final stage (owner report 2026-09-27, Claude).
-- At 75% Balnazzar (111247) jumps back up to the ledge he spawned on, turns passive and summons the add waves and
-- Lothraxion (111343). Nothing brought him back down, so he stayed out of reach and "Defeat Balnazzar" could not be
-- finished. Now, 3 sec after Lothraxion engages, he jumps back to the arena floor next to Lothraxion and turns aggressive.
-- Undo: undo_priest_scenario_balnazzar.sql
DELETE FROM world.smart_scripts WHERE entryorguid = 111247 AND source_type = 9 AND id IN (35, 36);
INSERT INTO world.smart_scripts (entryorguid, source_type, id, link, Difficulties, event_type, event_phase_mask, event_chance, event_flags,
    event_param1, event_param2, event_param3, event_param4, event_param5, action_type, action_param1, action_param2, action_param3,
    action_param4, action_param5, action_param6, target_type, target_param1, target_param2, target_param3, target_param4,
    target_x, target_y, target_z, target_o, comment) VALUES
(111247, 9, 35, 0, '', 0, 0, 100, 1, 3000, 3000, 0, 0, 0, 97, 20, 20, 0, 0, 0, 0, 8, 0, 0, 0, 0, 1365.0, 1344.2, 176.82, 3.12, 'TS - JTP back to the floor'),
(111247, 9, 36, 0, '', 0, 0, 100, 1, 2000, 2000, 0, 0, 0, 8, 2, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'TS - SS aggressive');
