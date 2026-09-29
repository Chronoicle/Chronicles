-- Undo for fix_draenei_survivor_naaru.sql
UPDATE world.creature_template SET unit_flags = 4608 WHERE entry = 16483;
