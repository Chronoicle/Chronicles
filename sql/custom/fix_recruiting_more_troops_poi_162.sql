-- #162 (gabrielf03d, approved reporter; Claude desktop team subagent, 2026-10-02): Priest class hall, Recruiting More
-- Troops (43851) had no map marker. Undo: sql/custom/undo_recruiting_more_troops_poi_162.sql. Live with a worldserver
-- restart (no .reload).
--
-- The quest has objective 286225 "Squad of Zealots trained" (StorageIndex 0, credit 106406, given by Vicar Eliza's
-- gossip SmartAI), but its POI only has the turn-in blob (ObjectiveIndex -1, at Eliza) and blob 32 (at Moira), the same
-- two as the client's QuestPOIBlob 362274 / 362282. With objective 0 open and no blob for it, the map shows nothing.
-- Adds an objective-0 blob at Vicar Eliza's spawn (creature 106451, 1314.8 / 1385.8), like Recruiting the Troops
-- (43275) has for its objective. Idx1 2 is free for this quest (no rows in quest_poi or quest_poi_points).

INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild)
SELECT 43851, 0, 2, 0, 286225, 106406, 1512, 1040, 1, 0, 0, 0, 0, 0, 0, 0 FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM world.quest_poi WHERE QuestID = 43851 AND (Idx1 = 2 OR ObjectiveIndex = 0));

INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild)
SELECT 43851, 2, 0, 1315, 1386, 0 FROM DUAL
WHERE EXISTS (SELECT 1 FROM world.quest_poi WHERE QuestID = 43851 AND Idx1 = 2 AND ObjectiveIndex = 0 AND QuestObjectiveID = 286225)
  AND NOT EXISTS (SELECT 1 FROM world.quest_poi_points WHERE QuestID = 43851 AND Idx1 = 2);
