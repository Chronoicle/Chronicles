-- Undo fix_ashbringer_66.sql (spell_loot_template had no rows for 199827 before)
DELETE FROM world.spell_loot_template WHERE Entry = 199827;
