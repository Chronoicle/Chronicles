-- Undo fix_neltharions_lair_13_4_bosses_drummers.sql (Refs #13): immunity masks and drummer positions from the backup tables
UPDATE world.creature_template ct JOIN world.bak_nl_13_4_template b ON b.entry = ct.entry SET ct.mechanic_immune_mask = b.mechanic_immune_mask;
UPDATE world.creature c JOIN world.bak_nl_13_4_drummers b ON b.guid = c.guid SET c.position_x = b.position_x, c.position_y = b.position_y, c.position_z = b.position_z, c.orientation = b.orientation;
DROP TABLE world.bak_nl_13_4_template;
DROP TABLE world.bak_nl_13_4_drummers;
