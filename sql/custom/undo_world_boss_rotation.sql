-- Undo fix_world_boss_rotation.sql (the old end of the rotation)
UPDATE world.game_event SET end_time = '2020-01-01 02:00:00' WHERE eventEntry IN (102, 103, 104);
