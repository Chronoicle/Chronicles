-- Undo for fix_recruiting_more_troops_poi_162.sql (#162): removes only the objective blob and point that fix added.
DELETE FROM world.quest_poi_points WHERE QuestID = 43851 AND Idx1 = 2 AND Idx2 = 0 AND X = 1315 AND Y = 1386 AND VerifiedBuild = 0;
DELETE FROM world.quest_poi WHERE QuestID = 43851 AND Idx1 = 2 AND ObjectiveIndex = 0 AND QuestObjectiveID = 286225 AND VerifiedBuild = 0;
