-- Vileshard Crawler 96247, Neltharion's Lair (Refs #4; owner 2026-09-29: retail values; desktop team, Claude subagent,
-- 2026-09-30). Undo: undo_neltharions_lair_13_4_crawler.sql
--
-- No retail damage value exists for this creature: the client data has none, UWOW's creature_difficulty_stat has
-- dmg_multiplier 1 for every NL creature, TrinityCore has no NL creature data and Wowhead shows none. Every NL trash mob
-- therefore hits the same per swing (Legion damage table x difficulty), the tiny Crawler as hard as a Hulk.
-- What is retail: Crawlers are Normal (non-elite) beasts (Wowhead), and their Heroic/Mythic health (difficulty stat
-- 2.8125 / 4.93598) is 34.6 % of the standard NL trash (8.125 / 14.259), i.e. a base of 1.7308 instead of 5.
--
-- 1. Normal health: HpMulti 5 (the elite value) gave Normal Crawlers more health than Heroic ones. 1.7308 = the base
--    the Heroic/Mythic values imply (x1.625 / x2.852 like all NL trash).
--      Normal 5.20M -> 1.80M; Heroic 2.92M and Mythic/keystone base 5.13M unchanged.
-- 2. Melee damage scaled by the same 34.6 % (dmg_multiplier 0.35). Per hit before armour/versatility/keystone level:
--      Normal  65,671-98,507   -> 22,985-34,477
--      Heroic  205,223-307,834 -> 71,828-107,742
--      M0      607,459-911,188 -> 212,611-318,916   (James saw 165-210K with his mitigation -> about 58-74K)
--      keystone base 607,459-728,951 -> 212,611-255,133
DROP TABLE IF EXISTS world.bak_nl_13_4_crawler;
CREATE TABLE world.bak_nl_13_4_crawler AS SELECT ct.entry, ct.dmg_multiplier, w.HpMulti FROM world.creature_template ct JOIN world.creature_template_wdb w ON w.Entry = ct.entry WHERE ct.entry = 96247;

UPDATE world.creature_template_wdb SET HpMulti = 1.7308 WHERE Entry = 96247;
UPDATE world.creature_template SET dmg_multiplier = 0.35 WHERE entry = 96247;
