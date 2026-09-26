-- James's Neltharion's Lair list (issue #13), 2026-09-26. Undo: ~/undo_nl_james.sql
-- Vileshard Hulks: immune to crowd control and slows
UPDATE world.creature_template SET mechanic_immune_mask = 617299699 WHERE entry = 91000;
-- Drums of War: an object, not attackable/selectable (it aggroed and followed players)
UPDATE world.creature_template SET unit_flags = unit_flags | 2 | 256 | 33554432 WHERE entry = 92387;
-- Naraxas: her loot comes from "Remains of the Fallen" (the instance spawns it when she dies); no corpse loot on top
UPDATE world.creature_template SET lootid = 0 WHERE entry = 91005;
