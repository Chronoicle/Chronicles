-- Undo fix_smartai_on_batch2.sql
UPDATE world.creature_template t JOIN world.bak_smartai_on_batch2 k ON k.entry = t.entry SET t.AIName = k.AIName;
