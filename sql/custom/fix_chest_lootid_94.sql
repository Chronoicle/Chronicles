-- #94 (audit, Claude desktop team 2026-09-29): chests (type 3) with loot id Data1 = 0 although gameobject_loot_template
-- has rows under their own entry. The core never falls back to the entry (GameObjectTemplate::GetLootId), so they open
-- empty, personal-loot treasures (Data30) included. Same fix as the Fel Reaver Husk in #93: Data1 = entry.
-- Undo: undo_chest_lootid_94.sql (uses the backup table below).
--
-- Left out on purpose (their items may come another way, review one by one if reported):
--   ScriptName / SmartAI objects (artifact pickups like The Ashbringer, Xal'atath, T'uure hand the item out by script),
--   chests with an on-open spell (Data26), dungeon encounter chests (Data25: boss loot, Superior/Peerless caches),
--   Mythic+ Challenger's Caches (ChallengeMgr fills those),
--   entries in personal_loot_template as entry, goEntry or cooldownid (boss / bonus-roll loot id).
CREATE TABLE world.bak_chest_lootid_94 AS
SELECT g.entry, g.Data1 FROM world.gameobject_template g
WHERE g.type = 3 AND g.Data1 = 0 AND g.Data25 = 0 AND g.Data26 = 0 AND g.ScriptName = '' AND g.AIName = ''
  AND EXISTS (SELECT 1 FROM world.gameobject_loot_template l WHERE l.entry = g.entry)
  AND NOT EXISTS (SELECT 1 FROM world.personal_loot_template p WHERE p.entry = g.entry OR p.goEntry = g.entry OR p.cooldownid = g.entry)
  AND g.entry NOT IN (252674,252677,252686,252668,252665,252056,252680,252671,252683,269852,269871,269843,272689,252676);

UPDATE world.gameobject_template g JOIN world.bak_chest_lootid_94 b ON b.entry = g.entry
SET g.Data1 = g.entry WHERE g.Data1 = 0;
