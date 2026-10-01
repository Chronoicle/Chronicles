-- #150 A new Demon Hunter (Night Elf 4 / Blood Elf 10, class 12) appeared in Mardum after the intro movie facing north
-- (orientation 0) instead of east toward Kayn Sunfury and the Illidari at the cliff edge. Face them and the battlefield:
-- 4.761345 is the retail facing (TrinityCore 2016_07_23_00_world.sql has this same start spot with it).
-- Only affects characters created after the restart. Undo: undo_dh_start_facing_150.sql.
UPDATE world.playercreateinfo SET orientation = 4.761345 WHERE class = 12 AND race IN (4, 10) AND map = 1481;
