-- #106 follow-up (gabrielf03d): Shadow Priest artifact scenario 991 "Blade in Twilight" (map 1539, priest phase 5737).
-- Undo: undo_xalatath_tomb_106.sql
--
-- (a) Stage 6 "Don't Fear the Reaper" (step index 5, criteria 29507 = script event 48994) stuck after a death.
--     Amassing Darkness 102693 casts Armageddon 203014 25 s after aggro (timed list 10269300); its effect 2 is an
--     instakill on itself. Its on-death credit (SmartAI id 4) went only to the closest LIVING player within 50 yd,
--     so when the player was dead or a ghost (graveyard 5281 is at the camp, ~140 yd away) nobody got it: the NPC is
--     dead and the step never completes. Now every player within 250 yd gets it, alive or dead.
UPDATE world.smart_scripts SET target_type = 18, target_param1 = 250
WHERE entryorguid = 102693 AND source_type = 0 AND id = 4;

-- (b) Invisible wall at the top of the passage down to the prison (Scenario Blockers 136651/136652, x ~1915).
--     Only Borgoth the Master Reaver 101897 (summoned when the Amassing Darkness dies) opened them, by TOGGLING every
--     blocker within 70 yd of where he died: killed further east (a ranged player standing near the entrance) the
--     passage stayed shut and the tomb entrance blocker 136650 was closed instead.
--     Now the passage opens when stage 7 "Dark Passage" starts ("The way is open to the prison ... unsealed passage"):
--     a guid script on the passage Shadow Bunny 369668 (12-13 yd from both blockers) drops its Shadow Defense Field
--     and opens the blockers within 15 yd. Borgoth's death no longer toggles anything (his id 3 becomes the death event).
DELETE FROM world.smart_scripts WHERE entryorguid = 101897 AND source_type = 0 AND id = 2;
UPDATE world.smart_scripts SET event_type = 6, event_flags = 1
WHERE entryorguid = 101897 AND source_type = 0 AND id = 3;

DELETE FROM world.smart_scripts WHERE entryorguid = -369668 AND source_type = 0;
INSERT INTO world.smart_scripts (entryorguid, source_type, id, link, Difficulties, event_type, event_phase_mask, event_chance, event_flags,
  event_param1, event_param2, event_param3, event_param4, event_param5, action_type, action_param1, action_param2, action_param3,
  action_param4, action_param5, action_param6, target_type, target_param1, target_param2, target_param3, target_param4,
  target_x, target_y, target_z, target_o, comment) VALUES
(-369668, 0, 0, 1, '', 60, 0, 100, 1, 1000, 1000, 0, 0, 0, 28, 200984, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Shadow Bunny (tomb passage) - Update on scenario 991 stage 7+ - Remove Shadow Defense Field (#106)'),
(-369668, 0, 1, 0, '', 61, 0, 100, 0, 0, 0, 0, 0, 0, 9, 0, 0, 0, 0, 0, 0, 15, 251349, 15, 0, 0, 0, 0, 0, 0, 'Shadow Bunny (tomb passage) - Link - Open Scenario Blockers 136651/136652 (#106)'),
-- A guid script replaces the entry script: keep the entry's data-set handler (its other row runs only in the warrior
-- scenario 1037, step 6, and its timed list 10146102 is empty).
(-369668, 0, 2, 0, '', 38, 0, 100, 1, 1, 1, 0, 0, 0, 28, 200984, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Shadow Bunny (tomb passage) - Data Set 1 1 - Remove Shadow Defense Field (as entry 101461, #106)');

DELETE FROM world.conditions WHERE SourceTypeOrReferenceId = 22 AND SourceGroup = 1 AND SourceEntry = -369668 AND SourceId = 0;
INSERT INTO world.conditions (SourceTypeOrReferenceId, SourceGroup, SourceEntry, SourceId, ElseGroup, ConditionTypeOrReference, ConditionTarget, ConditionValue1, ConditionValue2, ConditionValue3, NegativeCondition, ErrorTextId, ScriptName, Comment) VALUES
(22, 1, -369668, 0, 0, 44, 0, 991, 6, 0, 0, 0, '', 'Tomb passage bunny: scenario 991 step 7 Dark Passage (#106)'),
(22, 1, -369668, 0, 1, 44, 0, 991, 7, 0, 0, 0, '', 'Tomb passage bunny: scenario 991 step 8 Death to the Deacon (#106)'),
(22, 1, -369668, 0, 2, 44, 0, 991, 8, 0, 0, 0, '', 'Tomb passage bunny: scenario 991 step 9 Blade of the Black Empire (#106)'),
(22, 1, -369668, 0, 3, 44, 0, 991, 9, 0, 0, 0, '', 'Tomb passage bunny: scenario 991 step 10 True Death of Zakajz (#106)');

-- (c) Stage 5 "Reconsecration" ("Dispel their defenses and kill the ritualists"): the 4 Twilight Ritualists 101875 could
--     simply be killed. Now, in scenario 991 only (the Arms warrior scenario 1037 uses the same NPC), a ritualist takes no
--     damage (invincibility at 100% health) until Mass Dispel (32592, 15 yd around the target point, so a cast on its
--     pillar reaches it) hits it; that also drops the Shadow Defense Field on its pillar's Shadow Bunny.
--     The ward comes back if the ritualist resets (evade), like the rest of its script.
DELETE FROM world.smart_scripts WHERE entryorguid = 101875 AND source_type = 0 AND id IN (7, 8, 9);
INSERT INTO world.smart_scripts (entryorguid, source_type, id, link, Difficulties, event_type, event_phase_mask, event_chance, event_flags,
  event_param1, event_param2, event_param3, event_param4, event_param5, action_type, action_param1, action_param2, action_param3,
  action_param4, action_param5, action_param6, target_type, target_param1, target_param2, target_param3, target_param4,
  target_x, target_y, target_z, target_o, comment) VALUES
(101875, 0, 7, 0, '', 60, 0, 100, 1, 1000, 1000, 0, 0, 0, 42, 0, 100, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Twilight Ritualist - Update (scenario 991) - Ward: no damage until Mass Dispel (#106)'),
(101875, 0, 8, 9, '', 8, 0, 100, 0, 32592, 0, 0, 0, 0, 42, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Twilight Ritualist - Spell Hit Mass Dispel - Remove ward (#106)'),
(101875, 0, 9, 0, '', 61, 0, 100, 0, 0, 0, 0, 0, 0, 45, 1, 1, 0, 0, 0, 0, 19, 101461, 20, 0, 0, 0, 0, 0, 0, 'Twilight Ritualist - Link - Pillar Shadow Bunny drops its Shadow Defense Field (#106)');

DELETE FROM world.conditions WHERE SourceTypeOrReferenceId = 22 AND SourceGroup = 8 AND SourceEntry = 101875 AND SourceId = 0;
INSERT INTO world.conditions (SourceTypeOrReferenceId, SourceGroup, SourceEntry, SourceId, ElseGroup, ConditionTypeOrReference, ConditionTarget, ConditionValue1, ConditionValue2, ConditionValue3, NegativeCondition, ErrorTextId, ScriptName, Comment) VALUES
(22, 8, 101875, 0, 0, 44, 0, 991, 0, 0, 0, 0, '', 'Twilight Ritualist ward: scenario 991 step 1 (#106)'),
(22, 8, 101875, 0, 1, 44, 0, 991, 1, 0, 0, 0, '', 'Twilight Ritualist ward: scenario 991 step 2 (#106)'),
(22, 8, 101875, 0, 2, 44, 0, 991, 2, 0, 0, 0, '', 'Twilight Ritualist ward: scenario 991 step 3 (#106)'),
(22, 8, 101875, 0, 3, 44, 0, 991, 3, 0, 0, 0, '', 'Twilight Ritualist ward: scenario 991 step 4 (#106)'),
(22, 8, 101875, 0, 4, 44, 0, 991, 4, 0, 0, 0, '', 'Twilight Ritualist ward: scenario 991 step 5 Reconsecration (#106)');
