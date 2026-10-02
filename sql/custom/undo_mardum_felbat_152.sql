-- Undo for fix_mardum_felbat_152.sql (#152 Mardum): restores the value from before the fix, 2026-10-02.
UPDATE world.waypoint_data_script SET move_type = 1 WHERE id = 10267121 AND point = 10 AND move_type = 3;
