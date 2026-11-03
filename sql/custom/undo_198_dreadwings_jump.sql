-- undo #198 Dreadwing 119930 jump out
DELETE FROM world.smart_scripts WHERE entryorguid = 119930 AND source_type = 0 AND id IN (10, 11);
