-- Undo for sql/custom/fix_teldrassil_quest_pois.sql: restores the exact previous rows, taken from the live world DB
-- on 2026-09-29 before the fix. Worldserver restart, no .reload.

-- quest 486 Ursal the Mauler
DELETE FROM world.quest_poi WHERE QuestID = 486;
DELETE FROM world.quest_poi_points WHERE QuestID = 486;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(486,0,0,0,254069,2039,1,41,0,0,1,0,0,0,0,23877),
(486,0,1,0,254069,2039,1,41,0,0,1,0,0,0,0,26124),
(486,1,1,-1,0,0,1,41,0,0,1,0,0,0,0,23877),
(486,0,2,32,0,0,1,41,0,0,0,0,0,38704,0,26124);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(486,0,0,10287,1199,23877),
(486,1,0,9811,964,23877),
(486,2,0,9811,964,26124);

-- quest 932 Twisted Hatred
DELETE FROM world.quest_poi WHERE QuestID = 932;
DELETE FROM world.quest_poi_points WHERE QuestID = 932;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(932,0,0,0,255128,5221,1,41,0,0,1,0,0,0,0,23877),
(932,0,1,0,255128,5221,1,41,0,0,1,0,0,0,0,26124),
(932,1,1,-1,0,0,1,41,0,0,1,0,0,0,0,23877),
(932,0,2,32,0,0,1,41,0,0,0,0,0,57459,0,26124);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(932,0,0,10131,1191,23877),
(932,1,0,9890,972,23877),
(932,2,0,9890,972,26124);

-- quest 2438 The Emerald Dreamcatcher
DELETE FROM world.quest_poi WHERE QuestID = 2438;
DELETE FROM world.quest_poi_points WHERE QuestID = 2438;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(2438,0,0,0,256746,8048,1,41,0,0,1,0,0,0,0,23877),
(2438,0,1,0,256746,8048,1,41,0,0,1,0,0,0,0,26124),
(2438,1,1,-1,0,0,1,41,0,0,1,0,0,0,0,23877),
(2438,0,2,32,0,0,1,41,0,0,0,0,0,57459,0,26124);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(2438,0,0,9807,351,23877),
(2438,1,0,9890,972,23877),
(2438,2,0,9890,972,26124);

-- quest 14005 The Vengeance of Elune
DELETE FROM world.quest_poi WHERE QuestID = 14005;
DELETE FROM world.quest_poi_points WHERE QuestID = 14005;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(14005,0,0,0,264759,34521,1,41,0,0,1,0,0,0,0,23877),
(14005,0,1,0,264759,34521,1,41,0,0,0,0,0,0,0,26124),
(14005,1,1,-1,0,0,1,41,0,0,1,0,0,0,0,23877),
(14005,0,2,32,0,0,1,41,0,0,2,0,0,0,0,26124);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(14005,0,0,9138,1860,23877),
(14005,1,0,9569,1737,23877),
(14005,2,0,9571,1741,26124);

-- quest 918 Timberling Seeds
DELETE FROM world.quest_poi WHERE QuestID = 918;
DELETE FROM world.quest_poi_points WHERE QuestID = 918;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(918,0,0,0,254123,5168,1,41,0,0,1,0,0,0,0,23877),
(918,0,1,0,254123,5168,1,41,0,0,0,0,0,0,0,26124),
(918,1,1,0,254123,5168,1,41,0,0,1,0,0,0,0,23877),
(918,0,2,32,0,0,1,41,0,0,0,0,0,38303,0,26124),
(918,2,2,-1,0,0,1,41,0,0,1,0,0,0,0,23877);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(918,0,0,9501,649,23877),
(918,0,1,9585,681,23877),
(918,0,2,9616,701,23877),
(918,0,3,9644,755,23877),
(918,0,4,9653,782,23877),
(918,0,5,9650,851,23877),
(918,0,6,9584,1051,23877),
(918,0,7,9367,1385,23877),
(918,0,8,9275,1079,23877),
(918,0,9,9348,847,23877),
(918,0,10,9385,753,23877),
(918,0,11,9419,719,23877),
(918,1,0,10930,1522,23877),
(918,1,1,10949,1549,23877),
(918,1,2,10951,1580,23877),
(918,1,3,10948,1615,23877),
(918,1,4,10852,1649,23877),
(918,1,5,10683,1685,23877),
(918,1,6,10415,1685,23877),
(918,1,7,10380,1651,23877),
(918,1,8,10383,1582,23877),
(918,1,9,9348,847,26124),
(918,1,10,9385,753,26124),
(918,1,11,9419,718,26124),
(918,2,0,9507,714,23877);

-- quest 919 Timberling Sprouts
DELETE FROM world.quest_poi WHERE QuestID = 919;
DELETE FROM world.quest_poi_points WHERE QuestID = 919;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(919,0,0,0,254533,5169,1,41,0,0,1,0,0,0,0,23877),
(919,0,1,0,254533,5169,1,41,0,0,0,0,0,0,0,26124),
(919,1,1,-1,0,0,1,41,0,0,1,0,0,0,0,23877),
(919,0,2,32,0,0,1,41,0,0,0,0,0,38303,0,26124);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(919,0,0,9508,649,23877),
(919,0,1,9595,701,23877),
(919,0,2,9639,737,23877),
(919,0,3,9668,765,23877),
(919,0,4,9644,892,23877),
(919,0,5,9591,1007,23877),
(919,0,6,9465,1183,23877),
(919,0,7,9387,1265,23877),
(919,0,8,9324,1242,23877),
(919,0,9,9320,1150,23877),
(919,0,10,9359,827,23877),
(919,0,11,9383,754,23877),
(919,1,0,9507,714,23877),
(919,1,1,9595,701,26124),
(919,1,2,9639,737,26124),
(919,1,3,9668,764,26124),
(919,1,4,9644,892,26124),
(919,1,5,9591,1007,26124),
(919,1,6,9465,1183,26124),
(919,1,7,9387,1264,26124),
(919,1,8,9324,1242,26124),
(919,1,9,9320,1150,26124),
(919,1,10,9359,827,26124),
(919,1,11,9383,754,26124),
(919,2,0,9507,714,26124);

-- quest 487 The Road to Darnassus
DELETE FROM world.quest_poi WHERE QuestID = 487;
DELETE FROM world.quest_poi_points WHERE QuestID = 487;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(487,0,0,0,253890,2152,1,41,0,0,1,0,0,0,0,23877),
(487,0,1,0,253890,2152,1,41,0,0,1,0,0,0,0,26124),
(487,1,1,-1,0,0,1,41,0,0,1,0,0,0,0,23877),
(487,0,2,32,0,0,1,41,0,0,0,0,0,39150,0,26124);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(487,0,0,10317,1184,23877),
(487,0,1,10359,1202,23877),
(487,0,2,10384,1214,23877),
(487,0,3,10553,1305,23877),
(487,0,4,10564,1324,23877),
(487,0,5,10567,1352,23877),
(487,0,6,10151,1337,23877),
(487,1,0,10098,1336,23877),
(487,1,1,10359,1202,26124),
(487,1,2,10384,1214,26124),
(487,1,3,10553,1305,26124),
(487,1,4,10564,1324,26124),
(487,1,5,10567,1352,26124),
(487,1,6,10151,1337,26124),
(487,2,0,10098,1336,26124);

-- quest 937 The Enchanted Glade
DELETE FROM world.quest_poi WHERE QuestID = 937;
DELETE FROM world.quest_poi_points WHERE QuestID = 937;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(937,0,0,0,255333,5204,1,41,0,0,1,0,0,0,0,23877),
(937,0,1,0,255333,5204,1,41,0,0,1,0,0,0,0,26124),
(937,1,1,-1,0,0,1,41,0,0,1,0,0,0,0,23877),
(937,0,2,32,0,0,1,41,0,0,0,0,0,57467,0,26124);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(937,0,0,10386,1848,23877),
(937,0,1,10449,1852,23877),
(937,0,2,10881,1915,23877),
(937,0,3,10950,1966,23877),
(937,0,4,10939,2019,23877),
(937,0,5,10907,2078,23877),
(937,0,6,10853,2137,23877),
(937,0,7,10759,2214,23877),
(937,0,8,10612,2119,23877),
(937,0,9,10349,1916,23877),
(937,0,10,10316,1882,23877),
(937,1,0,10665,1864,23877),
(937,1,1,10449,1852,26124),
(937,1,2,10881,1915,26124),
(937,1,3,10950,1966,26124),
(937,1,4,10939,2019,26124),
(937,1,5,10907,2078,26124),
(937,1,6,10853,2137,26124),
(937,1,7,10759,2214,26124),
(937,1,8,10612,2119,26124),
(937,1,9,10349,1916,26124),
(937,1,10,10316,1882,26124),
(937,2,0,10678,1915,26124);

-- quest 923 Mossy Tumors
DELETE FROM world.quest_poi WHERE QuestID = 923;
DELETE FROM world.quest_poi_points WHERE QuestID = 923;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(923,0,0,0,254706,5170,1,41,0,0,1,0,0,0,0,23877),
(923,0,1,0,254706,5170,1,41,0,0,1,0,0,0,0,26124),
(923,1,1,-1,0,0,1,41,0,0,1,0,0,0,0,23877),
(923,0,2,32,0,0,1,41,0,0,0,0,0,57232,0,26124);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(923,0,0,10930,1522,23877),
(923,0,1,10949,1549,23877),
(923,0,2,10951,1580,23877),
(923,0,3,10948,1615,23877),
(923,0,4,10852,1649,23877),
(923,0,5,10683,1685,23877),
(923,0,6,10415,1685,23877),
(923,0,7,10380,1651,23877),
(923,0,8,10383,1582,23877),
(923,1,0,10118,1653,23877),
(923,1,1,10949,1549,26124),
(923,1,2,10951,1580,26124),
(923,1,3,10948,1615,26124),
(923,1,4,10852,1649,26124),
(923,1,5,10683,1685,26124),
(923,1,6,10415,1685,26124),
(923,1,7,10380,1651,26124),
(923,1,8,10383,1582,26124),
(923,2,0,10118,1653,26124);

-- quest 483 The Relics of Wakening
DELETE FROM world.quest_poi WHERE QuestID = 483;
DELETE FROM world.quest_poi_points WHERE QuestID = 483;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(483,0,0,-1,0,0,1,41,0,0,0,0,0,38704,0,23877),
(483,0,1,0,253872,3405,1,41,5,0,0,0,0,0,0,23877),
(483,0,2,0,253873,3406,1,41,5,0,0,0,0,0,0,23877),
(483,0,3,0,253874,3407,1,41,5,0,0,0,0,0,0,23877),
(483,0,4,0,253875,3408,1,41,5,0,0,0,0,0,0,23877),
(483,0,5,32,0,0,1,41,0,0,0,0,0,38704,0,26124);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(483,0,0,9811,964,23877),
(483,1,0,9882,1490,23877),
(483,2,0,9713,1538,23877),
(483,3,0,9839,1546,23877),
(483,4,0,9741,1527,23877),
(483,5,0,9811,964,26124);

-- quest 13945 Resident Danger
DELETE FROM world.quest_poi WHERE QuestID = 13945;
DELETE FROM world.quest_poi_points WHERE QuestID = 13945;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(13945,0,0,-1,0,0,1,41,0,0,1,0,0,0,0,26124),
(13945,5,0,0,252951,2010,1,41,0,0,1,0,0,0,0,23877),
(13945,0,1,-1,0,0,1,41,0,0,1,0,0,0,0,23877),
(13945,0,2,32,0,0,1,41,0,0,0,0,0,38300,0,26124);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(13945,0,0,9981,1344,23877),
(13945,0,1,10025,1372,23877),
(13945,0,2,10092,1458,23877),
(13945,0,3,10096,1465,23877),
(13945,0,4,9964,1548,23877),
(13945,0,5,9826,1625,23877),
(13945,0,6,9753,1631,23877),
(13945,0,7,9730,1608,23877),
(13945,0,8,9719,1551,23877),
(13945,0,9,9751,1522,23877),
(13945,0,10,9950,1362,23877),
(13945,1,0,9812,966,23877),
(13945,1,1,10025,1372,26124),
(13945,1,2,10092,1458,26124),
(13945,1,3,10096,1465,26124),
(13945,1,4,9964,1548,26124),
(13945,1,5,9826,1625,26124),
(13945,1,6,9753,1631,26124),
(13945,1,7,9730,1608,26124),
(13945,1,8,9719,1551,26124),
(13945,1,9,9751,1522,26124),
(13945,1,10,9950,1362,26124),
(13945,2,0,9812,966,26124);

-- quest 28715 Demonic Thieves
DELETE FROM world.quest_poi WHERE QuestID = 28715;
DELETE FROM world.quest_poi_points WHERE QuestID = 28715;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(28715,0,0,0,267351,46700,1,41,0,0,1,0,0,0,0,23877),
(28715,0,1,32,0,0,1,888,0,0,0,0,0,38296,0,26124);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(28715,0,0,10264,962,23877),
(28715,0,1,10368,1032,23877),
(28715,0,2,10333,1049,23877),
(28715,0,3,10302,1035,23877),
(28715,0,4,10253,993,23877),
(28715,0,5,10256,965,23877),
(28715,1,0,10329,825,23877),
(28715,1,1,10368,1032,26124),
(28715,1,2,10333,1049,26124),
(28715,1,3,10302,1035,26124),
(28715,1,4,10253,993,26124),
(28715,1,5,10256,965,26124),
(28715,2,0,10329,825,26124);

-- quest 28726 Webwood Corruption
DELETE FROM world.quest_poi WHERE QuestID = 28726;
DELETE FROM world.quest_poi_points WHERE QuestID = 28726;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(28726,0,0,0,267316,1986,1,41,0,0,1,0,0,0,0,23877),
(28726,0,1,32,0,0,1,41,0,0,0,0,0,298014,0,26124);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(28726,0,0,10909,854,23877),
(28726,0,1,10951,870,23877),
(28726,0,2,10973,937,23877),
(28726,0,3,10979,979,23877),
(28726,0,4,10887,984,23877),
(28726,0,5,10865,979,23877),
(28726,0,6,10776,926,23877),
(28726,0,7,10859,859,23877),
(28726,1,0,9569,1737,26124);

-- quest 28727 Vile Touch
DELETE FROM world.quest_poi WHERE QuestID = 28727;
DELETE FROM world.quest_poi_points WHERE QuestID = 28727;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(28727,0,0,0,267306,1994,1,41,2,0,1,0,0,0,0,23877),
(28727,0,1,32,0,0,1,41,0,0,0,0,0,298014,0,26124);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(28727,0,0,10941,923,23877),
(28727,1,0,9569,1737,26124);

-- quest 26940 Frost Nova
DELETE FROM world.quest_poi WHERE QuestID = 26940;
DELETE FROM world.quest_poi_points WHERE QuestID = 26940;
-- (had no quest_poi / quest_poi_points rows)

-- quest 26947 A Woodsman's Training
DELETE FROM world.quest_poi WHERE QuestID = 26947;
DELETE FROM world.quest_poi_points WHERE QuestID = 26947;
-- (had no quest_poi / quest_poi_points rows)

-- quest 26949 Learning the Word
DELETE FROM world.quest_poi WHERE QuestID = 26949;
DELETE FROM world.quest_poi_points WHERE QuestID = 26949;
-- (had no quest_poi / quest_poi_points rows)

-- quest 488 Zenn's Bidding
DELETE FROM world.quest_poi WHERE QuestID = 488;
DELETE FROM world.quest_poi_points WHERE QuestID = 488;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(488,0,0,-1,0,0,1,41,0,0,1,0,0,0,0,23877),
(488,0,1,0,253736,3409,1,41,0,0,1,0,0,0,0,23877),
(488,1,2,0,253736,3409,1,41,0,0,1,0,0,0,0,23877),
(488,2,3,0,253736,3409,1,41,0,0,1,0,0,0,0,23877),
(488,3,4,0,253736,3409,1,41,0,0,1,0,0,0,0,23877),
(488,0,5,0,253737,3411,1,41,0,0,1,0,0,0,0,23877),
(488,1,6,0,253737,3411,1,41,0,0,1,0,0,0,0,23877),
(488,2,7,0,253737,3411,1,41,0,0,1,0,0,0,0,23877),
(488,0,8,0,253738,3412,1,41,0,0,1,0,0,0,0,23877),
(488,1,9,0,253738,3412,1,41,0,0,1,0,0,0,0,23877),
(488,2,10,0,253738,3412,1,41,0,0,1,0,0,0,0,23877),
(488,0,11,32,0,0,1,41,0,0,0,0,0,39151,0,26124);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(488,0,0,9922,739,23877),
(488,1,0,9456,558,23877),
(488,1,1,9422,1505,23877),
(488,1,2,9386,1539,23877),
(488,1,3,9316,1539,23877),
(488,1,4,9279,1509,23877),
(488,1,5,9132,1286,23877),
(488,1,6,9133,1252,23877),
(488,1,7,9224,831,23877),
(488,1,8,9283,709,23877),
(488,1,9,9388,562,23877),
(488,2,0,9596,1002,23877),
(488,2,1,9971,1086,23877),
(488,2,2,10078,1296,23877),
(488,2,3,9969,1299,23877),
(488,2,4,9730,1232,23877),
(488,2,5,9692,1187,23877),
(488,3,0,9946,291,23877),
(488,3,1,9986,325,23877),
(488,3,2,10032,468,23877),
(488,3,3,9942,542,23877),
(488,4,0,9777,593,23877),
(488,4,1,9818,626,23877),
(488,4,2,9994,899,23877),
(488,4,3,9661,790,23877),
(488,4,4,9736,631,23877),
(488,5,0,9729,296,23877),
(488,5,1,9766,364,23877),
(488,5,2,9774,522,23877),
(488,5,3,9706,658,23877),
(488,5,4,9460,558,23877),
(488,6,0,10017,355,23877),
(488,6,1,10069,476,23877),
(488,6,2,10018,608,23877),
(488,6,3,9973,572,23877),
(488,6,4,9966,471,23877),
(488,7,0,9780,793,23877),
(488,7,1,9926,804,23877),
(488,7,2,10005,1125,23877),
(488,7,3,9890,1307,23877),
(488,7,4,9678,1165,23877),
(488,7,5,9555,979,23877),
(488,8,0,9637,1029,23877),
(488,8,1,9711,1029,23877),
(488,8,2,9967,1155,23877),
(488,8,3,10036,1230,23877),
(488,8,4,9598,1232,23877),
(488,8,5,9561,1189,23877),
(488,8,6,9531,1152,23877),
(488,8,7,9559,1114,23877),
(488,9,0,9783,225,23877),
(488,9,1,9906,250,23877),
(488,9,2,10006,692,23877),
(488,9,3,10003,732,23877),
(488,9,4,10001,768,23877),
(488,9,5,9943,870,23877),
(488,9,6,9818,808,23877),
(488,9,7,9440,511,23877),
(488,9,8,9664,302,23877),
(488,10,0,9239,1296,23877),
(488,10,1,9420,1432,23877),
(488,10,2,9489,1567,23877),
(488,10,3,9469,1599,23877),
(488,10,4,9161,1523,23877),
(488,10,5,9126,1483,23877),
(488,11,0,9922,739,26124);

-- quest 2459 Ferocitas the Dream Eater
DELETE FROM world.quest_poi WHERE QuestID = 2459;
DELETE FROM world.quest_poi_points WHERE QuestID = 2459;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(2459,0,0,0,256736,7235,1,41,0,0,1,0,0,0,0,23877),
(2459,0,1,0,256736,7235,1,41,0,0,1,0,0,0,0,26124),
(2459,1,1,0,256737,8050,1,41,0,0,1,0,0,0,0,23877),
(2459,0,2,1,256737,8050,1,41,0,0,1,0,0,0,0,26124),
(2459,2,2,-1,0,0,1,41,0,0,1,0,0,0,0,23877),
(2459,0,3,32,0,0,1,41,0,0,0,0,0,57459,0,26124);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(2459,0,0,10066,164,23877),
(2459,0,1,10079,184,23877),
(2459,0,2,10119,366,23877),
(2459,0,3,10100,422,23877),
(2459,0,4,10047,380,23877),
(2459,0,5,9958,267,23877),
(2459,1,0,10012,283,23877),
(2459,1,1,10079,184,26124),
(2459,1,2,10119,366,26124),
(2459,1,3,10100,422,26124),
(2459,1,4,10047,380,26124),
(2459,1,5,9958,267,26124),
(2459,2,0,9890,972,23877),
(2459,3,0,9890,972,26124);

-- quest 2499 Oakenscowl
DELETE FROM world.quest_poi WHERE QuestID = 2499;
DELETE FROM world.quest_poi_points WHERE QuestID = 2499;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(2499,0,0,0,256285,8136,1,41,0,0,1,0,0,0,0,23877),
(2499,0,1,0,256285,8136,1,41,0,0,0,0,0,0,0,26124),
(2499,2,1,-1,0,0,1,41,0,0,1,0,0,0,0,23877),
(2499,0,2,32,0,0,1,41,0,0,0,0,0,882997,0,26124);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(2499,0,0,10450,1439,23877),
(2499,1,0,10117,1654,23877),
(2499,2,0,10117,1654,26124);

-- quest 2518 Tears of the Moon
DELETE FROM world.quest_poi WHERE QuestID = 2518;
DELETE FROM world.quest_poi_points WHERE QuestID = 2518;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(2518,0,0,0,256358,8344,1,41,0,0,1,0,0,0,0,23877),
(2518,0,1,0,256358,8344,1,41,0,0,1,0,0,0,0,26124),
(2518,1,1,-1,0,0,1,41,0,0,1,0,0,0,0,23877),
(2518,0,2,32,0,0,1,41,0,0,0,0,0,81740,0,26124);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(2518,0,0,10977,1841,23877),
(2518,1,0,10677,1934,23877),
(2518,2,0,10677,1934,26124);

-- quest 7383 Teldrassil: The Burden of the Kaldorei
DELETE FROM world.quest_poi WHERE QuestID = 7383;
DELETE FROM world.quest_poi_points WHERE QuestID = 7383;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(7383,0,0,-1,0,0,1,41,0,0,0,0,0,0,0,26124),
(7383,1,0,0,262341,18151,1,41,0,0,3,0,0,0,0,23877),
(7383,0,1,0,262341,18151,1,41,0,0,2,0,0,0,0,26124),
(7383,2,1,-1,0,0,1,41,0,0,1,0,0,0,0,23877),
(7383,0,2,32,0,0,1,41,0,0,0,0,0,57228,0,26124);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(7383,0,0,10681,1876,23877),
(7383,1,0,10063,1827,23877),
(7383,2,0,9737,955,26124);

-- quest 13946 Nature's Reprisal
DELETE FROM world.quest_poi WHERE QuestID = 13946;
DELETE FROM world.quest_poi_points WHERE QuestID = 13946;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(13946,0,0,-1,0,0,1,41,0,0,1,0,0,0,0,23877),
(13946,0,1,0,265120,34440,1,41,0,0,1,0,0,0,0,26124),
(13946,1,1,0,265120,34440,1,41,0,0,1,0,0,0,0,23877),
(13946,0,2,32,0,0,1,41,0,0,0,0,0,38301,0,26124);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(13946,0,0,9872,959,23877),
(13946,1,0,10088,1029,23877),
(13946,1,1,10173,1086,23877),
(13946,1,2,10174,1108,23877),
(13946,1,3,10119,1122,23877),
(13946,1,4,10064,1121,23877),
(13946,1,5,10047,1035,23877),
(13946,2,0,9872,959,26124);

-- quest 28724 Iverron's Antidote
DELETE FROM world.quest_poi WHERE QuestID = 28724;
DELETE FROM world.quest_poi_points WHERE QuestID = 28724;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(28724,0,0,0,267281,10641,1,41,0,0,1,0,0,0,0,23877),
(28724,0,1,0,267281,10641,1,41,0,0,1,0,0,0,0,26124),
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
(28724,1,1,10563,808,26124),
(28724,1,2,10599,865,26124),
(28724,1,3,10576,900,26124),
(28724,1,4,10538,918,26124),
(28724,1,5,10485,895,26124),
(28724,2,0,10545,875,26124);
