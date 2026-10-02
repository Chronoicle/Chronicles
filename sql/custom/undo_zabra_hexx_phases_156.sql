-- Undo for fix_zabra_hexx_phases_156.sql (#156 follow-up): both Zabra Hexx spawns unphased again, the camp Zabra's
-- proximity credit back on, phase_definitions 7334/217-218 and their conditions removed (all added by the fix).
UPDATE world.smart_scripts SET event_flags = event_flags & ~0x80
WHERE entryorguid = 110686 AND source_type = 0 AND id = 0 AND event_type = 60 AND action_type = 33 AND action_param1 = 110751 AND event_flags = 0x80;

UPDATE world.creature SET PhaseId = '' WHERE guid = 267939 AND id = 110751 AND PhaseId = '6885';
UPDATE world.creature SET PhaseId = '' WHERE guid = 362544 AND id = 110686 AND PhaseId = '6891';

DELETE FROM world.conditions WHERE SourceTypeOrReferenceId = 23 AND SourceGroup = 7334 AND SourceEntry IN (217, 218) AND ConditionValue1 = 43373;
DELETE FROM world.phase_definitions WHERE zoneId = 7334 AND entry IN (217, 218) AND phaseId IN ('6885', '6891');
