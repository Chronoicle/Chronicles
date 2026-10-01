-- Undo fix_legion_rotations.sql (all these rows ended 2020-01-01 02:00:00 before)
UPDATE world.game_event SET end_time = '2020-01-01 02:00:00' WHERE eventEntry BETWEEN 105 AND 137 OR eventEntry BETWEEN 155 AND 167;
