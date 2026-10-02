-- Undo for fix_ample_supply_poi_159.sql (#159): the 14 junk points go back into the objective blobs of 43375 / 43376.
UPDATE world.quest_poi_points SET Idx1 = 1
WHERE VerifiedBuild = 23911 AND Idx1 = 101 AND ((QuestID = 43375 AND Idx2 BETWEEN 6 AND 12) OR (QuestID = 43376 AND Idx2 BETWEEN 8 AND 14));
