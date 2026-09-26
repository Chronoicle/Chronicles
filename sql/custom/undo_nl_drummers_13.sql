-- Undo fix_nl_drummers_13.sql (Refs #13)
UPDATE world.creature c JOIN world.bak_nl_drummers_13 b ON b.guid = c.guid SET c.position_x = b.position_x, c.position_y = b.position_y, c.position_z = b.position_z, c.orientation = b.orientation;
DROP TABLE world.bak_nl_drummers_13;
