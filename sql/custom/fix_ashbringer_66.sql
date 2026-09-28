-- #66 (Claude): picking up the Ashbringer (GO 247318, Ret artifact scenario) never gave the item. The chest has no loot
-- (Data1 = 0, sniffed), the item comes from 180850 -> 199827 "Retrieving the Ashbringer" (CREATE_ITEM_2 without item,
-- so it rolls spell_loot_template 199827, which had no row). Undo: undo_ashbringer_66.sql
DELETE FROM world.spell_loot_template WHERE Entry = 199827;
INSERT INTO world.spell_loot_template (Entry, Item, Currency, Reference, Chance, QuestRequired, LootMode, GroupId, MinCount, MaxCount, Comment)
VALUES (199827, 120978, 0, 0, 100, 0, 1, 0, 1, 1, 'Retrieving the Ashbringer - The Ashbringer');
