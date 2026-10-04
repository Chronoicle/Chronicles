-- Claude (dev-owner) 2026-10-04, owner request (fix all): SmartAI batch 3. Of the 128 SmartAI-off templates with risky rows
-- (left out of batch 2), help-helper read every row (~/Chronicles-pro/smartai_risky_128.md): these 79 only act on their own
-- triggers (combat summons/casts, emotes, credit on death / spell / gossip, escort or vehicle end -> despawn, proximity quest
-- credit). The other 49 stay off (despawn / faction / flags without a trigger, set data into other creatures, action lists).
-- 903 spawns. Apply once, right before a restart.
CREATE TABLE IF NOT EXISTS world.bak_smartai_on_batch3 (entry INT PRIMARY KEY, AIName VARCHAR(64));
INSERT IGNORE INTO world.bak_smartai_on_batch3 (entry, AIName)
SELECT entry, AIName FROM world.creature_template WHERE entry IN (483,523,952,2859,4316,5917,10583,12636,14394,17117,17214,17241,17242,17246,17649,17701,22160,22384,22484,22931,24938,24979,25063,25975,26113,26401,27680,28095,28212,28465,28557,28559,28560,29093,29102,29103,29480,29548,29715,31689,34258,34851,36361,36436,36599,37139,37145,37888,38808,38809,38810,38850,39337,39589,40950,40951,41309,41335,42983,43173,44049,44164,44569,44573,44598,44694,44879,44894,45893,45947,46416,47391,47747,49528,49893,51193,52207,106813,118201) AND AIName = '' AND ScriptName = '';
UPDATE world.creature_template t JOIN world.bak_smartai_on_batch3 b ON b.entry = t.entry SET t.AIName = 'SmartAI' WHERE t.AIName = '';
