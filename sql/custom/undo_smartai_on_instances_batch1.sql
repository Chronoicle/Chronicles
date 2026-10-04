-- Undo fix_smartai_on_instances_batch1.sql
UPDATE world.creature_template t JOIN world.bak_smartai_on_batch1 b ON b.entry = t.entry SET t.AIName = b.AIName;
