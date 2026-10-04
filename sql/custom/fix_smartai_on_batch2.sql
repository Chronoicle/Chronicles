-- Claude (dev-owner) 2026-10-04, owner request (item 1, batch 2). Creature templates with SmartAI rows but AIName '' and no
-- ScriptName: SmartAI never ran. Batch 2 = every remaining spawned one whose rows are ALL of a safe kind:
--   events: update ic/ooc, health %, aggro, kill, death, evade, range, respawn, target health, victim casting, friendly
--           health / missing buff, has aura, reset, link, behind target, friendly health %;
--   actions: talk, sound, emote, cast (out-of-combat casts only on self), emote state, auto attack, combat movement,
--           phase / inc phase, flee, call for help, sheath, store target, self / cross cast, interrupt, home pos,
--           health regen, root, random sound, corpse delay, animkit.
-- (counts in the commit message). The 370 with any other row (despawn, faction, flags, visibility, waypoints, data / instance
-- calls, summons, action lists, quest credit ...) are left for a separate review. Apply once, right before a restart.
DROP TEMPORARY TABLE IF EXISTS world.sai_b2;
CREATE TEMPORARY TABLE world.sai_b2 (entry INT PRIMARY KEY)
SELECT DISTINCT t.entry FROM world.creature_template t
WHERE t.AIName = '' AND t.ScriptName = ''
  AND EXISTS (SELECT 1 FROM world.smart_scripts s WHERE s.entryorguid = t.entry AND s.source_type = 0)
  AND EXISTS (SELECT 1 FROM world.creature c WHERE c.id = t.entry)
  AND t.entry NOT IN (23837, 3870, 90018, 90019, 93023, 114590)
  -- dev-check: SmartAI would replace the core's special AI for vehicles, spellclick NPCs, critters (8), totems (11),
  -- triggers (128) and guards (32768)
  AND t.VehicleId = 0 AND (t.npcflag & 16777216) = 0 AND (t.flags_extra & (128 | 32768)) = 0
  AND NOT EXISTS (SELECT 1 FROM world.creature_template_wdb w WHERE w.Entry = t.entry AND w.Type IN (8, 11))
  AND NOT EXISTS (SELECT 1 FROM world.creature c WHERE c.id = t.entry AND (c.npcflag & 16777216) <> 0);
DROP TEMPORARY TABLE IF EXISTS world.sai_b2_risky;
CREATE TEMPORARY TABLE world.sai_b2_risky (e INT PRIMARY KEY)
SELECT DISTINCT s.entryorguid e FROM world.smart_scripts s JOIN world.sai_b2 b ON b.entry = s.entryorguid
WHERE s.source_type = 0 AND (
      s.event_type NOT IN (0, 1, 2, 4, 5, 6, 7, 9, 11, 12, 13, 14, 16, 23, 25, 61, 67, 74)
   OR s.action_type NOT IN (1, 4, 5, 11, 17, 20, 21, 22, 23, 25, 39, 40, 64, 85, 86, 92, 100, 101, 102, 103, 115, 116, 128)
   OR (s.event_type IN (1, 11, 25) AND s.action_type IN (11, 85, 86) AND s.target_type NOT IN (0, 1))
   -- out-of-combat chains: a link row behind an OOC / respawn / reset event that casts on someone else
   OR (s.event_type = 61 AND s.action_type IN (11, 85, 86) AND s.target_type NOT IN (0, 1, 2)
       AND EXISTS (SELECT 1 FROM world.smart_scripts p WHERE p.entryorguid = s.entryorguid AND p.source_type = 0 AND p.event_type IN (1, 11, 25) AND p.link = s.id))
   -- rooting on spawn / reset (or its link) can freeze the mob for good
   OR (s.action_type = 103 AND s.event_type IN (1, 11, 25, 61)));
CREATE TABLE IF NOT EXISTS world.bak_smartai_on_batch2 (entry INT PRIMARY KEY, AIName VARCHAR(64));
INSERT IGNORE INTO world.bak_smartai_on_batch2 (entry, AIName)
SELECT t.entry, t.AIName FROM world.creature_template t JOIN world.sai_b2 b ON b.entry = t.entry
LEFT JOIN world.sai_b2_risky r ON r.e = t.entry WHERE r.e IS NULL;
UPDATE world.creature_template t JOIN world.bak_smartai_on_batch2 k ON k.entry = t.entry SET t.AIName = 'SmartAI' WHERE t.AIName = '';
