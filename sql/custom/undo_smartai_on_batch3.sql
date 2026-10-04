-- Undo fix_smartai_on_batch3.sql
UPDATE world.creature_template t JOIN world.bak_smartai_on_batch3 b ON b.entry = t.entry SET t.AIName = b.AIName;
