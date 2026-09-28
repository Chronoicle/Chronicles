-- Undo fix_eonar_crystal_beams_los.sql
DELETE FROM world.disables WHERE sourceType = 0 AND entry IN (259468, 259469, 259470, 259472);
