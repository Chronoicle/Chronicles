-- Undo for fix_tarindrella_follow_125.sql (none of these rows existed before, 2026-09-29; SmartAI id 0 of 49480 stays)
DELETE FROM world.spell_area WHERE spell = 92237 AND area = 257;
DELETE FROM world.conditions WHERE SourceTypeOrReferenceId IN (13, 17) AND SourceEntry = 92238;
DELETE FROM world.smart_scripts WHERE entryorguid = 49480 AND source_type = 0 AND id = 1;
