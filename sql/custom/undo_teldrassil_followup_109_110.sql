-- Undo for sql/custom/fix_teldrassil_followup_109_110.sql: the exact rows of quest 2399 before the fix (live world DB,
-- 2026-09-29). Worldserver restart, no .reload.
DELETE FROM world.quest_poi WHERE QuestID = 2399;
DELETE FROM world.quest_poi_points WHERE QuestID = 2399;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(2399,0,0,-1,0,0,1,41,0,0,1,0,0,0,0,23877),
(2399,0,1,32,0,0,1,41,0,0,0,0,0,80924,0,26124);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(2399,0,0,9502,718,23877),
(2399,0,1,9505,722,23877),
(2399,0,2,9503,720,23877),
(2399,1,0,9502,718,26124);
