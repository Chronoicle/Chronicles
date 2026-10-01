-- Azsuna, Azurewing Repose (Defending Azurewing Repose): two Senegos in the pool from the start, and after Hunger's End
-- (42756) the withered stay and both Senegos show (issue #144, gabrielf03d, approved reporter; Claude desktop team
-- subagent). Undo: sql/custom/undo_azurewing_repose_senegos_144.sql. Live with a worldserver restart (no .reload).
--
-- Why: in this core a player sees a spawn when both share at least one PhaseId, and a spawn without PhaseId is seen by
-- every player (WorldObject::InSamePhaseId). Azsuna's phase_definitions (zone 7334) hand out phase ids by quest state,
-- but the sniffed spawns carry the sniffer's whole phase list, zone-wide ids included (4270, 5433, 4793, 7564), which
-- every player in Azsuna has. So the sick Senegos (89975, no PhaseId at all), the healthy Senegos (100482) and the
-- withered showed in every quest state. Each now keeps only the one id of its own state, which no other Azsuna phase
-- definition hands out:
--   6656  sick Senegos     phase_definitions 7334/22: Hunger's End not taken yet
--   6884  healthy Senegos  phase_definitions 7334/24: Hunger's End taken, complete or turned in
--   6646  withered         phase_definitions 7334/21: from Still Alive (37862) on, now until Hunger's End is turned in
-- phase_definitions itself is not changed; only its conditions (source type 23, group = zone, entry = definition).
SET NAMES utf8mb4;

-- 1) One Senegos at a time: the sick one (starts the chapter) until Hunger's End is taken, then the healthy one (ends
--    Hunger's End, starts the later quests). 7334/22 and 7334/24 have opposite conditions, so they never overlap.
UPDATE world.creature SET PhaseId = '6656' WHERE guid = 266709 AND id = 89975;
UPDATE world.creature SET PhaseId = '6884' WHERE guid = 338483 AND id = 100482;

-- 2) Balance of Power (The Power Within 43496 -> ... ends at the healthy Senegos) does not need Hunger's End, so a
--    player who started it gets the healthy Senegos (7334/24, new or-group) and no longer the sick one (7334/22, added to
--    its "Hunger's End not taken" group). Without this they would lose the Senegos they turn those quests in to.
-- 3) The withered leave once Hunger's End is turned in: 7334/21 stayed on forever through "Still Alive rewarded".
DELETE FROM world.conditions WHERE SourceTypeOrReferenceId = 23 AND SourceGroup = 7334 AND SourceId = 0
  AND ((SourceEntry = 24 AND ElseGroup = 3 AND ConditionTypeOrReference = 14 AND ConditionValue1 = 43496)
    OR (SourceEntry = 22 AND ElseGroup = 1 AND ConditionTypeOrReference = 14 AND ConditionValue1 = 43496)
    OR (SourceEntry = 21 AND ElseGroup = 1 AND ConditionTypeOrReference = 8 AND ConditionValue1 = 42756));
INSERT INTO world.conditions (SourceTypeOrReferenceId, SourceGroup, SourceEntry, SourceId, ElseGroup, ConditionTypeOrReference, ConditionTarget, ConditionValue1, ConditionValue2, ConditionValue3, NegativeCondition, ErrorTextId, ScriptName, Comment) VALUES
(23, 7334, 24, 0, 3, 14, 0, 43496, 0, 0, 1, 0, '', 'Healthy Senegos (6884): The Power Within started'),
(23, 7334, 22, 0, 1, 14, 0, 43496, 0, 0, 0, 0, '', 'Sick Senegos (6656): The Power Within not started'),
(23, 7334, 21, 0, 1, 8, 0, 42756, 0, 0, 1, 0, '', 'Withered at Azurewing Repose (6646): gone once Hunger''s End is turned in');

UPDATE world.creature SET PhaseId = '6646'
WHERE id IN (91157, 103208) AND map = 1220 AND zoneId = 7334 AND PhaseId = '7564 6893 6886 6646 6595 5433 4793 4436 4270';
