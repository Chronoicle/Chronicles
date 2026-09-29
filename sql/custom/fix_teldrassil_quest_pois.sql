-- Teldrassil / Shadowglen quest map markers (tyrvana, desktop team batch, Refs #105).
-- Undo: sql/custom/undo_teldrassil_quest_pois.sql. Goes live with a worldserver restart (no .reload).
-- Players may need to delete the client's Cache folder to see the new markers.
--
-- Cause (same as #84/#88): quest_poi / quest_poi_points of these quests are two sniff imports merged into the same
-- keys: build 23877 (BlobIndex = Idx1, turn-in LAST, every objective written as ObjectiveIndex 0) and build 26124
-- (turn-in FIRST). Rows took each other's Idx1 and the point lists got mixed, so an objective had a second blob at
-- the quest giver (the marker "snaps" to whichever is closer), turn-in "areas" were objective polygons, objectives
-- were doubled, or the turn-in row was lost completely.
-- Rebuilt from the 7.3.5 client's own QuestPOIBlob.db2 / QuestPOIPoint.db2 (build 26972) in the retail layout, same
-- method as #84/#88: Idx1 0 = turn-in (ObjectiveIndex -1), then the objective areas (BlobIndex counts areas per
-- objective, QuestObjectiveID / QuestObjectID from quest_objectives by StorageIndex), then the quest-giver blob
-- (ObjectiveIndex 32). Flags / WoDUnk1 (SpawnTrackingID) kept from the old row of the same blob (26124 first).
-- Quests the client has no blobs for (the Cataclysm Shadowglen quests) are built from the NPC / object spawns.

-- 1) Reported quests, rebuilt from the client blobs.

-- quest 486 Ursal the Mauler: client QuestPOIBlob 23395, 23396, 399180. objective 0 had a 2nd blob at Athridas Bearmantle (Dolanaar), marker snapped between the two
DELETE FROM world.quest_poi WHERE QuestID = 486;
DELETE FROM world.quest_poi_points WHERE QuestID = 486;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(486,0,0,-1,0,0,1,41,0,0,1,0,0,0,0,26972),
(486,0,1,0,254069,2039,1,41,0,0,1,0,0,0,0,26972),
(486,0,2,32,0,0,1,41,0,0,0,0,0,38704,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(486,0,0,9811,964,26972),
(486,1,0,10287,1199,26972),
(486,2,0,9811,964,26972);

-- quest 932 Twisted Hatred: client QuestPOIBlob 24408, 24409, 399237. objective 0 had a 2nd blob at the quest giver in Dolanaar, marker snapped between the two
DELETE FROM world.quest_poi WHERE QuestID = 932;
DELETE FROM world.quest_poi_points WHERE QuestID = 932;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(932,0,0,-1,0,0,1,41,0,0,1,0,0,0,0,26972),
(932,0,1,0,255128,5221,1,41,0,0,1,0,0,0,0,26972),
(932,0,2,32,0,0,1,41,0,0,0,0,0,57459,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(932,0,0,9890,972,26972),
(932,1,0,10131,1191,26972),
(932,2,0,9890,972,26972);

-- quest 2438 The Emerald Dreamcatcher: client QuestPOIBlob 25572, 25573, 399279. objective 0 had a 2nd blob at the quest giver in Dolanaar, marker snapped between the two
DELETE FROM world.quest_poi WHERE QuestID = 2438;
DELETE FROM world.quest_poi_points WHERE QuestID = 2438;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(2438,0,0,-1,0,0,1,41,0,0,1,0,0,0,0,26972),
(2438,0,1,0,256746,8048,1,41,0,0,1,0,0,0,0,26972),
(2438,0,2,32,0,0,1,41,0,0,0,0,0,57459,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(2438,0,0,9890,972,26972),
(2438,1,0,9807,351,26972),
(2438,2,0,9890,972,26972);

-- quest 14005 The Vengeance of Elune: client QuestPOIBlob 50921, 50922, 422954. objective 0 had a 2nd blob at Tarindrella, marker snapped between the two
DELETE FROM world.quest_poi WHERE QuestID = 14005;
DELETE FROM world.quest_poi_points WHERE QuestID = 14005;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(14005,0,0,-1,0,0,1,41,0,0,1,0,0,0,0,26972),
(14005,0,1,0,264759,34521,1,41,0,0,0,0,0,0,0,26972),
(14005,0,2,32,0,0,1,41,0,0,2,0,0,0,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(14005,0,0,9569,1736,26972),
(14005,1,0,9138,1860,26972),
(14005,2,0,9571,1741,26972);

-- quest 918 Timberling Seeds: client QuestPOIBlob 24387, 24388, 24389. two objective areas (the 2nd one was the Mossy Tumors area + a tail of this quest's area)
DELETE FROM world.quest_poi WHERE QuestID = 918;
DELETE FROM world.quest_poi_points WHERE QuestID = 918;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(918,0,0,-1,0,0,1,41,0,0,1,0,0,0,0,26972),
(918,0,1,0,254123,5168,1,41,0,0,0,0,0,0,0,26972),
(918,0,2,32,0,0,1,41,0,0,0,0,0,38303,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(918,0,0,9507,714,26972),
(918,1,0,9501,649,26972),
(918,1,1,9585,681,26972),
(918,1,2,9616,701,26972),
(918,1,3,9644,755,26972),
(918,1,4,9653,782,26972),
(918,1,5,9650,850,26972),
(918,1,6,9584,1051,26972),
(918,1,7,9367,1385,26972),
(918,1,8,9275,1079,26972),
(918,1,9,9348,847,26972),
(918,1,10,9385,753,26972),
(918,1,11,9419,718,26972),
(918,2,0,9507,714,26972);

-- quest 919 Timberling Sprouts: client QuestPOIBlob 24390, 24391, 399228. turn-in blob was Denalan + 11 points of the objective area; objective doubled
DELETE FROM world.quest_poi WHERE QuestID = 919;
DELETE FROM world.quest_poi_points WHERE QuestID = 919;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(919,0,0,-1,0,0,1,41,0,0,1,0,0,0,0,26972),
(919,0,1,0,254533,5169,1,41,0,0,0,0,0,0,0,26972),
(919,0,2,32,0,0,1,41,0,0,0,0,0,38303,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(919,0,0,9507,714,26972),
(919,1,0,9508,649,26972),
(919,1,1,9595,701,26972),
(919,1,2,9639,737,26972),
(919,1,3,9668,764,26972),
(919,1,4,9644,892,26972),
(919,1,5,9591,1007,26972),
(919,1,6,9465,1183,26972),
(919,1,7,9387,1264,26972),
(919,1,8,9324,1242,26972),
(919,1,9,9320,1150,26972),
(919,1,10,9359,827,26972),
(919,1,11,9383,754,26972),
(919,2,0,9507,714,26972);

-- quest 487 The Road to Darnassus: client QuestPOIBlob 23397, 23398, 399181. turn-in blob was Moon Priestess Amara + 6 points of the objective area; objective doubled
DELETE FROM world.quest_poi WHERE QuestID = 487;
DELETE FROM world.quest_poi_points WHERE QuestID = 487;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(487,0,0,-1,0,0,1,41,0,0,1,0,0,0,0,26972),
(487,0,1,0,253890,2152,1,41,0,0,1,0,0,0,0,26972),
(487,0,2,32,0,0,1,41,0,0,0,0,0,39150,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(487,0,0,10098,1336,26972),
(487,1,0,10317,1184,26972),
(487,1,1,10359,1202,26972),
(487,1,2,10384,1214,26972),
(487,1,3,10553,1305,26972),
(487,1,4,10564,1324,26972),
(487,1,5,10567,1352,26972),
(487,1,6,10151,1337,26972),
(487,2,0,10098,1336,26972);

-- quest 937 The Enchanted Glade: client QuestPOIBlob 24414, 24415, 399240. turn-in blob was the client turn-in point + 10 points of the objective area; objective doubled. The client turn-in point (10665, 1864) is 52 yd from Sentinel Arynia Cloudsbreak (3519 at 10678.4, 1914.7), so the turn-in uses her spawn (= the client quest-giver blob) instead
DELETE FROM world.quest_poi WHERE QuestID = 937;
DELETE FROM world.quest_poi_points WHERE QuestID = 937;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(937,0,0,-1,0,0,1,41,0,0,1,0,0,0,0,26972),
(937,0,1,0,255333,5204,1,41,0,0,1,0,0,0,0,26972),
(937,0,2,32,0,0,1,41,0,0,0,0,0,57467,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(937,0,0,10678,1915,26972),
(937,1,0,10386,1848,26972),
(937,1,1,10449,1852,26972),
(937,1,2,10881,1915,26972),
(937,1,3,10950,1966,26972),
(937,1,4,10939,2019,26972),
(937,1,5,10907,2078,26972),
(937,1,6,10853,2137,26972),
(937,1,7,10759,2214,26972),
(937,1,8,10612,2119,26972),
(937,1,9,10349,1916,26972),
(937,1,10,10316,1882,26972),
(937,2,0,10678,1915,26972);

-- quest 923 Mossy Tumors: client QuestPOIBlob 24397, 24398, 399232. turn-in blob was Rellian + 8 points of the objective area; objective doubled (extra glitched marker)
DELETE FROM world.quest_poi WHERE QuestID = 923;
DELETE FROM world.quest_poi_points WHERE QuestID = 923;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(923,0,0,-1,0,0,1,41,0,0,1,0,0,0,0,26972),
(923,0,1,0,254706,5170,1,41,0,0,1,0,0,0,0,26972),
(923,0,2,32,0,0,1,41,0,0,0,0,0,57232,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(923,0,0,10118,1653,26972),
(923,1,0,10930,1522,26972),
(923,1,1,10949,1549,26972),
(923,1,2,10951,1580,26972),
(923,1,3,10948,1615,26972),
(923,1,4,10852,1649,26972),
(923,1,5,10683,1685,26972),
(923,1,6,10415,1685,26972),
(923,1,7,10380,1651,26972),
(923,1,8,10383,1582,26972),
(923,2,0,10118,1653,26972);

-- quest 483 The Relics of Wakening: client QuestPOIBlob 23382, 23383, 23384, 23385, 23386, 399179. the four relic chests (floor 5 = lower Ban'ethil Barrow Den) were all ObjectiveIndex 0; now 0-3 like the client, so each relic keeps its own marker until it is looted
DELETE FROM world.quest_poi WHERE QuestID = 483;
DELETE FROM world.quest_poi_points WHERE QuestID = 483;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(483,0,0,-1,0,0,1,41,0,0,0,0,0,38704,0,26972),
(483,0,1,0,253872,3405,1,41,5,0,0,0,0,0,0,26972),
(483,0,2,1,253873,3406,1,41,5,0,0,0,0,0,0,26972),
(483,0,3,2,253874,3407,1,41,5,0,0,0,0,0,0,26972),
(483,0,4,3,253875,3408,1,41,5,0,0,0,0,0,0,26972),
(483,0,5,32,0,0,1,41,0,0,0,0,0,38704,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(483,0,0,9811,964,26972),
(483,1,0,9882,1490,26972),
(483,2,0,9713,1538,26972),
(483,3,0,9839,1546,26972),
(483,4,0,9741,1527,26972),
(483,5,0,9811,964,26972);

-- quest 13945 Resident Danger: client QuestPOIBlob 50917, 50918, 405068. Two turn-in rows (one drew the whole objective area). The client blob of "Ban'ethil Gnarlpine slain" is on the surface map only (floor 0), but 40 of the 55 gnarlpines are inside Ban'ethil Barrow Den (areaId 262), whose map is Teldrassil floor 4 (upper) / 5 (lower) (DungeonMap 565/566): the objective gets the same area on floors 4 and 5 too (outline of the den spawns), so the marker also shows inside the den
DELETE FROM world.quest_poi WHERE QuestID = 13945;
DELETE FROM world.quest_poi_points WHERE QuestID = 13945;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(13945,0,0,-1,0,0,1,41,0,0,1,0,0,0,0,26972),
(13945,0,1,0,252951,2010,1,41,0,0,1,0,0,0,0,26972),
(13945,1,2,0,252951,2010,1,41,4,0,1,0,0,0,0,26972),
(13945,2,3,0,252951,2010,1,41,5,0,1,0,0,0,0,26972),
(13945,0,4,32,0,0,1,41,0,0,0,0,0,38300,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(13945,0,0,9812,966,26972),
(13945,1,0,9981,1344,26972),
(13945,1,1,10025,1372,26972),
(13945,1,2,10092,1458,26972),
(13945,1,3,10096,1465,26972),
(13945,1,4,9964,1548,26972),
(13945,1,5,9826,1625,26972),
(13945,1,6,9753,1631,26972),
(13945,1,7,9730,1608,26972),
(13945,1,8,9719,1551,26972),
(13945,1,9,9751,1522,26972),
(13945,1,10,9950,1362,26972),
(13945,2,0,9719,1552,26972),
(13945,2,1,9750,1522,26972),
(13945,2,2,9850,1463,26972),
(13945,2,3,9856,1461,26972),
(13945,2,4,9890,1474,26972),
(13945,2,5,9893,1484,26972),
(13945,2,6,9895,1553,26972),
(13945,2,7,9884,1581,26972),
(13945,2,8,9826,1626,26972),
(13945,2,9,9755,1632,26972),
(13945,2,10,9731,1609,26972),
(13945,3,0,9719,1552,26972),
(13945,3,1,9750,1522,26972),
(13945,3,2,9850,1463,26972),
(13945,3,3,9856,1461,26972),
(13945,3,4,9890,1474,26972),
(13945,3,5,9893,1484,26972),
(13945,3,6,9895,1553,26972),
(13945,3,7,9884,1581,26972),
(13945,3,8,9826,1626,26972),
(13945,3,9,9755,1632,26972),
(13945,3,10,9731,1609,26972),
(13945,4,0,9812,966,26972);

-- 2) Reported Shadowglen quests without client blobs: built from the spawns.

-- quest 28715 Demonic Thieves: no turn-in row (lost in the merge); the giver row drew the bag polygon. Turn-in at Melithar Staghelm (2077), objective = the 23877 area over the 15 Melithar's Stolen Bags (195074), giver row kept (26124: WMA 888, SpawnTracking 38296)
DELETE FROM world.quest_poi WHERE QuestID = 28715;
DELETE FROM world.quest_poi_points WHERE QuestID = 28715;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(28715,0,0,-1,0,0,1,888,0,0,1,0,0,0,0,26972),
(28715,0,1,0,267351,46700,1,41,0,0,1,0,0,0,0,26972),
(28715,0,2,32,0,0,1,888,0,0,0,0,0,38296,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(28715,0,0,10329,825,26972),
(28715,1,0,10264,962,26972),
(28715,1,1,10368,1032,26972),
(28715,1,2,10333,1049,26972),
(28715,1,3,10302,1035,26972),
(28715,1,4,10253,993,26972),
(28715,1,5,10256,965,26972),
(28715,2,0,10329,825,26972);

-- quest 28726 Webwood Corruption: no turn-in row. Turn-in added at Tarindrella (49480), objective (23877 Webwood Spider area) and giver row unchanged
DELETE FROM world.quest_poi WHERE QuestID = 28726;
DELETE FROM world.quest_poi_points WHERE QuestID = 28726;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(28726,0,0,-1,0,0,1,888,0,0,1,0,0,0,0,26972),
(28726,0,1,0,267316,1986,1,41,0,0,1,0,0,0,0,26972),
(28726,0,2,32,0,0,1,41,0,0,0,0,0,298014,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(28726,0,0,10748,932,26972),
(28726,1,0,10909,854,26972),
(28726,1,1,10951,870,26972),
(28726,1,2,10973,937,26972),
(28726,1,3,10979,979,26972),
(28726,1,4,10887,984,26972),
(28726,1,5,10865,979,26972),
(28726,1,6,10776,926,26972),
(28726,1,7,10859,859,26972),
(28726,2,0,9569,1737,26972);

-- quest 28727 Vile Touch: no turn-in row. Turn-in added at Tarindrella (49480); objective (Githyiss, Shadowthread Cave = floor 2) and giver unchanged
DELETE FROM world.quest_poi WHERE QuestID = 28727;
DELETE FROM world.quest_poi_points WHERE QuestID = 28727;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(28727,0,0,-1,0,0,1,888,0,0,1,0,0,0,0,26972),
(28727,0,1,0,267306,1994,1,41,2,0,1,0,0,0,0,26972),
(28727,0,2,32,0,0,1,41,0,0,0,0,0,298014,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(28727,0,0,10748,932,26972),
(28727,1,0,10941,923,26972),
(28727,2,0,9569,1737,26972);

-- 3) Shadowglen class training quests: no quest_poi rows at all (and no client blobs). Same layout as the #105 Sigil
-- rows: map 1, WMA 888 (Shadowglen); turn-in at the class trainer, objective ("Spell Practice Credit" 44175) at the four
-- Training Dummies 44614 (10481.8-10486.4, 805.6-826.4). 26949 (priest) was not reported but is the same case;
-- 26946 / 26948 / 31169 are disabled, 26945 (warrior) has no quest_objectives row, both left out.

-- quest 26940 Frost Nova: turn-in at Rhyanda 43006, objective at the dummies
DELETE FROM world.quest_poi WHERE QuestID = 26940;
DELETE FROM world.quest_poi_points WHERE QuestID = 26940;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(26940,0,0,-1,0,0,1,888,0,0,1,0,0,0,0,26972),
(26940,0,1,0,267229,44175,1,888,0,0,1,0,0,0,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(26940,0,0,10456,805,26972),
(26940,1,0,10484,816,26972);

-- quest 26947 A Woodsman's Training: turn-in at Ayanna Everstride 3596, objective at the dummies
DELETE FROM world.quest_poi WHERE QuestID = 26947;
DELETE FROM world.quest_poi_points WHERE QuestID = 26947;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(26947,0,0,-1,0,0,1,888,0,0,1,0,0,0,0,26972),
(26947,0,1,0,266534,44175,1,888,0,0,1,0,0,0,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(26947,0,0,10448,778,26972),
(26947,1,0,10484,816,26972);

-- quest 26949 Learning the Word: turn-in at Shanda 3595, objective at the dummies
DELETE FROM world.quest_poi WHERE QuestID = 26949;
DELETE FROM world.quest_poi_points WHERE QuestID = 26949;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(26949,0,0,-1,0,0,1,888,0,0,1,0,0,0,0,26972),
(26949,0,1,0,266550,44175,1,888,0,0,1,0,0,0,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(26949,0,0,10459,802,26972),
(26949,1,0,10484,816,26972);

-- 4) Not reported yet: same merge in the same zone with a visible effect, rebuilt from the client blobs the same
-- way (933, 935 and 2399 only have a duplicate blob on the same point and are left alone).

-- quest 488 Zenn's Bidding: client QuestPOIBlob 23399, 23400, 23401, 23402, 23403, 23404, 23405, 23406, 23407, 23408, 23409, 399182. the 10 objective areas were all ObjectiveIndex 0 (client: 4 x 0, 3 x 1, 3 x 2)
DELETE FROM world.quest_poi WHERE QuestID = 488;
DELETE FROM world.quest_poi_points WHERE QuestID = 488;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(488,0,0,-1,0,0,1,41,0,0,1,0,0,0,0,26972),
(488,0,1,0,253736,3409,1,41,0,0,1,0,0,0,0,26972),
(488,1,2,0,253736,3409,1,41,0,0,1,0,0,0,0,26972),
(488,2,3,0,253736,3409,1,41,0,0,1,0,0,0,0,26972),
(488,3,4,0,253736,3409,1,41,0,0,1,0,0,0,0,26972),
(488,0,5,1,253737,3411,1,41,0,0,1,0,0,0,0,26972),
(488,1,6,1,253737,3411,1,41,0,0,1,0,0,0,0,26972),
(488,2,7,1,253737,3411,1,41,0,0,1,0,0,0,0,26972),
(488,0,8,2,253738,3412,1,41,0,0,1,0,0,0,0,26972),
(488,1,9,2,253738,3412,1,41,0,0,1,0,0,0,0,26972),
(488,2,10,2,253738,3412,1,41,0,0,1,0,0,0,0,26972),
(488,0,11,32,0,0,1,41,0,0,0,0,0,39151,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(488,0,0,9922,739,26972),
(488,1,0,9456,558,26972),
(488,1,1,9422,1505,26972),
(488,1,2,9386,1539,26972),
(488,1,3,9316,1539,26972),
(488,1,4,9279,1509,26972),
(488,1,5,9132,1286,26972),
(488,1,6,9133,1252,26972),
(488,1,7,9224,831,26972),
(488,1,8,9283,709,26972),
(488,1,9,9388,562,26972),
(488,2,0,9596,1002,26972),
(488,2,1,9971,1086,26972),
(488,2,2,10078,1296,26972),
(488,2,3,9969,1299,26972),
(488,2,4,9730,1232,26972),
(488,2,5,9692,1187,26972),
(488,3,0,9946,291,26972),
(488,3,1,9986,325,26972),
(488,3,2,10032,468,26972),
(488,3,3,9942,542,26972),
(488,4,0,9777,593,26972),
(488,4,1,9818,626,26972),
(488,4,2,9994,899,26972),
(488,4,3,9661,790,26972),
(488,4,4,9736,631,26972),
(488,5,0,9729,296,26972),
(488,5,1,9766,364,26972),
(488,5,2,9774,522,26972),
(488,5,3,9706,658,26972),
(488,5,4,9460,558,26972),
(488,6,0,10017,355,26972),
(488,6,1,10069,476,26972),
(488,6,2,10018,608,26972),
(488,6,3,9973,572,26972),
(488,6,4,9966,471,26972),
(488,7,0,9780,793,26972),
(488,7,1,9926,804,26972),
(488,7,2,10005,1125,26972),
(488,7,3,9890,1307,26972),
(488,7,4,9678,1165,26972),
(488,7,5,9555,979,26972),
(488,8,0,9637,1029,26972),
(488,8,1,9711,1029,26972),
(488,8,2,9967,1155,26972),
(488,8,3,10036,1230,26972),
(488,8,4,9598,1232,26972),
(488,8,5,9561,1189,26972),
(488,8,6,9531,1152,26972),
(488,8,7,9559,1114,26972),
(488,9,0,9783,225,26972),
(488,9,1,9906,250,26972),
(488,9,2,10006,692,26972),
(488,9,3,10003,732,26972),
(488,9,4,10001,768,26972),
(488,9,5,9943,870,26972),
(488,9,6,9818,808,26972),
(488,9,7,9440,511,26972),
(488,9,8,9664,302,26972),
(488,10,0,9239,1296,26972),
(488,10,1,9420,1432,26972),
(488,10,2,9489,1567,26972),
(488,10,3,9469,1599,26972),
(488,10,4,9161,1523,26972),
(488,10,5,9126,1483,26972),
(488,11,0,9922,739,26972);

-- quest 2459 Ferocitas the Dream Eater: client QuestPOIBlob 25577, 25578, 25579, 399280. objective 0 had a 2nd blob on the objective-1 point; objective 1 doubled
DELETE FROM world.quest_poi WHERE QuestID = 2459;
DELETE FROM world.quest_poi_points WHERE QuestID = 2459;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(2459,0,0,-1,0,0,1,41,0,0,1,0,0,0,0,26972),
(2459,0,1,0,256736,7235,1,41,0,0,1,0,0,0,0,26972),
(2459,0,2,1,256737,8050,1,41,0,0,1,0,0,0,0,26972),
(2459,0,3,32,0,0,1,41,0,0,0,0,0,57459,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(2459,0,0,9890,972,26972),
(2459,1,0,10066,164,26972),
(2459,1,1,10079,184,26972),
(2459,1,2,10119,366,26972),
(2459,1,3,10100,422,26972),
(2459,1,4,10047,380,26972),
(2459,1,5,9958,267,26972),
(2459,2,0,10012,283,26972),
(2459,3,0,9890,972,26972);

-- quest 2499 Oakenscowl: client QuestPOIBlob 25591, 50924, 399281. objective 0 had a 2nd blob at the quest giver
DELETE FROM world.quest_poi WHERE QuestID = 2499;
DELETE FROM world.quest_poi_points WHERE QuestID = 2499;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(2499,0,0,-1,0,0,1,41,0,0,1,0,0,0,0,26972),
(2499,0,1,0,256285,8136,1,41,0,0,0,0,0,0,0,26972),
(2499,0,2,32,0,0,1,41,0,0,0,0,0,882997,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(2499,0,0,10117,1654,26972),
(2499,1,0,10450,1439,26972),
(2499,2,0,10117,1654,26972);

-- quest 2518 Tears of the Moon: client QuestPOIBlob 25596, 25597, 399283. objective 0 had a 2nd blob at the quest giver
DELETE FROM world.quest_poi WHERE QuestID = 2518;
DELETE FROM world.quest_poi_points WHERE QuestID = 2518;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(2518,0,0,-1,0,0,1,41,0,0,1,0,0,0,0,26972),
(2518,0,1,0,256358,8344,1,41,0,0,1,0,0,0,0,26972),
(2518,0,2,32,0,0,1,41,0,0,0,0,0,81740,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(2518,0,0,10677,1934,26972),
(2518,1,0,10977,1841,26972),
(2518,2,0,10677,1934,26972);

-- quest 7383 Teldrassil: The Burden of the Kaldorei: client QuestPOIBlob 41004, 57945, 399429. turn-in and objective doubled with swapped points: a turn-in marker also sat on the objective
DELETE FROM world.quest_poi WHERE QuestID = 7383;
DELETE FROM world.quest_poi_points WHERE QuestID = 7383;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(7383,0,0,-1,0,0,1,41,0,0,0,0,0,0,0,26972),
(7383,0,1,0,262341,18151,1,41,0,0,2,0,0,0,0,26972),
(7383,0,2,32,0,0,1,41,0,0,0,0,0,57228,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(7383,0,0,10063,1827,26972),
(7383,1,0,10681,1876,26972),
(7383,2,0,10063,1827,26972);

-- quest 13946 Nature's Reprisal: client QuestPOIBlob 50919, 50920, 405069. objective 0 had a 2nd blob at the quest giver
DELETE FROM world.quest_poi WHERE QuestID = 13946;
DELETE FROM world.quest_poi_points WHERE QuestID = 13946;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(13946,0,0,-1,0,0,1,41,0,0,1,0,0,0,0,26972),
(13946,0,1,0,265120,34440,1,41,0,0,1,0,0,0,0,26972),
(13946,0,2,32,0,0,1,41,0,0,0,0,0,38301,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(13946,0,0,9872,959,26972),
(13946,1,0,10088,1029,26972),
(13946,1,1,10173,1086,26972),
(13946,1,2,10174,1108,26972),
(13946,1,3,10119,1122,26972),
(13946,1,4,10064,1121,26972),
(13946,1,5,10047,1035,26972),
(13946,2,0,9872,959,26972);

-- quest 28724 Iverron's Antidote: no client blobs, #84 rule: keep the 23877 rows + the 26124 giver row, drop the 26124 objective row at Idx1 1 and the 26124 points merged into Idx1 1 (the turn-in drew 5 points of the objective area)
DELETE FROM world.quest_poi WHERE QuestID = 28724;
DELETE FROM world.quest_poi_points WHERE QuestID = 28724;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(28724,0,0,0,267281,10641,1,41,0,0,1,0,0,0,0,23877),
(28724,1,1,-1,0,0,1,41,0,0,1,0,0,0,0,23877),
(28724,0,2,32,0,0,1,888,0,0,0,0,0,528927,0,26124);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(28724,0,0,10551,806,23877),
(28724,0,1,10563,808,23877),
(28724,0,2,10599,865,23877),
(28724,0,3,10576,900,23877),
(28724,0,4,10538,918,23877),
(28724,0,5,10485,895,23877),
(28724,1,0,10545,875,23877),
(28724,2,0,10545,875,26124);
