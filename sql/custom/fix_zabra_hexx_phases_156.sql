-- #156 follow-up (gabrielf03d, approved reporter; Claude desktop team subagent, 2026-10-02): The Best and Brightest
-- (43373). Both Zabra Hexx spawns were unphased, so the petrified one (110751, guid 267939, the one you dispel) and the
-- free one at the camp ~80 yd away (110686, guid 362544, turn-in of 43373, giver of 43374 / 43375) were seen together,
-- and walking up to the free one finished the quest: his smart_scripts row 0 (repack) gives the 110751 credit every
-- 5 s to every player within 10 yd. Goes with fix_zabra_hexx_156.sql (the dispel credit). Undo:
-- sql/custom/undo_zabra_hexx_phases_156.sql. Live with a worldserver restart (no .reload).
--
-- Each Zabra gets his own Azsuna phase (client Phase.db2 IDs, unused in the DB and in the client's GameObjects /
-- AreaTrigger / PhaseXPhaseGroup): petrified 6885 while 43373 is in progress, free 6891 once it is complete or
-- rewarded. The dispel credit completes 43373, so the statue goes and the camp Zabra appears. The proximity credit
-- row is switched off with SMART_EVENT_FLAG_DEBUG_ONLY (0x80, skipped in release builds; nothing deleted).
-- phase_definitions is MyISAM: its INSERT comes first, so a clash on (7334, 217/218) stops the file before the rest.

INSERT INTO world.phase_definitions (zoneId, entry, phasemask, phaseId, PreloadMapID, VisibleMapID, UiWorldMapAreaID, flags, comment) VALUES
(7334, 217, 0, '6885', 0, 0, 0, 16, '43373 Priest CH: petrified Zabra Hexx (#156)'),
(7334, 218, 0, '6891', 0, 0, 0, 16, '43373 Priest CH: free Zabra Hexx at the camp (#156)');

INSERT INTO world.conditions (SourceTypeOrReferenceId, SourceGroup, SourceEntry, SourceId, ElseGroup, ConditionTypeOrReference, ConditionTarget,
  ConditionValue1, ConditionValue2, ConditionValue3, NegativeCondition, ErrorTextId, ScriptName, Comment) VALUES
(23, 7334, 217, 0, 0, 9, 0, 43373, 0, 0, 0, 0, '', 'Petrified Zabra Hexx: The Best and Brightest in progress (#156)'),
(23, 7334, 218, 0, 0, 28, 0, 43373, 0, 0, 0, 0, '', 'Zabra Hexx at the camp: The Best and Brightest complete (#156)'),
(23, 7334, 218, 0, 1, 8, 0, 43373, 0, 0, 0, 0, '', 'Zabra Hexx at the camp: The Best and Brightest rewarded (#156)');

UPDATE world.creature SET PhaseId = '6885' WHERE guid = 267939 AND id = 110751 AND PhaseId = '';
UPDATE world.creature SET PhaseId = '6891' WHERE guid = 362544 AND id = 110686 AND PhaseId = '';

UPDATE world.smart_scripts SET event_flags = event_flags | 0x80
WHERE entryorguid = 110686 AND source_type = 0 AND id = 0 AND event_type = 60 AND action_type = 33 AND action_param1 = 110751 AND event_flags = 0;
