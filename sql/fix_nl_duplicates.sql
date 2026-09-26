-- Neltharion's Lair #13: duplicate trash spawns in Ularogg's room (exact copies of 146728093-096). Undo: ~/undo_nl_duplicates.sql
DELETE FROM world.creature WHERE guid IN (146728577,146728578,146728579,146728580);
