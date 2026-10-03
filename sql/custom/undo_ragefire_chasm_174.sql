-- Undo fix_ragefire_chasm_174.sql
UPDATE world.creature_template SET unit_flags = unit_flags & ~256 WHERE entry IN (61404, 61716, 61724);
UPDATE world.creature_template_wdb SET Displayid1 = 169, Displayid2 = 11686 WHERE Entry = 61413;
