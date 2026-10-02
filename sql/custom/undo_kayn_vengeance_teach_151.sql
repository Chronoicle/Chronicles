-- Undo fix_kayn_vengeance_teach_151.sql (Refs #151). Before-state checked 2026-10-02: no smart_scripts rows for 93127.
DELETE FROM world.smart_scripts WHERE entryorguid = 93127 AND source_type = 0 AND id IN (0, 1);
