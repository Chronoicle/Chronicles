-- #124 (tyrvana, approved reporter; Claude desktop team subagent): Azuremyst Isle / Bloodmyst Isle quest map markers
-- and Tree's Company. Undo: sql/custom/undo_azuremyst_quests_124.sql. Live with a worldserver restart (no .reload).
-- Players need to delete the client's Cache folder to see the new markers.
--
-- Map markers: same broken quest_poi merge as #84/#88/#105/#118 (sniff builds 23877 = BlobIndex = Idx1, turn-in last,
-- every objective written as ObjectiveIndex 0; and 26124 = retail layout, turn-in first; merged into the same keys, so
-- rows took each other's Idx1 and the point lists got mixed: objective markers with a 2nd blob at the quest giver /
-- turn-in (the marker "snaps" between the two), turn-in "areas" made of the turn-in point + an objective polygon,
-- objectives showing another objective's area, doubled areas, polygon tails).
-- Rebuilt from the 7.3.5 client's own QuestPOIBlob.db2 / QuestPOIPoint.db2 (build 26972) exactly like #105/#118 (the
-- generator reproduces the 15 plain client-blob quests of fix_teldrassil_quest_pois.sql and 9473 of #118 row for row):
-- Idx1 0 = turn-in (ObjectiveIndex -1), then the objective areas (by ObjectiveIndex, BlobIndex counts areas per
-- objective, QuestObjectiveID / QuestObjectID from quest_objectives by StorageIndex), then the quest-giver blob
-- (ObjectiveIndex 32). Priority / Flags / WoDUnk1 (SpawnTrackingID) kept from the old row of the same blob (26124
-- first). Client ObjectiveIndex 27 / 30 blobs (extra areas without a quest_objectives row) kept as the client has them.
-- Every client turn-in point is within 1-2 yd of the quest ender's spawn (Prince Toreth 17674 quests 9687-9689: 28 yd,
-- the client giver blob is on the same point, kept), so no turn-in needed the spawn fallback.
--
-- Sweep (all quests with QuestSortID 3524/3525, a quest giver or ender spawned in zone 3524/3525, quest_poi rows on
-- WorldMapArea 464/476 or client blobs there; 316 quests): every quest whose rows draw something else than the client
-- blobs is rebuilt (section 2), merged quests without client blobs follow the #84 rule (section 3).
-- Left alone: 9452, 9538, 9711, 9748, 9759 (only an identical duplicate blob, nothing visible); merged quests whose
-- 26124 rows only doubled a 23877 blob on the same point (e.g. 9528, 9548, 9581, 9584, 9585, 9605, 9670); world-wide
-- holiday / event quests with areas in many zones (9260-9265 and 12817 Scourge invasion, 11118 Brewfest,
-- 11917/11947/11948/11953 Midsummer): same merge, but not Azuremyst/Bloodmyst quests (a holiday sweep).

-- 1) Reported quests, rebuilt from the client blobs.

-- quest 9544 The Prophecy of Akida: client QuestPOIBlob 30088, 30089, 30090, 400025. objective 0 area had a tail of another area; objective 27 area had a tail of another area; objective 27 was its point + 7 points of an objective area; turn-in was its point + 7 points of an objective area
DELETE FROM world.quest_poi WHERE QuestID = 9544;
DELETE FROM world.quest_poi_points WHERE QuestID = 9544;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9544,0,0,-1,0,0,530,464,0,0,1,0,0,0,0,26972),
(9544,0,1,0,261006,17375,530,464,0,2,1,0,0,0,0,26972),
(9544,0,2,27,0,0,530,464,0,1,1,0,0,0,0,26972),
(9544,0,3,32,0,0,530,464,0,0,0,0,0,142587,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9544,0,0,-4181,-12510,26972),
(9544,1,0,-4613,-11663,26972),
(9544,1,1,-4516,-11639,26972),
(9544,1,2,-4483,-11628,26972),
(9544,1,3,-4482,-11613,26972),
(9544,1,4,-4504,-11594,26972),
(9544,1,5,-4619,-11498,26972),
(9544,1,6,-4636,-11494,26972),
(9544,1,7,-4650,-11536,26972),
(9544,1,8,-4624,-11647,26972),
(9544,2,0,-4649,-11683,26972),
(9544,2,1,-4518,-11679,26972),
(9544,2,2,-4453,-11617,26972),
(9544,2,3,-4453,-11584,26972),
(9544,2,4,-4609,-11482,26972),
(9544,2,5,-4653,-11482,26972),
(9544,2,6,-4681,-11519,26972),
(9544,2,7,-4680,-11553,26972),
(9544,3,0,-4487,-11644,26972);

-- quest 9527 All That Remains: client QuestPOIBlob 30061, 30062, 400009. objective 0 was its point + 10 points of an objective area; turn-in was its point + 10 points of an objective area
DELETE FROM world.quest_poi WHERE QuestID = 9527;
DELETE FROM world.quest_poi_points WHERE QuestID = 9527;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9527,0,0,-1,0,0,530,464,0,0,1,0,0,0,0,26972),
(9527,0,1,0,262323,23789,530,464,0,0,0,0,0,0,0,26972),
(9527,0,2,32,0,0,530,464,0,0,0,0,0,141670,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9527,0,0,-5358,-11175,26972),
(9527,1,0,-4950,-11248,26972),
(9527,1,1,-4919,-11183,26972),
(9527,1,2,-4887,-10984,26972),
(9527,1,3,-4915,-10952,26972),
(9527,1,4,-5016,-10850,26972),
(9527,1,5,-5081,-10849,26972),
(9527,1,6,-5151,-10849,26972),
(9527,1,7,-5217,-10916,26972),
(9527,1,8,-5281,-11049,26972),
(9527,1,9,-5250,-11085,26972),
(9527,1,10,-5150,-11183,26972),
(9527,2,0,-5358,-11175,26972);

-- quest 9513 Reclaiming the Ruins: client QuestPOIBlob 30024, 30025, 30026, 30027, 30028, 30029, 400003. objective 0 doubled; objective 0 area had a tail of another area; objective 0 showed the objective 1 area; objective 1 showed the objective 2 area; objective 0 showed the objective 2 area; objective 2 was its point + 7 points of an objective area; turn-in was its point + 7 points of an objective area
DELETE FROM world.quest_poi WHERE QuestID = 9513;
DELETE FROM world.quest_poi_points WHERE QuestID = 9513;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9513,0,0,-1,0,0,530,464,0,0,1,0,0,0,0,26972),
(9513,0,1,0,259730,17194,530,464,0,0,0,0,0,0,0,26972),
(9513,1,2,0,259730,17194,530,464,0,0,0,0,0,0,0,26972),
(9513,0,3,1,259731,17193,530,464,0,0,0,0,0,0,0,26972),
(9513,1,4,1,259731,17193,530,464,0,0,0,0,0,0,0,26972),
(9513,0,5,2,259732,17195,530,464,0,0,0,0,0,0,0,26972),
(9513,0,6,32,0,0,530,464,0,0,0,0,0,141202,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9513,0,0,-4702,-12419,26972),
(9513,1,0,-4915,-12181,26972),
(9513,1,1,-4883,-12152,26972),
(9513,1,2,-4883,-12114,26972),
(9513,1,3,-4916,-12048,26972),
(9513,1,4,-4953,-12015,26972),
(9513,1,5,-5051,-11981,26972),
(9513,2,0,-4886,-11949,26972),
(9513,2,1,-4688,-11548,26972),
(9513,2,2,-4820,-11465,26972),
(9513,2,3,-5048,-11586,26972),
(9513,2,4,-5048,-11652,26972),
(9513,2,5,-5048,-11784,26972),
(9513,2,6,-5017,-11883,26972),
(9513,3,0,-5051,-11913,26972),
(9513,3,1,-4879,-11820,26972),
(9513,3,2,-4688,-11548,26972),
(9513,3,3,-4820,-11465,26972),
(9513,3,4,-5018,-11552,26972),
(9513,3,5,-5048,-11586,26972),
(9513,4,0,-4915,-12181,26972),
(9513,4,1,-4883,-12114,26972),
(9513,4,2,-4850,-11918,26972),
(9513,4,3,-4950,-11950,26972),
(9513,4,4,-5017,-12017,26972),
(9513,4,5,-5020,-12082,26972),
(9513,4,6,-4950,-12151,26972),
(9513,5,0,-4915,-12181,26972),
(9513,5,1,-4883,-12114,26972),
(9513,5,2,-4688,-11548,26972),
(9513,5,3,-4820,-11465,26972),
(9513,5,4,-5048,-11586,26972),
(9513,5,5,-5046,-11719,26972),
(9513,5,6,-5017,-12017,26972),
(9513,5,7,-4985,-12116,26972),
(9513,6,0,-4702,-12419,26972);

-- quest 9523 Precious and Fragile Things Need Special Handling: client QuestPOIBlob 30053, 30054, 400007. objective 0 was its point + 7 points of an objective area; turn-in was its point + 7 points of an objective area
DELETE FROM world.quest_poi WHERE QuestID = 9523;
DELETE FROM world.quest_poi_points WHERE QuestID = 9523;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9523,0,0,-1,0,0,530,464,0,0,1,0,0,0,0,26972),
(9523,0,1,0,260917,23779,530,464,0,0,0,0,0,0,0,26972),
(9523,0,2,32,0,0,530,464,0,0,0,0,0,141203,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9523,0,0,-4694,-12423,26972),
(9523,1,0,-4940,-11953,26972),
(9523,1,1,-4914,-11949,26972),
(9523,1,2,-4880,-11915,26972),
(9523,1,3,-4686,-11567,26972),
(9523,1,4,-4844,-11473,26972),
(9523,1,5,-4989,-11632,26972),
(9523,1,6,-5002,-11663,26972),
(9523,1,7,-4947,-11931,26972),
(9523,2,0,-4694,-12423,26972);

-- quest 9573 Chieftain Oomooroo: client QuestPOIBlob 30140, 30141, 30142, 400046. objective 0 showed the objective 1 area; objective 1 was its point + 9 points of an objective area; turn-in was its point + 9 points of an objective area
DELETE FROM world.quest_poi WHERE QuestID = 9573;
DELETE FROM world.quest_poi_points WHERE QuestID = 9573;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9573,0,0,-1,0,0,530,464,0,0,1,0,0,0,0,26972),
(9573,0,1,0,261325,17448,530,464,0,0,0,0,0,0,0,26972),
(9573,0,2,1,261326,17189,530,464,0,0,0,0,0,0,0,26972),
(9573,0,3,32,0,0,530,464,0,0,0,0,0,142977,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9573,0,0,-3368,-12409,26972),
(9573,1,0,-3177,-12429,26972),
(9573,2,0,-3125,-12557,26972),
(9573,2,1,-3080,-12504,26972),
(9573,2,2,-3070,-12483,26972),
(9573,2,3,-3082,-12461,26972),
(9573,2,4,-3153,-12402,26972),
(9573,2,5,-3219,-12367,26972),
(9573,2,6,-3256,-12361,26972),
(9573,2,7,-3244,-12446,26972),
(9573,2,8,-3221,-12484,26972),
(9573,2,9,-3207,-12499,26972),
(9573,3,0,-3368,-12409,26972);

-- quest 9530 I've Got a Plant: client QuestPOIBlob 30066, 30067, 30068, 400013. objective 0 showed the objective 1 area; objective 1 was its point + 5 points of an objective area; turn-in was its point + 5 points of an objective area
DELETE FROM world.quest_poi WHERE QuestID = 9530;
DELETE FROM world.quest_poi_points WHERE QuestID = 9530;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9530,0,0,-1,0,0,530,464,0,0,1,0,0,0,0,26972),
(9530,0,1,0,261016,23790,530,464,0,0,0,0,0,0,0,26972),
(9530,0,2,1,261017,23791,530,464,0,0,0,0,0,0,0,26972),
(9530,0,3,32,0,0,530,464,0,0,0,0,0,141201,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9530,0,0,-4700,-12415,26972),
(9530,1,0,-4508,-12507,26972),
(9530,1,1,-4484,-12370,26972),
(9530,1,2,-4576,-12370,26972),
(9530,2,0,-4520,-12822,26972),
(9530,2,1,-4477,-12761,26972),
(9530,2,2,-4349,-12537,26972),
(9530,2,3,-4677,-12004,26972),
(9530,2,4,-4817,-12080,26972),
(9530,2,5,-4617,-12649,26972),
(9530,3,0,-4700,-12415,26972);

-- quest 9562 Murlocs... Why Here? Why Now?: client QuestPOIBlob 30113, 30115, 400034. objective 0 was its point + 8 points of an objective area; turn-in was its point + 8 points of an objective area
DELETE FROM world.quest_poi WHERE QuestID = 9562;
DELETE FROM world.quest_poi_points WHERE QuestID = 9562;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9562,0,0,-1,0,0,530,464,0,0,1,0,0,0,0,26972),
(9562,0,1,0,259876,23849,530,464,0,0,1,0,0,0,0,26972),
(9562,0,2,32,0,0,530,464,0,0,0,0,0,142978,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9562,0,0,-3431,-12317,26972),
(9562,1,0,-3103,-11961,26972),
(9562,1,1,-3083,-11949,26972),
(9562,1,2,-3086,-11916,26972),
(9562,1,3,-3122,-11883,26972),
(9562,1,4,-3446,-11718,26972),
(9562,1,5,-3507,-11719,26972),
(9562,1,6,-3535,-11840,26972),
(9562,1,7,-3509,-11873,26972),
(9562,1,8,-3393,-11918,26972),
(9562,2,0,-3431,-12317,26972);

-- quest 9560 Beasts of the Apocalypse!: client QuestPOIBlob 30110, 30111, 400032. objective 0 was its point + 10 points of an objective area; turn-in was its point + 10 points of an objective area
DELETE FROM world.quest_poi WHERE QuestID = 9560;
DELETE FROM world.quest_poi_points WHERE QuestID = 9560;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9560,0,0,-1,0,0,530,464,0,0,1,0,0,0,0,26972),
(9560,0,1,0,262499,23845,530,464,0,0,1,0,0,0,0,26972),
(9560,0,2,32,0,0,530,464,0,0,0,0,0,142997,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9560,0,0,-3443,-12322,26972),
(9560,1,0,-3385,-12814,26972),
(9560,1,1,-3247,-12784,26972),
(9560,1,2,-3087,-12715,26972),
(9560,1,3,-3067,-12635,26972),
(9560,1,4,-3085,-12615,26972),
(9560,1,5,-3148,-12620,26972),
(9560,1,6,-3381,-12653,26972),
(9560,1,7,-3413,-12688,26972),
(9560,1,8,-3417,-12717,26972),
(9560,1,9,-3418,-12752,26972),
(9560,1,10,-3411,-12780,26972),
(9560,2,0,-3443,-12322,26972);

-- quest 9506 A Small Start: client QuestPOIBlob 30012, 30013, 30014, 399999. objective 0 showed the objective 1 point; objective 1 had a 2nd blob at the quest giver, the marker snapped between the two
DELETE FROM world.quest_poi WHERE QuestID = 9506;
DELETE FROM world.quest_poi_points WHERE QuestID = 9506;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9506,0,0,-1,0,0,530,464,0,0,1,0,0,0,0,26972),
(9506,0,1,0,259812,23738,530,464,0,0,0,0,0,0,0,26972),
(9506,0,2,1,259813,23739,530,464,0,0,0,0,0,0,0,26972),
(9506,0,3,32,0,0,530,464,0,0,0,0,0,141201,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9506,0,0,-4700,-12415,26972),
(9506,1,0,-4630,-12925,26972),
(9506,2,0,-4596,-12886,26972),
(9506,3,0,-4700,-12415,26972);

-- quest 9531 Tree's Company: client QuestPOIBlob 30070, 38195, 400015. objective 0 had a 2nd blob at the quest giver, the marker snapped between the two
DELETE FROM world.quest_poi WHERE QuestID = 9531;
DELETE FROM world.quest_poi_points WHERE QuestID = 9531;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9531,0,0,-1,0,0,530,464,0,0,1,0,0,0,0,26972),
(9531,0,1,0,260812,17243,530,464,0,0,2,0,0,0,0,26972),
(9531,0,2,32,0,0,530,464,0,0,0,0,0,141201,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9531,0,0,-4700,-12415,26972),
(9531,1,0,-5043,-11261,26972),
(9531,2,0,-4700,-12415,26972);

-- quest 9537 Show Gnomercy: client QuestPOIBlob 30081, 38197, 38198, 400017. objective 0 doubled; objective 0 had a 2nd blob at the quest giver, the marker snapped between the two
DELETE FROM world.quest_poi WHERE QuestID = 9537;
DELETE FROM world.quest_poi_points WHERE QuestID = 9537;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9537,0,0,-1,0,0,530,464,0,0,1,0,0,0,0,26972),
(9537,0,1,0,259558,23899,530,464,0,0,0,0,0,0,0,26972),
(9537,1,2,0,259558,23899,530,464,0,0,0,0,0,0,0,26972),
(9537,0,3,32,0,0,530,464,0,0,0,0,0,141201,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9537,0,0,-4700,-12415,26972),
(9537,1,0,-5043,-11261,26972),
(9537,2,0,-4705,-12548,26972),
(9537,3,0,-4700,-12415,26972);

-- quest 9570 The Kurken is Lurkin': client QuestPOIBlob 30132, 30133, 400042. objective 0 had a 2nd blob at the quest giver, the marker snapped between the two
DELETE FROM world.quest_poi WHERE QuestID = 9570;
DELETE FROM world.quest_poi_points WHERE QuestID = 9570;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9570,0,0,-1,0,0,530,464,0,0,1,0,0,0,0,26972),
(9570,0,1,0,261038,23860,530,464,0,0,0,0,0,0,0,26972),
(9570,0,2,32,0,0,530,464,0,0,0,0,0,143016,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9570,0,0,-3398,-12412,26972),
(9570,1,0,-3144,-12532,26972),
(9570,2,0,-3398,-12412,26972);

-- 2) Found by the sweep: quests with client blobs, rebuilt the same way.

-- quest 9454 The Great Moongraze Hunt: client QuestPOIBlob 29924, 37475, 37476, 37477, 37478, 37479, 399980. objective 0 area had a tail of another area; objective 0 doubled; objective 0 was its point + 11 points of an objective area; turn-in was its point + 11 points of an objective area
DELETE FROM world.quest_poi WHERE QuestID = 9454;
DELETE FROM world.quest_poi_points WHERE QuestID = 9454;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9454,0,0,-1,0,0,530,464,0,0,1,0,0,0,0,26972),
(9454,0,1,0,259744,23676,530,464,0,0,0,0,0,0,0,26972),
(9454,1,2,0,259744,23676,530,464,0,0,0,0,0,0,0,26972),
(9454,2,3,0,259744,23676,530,464,0,0,0,0,0,0,0,26972),
(9454,3,4,0,259744,23676,530,464,0,0,0,0,0,0,0,26972),
(9454,4,5,0,259744,23676,530,464,0,0,0,0,0,0,0,26972),
(9454,0,6,32,0,0,530,464,0,0,0,0,0,140893,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9454,0,0,-4204,-12526,26972),
(9454,1,0,-4456,-12382,26972),
(9454,1,1,-4383,-12382,26972),
(9454,1,2,-4287,-12347,26972),
(9454,1,3,-4253,-12318,26972),
(9454,1,4,-4152,-12149,26972),
(9454,1,5,-4084,-11614,26972),
(9454,1,6,-4154,-11555,26972),
(9454,1,7,-4419,-11546,26972),
(9454,1,8,-4817,-11949,26972),
(9454,1,9,-4846,-11982,26972),
(9454,1,10,-4781,-12251,26972),
(9454,1,11,-4652,-12319,26972),
(9454,2,0,-4184,-12918,26972),
(9454,2,1,-4120,-12917,26972),
(9454,2,2,-4015,-12880,26972),
(9454,2,3,-3983,-12850,26972),
(9454,2,4,-3989,-12786,26972),
(9454,2,5,-4052,-12716,26972),
(9454,2,6,-4181,-12786,26972),
(9454,3,0,-4417,-12884,26972),
(9454,3,1,-4349,-12882,26972),
(9454,3,2,-4315,-12851,26972),
(9454,3,3,-4252,-12651,26972),
(9454,3,4,-4284,-12616,26972),
(9454,3,5,-4382,-12516,26972),
(9454,3,6,-4585,-12516,26972),
(9454,3,7,-4615,-12617,26972),
(9454,3,8,-4616,-12815,26972),
(9454,4,0,-4550,-11882,26972),
(9454,4,1,-4585,-11785,26972),
(9454,4,2,-4749,-11550,26972),
(9454,4,3,-4818,-11486,26972),
(9454,4,4,-4814,-11551,26972),
(9454,4,5,-4783,-11785,26972),
(9454,5,0,-3582,-12783,26972),
(9454,5,1,-3519,-12783,26972),
(9454,5,2,-3482,-12752,26972),
(9454,5,3,-3484,-12684,26972),
(9454,5,4,-3753,-12284,26972),
(9454,5,5,-3843,-12187,26972),
(9454,5,6,-3883,-12151,26972),
(9454,5,7,-4014,-12154,26972),
(9454,5,8,-4079,-12220,26972),
(9454,5,9,-4079,-12282,26972),
(9454,5,10,-4048,-12583,26972),
(9454,5,11,-3920,-12714,26972),
(9454,6,0,-4204,-12526,26972);

-- quest 9463 Medicinal Purpose: client QuestPOIBlob 29939, 29940, 29941, 29942, 399985. objective 0 area had a tail of another area; objective 0 was its point + 5 points of an objective area; turn-in was its point + 5 points of an objective area
DELETE FROM world.quest_poi WHERE QuestID = 9463;
DELETE FROM world.quest_poi_points WHERE QuestID = 9463;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9463,0,0,-1,0,0,530,464,0,0,1,0,0,0,0,26972),
(9463,0,1,0,259816,23685,530,464,0,0,0,0,0,0,0,26972),
(9463,1,2,0,259816,23685,530,464,0,0,0,0,0,0,0,26972),
(9463,2,3,0,259816,23685,530,464,0,0,0,0,0,0,0,26972),
(9463,0,4,32,0,0,530,464,0,0,0,0,0,141068,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9463,0,0,-4199,-12470,26972),
(9463,1,0,-4456,-12382,26972),
(9463,1,1,-4383,-12382,26972),
(9463,1,2,-4253,-12318,26972),
(9463,1,3,-4152,-12149,26972),
(9463,1,4,-4317,-11985,26972),
(9463,1,5,-4550,-11882,26972),
(9463,1,6,-4817,-11949,26972),
(9463,1,7,-4846,-11982,26972),
(9463,1,8,-4847,-12048,26972),
(9463,1,9,-4781,-12251,26972),
(9463,1,10,-4748,-12283,26972),
(9463,2,0,-4581,-12921,26972),
(9463,2,1,-4316,-12914,26972),
(9463,2,2,-4252,-12651,26972),
(9463,2,3,-4382,-12516,26972),
(9463,2,4,-4485,-12484,26972),
(9463,2,5,-4585,-12516,26972),
(9463,2,6,-4614,-12551,26972),
(9463,2,7,-4614,-12683,26972),
(9463,2,8,-4614,-12751,26972),
(9463,3,0,-4120,-12917,26972),
(9463,3,1,-3949,-12884,26972),
(9463,3,2,-4016,-12750,26972),
(9463,3,3,-4149,-12686,26972),
(9463,3,4,-4181,-12786,26972),
(9463,3,5,-4181,-12851,26972),
(9463,4,0,-4199,-12470,26972);

-- quest 9512 Cookie's Jumbo Gumbo: client QuestPOIBlob 30021, 30022, 30023, 400001. turn-in showed the objective 0 area; objective 0 area had a tail of another area; objective 0 was its point + 2 points of an objective area; turn-in was its point + 2 points of an objective area
DELETE FROM world.quest_poi WHERE QuestID = 9512;
DELETE FROM world.quest_poi_points WHERE QuestID = 9512;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9512,0,0,-1,0,0,530,464,0,0,0,0,0,0,0,26972),
(9512,0,1,0,259945,23757,530,464,0,0,2,0,0,0,0,26972),
(9512,1,2,0,259945,23757,530,464,0,0,2,0,0,0,0,26972),
(9512,0,3,32,0,0,530,464,0,0,0,0,0,141206,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9512,0,0,-4709,-12400,26972),
(9512,1,0,-4665,-13002,26972),
(9512,1,1,-4642,-12801,26972),
(9512,1,2,-4684,-12575,26972),
(9512,1,3,-4850,-12286,26972),
(9512,1,4,-4870,-12475,26972),
(9512,1,5,-4801,-12716,26972),
(9512,2,0,-5219,-11318,26972),
(9512,2,1,-5386,-10950,26972),
(9512,2,2,-5398,-11184,26972),
(9512,3,0,-4709,-12400,26972);

-- quest 9571 The Kurken's Hide: client QuestPOIBlob 30134, 30135, 400044. objective 0 had a 2nd blob at the quest giver, the marker snapped between the two
DELETE FROM world.quest_poi WHERE QuestID = 9571;
DELETE FROM world.quest_poi_points WHERE QuestID = 9571;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9571,0,0,-1,0,0,530,464,0,0,1,0,0,0,0,26972),
(9571,0,1,0,260979,23860,530,464,0,0,0,0,0,0,0,26972),
(9571,0,2,32,0,0,530,464,0,0,0,0,0,143016,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9571,0,0,-3443,-12322,26972),
(9571,1,0,-3144,-12532,26972),
(9571,2,0,-3398,-12412,26972);

-- quest 9579 Galaen's Fate: client QuestPOIBlob 30159, 30160, 400050. objective 0 was its point + 10 points of an objective area; turn-in was its point + 10 points of an objective area
DELETE FROM world.quest_poi WHERE QuestID = 9579;
DELETE FROM world.quest_poi_points WHERE QuestID = 9579;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9579,0,0,-1,0,0,530,476,0,0,1,0,0,0,0,26972),
(9579,0,1,0,261767,23873,530,476,0,0,1,0,0,0,0,26972),
(9579,0,2,32,0,0,530,476,0,0,0,0,0,143493,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9579,0,0,-2014,-11812,26972),
(9579,1,0,-2082,-11418,26972),
(9579,1,1,-2048,-11416,26972),
(9579,1,2,-2018,-11387,26972),
(9579,1,3,-2014,-11350,26972),
(9579,1,4,-2016,-11283,26972),
(9579,1,5,-2023,-11259,26972),
(9579,1,6,-2079,-11224,26972),
(9579,1,7,-2115,-11218,26972),
(9579,1,8,-2152,-11286,26972),
(9579,1,9,-2148,-11352,26972),
(9579,1,10,-2113,-11416,26972),
(9579,2,0,-2090,-11298,26972);

-- quest 9648 Mac'Aree Mushroom Menagerie: client QuestPOIBlob 30249, 30250, 30251, 30252, 38202, 38203, 38204, 38205, 41034, 400091. objective 0 area had a tail of another area; objective 1 area had a tail of another area; objective 0 showed the objective 1 area; objective 1 showed the objective 2 area; objective 0 showed the objective 2 area; objective 2 area had a tail of another area; objective 2 showed the objective 3 area; objective 0 showed the objective 3 area; objective 3 area had a tail of another area; objective 3 was its point + 4 points of an objective area; turn-in was its point + 4 points of an objective area
DELETE FROM world.quest_poi WHERE QuestID = 9648;
DELETE FROM world.quest_poi_points WHERE QuestID = 9648;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9648,0,0,-1,0,0,530,476,0,0,1,0,0,0,0,26972),
(9648,0,1,0,261182,24041,530,476,0,0,1,0,0,0,0,26972),
(9648,0,2,1,261183,24040,530,476,0,0,1,0,0,0,0,26972),
(9648,1,3,1,261183,24040,530,476,0,0,1,0,0,0,0,26972),
(9648,2,4,1,261183,24040,530,476,0,0,1,0,0,0,0,26972),
(9648,0,5,2,261184,24042,530,476,0,0,1,0,0,0,0,26972),
(9648,1,6,2,261184,24042,530,476,0,0,1,0,0,0,0,26972),
(9648,0,7,3,261185,24043,530,476,0,0,1,0,0,0,0,26972),
(9648,1,8,3,261185,24043,530,476,0,0,1,0,0,0,0,26972),
(9648,0,9,32,0,0,530,476,0,0,0,0,0,144988,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9648,0,0,-1994,-11916,26972),
(9648,1,0,-2062,-12235,26972),
(9648,1,1,-2117,-12180,26972),
(9648,1,2,-2353,-11958,26972),
(9648,1,3,-2540,-11869,26972),
(9648,1,4,-2480,-11926,26972),
(9648,2,0,-2061,-12126,26972),
(9648,2,1,-2082,-12059,26972),
(9648,2,2,-2105,-11997,26972),
(9648,2,3,-2209,-11980,26972),
(9648,3,0,-1942,-12205,26972),
(9648,3,1,-1910,-12107,26972),
(9648,3,2,-1957,-11990,26972),
(9648,4,0,-2402,-11815,26972),
(9648,4,1,-2212,-11658,26972),
(9648,4,2,-2651,-11567,26972),
(9648,4,3,-2635,-11693,26972),
(9648,4,4,-2525,-11761,26972),
(9648,5,0,-1787,-12165,26972),
(9648,5,1,-1672,-12100,26972),
(9648,5,2,-1636,-12077,26972),
(9648,5,3,-1671,-12055,26972),
(9648,5,4,-1836,-12059,26972),
(9648,5,5,-1830,-12121,26972),
(9648,6,0,-2316,-12317,26972),
(9648,6,1,-2176,-12313,26972),
(9648,6,2,-2204,-12291,26972),
(9648,6,3,-2279,-12245,26972),
(9648,7,0,-2430,-11634,26972),
(9648,7,1,-2342,-11589,26972),
(9648,7,2,-2393,-11490,26972),
(9648,7,3,-2489,-11418,26972),
(9648,7,4,-2581,-11477,26972),
(9648,7,5,-2629,-11527,26972),
(9648,8,0,-2612,-11316,26972),
(9648,8,1,-2426,-11292,26972),
(9648,8,2,-2363,-11249,26972),
(9648,8,3,-2405,-11170,26972),
(9648,8,4,-2525,-11127,26972),
(9648,9,0,-1994,-11916,26972);

-- quest 9649 Ysera's Tears: client QuestPOIBlob 30253, 38061, 400092. objective 0 was its point + 6 points of an objective area; turn-in was its point + 6 points of an objective area
DELETE FROM world.quest_poi WHERE QuestID = 9649;
DELETE FROM world.quest_poi_points WHERE QuestID = 9649;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9649,0,0,-1,0,0,530,476,0,0,1,0,0,0,0,26972),
(9649,0,1,0,260963,24049,530,476,0,0,1,0,0,0,0,26972),
(9649,0,2,32,0,0,530,476,0,0,0,0,0,144988,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9649,0,0,-1994,-11916,26972),
(9649,1,0,-1220,-12580,26972),
(9649,1,1,-1051,-12559,26972),
(9649,1,2,-947,-12523,26972),
(9649,1,3,-1012,-12408,26972),
(9649,1,4,-1113,-12379,26972),
(9649,1,5,-1226,-12448,26972),
(9649,1,6,-1376,-12546,26972),
(9649,2,0,-1994,-11916,26972);

-- quest 9663 The Kessel Run: client QuestPOIBlob 30254, 30256, 38207, 38209, 400093. objective 0 showed the objective 1 point; objective 1 showed the objective 2 point; objective 0 showed the objective 2 point; objective 2 had a 2nd blob at the quest giver, the marker snapped between the two
DELETE FROM world.quest_poi WHERE QuestID = 9663;
DELETE FROM world.quest_poi_points WHERE QuestID = 9663;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9663,0,0,-1,0,0,530,476,0,0,1,0,0,0,0,26972),
(9663,0,1,0,261366,17440,530,464,0,0,0,0,0,0,0,26972),
(9663,0,2,1,261367,17116,530,464,0,0,0,0,0,0,0,26972),
(9663,0,3,2,261368,17240,530,464,0,0,0,0,0,0,0,26972),
(9663,0,4,32,0,0,530,476,0,0,0,0,0,144814,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9663,0,0,-2662,-12130,26972),
(9663,1,0,-3353,-12400,26972),
(9663,2,0,-4167,-12418,26972),
(9663,3,0,-4700,-12415,26972),
(9663,4,0,-2662,-12130,26972);

-- quest 9666 Declaration of Power: client QuestPOIBlob 30267, 38211, 44302, 400095. objective 0 had a 2nd blob at the quest giver, the marker snapped between the two; objective 30 doubled
DELETE FROM world.quest_poi WHERE QuestID = 9666;
DELETE FROM world.quest_poi_points WHERE QuestID = 9666;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9666,0,0,-1,0,0,530,476,0,0,1,0,0,0,0,26972),
(9666,0,1,0,260916,17701,530,476,0,0,0,0,0,0,0,26972),
(9666,0,2,30,0,0,530,476,0,1,2,0,0,0,0,26972),
(9666,0,3,32,0,0,530,476,0,0,0,0,0,144814,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9666,0,0,-2662,-12130,26972),
(9666,1,0,-2222,-12322,26972),
(9666,2,0,-2233,-12319,26972),
(9666,3,0,-2662,-12130,26972);

-- quest 9674 The Bloodcursed Naga: client QuestPOIBlob 30279, 30280, 30281, 400104. objective 0 area had a tail of another area; objective 0 was its point + 8 points of an objective area; turn-in was its point + 8 points of an objective area
DELETE FROM world.quest_poi WHERE QuestID = 9674;
DELETE FROM world.quest_poi_points WHERE QuestID = 9674;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9674,0,0,-1,0,0,530,476,0,0,1,0,0,0,0,26972),
(9674,0,1,0,259485,17713,530,476,0,0,1,0,0,0,0,26972),
(9674,1,2,0,259485,17713,530,476,0,0,1,0,0,0,0,26972),
(9674,0,3,32,0,0,530,476,0,0,0,0,0,145459,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9674,0,0,-1251,-12657,26972),
(9674,1,0,-1386,-12817,26972),
(9674,1,1,-1351,-12814,26972),
(9674,1,2,-1117,-12781,26972),
(9674,1,3,-986,-12753,26972),
(9674,1,4,-983,-12715,26972),
(9674,1,5,-984,-12684,26972),
(9674,1,6,-1053,-12653,26972),
(9674,1,7,-1116,-12653,26972),
(9674,1,8,-1318,-12715,26972),
(9674,1,9,-1351,-12750,26972),
(9674,1,10,-1382,-12787,26972),
(9674,2,0,-1957,-12936,26972),
(9674,2,1,-1914,-12930,26972),
(9674,2,2,-1728,-12812,26972),
(9674,2,3,-1705,-12761,26972),
(9674,2,4,-1752,-12716,26972),
(9674,2,5,-1948,-12791,26972),
(9674,2,6,-1978,-12826,26972),
(9674,2,7,-2010,-12867,26972),
(9674,2,8,-1992,-12913,26972),
(9674,3,0,-1251,-12657,26972);

-- quest 9682 The Hopeless Ones...: client QuestPOIBlob 30291, 30292, 400105. objective 0 was its point + 6 points of an objective area; turn-in was its point + 6 points of an objective area
DELETE FROM world.quest_poi WHERE QuestID = 9682;
DELETE FROM world.quest_poi_points WHERE QuestID = 9682;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9682,0,0,-1,0,0,530,476,0,0,1,0,0,0,0,26972),
(9682,0,1,0,262405,24153,530,476,0,0,1,0,0,0,0,26972),
(9682,0,2,32,0,0,530,476,0,0,0,0,0,145459,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9682,0,0,-1251,-12657,26972),
(9682,1,0,-1251,-12951,26972),
(9682,1,1,-1116,-12951,26972),
(9682,1,2,-1081,-12933,26972),
(9682,1,3,-1048,-12916,26972),
(9682,1,4,-979,-12847,26972),
(9682,1,5,-983,-12816,26972),
(9682,1,6,-1038,-12792,26972),
(9682,2,0,-1251,-12657,26972);

-- quest 9683 Ending the Bloodcurse: client QuestPOIBlob 30293, 30294, 400106. objective 0 had a 2nd blob at the quest giver, the marker snapped between the two
DELETE FROM world.quest_poi WHERE QuestID = 9683;
DELETE FROM world.quest_poi_points WHERE QuestID = 9683;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9683,0,0,-1,0,0,530,476,0,0,1,0,0,0,0,26972),
(9683,0,1,0,262252,17715,530,476,0,0,1,0,0,0,0,26972),
(9683,0,2,32,0,0,530,476,0,0,0,0,0,145459,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9683,0,0,-1251,-12657,26972),
(9683,1,0,-1902,-12863,26972),
(9683,2,0,-1251,-12657,26972);

-- quest 9687 Restoring Sanctity: client QuestPOIBlob 30300, 30301, 30302, 30303, 30304, 30305, 30306, 400107. objective 0 doubled; objective 0 area had a tail of another area; objective 0 was its point + 2 points of an objective area; turn-in was its point + 2 points of an objective area
DELETE FROM world.quest_poi WHERE QuestID = 9687;
DELETE FROM world.quest_poi_points WHERE QuestID = 9687;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9687,0,0,-1,0,0,530,476,0,0,1,0,0,0,0,26972),
(9687,0,1,0,256518,24185,530,476,0,0,1,0,0,0,0,26972),
(9687,1,2,0,256518,24185,530,476,0,0,1,0,0,0,0,26972),
(9687,2,3,0,256518,24185,530,476,0,0,1,0,0,0,0,26972),
(9687,3,4,0,256518,24185,530,476,0,0,1,0,0,0,0,26972),
(9687,4,5,0,256518,24185,530,476,0,0,1,0,0,0,0,26972),
(9687,5,6,0,256518,24185,530,476,0,0,1,0,0,0,0,26972),
(9687,0,7,32,0,0,530,476,0,0,0,0,0,145131,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9687,0,0,-1502,-12498,26972),
(9687,1,0,-1440,-11856,26972),
(9687,1,1,-1418,-11831,26972),
(9687,1,2,-1452,-11828,26972),
(9687,2,0,-1664,-11829,26972),
(9687,2,1,-1653,-11788,26972),
(9687,2,2,-1681,-11825,26972),
(9687,3,0,-1498,-12065,26972),
(9687,3,1,-1542,-12013,26972),
(9687,3,2,-1542,-12051,26972),
(9687,4,0,-1544,-11842,26972),
(9687,4,1,-1529,-11831,26972),
(9687,4,2,-1523,-11812,26972),
(9687,4,3,-1546,-11821,26972),
(9687,5,0,-1522,-11942,26972),
(9687,5,1,-1485,-11936,26972),
(9687,5,2,-1507,-11908,26972),
(9687,6,0,-1387,-11978,26972),
(9687,6,1,-1388,-11952,26972),
(9687,6,2,-1416,-11976,26972),
(9687,7,0,-1502,-12498,26972);

-- quest 9688 Into the Dream: client QuestPOIBlob 30307, 30308, 30309, 30310, 30311, 30312, 400108. objective 0 doubled; objective 0 area had a tail of another area; objective 0 showed the objective 1 area; objective 1 was its point + 10 points of an objective area; turn-in was its point + 10 points of an objective area
DELETE FROM world.quest_poi WHERE QuestID = 9688;
DELETE FROM world.quest_poi_points WHERE QuestID = 9688;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9688,0,0,-1,0,0,530,476,0,0,1,0,0,0,0,26972),
(9688,0,1,0,256356,17588,530,476,0,0,1,0,0,0,0,26972),
(9688,1,2,0,256356,17588,530,476,0,0,1,0,0,0,0,26972),
(9688,2,3,0,256356,17588,530,476,0,0,1,0,0,0,0,26972),
(9688,0,4,1,256357,17589,530,476,0,0,1,0,0,0,0,26972),
(9688,1,5,1,256357,17589,530,476,0,0,1,0,0,0,0,26972),
(9688,0,6,32,0,0,530,476,0,0,0,0,0,145131,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9688,0,0,-1502,-12498,26972),
(9688,1,0,-1348,-12618,26972),
(9688,1,1,-1290,-12554,26972),
(9688,1,2,-1213,-12424,26972),
(9688,1,3,-1450,-12451,26972),
(9688,1,4,-1473,-12492,26972),
(9688,1,5,-1452,-12585,26972),
(9688,2,0,-1082,-12617,26972),
(9688,2,1,-950,-12616,26972),
(9688,2,2,-884,-12551,26972),
(9688,2,3,-884,-12484,26972),
(9688,2,4,-985,-12384,26972),
(9688,2,5,-1052,-12385,26972),
(9688,2,6,-1082,-12418,26972),
(9688,2,7,-1117,-12585,26972),
(9688,3,0,-1380,-12385,26972),
(9688,3,1,-1150,-12349,26972),
(9688,3,2,-1251,-12251,26972),
(9688,3,3,-1284,-12241,26972),
(9688,3,4,-1316,-12249,26972),
(9688,4,0,-1016,-12616,26972),
(9688,4,1,-950,-12616,26972),
(9688,4,2,-917,-12583,26972),
(9688,4,3,-918,-12520,26972),
(9688,4,4,-1016,-12411,26972),
(9688,4,5,-1084,-12351,26972),
(9688,4,6,-1113,-12382,26972),
(9688,4,7,-1115,-12515,26972),
(9688,5,0,-1281,-12619,26972),
(9688,5,1,-1251,-12584,26972),
(9688,5,2,-1185,-12448,26972),
(9688,5,3,-1184,-12317,26972),
(9688,5,4,-1251,-12251,26972),
(9688,5,5,-1284,-12241,26972),
(9688,5,6,-1348,-12283,26972),
(9688,5,7,-1380,-12319,26972),
(9688,5,8,-1473,-12492,26972),
(9688,5,9,-1479,-12549,26972),
(9688,5,10,-1452,-12585,26972),
(9688,6,0,-1502,-12498,26972);

-- quest 9689 Razormaw: client QuestPOIBlob 30313, 30314, 400109. turn-in showed the objective 0 point
DELETE FROM world.quest_poi WHERE QuestID = 9689;
DELETE FROM world.quest_poi_points WHERE QuestID = 9689;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9689,0,0,-1,0,0,530,476,0,0,1,0,0,0,0,26972),
(9689,0,1,0,256813,17592,530,476,0,0,3,0,0,0,0,26972),
(9689,0,2,32,0,0,530,476,0,0,0,0,0,145131,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9689,0,0,-1502,-12498,26972),
(9689,1,0,-1217,-12482,26972),
(9689,2,0,-1502,-12498,26972);

-- quest 9694 Blood Watch: client QuestPOIBlob 30319, 30320, 400111. objective 0 was its point + 9 points of an objective area; turn-in was its point + 9 points of an objective area
DELETE FROM world.quest_poi WHERE QuestID = 9694;
DELETE FROM world.quest_poi_points WHERE QuestID = 9694;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9694,0,0,-1,0,0,530,476,0,0,1,0,0,0,0,26972),
(9694,0,1,0,260323,17604,530,476,0,0,1,0,0,0,0,26972),
(9694,0,2,32,0,0,530,476,0,0,0,0,0,145136,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9694,0,0,-1960,-11883,26972),
(9694,1,0,-1830,-11721,26972),
(9694,1,1,-1749,-11717,26972),
(9694,1,2,-1713,-11693,26972),
(9694,1,3,-1681,-11660,26972),
(9694,1,4,-1682,-11615,26972),
(9694,1,5,-1720,-11586,26972),
(9694,1,6,-1782,-11548,26972),
(9694,1,7,-1814,-11558,26972),
(9694,1,8,-1852,-11588,26972),
(9694,1,9,-1860,-11669,26972),
(9694,2,0,-1960,-11883,26972);

-- quest 9696 Translations...: client QuestPOIBlob 30322, 30323, 30324, 30325, 400112. objective 0 area had a tail of another area; objective 0 doubled; objective 0 was its point + 10 points of an objective area; turn-in was its point + 10 points of an objective area
DELETE FROM world.quest_poi WHERE QuestID = 9696;
DELETE FROM world.quest_poi_points WHERE QuestID = 9696;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9696,0,0,-1,0,0,530,476,0,0,1,0,0,0,0,26972),
(9696,0,1,0,260211,24399,530,476,0,0,1,0,0,0,0,26972),
(9696,1,2,0,260211,24399,530,476,0,0,1,0,0,0,0,26972),
(9696,2,3,0,260211,24399,530,476,0,0,1,0,0,0,0,26972),
(9696,0,4,32,0,0,530,476,0,0,0,0,0,145136,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9696,0,0,-1943,-11851,26972),
(9696,1,0,-1886,-10919,26972),
(9696,1,1,-1852,-10915,26972),
(9696,1,2,-1819,-10883,26972),
(9696,1,3,-1809,-10644,26972),
(9696,1,4,-1810,-10595,26972),
(9696,1,5,-1894,-10519,26972),
(9696,1,6,-1943,-10524,26972),
(9696,1,7,-2054,-10623,26972),
(9696,1,8,-2119,-10748,26972),
(9696,1,9,-2114,-10853,26972),
(9696,1,10,-2085,-10882,26972),
(9696,1,11,-2018,-10915,26972),
(9696,2,0,-1830,-11721,26972),
(9696,2,1,-1749,-11717,26972),
(9696,2,2,-1713,-11693,26972),
(9696,2,3,-1681,-11660,26972),
(9696,2,4,-1682,-11615,26972),
(9696,2,5,-1720,-11586,26972),
(9696,2,6,-1782,-11548,26972),
(9696,2,7,-1814,-11558,26972),
(9696,2,8,-1852,-11588,26972),
(9696,2,9,-1860,-11669,26972),
(9696,3,0,-2082,-11418,26972),
(9696,3,1,-2048,-11416,26972),
(9696,3,2,-2018,-11387,26972),
(9696,3,3,-2014,-11350,26972),
(9696,3,4,-2016,-11283,26972),
(9696,3,5,-2023,-11259,26972),
(9696,3,6,-2079,-11224,26972),
(9696,3,7,-2115,-11218,26972),
(9696,3,8,-2152,-11286,26972),
(9696,3,9,-2148,-11352,26972),
(9696,3,10,-2113,-11416,26972),
(9696,4,0,-1960,-11883,26972);

-- quest 9700 I Shoot Magic Into the Darkness: client QuestPOIBlob 30329, 30330, 30331, 400117. objective 0 area had a tail of another area; objective 1 was its point + 3 points of an objective area; turn-in was its point + 3 points of an objective area
DELETE FROM world.quest_poi WHERE QuestID = 9700;
DELETE FROM world.quest_poi_points WHERE QuestID = 9700;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9700,0,0,-1,0,0,530,476,0,0,1,0,0,0,0,26972),
(9700,0,1,0,260374,17550,530,476,0,0,1,0,0,0,0,26972),
(9700,0,2,1,260375,-1,530,476,0,0,1,0,0,0,0,26972),
(9700,0,3,32,0,0,530,476,0,0,0,0,0,145136,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9700,0,0,-1960,-11883,26972),
(9700,1,0,-1282,-11850,26972),
(9700,1,1,-1183,-11837,26972),
(9700,1,2,-1147,-11830,26972),
(9700,1,3,-1181,-11756,26972),
(9700,1,4,-1251,-11752,26972),
(9700,1,5,-1313,-11784,26972),
(9700,2,0,-1164,-11863,26972),
(9700,2,1,-1130,-11829,26972),
(9700,2,2,-1164,-11795,26972),
(9700,2,3,-1198,-11829,26972),
(9700,3,0,-1960,-11883,26972);

-- quest 9703 The Cryo-Core: client QuestPOIBlob 30336, 30337, 400120. objective 0 was its point + 9 points of an objective area; turn-in was its point + 9 points of an objective area
DELETE FROM world.quest_poi WHERE QuestID = 9703;
DELETE FROM world.quest_poi_points WHERE QuestID = 9703;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9703,0,0,-1,0,0,530,476,0,0,1,0,0,0,0,26972),
(9703,0,1,0,260705,24236,530,476,0,0,1,0,0,0,0,26972),
(9703,0,2,32,0,0,530,476,0,0,0,0,0,146260,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9703,0,0,-1959,-11890,26972),
(9703,1,0,-2116,-11416,26972),
(9703,1,1,-2057,-11410,26972),
(9703,1,2,-2021,-11386,26972),
(9703,1,3,-2006,-11316,26972),
(9703,1,4,-2012,-11293,26972),
(9703,1,5,-2048,-11248,26972),
(9703,1,6,-2108,-11212,26972),
(9703,1,7,-2127,-11244,26972),
(9703,1,8,-2159,-11377,26972),
(9703,1,9,-2144,-11395,26972),
(9703,2,0,-1959,-11890,26972);

-- quest 9740 The Sun Gate: client QuestPOIBlob 30393, 30394, 400138. objective 0 had a 2nd blob at the quest giver, the marker snapped between the two
DELETE FROM world.quest_poi WHERE QuestID = 9740;
DELETE FROM world.quest_poi_points WHERE QuestID = 9740;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9740,0,0,-1,0,0,530,476,0,0,1,0,0,0,0,26972),
(9740,0,1,0,259560,182026,530,476,0,0,1,0,0,0,0,26972),
(9740,0,2,32,0,0,530,476,0,0,0,0,0,146261,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9740,0,0,-1963,-11887,26972),
(9740,1,0,-2143,-10692,26972),
(9740,2,0,-1963,-11887,26972);

-- quest 9741 Critters of the Void: client QuestPOIBlob 30395, 30396, 400139. objective 0 was its point + 6 points of an objective area; turn-in was its point + 6 points of an objective area
DELETE FROM world.quest_poi WHERE QuestID = 9741;
DELETE FROM world.quest_poi_points WHERE QuestID = 9741;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9741,0,0,-1,0,0,530,476,0,0,1,0,0,0,0,26972),
(9741,0,1,0,254017,17887,530,476,0,0,1,0,0,0,0,26972),
(9741,0,2,32,0,0,530,476,0,0,0,0,0,146735,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9741,0,0,-1963,-11887,26972),
(9741,1,0,-2073,-10784,26972),
(9741,1,1,-2068,-10747,26972),
(9741,1,2,-2118,-10670,26972),
(9741,1,3,-2157,-10663,26972),
(9741,1,4,-2160,-10694,26972),
(9741,1,5,-2161,-10707,26972),
(9741,1,6,-2104,-10781,26972),
(9741,2,0,-1756,-11061,26972);

-- quest 9746 Limits of Physical Exhaustion: client QuestPOIBlob 30401, 30402, 30403, 400143. objective 0 area had a tail of another area; objective 1 was its point + 6 points of an objective area; turn-in was its point + 6 points of an objective area
DELETE FROM world.quest_poi WHERE QuestID = 9746;
DELETE FROM world.quest_poi_points WHERE QuestID = 9746;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9746,0,0,-1,0,0,530,476,0,0,1,0,0,0,0,26972),
(9746,0,1,0,256681,17608,530,476,0,0,1,0,0,0,0,26972),
(9746,0,2,1,256682,17607,530,476,0,0,1,0,0,0,0,26972),
(9746,0,3,32,0,0,530,476,0,0,0,0,0,146261,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9746,0,0,-1963,-11887,26972),
(9746,1,0,-1886,-10919,26972),
(9746,1,1,-1819,-10883,26972),
(9746,1,2,-1818,-10850,26972),
(9746,1,3,-2087,-10720,26972),
(9746,1,4,-2119,-10748,26972),
(9746,1,5,-2114,-10853,26972),
(9746,1,6,-2085,-10882,26972),
(9746,1,7,-2018,-10915,26972),
(9746,2,0,-1852,-10915,26972),
(9746,2,1,-1819,-10883,26972),
(9746,2,2,-1817,-10817,26972),
(9746,2,3,-2087,-10720,26972),
(9746,2,4,-2119,-10748,26972),
(9746,2,5,-2114,-10853,26972),
(9746,2,6,-2051,-10883,26972),
(9746,3,0,-1963,-11887,26972);

-- quest 9756 What We Don't Know...: client QuestPOIBlob 30416, 30417, 400150. objective 0 had a 2nd blob at the quest giver, the marker snapped between the two
DELETE FROM world.quest_poi WHERE QuestID = 9756;
DELETE FROM world.quest_poi_points WHERE QuestID = 9756;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9756,0,0,-1,0,0,530,476,0,0,1,0,0,0,0,26972),
(9756,0,1,0,253869,17974,530,476,0,0,1,0,0,0,0,26972),
(9756,0,2,32,0,0,530,476,0,0,0,0,0,144922,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9756,0,0,-1916,-11794,26972),
(9756,1,0,-1934,-11848,26972),
(9756,2,0,-1916,-11794,26972);

-- quest 9761 Clearing the Way: client QuestPOIBlob 30423, 30424, 30425, 400154. objective 0 showed the objective 1 area; objective 1 was its point + 11 points of an objective area; turn-in was its point + 11 points of an objective area
DELETE FROM world.quest_poi WHERE QuestID = 9761;
DELETE FROM world.quest_poi_points WHERE QuestID = 9761;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9761,0,0,-1,0,0,530,476,0,0,1,0,0,0,0,26972),
(9761,0,1,0,259156,17610,530,476,0,0,1,0,0,0,0,26972),
(9761,0,2,1,259157,17609,530,476,0,0,1,0,0,0,0,26972),
(9761,0,3,32,0,0,530,476,0,0,0,0,0,147415,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9761,0,0,-1777,-11078,26972),
(9761,1,0,-1962,-10798,26972),
(9761,1,1,-1910,-10781,26972),
(9761,1,2,-1872,-10730,26972),
(9761,1,3,-1845,-10684,26972),
(9761,1,4,-1814,-10618,26972),
(9761,1,5,-1810,-10595,26972),
(9761,1,6,-1894,-10519,26972),
(9761,1,7,-1940,-10522,26972),
(9761,1,8,-1943,-10524,26972),
(9761,1,9,-2054,-10627,26972),
(9761,1,10,-2014,-10756,26972),
(9761,1,11,-2012,-10759,26972),
(9761,2,0,-1965,-10801,26972),
(9761,2,1,-1881,-10747,26972),
(9761,2,2,-1845,-10684,26972),
(9761,2,3,-1824,-10641,26972),
(9761,2,4,-1810,-10595,26972),
(9761,2,5,-1894,-10519,26972),
(9761,2,6,-1906,-10520,26972),
(9761,2,7,-1943,-10524,26972),
(9761,2,8,-2054,-10623,26972),
(9761,2,9,-2054,-10627,26972),
(9761,2,10,-2014,-10756,26972),
(9761,2,11,-2012,-10759,26972),
(9761,3,0,-1777,-11078,26972);

-- quest 9779 Intercepting the Message: client QuestPOIBlob 30471, 30472, 30473, 30474, 400167. objective 0 area had a tail of another area; objective 0 doubled; objective 0 was its point + 10 points of an objective area; turn-in was its point + 10 points of an objective area
DELETE FROM world.quest_poi WHERE QuestID = 9779;
DELETE FROM world.quest_poi_points WHERE QuestID = 9779;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9779,0,0,-1,0,0,530,476,0,0,1,0,0,0,0,26972),
(9779,0,1,0,261860,24399,530,476,0,0,1,0,0,0,0,26972),
(9779,1,2,0,261860,24399,530,476,0,0,1,0,0,0,0,26972),
(9779,2,3,0,261860,24399,530,476,0,0,1,0,0,0,0,26972),
(9779,0,4,32,0,0,530,476,0,0,0,0,0,145136,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9779,0,0,-1960,-11883,26972),
(9779,1,0,-1886,-10919,26972),
(9779,1,1,-1852,-10915,26972),
(9779,1,2,-1819,-10883,26972),
(9779,1,3,-1809,-10644,26972),
(9779,1,4,-1810,-10595,26972),
(9779,1,5,-1894,-10519,26972),
(9779,1,6,-1943,-10524,26972),
(9779,1,7,-2054,-10623,26972),
(9779,1,8,-2119,-10748,26972),
(9779,1,9,-2114,-10853,26972),
(9779,1,10,-2085,-10882,26972),
(9779,1,11,-2018,-10915,26972),
(9779,2,0,-1830,-11721,26972),
(9779,2,1,-1749,-11717,26972),
(9779,2,2,-1713,-11693,26972),
(9779,2,3,-1681,-11660,26972),
(9779,2,4,-1682,-11615,26972),
(9779,2,5,-1720,-11586,26972),
(9779,2,6,-1782,-11548,26972),
(9779,2,7,-1814,-11558,26972),
(9779,2,8,-1852,-11588,26972),
(9779,2,9,-1860,-11669,26972),
(9779,3,0,-2082,-11418,26972),
(9779,3,1,-2048,-11416,26972),
(9779,3,2,-2018,-11387,26972),
(9779,3,3,-2014,-11350,26972),
(9779,3,4,-2016,-11283,26972),
(9779,3,5,-2023,-11259,26972),
(9779,3,6,-2079,-11224,26972),
(9779,3,7,-2115,-11218,26972),
(9779,3,8,-2152,-11286,26972),
(9779,3,9,-2148,-11352,26972),
(9779,3,10,-2113,-11416,26972),
(9779,4,0,-1960,-11883,26972);

-- quest 10065 Cutting a Path: client QuestPOIBlob 31126, 31127, 31128, 400395. objective 0 area had a tail of another area; objective 0 was its point + 3 points of an objective area; turn-in was its point + 3 points of an objective area
DELETE FROM world.quest_poi WHERE QuestID = 10065;
DELETE FROM world.quest_poi_points WHERE QuestID = 10065;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(10065,0,0,-1,0,0,530,476,0,0,1,0,0,0,0,26972),
(10065,0,1,0,259224,17527,530,476,0,0,1,0,0,0,0,26972),
(10065,1,2,0,259224,17527,530,476,0,0,1,0,0,0,0,26972),
(10065,0,3,32,0,0,530,476,0,0,0,0,0,146735,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(10065,0,0,-1757,-11062,26972),
(10065,1,0,-1984,-11183,26972),
(10065,1,1,-1883,-11150,26972),
(10065,1,2,-1852,-11117,26972),
(10065,1,3,-1952,-11018,26972),
(10065,1,4,-2116,-10918,26972),
(10065,1,5,-2189,-11117,26972),
(10065,1,6,-2151,-11150,26972),
(10065,1,7,-2115,-11181,26972),
(10065,2,0,-1818,-11015,26972),
(10065,2,1,-1720,-10917,26972),
(10065,2,2,-1782,-10917,26972),
(10065,2,3,-1816,-10952,26972),
(10065,3,0,-1757,-11062,26972);

-- quest 10066 Oh, the Tangled Webs They Weave: client QuestPOIBlob 31129, 31130, 31131, 400396. objective 0 area had a tail of another area; objective 0 was its point + 2 points of an objective area; turn-in was its point + 2 points of an objective area
DELETE FROM world.quest_poi WHERE QuestID = 10066;
DELETE FROM world.quest_poi_points WHERE QuestID = 10066;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(10066,0,0,-1,0,0,530,476,0,0,1,0,0,0,0,26972),
(10066,0,1,0,260527,17346,530,476,0,0,1,0,0,0,0,26972),
(10066,1,2,0,260527,17346,530,476,0,0,1,0,0,0,0,26972),
(10066,0,3,32,0,0,530,476,0,0,0,0,0,147415,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(10066,0,0,-1777,-11078,26972),
(10066,1,0,-2048,-11183,26972),
(10066,1,1,-1984,-11183,26972),
(10066,1,2,-1949,-11150,26972),
(10066,1,3,-1949,-11088,26972),
(10066,1,4,-1952,-11018,26972),
(10066,1,5,-1982,-10988,26972),
(10066,1,6,-2085,-10950,26972),
(10066,1,7,-2115,-10984,26972),
(10066,1,8,-2151,-11150,26972),
(10066,2,0,-1848,-11046,26972),
(10066,2,1,-1816,-10952,26972),
(10066,2,2,-1849,-10984,26972),
(10066,3,0,-1777,-11078,26972);

-- quest 10067 Fouled Water Spirits: client QuestPOIBlob 31132, 31133, 400397. objective 0 was its point + 7 points of an objective area; turn-in was its point + 7 points of an objective area
DELETE FROM world.quest_poi WHERE QuestID = 10067;
DELETE FROM world.quest_poi_points WHERE QuestID = 10067;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(10067,0,0,-1,0,0,530,476,0,0,1,0,0,0,0,26972),
(10067,0,1,0,258964,17358,530,476,0,0,1,0,0,0,0,26972),
(10067,0,2,32,0,0,530,476,0,0,0,0,0,147415,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(10067,0,0,-1777,-11078,26972),
(10067,1,0,-1544,-11172,26972),
(10067,1,1,-1525,-11143,26972),
(10067,1,2,-1490,-11017,26972),
(10067,1,3,-1516,-10950,26972),
(10067,1,4,-1614,-10990,26972),
(10067,1,5,-1647,-11049,26972),
(10067,1,6,-1653,-11085,26972),
(10067,1,7,-1615,-11140,26972),
(10067,2,0,-1777,-11078,26972);

-- quest 10324 The Great Moongraze Hunt: client QuestPOIBlob 31633, 31634, 31635, 31636, 400599. objective 0 doubled; objective 0 area had a tail of another area; objective 0 was its point + 6 points of an objective area; turn-in was its point + 6 points of an objective area
DELETE FROM world.quest_poi WHERE QuestID = 10324;
DELETE FROM world.quest_poi_points WHERE QuestID = 10324;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(10324,0,0,-1,0,0,530,464,0,0,1,0,0,0,0,26972),
(10324,0,1,0,258996,23677,530,464,0,0,0,0,0,0,0,26972),
(10324,1,2,0,258996,23677,530,464,0,0,0,0,0,0,0,26972),
(10324,2,3,0,258996,23677,530,464,0,0,0,0,0,0,0,26972),
(10324,0,4,32,0,0,530,464,0,0,0,0,0,140893,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(10324,0,0,-4204,-12526,26972),
(10324,1,0,-4450,-11983,26972),
(10324,1,1,-4151,-11886,26972),
(10324,1,2,-4084,-11614,26972),
(10324,1,3,-4154,-11555,26972),
(10324,1,4,-4419,-11546,26972),
(10324,1,5,-4449,-11718,26972),
(10324,2,0,-3582,-12783,26972),
(10324,2,1,-3519,-12783,26972),
(10324,2,2,-3482,-12752,26972),
(10324,2,3,-3484,-12684,26972),
(10324,2,4,-3753,-12284,26972),
(10324,2,5,-3843,-12187,26972),
(10324,2,6,-3883,-12151,26972),
(10324,2,7,-4014,-12154,26972),
(10324,2,8,-4079,-12220,26972),
(10324,2,9,-4079,-12282,26972),
(10324,2,10,-4048,-12583,26972),
(10324,2,11,-3920,-12714,26972),
(10324,3,0,-4583,-11851,26972),
(10324,3,1,-4585,-11785,26972),
(10324,3,2,-4749,-11550,26972),
(10324,3,3,-4818,-11486,26972),
(10324,3,4,-4814,-11551,26972),
(10324,3,5,-4783,-11785,26972),
(10324,3,6,-4681,-11819,26972),
(10324,4,0,-4204,-12526,26972);

-- 3) Found by the sweep: merged quests without client blobs, #84 rule (as 8325/9402/12816 in #84, 9147-9315 in #88,
-- 28724 in #105): keep the 23877 rows and the 26124 quest-giver rows (ObjectiveIndex 32), drop the other 26124 rows
-- and the 26124 points merged into Idx1 values owned by 23877 rows; 23877 rows of a later objective carried
-- ObjectiveIndex 0: set to quest_objectives.StorageIndex.

-- quest 9456 Nightstalker Clean Up, Isle 2...: no client blobs, #84 rule: 3 objective areas doubled by 26124 rows; objective 0 had a 2nd blob on the turn-in point (Idx1 4), the marker snapped between the two; 26124 points merged into Idx1 2, 4 (tails on the 23877 areas)
DELETE FROM world.quest_poi WHERE QuestID = 9456;
DELETE FROM world.quest_poi_points WHERE QuestID = 9456;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9456,0,0,0,260422,17202,530,464,0,0,1,0,0,0,0,23877),
(9456,1,1,0,260422,17202,530,464,0,0,1,0,0,0,0,23877),
(9456,2,2,0,260422,17202,530,464,0,0,1,0,0,0,0,23877),
(9456,3,3,0,260422,17202,530,464,0,0,1,0,0,0,0,23877),
(9456,4,4,-1,0,0,530,464,0,0,1,0,0,0,0,23877),
(9456,0,5,32,0,0,530,464,0,0,0,0,0,140895,0,26124),
(9456,1,6,32,0,0,530,476,0,0,0,0,0,147841,0,26124);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9456,0,0,-4385,-11983,23877),
(9456,0,1,-4183,-11784,23877),
(9456,0,2,-4151,-11750,23877),
(9456,0,3,-4252,-11584,23877),
(9456,0,4,-4314,-11522,23877),
(9456,0,5,-4479,-11745,23877),
(9456,0,6,-4481,-11884,23877),
(9456,1,0,-3922,-12385,23877),
(9456,1,1,-3749,-12351,23877),
(9456,1,2,-3717,-12318,23877),
(9456,1,3,-3883,-12151,23877),
(9456,1,4,-4014,-12154,23877),
(9456,1,5,-4047,-12189,23877),
(9456,1,6,-4079,-12282,23877),
(9456,1,7,-4014,-12350,23877),
(9456,2,0,-4681,-11819,23877),
(9456,2,1,-4651,-11784,23877),
(9456,2,2,-4749,-11550,23877),
(9456,2,3,-4784,-11516,23877),
(9456,2,4,-4818,-11486,23877),
(9456,2,5,-4783,-11651,23877),
(9456,2,6,-4748,-11816,23877),
(9456,3,0,-3486,-12814,23877),
(9456,3,1,-3482,-12752,23877),
(9456,3,2,-3484,-12618,23877),
(9456,3,3,-3685,-12482,23877),
(9456,3,4,-3783,-12452,23877),
(9456,3,5,-3850,-12450,23877),
(9456,3,6,-3950,-12486,23877),
(9456,3,7,-4017,-12550,23877),
(9456,3,8,-3983,-12587,23877),
(9456,3,9,-3785,-12716,23877),
(9456,3,10,-3550,-12813,23877),
(9456,4,0,-4167,-12418,23877),
(9456,5,0,-4167,-12418,26124),
(9456,6,0,-1958,-11822,26124);

-- quest 9515 Warlord Sriss'tiz: no client blobs, #84 rule: objective 0 had a 2nd blob on the turn-in point (Idx1 1), the marker snapped between the two
DELETE FROM world.quest_poi WHERE QuestID = 9515;
DELETE FROM world.quest_poi_points WHERE QuestID = 9515;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9515,0,0,0,261253,17298,530,464,0,0,1,0,0,0,0,23877),
(9515,1,1,-1,0,0,530,464,0,0,1,0,0,0,0,23877),
(9515,0,2,32,0,0,530,464,0,0,0,0,0,141202,0,26124),
(9515,1,3,32,0,0,530,476,0,0,0,0,0,147778,0,26124);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9515,0,0,-4806,-11520,23877),
(9515,1,0,-4702,-12419,23877),
(9515,2,0,-4702,-12419,26124),
(9515,3,0,-1953,-11835,26124);

-- quest 9549 Artifacts of the Blacksilt: no client blobs, #84 rule: a 26124 objective 0 row showed the objective 1 area (Idx1 1); objective 1 had a 2nd blob on the turn-in point (Idx1 2), the marker snapped between the two; 26124 points merged into Idx1 2 (tails on the 23877 areas); 23877 rows at Idx1 1 had ObjectiveIndex 0 for objective 1
DELETE FROM world.quest_poi WHERE QuestID = 9549;
DELETE FROM world.quest_poi_points WHERE QuestID = 9549;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9549,0,0,0,260556,23834,530,476,0,0,1,0,0,0,0,23877),
(9549,1,1,1,260557,23833,530,476,0,0,1,0,0,0,0,23877),
(9549,2,2,-1,0,0,530,476,0,0,1,0,0,0,0,23877),
(9549,0,3,32,0,0,530,476,0,0,0,0,0,142871,0,26124);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9549,0,0,-1163,-11665,23877),
(9549,0,1,-1118,-11417,23877),
(9549,0,2,-1082,-11193,23877),
(9549,0,3,-1085,-11114,23877),
(9549,0,4,-1145,-11046,23877),
(9549,0,5,-1411,-11221,23877),
(9549,0,6,-1181,-11651,23877),
(9549,1,0,-1218,-11517,23877),
(9549,1,1,-1153,-11516,23877),
(9549,1,2,-1082,-11193,23877),
(9549,1,3,-1085,-11114,23877),
(9549,1,4,-1250,-10884,23877),
(9549,1,5,-1281,-10920,23877),
(9549,1,6,-1411,-11221,23877),
(9549,1,7,-1243,-11512,23877),
(9549,2,0,-1220,-11450,23877),
(9549,3,0,-1220,-11450,26124);

-- quest 9567 Know Thine Enemy: no client blobs, #84 rule: objective 0 had a 2nd blob on the turn-in point (Idx1 1), the marker snapped between the two
DELETE FROM world.quest_poi WHERE QuestID = 9567;
DELETE FROM world.quest_poi_points WHERE QuestID = 9567;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9567,0,0,0,260668,23859,530,476,0,0,1,0,0,0,0,23877),
(9567,1,1,-1,0,0,530,476,0,0,1,0,0,0,0,23877),
(9567,0,2,32,0,0,530,476,0,0,0,0,0,142869,0,26124);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9567,0,0,-2310,-11266,23877),
(9567,1,0,-2020,-11872,23877),
(9567,2,0,-2020,-11872,26124);

-- quest 9569 Containing the Threat: no client blobs, #84 rule: 1 objective area doubled by 26124 rows; a 26124 objective 0 row showed the objective 1 area (Idx1 1); a 26124 objective 1 row showed the objective 2 area (Idx1 2); a 26124 objective 2 row showed the objective 3 area (Idx1 4); objective 3 had a 2nd blob on the turn-in point (Idx1 5), the marker snapped between the two; 26124 points merged into Idx1 2, 3, 5 (tails on the 23877 areas); 23877 rows at Idx1 1, 2, 3, 4 had ObjectiveIndex 0 for objective 1/2/3
DELETE FROM world.quest_poi WHERE QuestID = 9569;
DELETE FROM world.quest_poi_points WHERE QuestID = 9569;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9569,0,0,0,260777,17494,530,476,0,0,1,0,0,0,0,23877),
(9569,1,1,1,260778,17342,530,476,0,0,1,0,0,0,0,23877),
(9569,2,2,2,260779,17340,530,476,0,0,1,0,0,0,0,23877),
(9569,3,3,2,260779,17340,530,476,0,0,1,0,0,0,0,23877),
(9569,4,4,3,260780,23863,530,476,0,0,1,0,0,0,0,23877),
(9569,5,5,-1,0,0,530,476,0,0,1,0,0,0,0,23877),
(9569,0,6,32,0,0,530,476,0,0,0,0,0,142869,0,26124);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9569,0,0,-1401,-11442,23877),
(9569,1,0,-1483,-11506,23877),
(9569,1,1,-1453,-11464,23877),
(9569,1,2,-1519,-11285,23877),
(9569,1,3,-1546,-11217,23877),
(9569,1,4,-1582,-11218,23877),
(9569,1,5,-1622,-11253,23877),
(9569,1,6,-1626,-11286,23877),
(9569,1,7,-1612,-11354,23877),
(9569,2,0,-1524,-11487,23877),
(9569,2,1,-1453,-11464,23877),
(9569,2,2,-1516,-11315,23877),
(9569,2,3,-1552,-11315,23877),
(9569,2,4,-1612,-11354,23877),
(9569,3,0,-1626,-11286,23877),
(9569,3,1,-1559,-11240,23877),
(9569,3,2,-1552,-11211,23877),
(9569,3,3,-1620,-11215,23877),
(9569,4,0,-1466,-11474,23877),
(9569,4,1,-1447,-11469,23877),
(9569,4,2,-1382,-11450,23877),
(9569,4,3,-1567,-11286,23877),
(9569,4,4,-1586,-11321,23877),
(9569,4,5,-1561,-11394,23877),
(9569,4,6,-1528,-11460,23877),
(9569,5,0,-2020,-11872,23877),
(9569,6,0,-2020,-11872,26124);

-- quest 9574 Victims of Corruption: no client blobs, #84 rule: 8 objective areas doubled by 26124 rows; objective 0 had a 2nd blob on the turn-in point (Idx1 9), the marker snapped between the two; 26124 points merged into Idx1 5, 8, 9 (tails on the 23877 areas)
DELETE FROM world.quest_poi WHERE QuestID = 9574;
DELETE FROM world.quest_poi_points WHERE QuestID = 9574;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9574,0,0,0,262371,23869,530,476,0,0,1,0,0,0,0,23877),
(9574,1,1,0,262371,23869,530,476,0,0,1,0,0,0,0,23877),
(9574,2,2,0,262371,23869,530,476,0,0,1,0,0,0,0,23877),
(9574,3,3,0,262371,23869,530,476,0,0,1,0,0,0,0,23877),
(9574,4,4,0,262371,23869,530,476,0,0,1,0,0,0,0,23877),
(9574,5,5,0,262371,23869,530,476,0,0,1,0,0,0,0,23877),
(9574,6,6,0,262371,23869,530,476,0,0,1,0,0,0,0,23877),
(9574,7,7,0,262371,23869,530,476,0,0,1,0,0,0,0,23877),
(9574,8,8,0,262371,23869,530,476,0,0,1,0,0,0,0,23877),
(9574,9,9,-1,0,0,530,476,0,0,1,0,0,0,0,23877),
(9574,0,10,32,0,0,530,476,0,0,0,0,0,142870,0,26124);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9574,0,0,-2215,-11816,23877),
(9574,0,1,-2151,-11816,23877),
(9574,0,2,-2157,-11786,23877),
(9574,1,0,-1722,-11943,23877),
(9574,1,1,-1750,-11816,23877),
(9574,1,2,-1850,-11918,23877),
(9574,2,0,-2414,-11881,23877),
(9574,2,1,-2476,-11819,23877),
(9574,2,2,-2450,-11877,23877),
(9574,3,0,-1958,-12208,23877),
(9574,3,1,-1884,-12149,23877),
(9574,3,2,-1913,-12118,23877),
(9574,3,3,-1949,-12151,23877),
(9574,4,0,-2081,-12148,23877),
(9574,4,1,-2051,-12117,23877),
(9574,4,2,-2018,-12082,23877),
(9574,4,3,-2084,-11951,23877),
(9574,5,0,-1820,-11750,23877),
(9574,5,1,-1880,-11679,23877),
(9574,5,2,-1918,-11718,23877),
(9574,6,0,-2181,-12049,23877),
(9574,6,1,-2183,-11986,23877),
(9574,6,2,-2249,-11981,23877),
(9574,7,0,-2382,-11783,23877),
(9574,7,1,-2316,-11781,23877),
(9574,7,2,-2283,-11696,23877),
(9574,7,3,-2349,-11661,23877),
(9574,7,4,-2516,-11652,23877),
(9574,7,5,-2582,-11650,23877),
(9574,7,6,-2515,-11716,23877),
(9574,8,0,-2518,-11582,23877),
(9574,8,1,-2516,-11516,23877),
(9574,8,2,-2583,-11516,23877),
(9574,9,0,-2014,-11812,23877),
(9574,10,0,-2014,-11812,26124);

-- quest 9580 The Bear Necessities: no client blobs, #84 rule: 4 objective areas doubled by 26124 rows; objective 0 had a 2nd blob on the turn-in point (Idx1 5), the marker snapped between the two; 26124 points merged into Idx1 1, 2, 4, 5 (tails on the 23877 areas)
DELETE FROM world.quest_poi WHERE QuestID = 9580;
DELETE FROM world.quest_poi_points WHERE QuestID = 9580;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9580,0,0,0,260955,24026,530,476,0,0,1,0,0,0,0,23877),
(9580,1,1,0,260955,24026,530,476,0,0,1,0,0,0,0,23877),
(9580,2,2,0,260955,24026,530,476,0,0,1,0,0,0,0,23877),
(9580,3,3,0,260955,24026,530,476,0,0,1,0,0,0,0,23877),
(9580,4,4,0,260955,24026,530,476,0,0,1,0,0,0,0,23877),
(9580,5,5,-1,0,0,530,476,0,0,1,0,0,0,0,23877),
(9580,0,6,32,0,0,530,476,0,0,0,0,0,144794,0,26124);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9580,0,0,-2015,-11547,23877),
(9580,0,1,-1915,-11515,23877),
(9580,0,2,-1880,-11487,23877),
(9580,0,3,-1786,-11381,23877),
(9580,0,4,-1818,-11280,23877),
(9580,0,5,-1851,-11184,23877),
(9580,0,6,-1916,-11189,23877),
(9580,0,7,-1951,-11219,23877),
(9580,0,8,-2115,-11516,23877),
(9580,1,0,-1515,-11649,23877),
(9580,1,1,-1451,-11646,23877),
(9580,1,2,-1451,-11581,23877),
(9580,1,3,-1650,-11453,23877),
(9580,1,4,-1683,-11482,23877),
(9580,1,5,-1582,-11646,23877),
(9580,2,0,-1350,-11549,23877),
(9580,2,1,-1271,-11398,23877),
(9580,2,2,-1323,-11404,23877),
(9580,2,3,-1382,-11517,23877),
(9580,3,0,-1716,-11384,23877),
(9580,3,1,-1681,-11352,23877),
(9580,3,2,-1684,-11086,23877),
(9580,3,3,-1718,-11120,23877),
(9580,3,4,-1750,-11216,23877),
(9580,4,0,-1218,-11684,23877),
(9580,4,1,-1282,-11621,23877),
(9580,4,2,-1347,-11682,23877),
(9580,4,3,-1284,-11683,23877),
(9580,5,0,-1998,-11897,23877),
(9580,6,0,-1998,-11897,26124);

-- quest 9582 Strength of One: no client blobs, #84 rule: objective 0 had a 2nd blob on the turn-in point (Idx1 1), the marker snapped between the two
DELETE FROM world.quest_poi WHERE QuestID = 9582;
DELETE FROM world.quest_poi_points WHERE QuestID = 9582;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9582,0,0,0,260918,17556,530,464,0,0,1,0,0,0,0,23877),
(9582,1,1,-1,0,0,530,464,0,0,1,0,0,0,0,23877),
(9582,0,2,32,0,0,530,464,0,0,0,0,0,143456,0,26124);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9582,0,0,-3064,-12699,23877),
(9582,1,0,-4165,-12536,23877),
(9582,2,0,-4165,-12536,26124);

-- quest 9624 A Favorite Treat: no client blobs, #84 rule: 2 objective areas doubled by 26124 rows; objective 0 had a 2nd blob on the turn-in point (Idx1 3), the marker snapped between the two; 26124 points merged into Idx1 1, 3 (tails on the 23877 areas)
DELETE FROM world.quest_poi WHERE QuestID = 9624;
DELETE FROM world.quest_poi_points WHERE QuestID = 9624;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9624,0,0,0,261113,23927,530,476,0,0,1,0,0,0,0,23877),
(9624,1,1,0,261113,23927,530,476,0,0,1,0,0,0,0,23877),
(9624,2,2,0,261113,23927,530,476,0,0,1,0,0,0,0,23877),
(9624,3,3,-1,0,0,530,476,0,0,1,0,0,0,0,23877),
(9624,0,4,32,0,0,530,476,0,0,0,0,0,144538,0,26124);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9624,0,0,-2533,-12169,23877),
(9624,0,1,-2496,-12162,23877),
(9624,0,2,-2477,-12127,23877),
(9624,0,3,-2486,-12106,23877),
(9624,0,4,-2637,-11954,23877),
(9624,0,5,-2691,-11932,23877),
(9624,0,6,-2715,-11930,23877),
(9624,0,7,-2762,-11991,23877),
(9624,0,8,-2758,-12034,23877),
(9624,0,9,-2670,-12110,23877),
(9624,1,0,-2593,-12328,23877),
(9624,1,1,-2529,-12324,23877),
(9624,1,2,-2614,-12211,23877),
(9624,1,3,-2634,-12201,23877),
(9624,1,4,-2679,-12296,23877),
(9624,2,0,-2426,-12391,23877),
(9624,2,1,-2342,-12340,23877),
(9624,2,2,-2384,-12250,23877),
(9624,2,3,-2428,-12271,23877),
(9624,2,4,-2442,-12326,23877),
(9624,2,5,-2442,-12369,23877),
(9624,3,0,-2690,-12145,23877),
(9624,4,0,-2690,-12145,26124);

-- quest 9629 Catch and Release: no client blobs, #84 rule: 1 objective area doubled by 26124 rows; objective 0 had a 2nd blob on the turn-in point (Idx1 2), the marker snapped between the two; 26124 points merged into Idx1 2 (tails on the 23877 areas)
DELETE FROM world.quest_poi WHERE QuestID = 9629;
DELETE FROM world.quest_poi_points WHERE QuestID = 9629;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9629,0,0,0,261063,17654,530,476,0,0,1,0,0,0,0,23877),
(9629,1,1,0,261063,17654,530,476,0,0,1,0,0,0,0,23877),
(9629,2,2,-1,0,0,530,476,0,0,1,0,0,0,0,23877),
(9629,0,3,32,0,0,530,476,0,0,0,0,0,142870,0,26124);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9629,0,0,-2849,-11283,23877),
(9629,0,1,-2821,-11282,23877),
(9629,0,2,-2760,-11209,23877),
(9629,0,3,-2787,-11182,23877),
(9629,0,4,-2819,-11182,23877),
(9629,0,5,-2850,-11185,23877),
(9629,1,0,-2719,-11816,23877),
(9629,1,1,-2722,-11784,23877),
(9629,1,2,-2820,-11384,23877),
(9629,1,3,-2852,-11353,23877),
(9629,1,4,-2850,-11647,23877),
(9629,1,5,-2849,-11716,23877),
(9629,1,6,-2817,-11749,23877),
(9629,2,0,-2014,-11812,23877),
(9629,3,0,-2014,-11812,26124);

-- quest 9634 Alien Predators: no client blobs, #84 rule: 1 objective area doubled by 26124 rows; objective 0 had a 2nd blob on the turn-in point (Idx1 2), the marker snapped between the two; 26124 points merged into Idx1 1, 2 (tails on the 23877 areas)
DELETE FROM world.quest_poi WHERE QuestID = 9634;
DELETE FROM world.quest_poi_points WHERE QuestID = 9634;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9634,0,0,0,261278,17525,530,476,0,0,1,0,0,0,0,23877),
(9634,1,1,0,261278,17525,530,476,0,0,1,0,0,0,0,23877),
(9634,2,2,-1,0,0,530,476,0,0,1,0,0,0,0,23877),
(9634,0,3,32,0,0,530,476,0,0,0,0,0,144542,0,26124);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9634,0,0,-2755,-12055,23877),
(9634,0,1,-2684,-12051,23877),
(9634,0,2,-2550,-12016,23877),
(9634,0,3,-2518,-11987,23877),
(9634,0,4,-2583,-11921,23877),
(9634,0,5,-2617,-11916,23877),
(9634,0,6,-2683,-11915,23877),
(9634,0,7,-2715,-11918,23877),
(9634,0,8,-2747,-11923,23877),
(9634,0,9,-2776,-11984,23877),
(9634,1,0,-2551,-12510,23877),
(9634,1,1,-2515,-12510,23877),
(9634,1,2,-2454,-12508,23877),
(9634,1,3,-2448,-12485,23877),
(9634,1,4,-2649,-12316,23877),
(9634,1,5,-2744,-12279,23877),
(9634,1,6,-2614,-12475,23877),
(9634,1,7,-2580,-12509,23877),
(9634,2,0,-2670,-12131,23877),
(9634,3,0,-2670,-12131,26124);

-- quest 9643 Constrictor Vines: no client blobs, #84 rule: 4 objective areas doubled by 26124 rows; objective 0 had a 2nd blob on the turn-in point (Idx1 5), the marker snapped between the two; 26124 points merged into Idx1 1, 3, 4, 5 (tails on the 23877 areas)
DELETE FROM world.quest_poi WHERE QuestID = 9643;
DELETE FROM world.quest_poi_points WHERE QuestID = 9643;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9643,0,0,0,262211,23994,530,476,0,0,1,0,0,0,0,23877),
(9643,1,1,0,262211,23994,530,476,0,0,1,0,0,0,0,23877),
(9643,2,2,0,262211,23994,530,476,0,0,1,0,0,0,0,23877),
(9643,3,3,0,262211,23994,530,476,0,0,1,0,0,0,0,23877),
(9643,4,4,0,262211,23994,530,476,0,0,1,0,0,0,0,23877),
(9643,5,5,-1,0,0,530,476,0,0,1,0,0,0,0,23877),
(9643,0,6,32,0,0,530,476,0,0,0,0,0,144794,0,26124);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9643,0,0,-2015,-11547,23877),
(9643,0,1,-1752,-11482,23877),
(9643,0,2,-1786,-11451,23877),
(9643,0,3,-1882,-11417,23877),
(9643,0,4,-1986,-11451,23877),
(9643,0,5,-2077,-11488,23877),
(9643,0,6,-2115,-11516,23877),
(9643,1,0,-1950,-11349,23877),
(9643,1,1,-1882,-11348,23877),
(9643,1,2,-1818,-11280,23877),
(9643,1,3,-1817,-11217,23877),
(9643,1,4,-1916,-11189,23877),
(9643,1,5,-1949,-11283,23877),
(9643,2,0,-1515,-11649,23877),
(9643,2,1,-1451,-11646,23877),
(9643,2,2,-1350,-11549,23877),
(9643,2,3,-1319,-11516,23877),
(9643,2,4,-1612,-11486,23877),
(9643,2,5,-1647,-11515,23877),
(9643,2,6,-1582,-11646,23877),
(9643,3,0,-1684,-11284,23877),
(9643,3,1,-1683,-11148,23877),
(9643,3,2,-1684,-11086,23877),
(9643,3,3,-1751,-11151,23877),
(9643,3,4,-1717,-11252,23877),
(9643,4,0,-1681,-11415,23877),
(9643,4,1,-1681,-11352,23877),
(9643,4,2,-1716,-11384,23877),
(9643,5,0,-1998,-11897,23877),
(9643,6,0,-1998,-11897,26124);

-- quest 9646 WANTED: Deathclaw: no client blobs, #84 rule: objective 0 had a 2nd blob on the turn-in point (Idx1 1), the marker snapped between the two
DELETE FROM world.quest_poi WHERE QuestID = 9646;
DELETE FROM world.quest_poi_points WHERE QuestID = 9646;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9646,0,0,0,261617,24025,530,476,0,0,1,0,0,0,0,23877),
(9646,1,1,-1,0,0,530,476,0,0,1,0,0,0,0,23877),
(9646,0,2,32,0,0,530,476,0,0,0,0,0,145001,0,26124);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9646,0,0,-1423,-11289,23877),
(9646,1,0,-1916,-11791,23877),
(9646,2,0,-2044,-11878,26124);

-- quest 9647 Culling the Flutterers: no client blobs, #84 rule: 2 objective areas doubled by 26124 rows; objective 0 had a 2nd blob on the turn-in point (Idx1 3), the marker snapped between the two; 26124 points merged into Idx1 1, 2, 3 (tails on the 23877 areas)
DELETE FROM world.quest_poi WHERE QuestID = 9647;
DELETE FROM world.quest_poi_points WHERE QuestID = 9647;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9647,0,0,0,262320,17350,530,476,0,0,1,0,0,0,0,23877),
(9647,1,1,0,262320,17350,530,476,0,0,1,0,0,0,0,23877),
(9647,2,2,0,262320,17350,530,476,0,0,1,0,0,0,0,23877),
(9647,3,3,-1,0,0,530,476,0,0,1,0,0,0,0,23877),
(9647,0,4,32,0,0,530,476,0,0,0,0,0,144794,0,26124);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9647,0,0,-2015,-11547,23877),
(9647,0,1,-1915,-11515,23877),
(9647,0,2,-1880,-11487,23877),
(9647,0,3,-1916,-11449,23877),
(9647,0,4,-2097,-11470,23877),
(9647,0,5,-2115,-11516,23877),
(9647,1,0,-1419,-11651,23877),
(9647,1,1,-1427,-11544,23877),
(9647,1,2,-1512,-11583,23877),
(9647,1,3,-1582,-11646,23877),
(9647,1,4,-1515,-11649,23877),
(9647,2,0,-1950,-11349,23877),
(9647,2,1,-1882,-11348,23877),
(9647,2,2,-1886,-11282,23877),
(9647,2,3,-1949,-11283,23877),
(9647,3,0,-1998,-11897,23877),
(9647,4,0,-1998,-11897,26124);

-- quest 9667 Saving Princess Stillpine: no client blobs; here the 23877 rows are in the retail layout (turn-in first, the points belong to them: turn-in on Stillpine Ambassador Frasaboo 18803) and three 21154 rows in the old layout (turn-in last) sat on the same Idx1: the 21154 turn-in row put a 2nd turn-in marker on the objective-27 point, its objective-27 row sat on an objective-0 point. #84 rule: keep the 23877 rows + both 26124 quest-giver rows, drop the 21154 rows
DELETE FROM world.quest_poi WHERE QuestID = 9667;
DELETE FROM world.quest_poi_points WHERE QuestID = 9667;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9667,0,0,-1,0,0,530,476,0,0,1,0,0,0,0,23877),
(9667,0,1,0,261128,17682,530,476,0,2,1,0,0,0,0,23877),
(9667,1,2,0,261128,17682,530,476,0,2,1,0,0,0,0,23877),
(9667,0,3,27,0,0,530,476,0,1,1,0,0,0,0,23877),
(9667,0,4,32,0,0,530,476,0,0,0,0,0,145408,0,26124),
(9667,1,5,32,0,0,530,476,0,0,0,0,0,147713,0,26124);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9667,0,0,-1975,-11874,23877),
(9667,1,0,-2520,-12302,23877),
(9667,2,0,-1967,-11824,23877),
(9667,3,0,-2427,-12167,23877),
(9667,4,0,-2520,-12302,26124),
(9667,5,0,-1967,-11824,26124);

-- quest 9669 The Missing Expedition: no client blobs, #84 rule: a 26124 objective 0 row showed the objective 1 area (Idx1 1); a 26124 objective 1 row showed the objective 2 point (Idx1 2); objective 2 had a 2nd blob on the turn-in point (Idx1 3), the marker snapped between the two; 26124 points merged into Idx1 2 (tails on the 23877 areas); 23877 rows at Idx1 1, 2 had ObjectiveIndex 0 for objective 1/2
DELETE FROM world.quest_poi WHERE QuestID = 9669;
DELETE FROM world.quest_poi_points WHERE QuestID = 9669;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9669,0,0,0,260925,17523,530,476,0,0,1,0,0,0,0,23877),
(9669,1,1,1,260926,17522,530,476,0,0,1,0,0,0,0,23877),
(9669,2,2,2,260927,17683,530,476,0,0,1,0,0,0,0,23877),
(9669,3,3,-1,0,0,530,476,0,0,1,0,0,0,0,23877),
(9669,0,4,32,0,0,530,476,0,0,0,0,0,145130,0,26124);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9669,0,0,-1552,-10916,23877),
(9669,0,1,-1522,-10885,23877),
(9669,0,2,-1379,-10683,23877),
(9669,0,3,-1379,-10645,23877),
(9669,0,4,-1416,-10621,23877),
(9669,0,5,-1686,-10648,23877),
(9669,0,6,-1714,-10682,23877),
(9669,0,7,-1711,-10720,23877),
(9669,0,8,-1678,-10817,23877),
(9669,0,9,-1650,-10851,23877),
(9669,0,10,-1582,-10913,23877),
(9669,1,0,-1552,-10916,23877),
(9669,1,1,-1522,-10885,23877),
(9669,1,2,-1379,-10683,23877),
(9669,1,3,-1379,-10645,23877),
(9669,1,4,-1416,-10621,23877),
(9669,1,5,-1686,-10648,23877),
(9669,1,6,-1714,-10682,23877),
(9669,1,7,-1711,-10720,23877),
(9669,1,8,-1678,-10817,23877),
(9669,1,9,-1650,-10851,23877),
(9669,1,10,-1582,-10913,23877),
(9669,2,0,-1583,-10667,23877),
(9669,3,0,-1999,-11812,23877),
(9669,4,0,-1999,-11812,26124);

-- 4) Tree's Company (9531): the Tree Disguise Kit (23792) casts Tree Disguise 30298 (3 s cast, 90 s: transform into
--    17315 + root + SEND_EVENT 10675). It needs the spell focus 1377 = Naga Flag 181694 (type 8, radius 30; spawn 7801
--    at -5083.4, -11252.2) and has a condition (conditions 17/30298: CONDITION_NEAR_CREATURE 17318, 30 yd, negated) so
--    it cannot start a second meeting while Geezle is there. Event 10675 (event_scripts) summons Geezle 17318 at the flag
--    for 90 s; his SmartAI summons Engineer "Spark" Overgrind 17243, who walks to him (path 17243), they talk, and Spark
--    gives the credit "The Traitor Uncovered" (kill credit 17243).
-- 4a) Geezle also had a permanent spawn (creature 36546) on the exact event summon point: whenever it was up, the kit
--    failed with "You can't do that yet" (the negated near-Geezle condition), and that Geezle ran the meeting on its own
--    at every respawn (5 min), crediting whoever stood near Spark. Geezle only comes when the kit is used ("Use the
--    disguise kit when you see the flag and wait. Eventually the traitor will show up."): spawn removed. No
--    creature_addon / smart_scripts / pool / game_event rows use that guid.
DELETE FROM world.creature WHERE guid = 36546 AND id = 17318;
-- 4b) Spark gave the credit to players within 15 yd of him, but the kit works up to 30 yd from the flag and roots the
--    tree where it was used, so a tree 16-30 yd away watched the whole meeting without credit. Now every player within
--    50 yd of Spark who wears the Tree Disguise (aura 30298) gets it (PLAYER_DISTANCE target_param2 = required aura),
--    like the TrinityCore npc_geezle script (50 yd, disguise aura).
UPDATE world.smart_scripts SET target_param1 = 50, target_param2 = 30298,
  comment = 'Link - Give quest credit (disguised players within 50 yd)'
WHERE entryorguid = 17243 AND source_type = 0 AND id = 7 AND action_type = 33 AND target_type = 18;
