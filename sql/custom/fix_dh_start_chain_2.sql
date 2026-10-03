-- Claude (dev-owner) 2026-10-03, DH start audit part 2.
-- On Felbat Wings (39663) comes after Stop the Bombardment (38727) AND Their Numbers Are Legion (38819) (one exclusive
-- group -38727, RewardNextQuest 39663; wowhead series step 5) plus the spec quest (PrevQuestID 39516 / 39515.NextQuestID).
-- Nothing required the two, so they could be skipped.
DELETE FROM world.conditions WHERE SourceTypeOrReferenceId = 19 AND SourceEntry = 39663 AND ConditionTypeOrReference = 8 AND ConditionValue1 IN (38727, 38819);
INSERT INTO world.conditions (SourceTypeOrReferenceId, SourceGroup, SourceEntry, SourceId, ElseGroup, ConditionTypeOrReference, ConditionTarget, ConditionValue1, ConditionValue2, ConditionValue3, NegativeCondition, ErrorTextId, ScriptName, Comment) VALUES
(19, 0, 39663, 0, 0, 8, 0, 38727, 0, 0, 0, 0, '', 'On Felbat Wings: after Stop the Bombardment'),
(19, 0, 39663, 0, 0, 8, 0, 38819, 0, 0, 0, 0, '', 'On Felbat Wings: after Their Numbers Are Legion');
-- The Call of War (39691 Alliance, 40976 Audience with the Warchief Horde) had no prerequisite: after the Vault
-- (Illidari, We Are Leaving 39689 Alliance / 39690 Horde).
UPDATE world.quest_template_addon SET NextQuestID = 39691 WHERE ID = 39689;
UPDATE world.quest_template_addon SET NextQuestID = 40976 WHERE ID = 39690;
