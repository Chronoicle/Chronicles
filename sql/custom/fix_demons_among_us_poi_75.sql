-- #75 (James, Claude 2026-09-28): Demons Among Us (40593) had map markers only for its two creature objectives; the two
-- Demon Portal objectives (gameobjects 246706 / 246707, storage 2 / 3) had no quest POI, so the courtyard portal showed
-- no marker. One POI each at the portal. Undo: undo_demons_among_us_poi_75.sql
DELETE FROM world.quest_poi WHERE QuestID = 40593 AND Idx1 IN (6, 7);
DELETE FROM world.quest_poi_points WHERE QuestID = 40593 AND Idx1 IN (6, 7);
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(40593, 0, 6, 2, 281580, 246706, 0, 301, 0, 0, 0, 0, 0, 1103758, 0, 26972),
(40593, 0, 7, 3, 281581, 246707, 0, 301, 0, 0, 0, 0, 0, 1103758, 0, 26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y) VALUES
(40593, 6, 0, -8318, 291),
(40593, 7, 0, -8379, 322);
