-- Undo fix_neltharions_lair_13_4_crawler.sql (Refs #4): Vileshard Crawler health and damage from the backup table
UPDATE world.creature_template ct JOIN world.bak_nl_13_4_crawler b ON b.entry = ct.entry SET ct.dmg_multiplier = b.dmg_multiplier;
UPDATE world.creature_template_wdb w JOIN world.bak_nl_13_4_crawler b ON b.entry = w.Entry SET w.HpMulti = b.HpMulti;
DROP TABLE world.bak_nl_13_4_crawler;
