-- #106 Shadow Priest artifact (quest 40710 Blade in Twilight, scenario 991 on map 1539), stage 2 "Raiding the Tomb Raiders"
-- (step index 1, criteria 29342 = script event 48121 "Enter the tomb at the bottom of the lake") never completes.
-- Undo: undo_xalatath_slaghammer_106.sql
-- The only thing that sends 48121 is Shadowlord Slaghammer (101430) SmartAI id 0: OOC_LOS (non-hostile unit within 70 yd),
-- NOT_REPEATABLE, "complete scenario criteria" on the invoker. The event takes any non-hostile unit and any step: the
-- Shadow Bunny 101461 (guid 369667, neutral, 31 yd away, same phase 5737) or the player during stage 1 fires it first,
-- the criteria goes to a non-player or is ignored (Scenario::CanUpdateCriteria only counts the current step), and the
-- event never runs again. DBErrors.log shows the chain ran twice since the 10:29 restart ("Entry 101430 ... Event 1").
-- Fix: the event only counts for a player on step index 1. Conditions are checked before the event is marked as run
-- (SmartScript::ProcessEventsFor / ProcessEvent), so a failed check no longer uses it up.
DELETE FROM world.conditions WHERE SourceTypeOrReferenceId = 22 AND SourceGroup = 1 AND SourceEntry = 101430 AND SourceId = 0;
INSERT INTO world.conditions (SourceTypeOrReferenceId, SourceGroup, SourceEntry, SourceId, ElseGroup, ConditionTypeOrReference, ConditionTarget, ConditionValue1, ConditionValue2, ConditionValue3, NegativeCondition, ErrorTextId, ScriptName, Comment) VALUES
(22, 1, 101430, 0, 0, 32, 0, 16,  0, 0, 0, 0, '', 'Shadowlord Slaghammer - OOC LOS: invoker must be a player (#106)'),
(22, 1, 101430, 0, 0, 44, 0, 991, 1, 0, 0, 0, '', 'Shadowlord Slaghammer - OOC LOS: only on scenario 991 step 2 Raiding the Tomb Raiders (#106)');
