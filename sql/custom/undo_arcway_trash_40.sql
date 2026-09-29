-- Undo fix_arcway_trash_40.sql (Refs #40). Before-state checked 2026-09-29: no rows existed for the deleted keys.
UPDATE world.creature_template SET unit_flags = 0 WHERE entry = 105493;
DELETE FROM world.smart_scripts WHERE entryorguid IN (106059, 98756, 105682) AND source_type = 0 AND id = 2;
UPDATE world.smart_scripts SET target_type = 2 WHERE entryorguid = 98756 AND source_type = 0 AND id = 0 AND action_param1 = 211217;
DELETE FROM world.spell_dummy_trigger WHERE spell_id = 211933 AND spell_trigger = 211919;
