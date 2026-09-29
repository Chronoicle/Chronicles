-- Undo #94: put Data1 back to 0 for exactly the chests fix_chest_lootid_94.sql changed.
UPDATE world.gameobject_template g JOIN world.bak_chest_lootid_94 b ON b.entry = g.entry
SET g.Data1 = b.Data1 WHERE g.Data1 = g.entry;
DROP TABLE world.bak_chest_lootid_94;
