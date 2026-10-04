-- Claude (dev-owner) 2026-10-04, owner request (item 1, batch 1 = dungeons and raids).
-- 3,218 creature templates have SmartAI rows but AIName '' (and no ScriptName), so their SmartAI never runs (same bug as
-- Goblin Overseer / Mining Monkey in the Deadmines, #176). Batch 1: the 577 of them spawned in instance maps (59 dungeons
-- and raids, 5,399 spawns): mostly in-combat spell casts (timed, range, aggro, health %). The SmartAI loader still skips
-- invalid rows (DBErrors). Apply once, right before a restart.
CREATE TABLE IF NOT EXISTS world.bak_smartai_on_batch1 AS
SELECT DISTINCT t.entry, t.AIName FROM world.creature_template t
JOIN world.creature c ON c.id = t.entry
WHERE t.AIName = '' AND t.ScriptName = ''
  AND c.map IN (SELECT map FROM world.instance_template)
  AND EXISTS (SELECT 1 FROM world.smart_scripts s WHERE s.entryorguid = t.entry AND s.source_type = 0);
UPDATE world.creature_template t JOIN world.bak_smartai_on_batch1 b ON b.entry = t.entry SET t.AIName = 'SmartAI' WHERE t.AIName = '';
