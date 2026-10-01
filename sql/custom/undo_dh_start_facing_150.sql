-- Undo for fix_dh_start_facing_150.sql: the value from before the fix, 2026-10-02.
UPDATE world.playercreateinfo SET orientation = 0 WHERE class = 12 AND race IN (4, 10) AND map = 1481;
