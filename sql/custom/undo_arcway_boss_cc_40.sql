-- Undo fix_arcway_boss_cc_40.sql: all four had mask 0 before (checked 2026-09-29).
UPDATE world.creature_template SET mechanic_immune_mask = 0 WHERE entry IN (98203, 98206, 98207, 98208);
