-- Issues #83 and #84: blood elf starting zone (Sunstrider Isle / Eversong Woods) quests.
-- Undo: sql/custom/undo_blood_elf_quests_83_84.sql. Goes live with a worldserver restart (no .reload).
-- Players with an old creature cache may need to delete the client's Cache folder to see the quest-mob change.

-- #83: quest mobs not highlighted. The client highlights a mob for an item objective (tooltip "0/8", glow) only
-- when the creature query response lists the item (creature_template_wdb.QuestItemN). These mobs drop the quest
-- item (creature_loot_template, QuestRequired = 1) but had no QuestItem. All QuestItem1..10 were 0 before.
UPDATE world.creature_template_wdb SET QuestItem1 = 20797 WHERE Entry IN (15366, 15372);              -- Springpaw Cub, Springpaw Lynx: Lynx Collar (8326 Unfortunate Measures)
UPDATE world.creature_template_wdb SET QuestItem1 = 20482 WHERE Entry IN (15273, 15274, 15294, 15298); -- Arcane Wraith, Mana Wyrm, Feral Tender, Tainted Arcane Wraith: Arcane Sliver (37440 A Fistful of Slivers)
UPDATE world.creature_template_wdb SET QuestItem1 = 21808 WHERE Entry = 15638;                        -- Arcane Patroller: Arcane Core (8472 Major Malfunction)
UPDATE world.creature_template_wdb SET QuestItem1 = 20772 WHERE Entry IN (15651, 15652);              -- Springpaw Stalker, Elder Springpaw: Springpaw Pelt (8491 Pelt Collection)
UPDATE world.creature_template_wdb SET QuestItem1 = 21771 WHERE Entry IN (15668, 15669);              -- Grimscale Murloc, Grimscale Oracle: Captain Kelisendra's Cargo (8886 Grimscale Pirates!)

-- #84: wrong map markers. quest_poi / quest_poi_points of these quests were two sniff imports (builds 23877 and
-- 26124) merged into the same keys: the 23877 set used BlobIndex = Idx1 with the turn-in last, the 26124 set
-- used BlobIndex 0 with the turn-in first, so rows took each other's Idx1 and the point lists got mixed
-- (turn-in "areas" made of objective polygons, objective circles at the quest giver, doubled areas).
-- Rebuilt from the 7.3.5 client's own QuestPOIBlob.db2 / QuestPOIPoint.db2 (build 26972) in the retail layout:
-- Idx1 0 = turn-in (ObjectiveIndex -1), then the objective areas (BlobIndex counts areas per objective), then
-- the quest-giver blob (ObjectiveIndex 32; Flags and WoDUnk1 kept from the 26124 rows).
-- 8472 and 8491 (#83) had the same corruption and are rebuilt too.

-- quest 8472: client QuestPOIBlob 28475, 28476, 28477, 399548
DELETE FROM world.quest_poi WHERE QuestID = 8472;
DELETE FROM world.quest_poi_points WHERE QuestID = 8472;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(8472,0,0,-1,0,0,530,462,0,0,1,0,0,0,0,26972),
(8472,0,1,0,259530,21808,530,462,0,0,1,0,0,0,0,26972),
(8472,1,2,0,259530,21808,530,462,0,0,1,0,0,0,0,26972),
(8472,0,3,32,0,0,530,462,0,0,0,0,0,122183,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(8472,0,0,9521,-6815,26972),
(8472,1,0,9755,-6575,26972),
(8472,1,1,9782,-6555,26972),
(8472,1,2,9816,-6493,26972),
(8472,1,3,9735,-6494,26972),
(8472,2,0,9758,-6856,26972),
(8472,2,1,9818,-6834,26972),
(8472,2,2,9667,-6732,26972),
(8472,2,3,9658,-6801,26972),
(8472,2,4,9672,-6851,26972),
(8472,3,0,9521,-6815,26972);

-- quest 8473: client QuestPOIBlob 28478, 28479, 399549
DELETE FROM world.quest_poi WHERE QuestID = 8473;
DELETE FROM world.quest_poi_points WHERE QuestID = 8473;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(8473,0,0,-1,0,0,530,462,0,0,1,0,0,0,0,26972),
(8473,0,1,0,259685,15637,530,462,0,0,1,0,0,0,0,26972),
(8473,0,2,32,0,0,530,462,0,0,0,0,0,122304,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(8473,0,0,8414,-6165,26972),
(8473,1,0,8117,-6550,26972),
(8473,1,1,8182,-6550,26972),
(8473,1,2,8250,-6550,26972),
(8473,1,3,8315,-6550,26972),
(8473,1,4,8349,-6518,26972),
(8473,1,5,8370,-6310,26972),
(8473,1,6,8346,-6117,26972),
(8473,1,7,8281,-6052,26972),
(8473,1,8,8249,-6021,26972),
(8473,1,9,8188,-6021,26972),
(8473,1,10,8151,-6114,26972),
(8473,2,0,8414,-6165,26972);

-- quest 8480: client QuestPOIBlob 28495, 28496, 399554
DELETE FROM world.quest_poi WHERE QuestID = 8480;
DELETE FROM world.quest_poi_points WHERE QuestID = 8480;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(8480,0,0,-1,0,0,530,462,0,0,1,0,0,0,0,26972),
(8480,0,1,0,260261,22413,530,462,0,0,1,0,0,0,0,26972),
(8480,0,2,32,0,0,530,462,0,0,0,0,0,122305,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(8480,0,0,8849,-6278,26972),
(8480,1,0,8811,-6194,26972),
(8480,1,1,8856,-6183,26972),
(8480,1,2,8836,-6004,26972),
(8480,1,3,8806,-5977,26972),
(8480,1,4,8756,-5943,26972),
(8480,1,5,8711,-6034,26972),
(8480,1,6,8709,-6114,26972),
(8480,1,7,8772,-6164,26972),
(8480,2,0,8849,-6278,26972);

-- quest 8482: client QuestPOIBlob 28498, 37594, 422946
DELETE FROM world.quest_poi WHERE QuestID = 8482;
DELETE FROM world.quest_poi_points WHERE QuestID = 8482;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(8482,0,0,-1,0,0,530,462,0,0,1,0,0,0,0,26972),
(8482,0,1,0,252881,20765,530,462,0,0,0,0,0,0,0,26972),
(8482,0,2,32,0,0,530,462,0,0,2,0,0,0,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(8482,0,0,9531,-6860,26972),
(8482,1,0,9005,-6194,26972),
(8482,1,1,9121,-6171,26972),
(8482,1,2,9090,-6127,26972),
(8482,2,0,9042,-6298,26972);

-- quest 8483: client QuestPOIBlob 28499, 28500, 399556
DELETE FROM world.quest_poi WHERE QuestID = 8483;
DELETE FROM world.quest_poi_points WHERE QuestID = 8483;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(8483,0,0,-1,0,0,530,462,0,0,1,0,0,0,0,26972),
(8483,0,1,0,260459,20764,530,462,0,0,0,0,0,0,0,26972),
(8483,0,2,32,0,0,530,462,0,0,0,0,0,122182,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(8483,0,0,9531,-6860,26972),
(8483,1,0,9292,-6683,26972),
(8483,2,0,9531,-6860,26972);

-- quest 8491: client QuestPOIBlob 28512, 28514, 28516, 28519, 28520, 399561
DELETE FROM world.quest_poi WHERE QuestID = 8491;
DELETE FROM world.quest_poi_points WHERE QuestID = 8491;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(8491,0,0,-1,0,0,530,462,0,0,1,0,0,0,0,26972),
(8491,0,1,0,256671,20772,530,462,0,0,1,0,0,0,0,26972),
(8491,1,2,0,256671,20772,530,462,0,0,1,0,0,0,0,26972),
(8491,2,3,0,256671,20772,530,462,0,0,1,0,0,0,0,26972),
(8491,3,4,0,256671,20772,530,462,0,0,1,0,0,0,0,26972),
(8491,0,5,32,0,0,530,462,0,0,0,0,0,122320,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(8491,0,0,8756,-6690,26972),
(8491,1,0,8718,-6284,26972),
(8491,1,1,8682,-6184,26972),
(8491,1,2,8648,-6150,26972),
(8491,1,3,8587,-6212,26972),
(8491,2,0,8715,-6888,26972),
(8491,2,1,8783,-6884,26972),
(8491,2,2,9018,-6851,26972),
(8491,2,3,8985,-6481,26972),
(8491,2,4,8853,-6351,26972),
(8491,2,5,8814,-6392,26972),
(8491,3,0,8416,-6050,26972),
(8491,3,1,8486,-6048,26972),
(8491,3,2,8680,-5921,26972),
(8491,3,3,8684,-5785,26972),
(8491,3,4,8482,-5651,26972),
(8491,3,5,8350,-5716,26972),
(8491,3,6,8320,-5748,26972),
(8491,3,7,8377,-6015,26972),
(8491,4,0,8514,-6621,26972),
(8491,4,1,8583,-6617,26972),
(8491,4,2,8720,-6551,26972),
(8491,4,3,8717,-6484,26972),
(8491,4,4,8617,-6447,26972),
(8491,5,0,8756,-6690,26972);

-- quest 8886: client QuestPOIBlob 28941, 28942, 399762
DELETE FROM world.quest_poi WHERE QuestID = 8886;
DELETE FROM world.quest_poi_points WHERE QuestID = 8886;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(8886,0,0,-1,0,0,530,462,0,0,1,0,0,0,0,26972),
(8886,0,1,0,260412,21771,530,462,0,0,1,0,0,0,0,26972),
(8886,0,2,32,0,0,530,462,0,0,0,0,0,127201,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(8886,0,0,8854,-6278,26972),
(8886,1,0,8887,-5780,26972),
(8886,1,1,8885,-5713,26972),
(8886,1,2,8851,-5684,26972),
(8886,1,3,8812,-5652,26972),
(8886,1,4,8621,-5621,26972),
(8886,1,5,8587,-5655,26972),
(8886,1,6,8611,-5682,26972),
(8886,1,7,8783,-5775,26972),
(8886,2,0,8854,-6278,26972);

-- quest 8892: client QuestPOIBlob 28951, 28952, 28953, 399767
DELETE FROM world.quest_poi WHERE QuestID = 8892;
DELETE FROM world.quest_poi_points WHERE QuestID = 8892;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(8892,0,0,-1,0,0,530,462,0,0,1,0,0,0,0,26972),
(8892,0,1,0,257349,15645,530,462,0,0,1,0,0,0,0,26972),
(8892,0,2,1,257350,16162,530,462,0,0,1,0,0,0,0,26972),
(8892,0,3,32,0,0,530,462,0,0,0,0,0,127298,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(8892,0,0,8716,-6622,26972),
(8892,1,0,8824,-6197,26972),
(8892,1,1,8801,-5899,26972),
(8892,1,2,8795,-5899,26972),
(8892,1,3,8758,-5952,26972),
(8892,1,4,8722,-6018,26972),
(8892,1,5,8697,-6104,26972),
(8892,1,6,8791,-6196,26972),
(8892,2,0,8824,-6197,26972),
(8892,2,1,8795,-5899,26972),
(8892,2,2,8757,-5919,26972),
(8892,2,3,8697,-6104,26972),
(8892,2,4,8708,-6125,26972),
(8892,2,5,8769,-6181,26972),
(8892,2,6,8791,-6196,26972),
(8892,3,0,8716,-6622,26972);

-- quest 9064: client QuestPOIBlob 29240, 29241, 399790
DELETE FROM world.quest_poi WHERE QuestID = 9064;
DELETE FROM world.quest_poi_points WHERE QuestID = 9064;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9064,0,0,-1,0,0,530,462,0,0,1,0,0,0,0,26972),
(9064,0,1,0,259342,22414,530,462,0,0,1,0,0,0,0,26972),
(9064,0,2,32,0,0,530,462,0,0,0,0,0,127313,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9064,0,0,9252,-7231,26972),
(9064,1,0,9006,-6671,26972),
(9064,2,0,9038,-6698,26972);

-- quest 9066: client QuestPOIBlob 29244, 29245, 29246, 399792
DELETE FROM world.quest_poi WHERE QuestID = 9066;
DELETE FROM world.quest_poi_points WHERE QuestID = 9066;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9066,0,0,-1,0,0,530,462,0,0,1,0,0,0,0,26972),
(9066,0,1,0,258309,15945,530,462,0,0,1,0,0,0,0,26972),
(9066,0,2,1,258310,15941,530,462,0,0,1,0,0,0,0,26972),
(9066,0,3,32,0,0,530,462,0,0,0,0,0,127520,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9066,0,0,9252,-7231,26972),
(9066,1,0,9038,-6698,26972),
(9066,2,0,9189,-6713,26972),
(9066,3,0,9252,-7231,26972);

-- quest 9252: client QuestPOIBlob 29609, 29610, 29611, 399860
DELETE FROM world.quest_poi WHERE QuestID = 9252;
DELETE FROM world.quest_poi_points WHERE QuestID = 9252;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9252,0,0,-1,0,0,530,462,0,0,1,0,0,0,0,26972),
(9252,0,1,0,260888,15658,530,462,0,0,1,0,0,0,0,26972),
(9252,0,2,1,260889,15657,530,462,0,0,1,0,0,0,0,26972),
(9252,0,3,32,0,0,530,462,0,0,0,0,0,127299,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9252,0,0,8685,-6799,26972),
(9252,1,0,8757,-7153,26972),
(9252,1,1,8952,-6948,26972),
(9252,1,2,8052,-6711,26972),
(9252,1,3,8049,-6750,26972),
(9252,1,4,8325,-7011,26972),
(9252,2,0,8415,-7018,26972),
(9252,2,1,8517,-7017,26972),
(9252,2,2,8552,-6986,26972),
(9252,2,3,8085,-6717,26972),
(9252,2,4,8052,-6711,26972),
(9252,2,5,8049,-6750,26972),
(9252,2,6,8325,-7011,26972),
(9252,2,7,8351,-7016,26972),
(9252,3,0,8685,-6799,26972);
