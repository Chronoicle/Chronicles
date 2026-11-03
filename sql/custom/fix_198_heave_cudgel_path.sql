-- #198 item 6 (Claude dev-helper 2026-11-03): Heave Cudgel 121710 is teleported to (-573.15,2526.32,439.68) and walks
-- path 387381 (boss_thrashbite JustSummoned), which had 0 points, so it stayed at the entrance.
-- ESTIMATE, not retail: a sweep around the room (box x -587.5..-469.8, y 2478.7..2559.8, floor ~439) at speed 4 (~48 yd in its 12 s).
INSERT INTO world.waypoint_data (id, point, position_x, position_y, position_z, orientation, delay, delay_chance, move_type, speed, action, action_chance, entry, wpguid) VALUES
(387381, 1, -555.0, 2543.0, 439.5, 0, 0, 0, 1, 0, 0, 100, 121710, 0),
(387381, 2, -530.0, 2550.0, 439.5, 0, 0, 0, 1, 0, 0, 100, 121710, 0),
(387381, 3, -505.0, 2540.0, 439.5, 0, 0, 0, 1, 0, 0, 100, 121710, 0),
(387381, 4, -490.0, 2518.0, 439.5, 0, 0, 0, 1, 0, 0, 100, 121710, 0),
(387381, 5, -500.0, 2495.0, 439.5, 0, 0, 0, 1, 0, 0, 100, 121710, 0),
(387381, 6, -525.0, 2486.0, 439.5, 0, 0, 0, 1, 0, 0, 100, 121710, 0),
(387381, 7, -552.0, 2494.0, 439.5, 0, 0, 0, 1, 0, 0, 100, 121710, 0);
