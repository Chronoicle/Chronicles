-- Follow-up reports by tyrvana after the 2026-09-29 20:27 UTC restart (Refs #109 #110; desktop team 2026-09-29).
-- Undo: sql/custom/undo_teldrassil_followup_109_110.sql. Live with a worldserver restart (no .reload); players may need
-- to delete the client's Cache folder to see the new marker.
--
-- No DB change for the other two reports (checked, not caused by our fixes):
-- * Learning New Techniques (26945), "Continue" greyed out: the test character (Elfwarone) turned 26945 in at
--   17:51 UTC, before the restart, and after the restart had it in the quest log again (GM `.quest add`, which does not
--   check "already rewarded"). Player::CanCompleteQuest refuses a non-repeatable quest that is already rewarded, so the
--   request-items window never allows Continue. Quest data matches the human warrior quest 26913 (Charge 100 is
--   learned at level 3); `.quest remove 26945` (clears log + rewarded) and taking it again from Alyissia works.
-- * The Shimmering Frond (931) not offered by the Strange Fronded Plant (6752): quest, starter, object and item data
--   are unchanged by our fixes and allow it (no prerequisite, no disable, no condition). The character played at report
--   time (Asfdasf) already has 931 rewarded, and a rewarded quest is never offered again.

-- The Sprouted Fronds (2399): started and turned in at the Sprouted Frond (object 7510), whose three spawns stand in
-- Denalan's garden at Wellspring Hovel (10121-10125, 1653-1656). The client blobs (QuestPOIBlob 41029 turn-in,
-- 399273 quest giver) point at Lake Al'Ameth (9502, 718), 700 yd south, where there is no frond: the map marker sent
-- players to the lake. Same method as fix_teldrassil_quest_pois.sql (937): the turn-in and the quest-giver blob use the
-- object spawn; Idx1 0 = turn-in, then the giver (the quest has no objectives); Flags / WoDUnk1 kept from the old rows.
DELETE FROM world.quest_poi WHERE QuestID = 2399;
DELETE FROM world.quest_poi_points WHERE QuestID = 2399;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(2399,0,0,-1,0,0,1,41,0,0,1,0,0,0,0,26972),
(2399,0,1,32,0,0,1,41,0,0,0,0,0,80924,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(2399,0,0,10123,1654,26972),
(2399,1,0,10123,1654,26972);
