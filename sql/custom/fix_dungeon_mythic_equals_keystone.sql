-- Owner request 2026-09-28 (Claude): the same health scaling in every Legion dungeon as in Vault of the Wardens (checked
-- against UWOW there): Mythic 0 and keystones use ONE creature_difficulty_stat multiplier (UWOW: M0 health = keystone
-- base, then ChallengeModeHealth per level). Hostile NPCs spawned in the 13 Legion dungeon maps:
--   both rows differ   -> Mythic (23) := Keystone (8)
--   keystone row only  -> add Mythic = Keystone        (M0 used HpMulti x1.65 before)
--   mythic row only    -> add Keystone = Mythic        (keys used HpMulti x1.65 before)
-- Heroic unchanged. Undo: undo_dungeon_mythic_equals_keystone.sql (row dump from before)
DROP TEMPORARY TABLE IF EXISTS world.tmp_legion_dungeon_npcs;
CREATE TEMPORARY TABLE world.tmp_legion_dungeon_npcs (entry INT UNSIGNED PRIMARY KEY)
  SELECT DISTINCT c.id AS entry FROM world.creature c JOIN world.creature_template t ON t.entry = c.id
  WHERE c.map IN (1456,1466,1458,1477,1493,1501,1492,1516,1571,1544,1651,1677,1753) AND t.faction NOT IN (35, 31, 188) AND t.flags_extra & 128 = 0;
UPDATE world.creature_difficulty_stat m
  JOIN world.creature_difficulty_stat k ON k.entry = m.entry AND k.difficulty = 8
  JOIN world.tmp_legion_dungeon_npcs n ON n.entry = m.entry
  SET m.HealthModifier = k.HealthModifier
  WHERE m.difficulty = 23 AND ABS(k.HealthModifier - m.HealthModifier) > 0.001;
INSERT IGNORE INTO world.creature_difficulty_stat (entry, difficulty, dmg_multiplier, HealthModifier)
  SELECT k.entry, 23, k.dmg_multiplier, k.HealthModifier FROM world.creature_difficulty_stat k
  JOIN world.tmp_legion_dungeon_npcs n ON n.entry = k.entry WHERE k.difficulty = 8;
INSERT IGNORE INTO world.creature_difficulty_stat (entry, difficulty, dmg_multiplier, HealthModifier)
  SELECT m.entry, 8, m.dmg_multiplier, m.HealthModifier FROM world.creature_difficulty_stat m
  JOIN world.tmp_legion_dungeon_npcs n ON n.entry = m.entry WHERE m.difficulty = 23;
DROP TEMPORARY TABLE world.tmp_legion_dungeon_npcs;
