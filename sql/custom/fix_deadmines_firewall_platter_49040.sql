-- #140 dungeon bots, first find (2026-10-01): Deadmines "Glubtok Firewall Platter Creature Level 1c" (49040), 4 static
-- spawns in Glubtok's room (spawnMask 6 = Normal + Heroic), was a hostile (faction 14), attackable level-85 creature
-- with ~1000-1350 melee damage: the level-15 bot group pulled it in front of Glubtok and wiped 6 times out of 6; a
-- low-level player group would too. It's a part of the heroic fire wall rig (the platter 48974 is friendly, the other
-- "Level 1a/1b/2a/2b/2c" parts are level 1 without static spawns, spawned by boss_glubtok); boss_glubtok doesn't use
-- 49040. Same data in the upstream LegionCore world dump (2024-10-23). Now friendly, not attackable, not selectable.
-- Needs a worldserver restart (creature_template is read at startup). Undo: undo_deadmines_firewall_platter_49040.sql
UPDATE world.creature_template SET faction = 35, unit_flags = unit_flags | 2 | 256 | 512 | 33554432 WHERE entry = 49040;
