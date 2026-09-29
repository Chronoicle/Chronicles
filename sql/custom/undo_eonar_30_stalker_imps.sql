-- Undo fix_eonar_30_stalker_imps.sql: flags_extra was 0 for all three before.
UPDATE world.creature_template SET flags_extra = 0 WHERE entry IN (126937, 126980, 127694);
