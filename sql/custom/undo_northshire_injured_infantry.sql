-- Undo for fix_northshire_injured_infantry.sql
UPDATE world.creature_template_addon SET bytes1 = 0 WHERE entry = 50047;
