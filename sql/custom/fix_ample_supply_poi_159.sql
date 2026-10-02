-- #159 (gabrielf03d, approved reporter; Claude desktop team subagent, 2026-10-02): Priest class hall, An Ample Supply
-- (43375) had no area on the map. Undo: sql/custom/undo_ample_supply_poi_159.sql. Live with a worldserver restart (no .reload).
--
-- The objective blob (quest_poi Idx1 1) has the client's 6 points (QuestPOIBlob 359133, QuestPOIPoint 774600-774605)
-- plus 7 junk points from a broken build-23911 import (X/Y like 536870912 / -1006632960, raw binary), so the area
-- polygon spans half the world and the client draws nothing. Problem Salver (43376, next in the chain) has the same
-- 7 junk points after its 8 real ones (QuestPOIBlob 359173). The junk points are moved to Idx1 101, which has no
-- quest_poi row, so the loader never attaches them (nothing deleted; ~520 other quests have such junk points: separate cleanup).

UPDATE world.quest_poi_points SET Idx1 = 101
WHERE VerifiedBuild = 23911 AND Idx1 = 1 AND ((QuestID = 43375 AND Idx2 BETWEEN 6 AND 12) OR (QuestID = 43376 AND Idx2 BETWEEN 8 AND 14));
