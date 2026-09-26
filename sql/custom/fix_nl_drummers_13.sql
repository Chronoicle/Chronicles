-- Neltharion's Lair: Understone Drummers 92610 spawned ~26 yd from their Drums of War 92387 and only walked over in
-- combat (Refs #13, Claude 2026-09-27). Place them 3 yd from their drum, facing it. Backup: world.bak_nl_drummers_13
DROP TABLE IF EXISTS world.bak_nl_drummers_13;
CREATE TABLE world.bak_nl_drummers_13 AS SELECT guid, position_x, position_y, position_z, orientation FROM world.creature WHERE guid IN (11566198, 11566199);
UPDATE world.creature SET position_x = 2570.70, position_y = 1514.82, position_z = -54.31, orientation = 0.70 WHERE guid = 11566198 AND id = 92610;
UPDATE world.creature SET position_x = 2658.75, position_y = 1611.61, position_z = -54.54, orientation = 1.01 WHERE guid = 11566199 AND id = 92610;
