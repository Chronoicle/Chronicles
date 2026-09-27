-- Undo fix_mindbender_44.sql (there were no addon rows before)
DELETE FROM world.creature_template_addon WHERE entry IN (62982, 67236);
