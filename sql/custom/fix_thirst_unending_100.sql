-- #100 (tyrvana, Claude desktop team 2026-09-29): Thirst Unending (37439) gives no credit to blood elf Paladins.
-- Mana Wyrm 15274's SmartAI gives the objective's kill credit 15468 on SpellHit of each class's Arcane Torrent
-- (28730 mage/warlock, 25046 rogue, 50613 DK, 69179 warrior, 80483 hunter, 129597 monk, 232633 priest), but not
-- the Paladin's 155145 (SkillLineAbility class mask 2). Seen in the DB: Tyrvana (Paladin) at 0/1, a Warrior at 1/1.
-- The new row is a copy of the Warrior row (id 6) with the Paladin spell. Undo: undo_thirst_unending_100.sql
CREATE TEMPORARY TABLE tmp_ss_100 AS
  SELECT * FROM world.smart_scripts WHERE entryorguid = 15274 AND source_type = 0 AND id = 6 AND event_param1 = 69179;
UPDATE tmp_ss_100 SET id = 8, event_param1 = 155145, comment = 'SpellHit (Paladin Arcane Torrent) - Kill Credit';
INSERT IGNORE INTO world.smart_scripts SELECT * FROM tmp_ss_100;
DROP TEMPORARY TABLE tmp_ss_100;
