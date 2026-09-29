-- Undo for fix_xalatath_slaghammer_106.sql (there were no conditions for Slaghammer's SmartAI before)
DELETE FROM world.conditions WHERE SourceTypeOrReferenceId = 22 AND SourceGroup = 1 AND SourceEntry = 101430 AND SourceId = 0;
