-- Undo fix_psyfiend_48.sql (live values before the fix)
UPDATE world.creature_template SET mechanic_immune_mask = 0, unit_flags3 = 0 WHERE entry = 101398;
