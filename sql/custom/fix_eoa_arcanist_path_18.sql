-- Eye of Azshara, Lady Hatecoil: the 4th Hatecoil Arcanist (97171) the boss summons at (-3652.25, 4623.6, 15.37)
-- (boss_lady_hatecoil.cpp SummonNagas, nagPos[3]) starts MovePath(9717100, repeat) but the path had no waypoints, so it
-- stood still (Refs #18, Claude 2026-09-29). No retail route is available: this is a small walking loop through the
-- ground spawn points of the Saltsea Droplets (97172) around it (11657089, 11657090, 11657093), back to its spawn,
-- so every point is a known standable position. Other three Arcanists stay stationary as scripted.
-- Undo: undo_eoa_arcanist_path_18.sql (path 9717100 had 0 rows before).
DELETE FROM world.waypoint_data WHERE id = 9717100;
INSERT INTO world.waypoint_data (id, point, position_x, position_y, position_z, orientation, delay, move_type, action_chance) VALUES
(9717100, 1, -3652.25, 4623.60, 15.37, 0, 3000, 0, 100),
(9717100, 2, -3644.04, 4634.02, 12.19, 0,    0, 0, 100),
(9717100, 3, -3649.31, 4646.35, 15.76, 0, 3000, 0, 100),
(9717100, 4, -3655.80, 4634.24, 16.80, 0,    0, 0, 100);
