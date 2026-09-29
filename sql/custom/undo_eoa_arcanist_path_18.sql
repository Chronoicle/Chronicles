-- Undo fix_eoa_arcanist_path_18.sql (Refs #18): path 9717100 had no rows before.
DELETE FROM world.waypoint_data WHERE id = 9717100;
