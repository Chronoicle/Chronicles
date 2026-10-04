-- Claude (dev-owner) 2026-10-04, dev-check review: setting AIName = 'SmartAI' bypasses the special AI the core picks for
-- vehicles, spellclick NPCs, critters, totems, guards and triggers (CreatureAISelector). Six of them got into batch 1
-- (critter 10461, vehicles 24083 / 36558 / 57475, triggers 54638 / 73678): back to their original empty AIName.
UPDATE world.creature_template t JOIN world.bak_smartai_on_batch1 b ON b.entry = t.entry SET t.AIName = b.AIName
WHERE t.entry IN (10461, 24083, 36558, 57475, 54638, 73678);
