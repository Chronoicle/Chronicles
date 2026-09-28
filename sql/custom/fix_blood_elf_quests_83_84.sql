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

-- Review follow-up (2026-09-28): 21 more Eversong quests had the same 23877/26124 merge, and the other Grimscale
-- murlocs miss their quest item.

-- #83: Fish Heads, Fish Heads... (8884, item 21757). Every Grimscale murloc drops 21757 (creature_loot_template,
-- QuestRequired = 1, no conditions). Mmmrrrggglll (15937) already lists it (QuestItem1); QuestItem1 of 15668/15669
-- is set to 21771 above, so 21757 goes in QuestItem2 there.
UPDATE world.creature_template_wdb SET QuestItem2 = 21757 WHERE Entry IN (15668, 15669);              -- Grimscale Murloc, Grimscale Oracle
UPDATE world.creature_template_wdb SET QuestItem1 = 21757 WHERE Entry IN (15670, 15950);              -- Grimscale Forager, Grimscale Seer

-- #84: quests with client blobs, rebuilt the same way as above.
-- quest 8463: client QuestPOIBlob 28459, 28460, 399546
DELETE FROM world.quest_poi WHERE QuestID = 8463;
DELETE FROM world.quest_poi_points WHERE QuestID = 8463;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(8463,0,0,-1,0,0,530,462,0,0,1,0,0,0,0,26972),
(8463,0,1,0,260235,20743,530,462,0,0,0,0,0,0,0,26972),
(8463,0,2,32,0,0,530,462,0,0,0,0,0,122182,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(8463,0,0,9531,-6860,26972),
(8463,1,0,9780,-6863,26972),
(8463,1,1,9906,-6803,26972),
(8463,1,2,9908,-6711,26972),
(8463,1,3,9908,-6621,26972),
(8463,1,4,9764,-6507,26972),
(8463,1,5,9729,-6488,26972),
(8463,1,6,9619,-6477,26972),
(8463,1,7,9541,-6495,26972),
(8463,1,8,9503,-6540,26972),
(8463,1,9,9505,-6649,26972),
(8463,1,10,9579,-6798,26972),
(8463,1,11,9669,-6854,26972),
(8463,2,0,9531,-6860,26972);

-- quest 8475: client QuestPOIBlob 28481, 28482, 399550
DELETE FROM world.quest_poi WHERE QuestID = 8475;
DELETE FROM world.quest_poi_points WHERE QuestID = 8475;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(8475,0,0,-1,0,0,530,462,0,0,1,0,0,0,0,26972),
(8475,0,1,0,260489,15654,530,462,0,0,1,0,0,0,0,26972),
(8475,0,2,32,0,0,530,462,0,0,0,0,0,122180,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(8475,0,0,9375,-6967,26972),
(8475,1,0,8999,-7033,26972),
(8475,1,1,9252,-7015,26972),
(8475,1,2,9315,-6984,26972),
(8475,1,3,9292,-6939,26972),
(8475,1,4,9277,-6916,26972),
(8475,1,5,9034,-6913,26972),
(8475,1,6,8967,-6933,26972),
(8475,1,7,8967,-7000,26972),
(8475,2,0,9375,-6967,26972);

-- quest 8476: client QuestPOIBlob 28483, 28484, 28485, 28486, 28487, 28488, 28489, 399551
DELETE FROM world.quest_poi WHERE QuestID = 8476;
DELETE FROM world.quest_poi_points WHERE QuestID = 8476;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(8476,0,0,-1,0,0,530,462,0,0,1,0,0,0,0,26972),
(8476,0,1,0,259031,15643,530,462,0,0,1,0,0,0,0,26972),
(8476,1,2,0,259031,15643,530,462,0,0,1,0,0,0,0,26972),
(8476,2,3,0,259031,15643,530,462,0,0,1,0,0,0,0,26972),
(8476,0,4,1,259032,15641,530,462,0,0,1,0,0,0,0,26972),
(8476,1,5,1,259032,15641,530,462,0,0,1,0,0,0,0,26972),
(8476,2,6,1,259032,15641,530,462,0,0,1,0,0,0,0,26972),
(8476,0,7,32,0,0,530,462,0,0,0,0,0,122318,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(8476,0,0,8981,-7458,26972),
(8476,1,0,8329,-7956,26972),
(8476,1,1,8347,-7940,26972),
(8476,1,2,8350,-7881,26972),
(8476,1,3,8304,-7877,26972),
(8476,2,0,8481,-7618,26972),
(8476,2,1,8519,-7582,26972),
(8476,2,2,8485,-7544,26972),
(8476,2,3,8446,-7518,26972),
(8476,2,4,8386,-7517,26972),
(8476,2,5,8385,-7581,26972),
(8476,3,0,8449,-8018,26972),
(8476,3,1,8652,-8011,26972),
(8476,3,2,8684,-7985,26972),
(8476,3,3,8716,-7884,26972),
(8476,3,4,8670,-7844,26972),
(8476,3,5,8551,-7884,26972),
(8476,3,6,8451,-7950,26972),
(8476,4,0,8412,-7588,26972),
(8476,4,1,8519,-7582,26972),
(8476,4,2,8485,-7544,26972),
(8476,4,3,8446,-7518,26972),
(8476,4,4,8386,-7517,26972),
(8476,4,5,8385,-7581,26972),
(8476,5,0,8449,-8018,26972),
(8476,5,1,8684,-7985,26972),
(8476,5,2,8687,-7945,26972),
(8476,5,3,8670,-7844,26972),
(8476,5,4,8551,-7884,26972),
(8476,5,5,8485,-7947,26972),
(8476,6,0,8347,-7940,26972),
(8476,6,1,8350,-7881,26972),
(8476,6,2,8304,-7877,26972),
(8476,6,3,8317,-7917,26972),
(8476,7,0,8981,-7458,26972);

-- quest 8477: client QuestPOIBlob 28490, 28491, 399552
DELETE FROM world.quest_poi WHERE QuestID = 8477;
DELETE FROM world.quest_poi_points WHERE QuestID = 8477;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(8477,0,0,-1,0,0,530,462,0,0,1,0,0,0,0,26972),
(8477,0,1,0,258752,20759,530,462,0,0,1,0,0,0,0,26972),
(8477,0,2,32,0,0,530,462,0,0,0,0,0,122319,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(8477,0,0,8986,-7419,26972),
(8477,1,0,8668,-7940,26972),
(8477,2,0,8986,-7419,26972);

-- quest 8479: client QuestPOIBlob 28493, 28494, 399553
DELETE FROM world.quest_poi WHERE QuestID = 8479;
DELETE FROM world.quest_poi_points WHERE QuestID = 8479;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(8479,0,0,-1,0,0,530,462,0,0,1,0,0,0,0,26972),
(8479,0,1,0,260136,20760,530,462,0,0,1,0,0,0,0,26972),
(8479,0,2,32,0,0,530,462,0,0,0,0,0,122307,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(8479,0,0,8667,-7961,26972),
(8479,1,0,8425,-7566,26972),
(8479,2,0,8667,-7961,26972);

-- quest 8486: client QuestPOIBlob 28503, 28504, 28505, 399558
DELETE FROM world.quest_poi WHERE QuestID = 8486;
DELETE FROM world.quest_poi_points WHERE QuestID = 8486;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(8486,0,0,-1,0,0,530,462,0,0,1,0,0,0,0,26972),
(8486,0,1,0,260082,15648,530,462,0,0,1,0,0,0,0,26972),
(8486,0,2,1,260083,15647,530,462,0,0,1,0,0,0,0,26972),
(8486,0,3,32,0,0,530,462,0,0,0,0,0,122187,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(8486,0,0,9156,-6295,26972),
(8486,1,0,9081,-6286,26972),
(8486,1,1,9144,-6262,26972),
(8486,1,2,9167,-6233,26972),
(8486,1,3,9154,-6183,26972),
(8486,1,4,9018,-6116,26972),
(8486,1,5,8990,-6104,26972),
(8486,1,6,8979,-6132,26972),
(8486,1,7,9018,-6283,26972),
(8486,2,0,9050,-6282,26972),
(8486,2,1,9144,-6262,26972),
(8486,2,2,9167,-6233,26972),
(8486,2,3,9181,-6215,26972),
(8486,2,4,9018,-6116,26972),
(8486,2,5,8990,-6104,26972),
(8486,2,6,8979,-6132,26972),
(8486,2,7,9018,-6249,26972),
(8486,3,0,9156,-6295,26972);

-- quest 8487: client QuestPOIBlob 28506, 28507, 399559
DELETE FROM world.quest_poi WHERE QuestID = 8487;
DELETE FROM world.quest_poi_points WHERE QuestID = 8487;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(8487,0,0,-1,0,0,530,462,0,0,1,0,0,0,0,26972),
(8487,0,1,0,259712,20771,530,462,0,0,1,0,0,0,0,26972),
(8487,0,2,32,0,0,530,462,0,0,0,0,0,122193,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(8487,0,0,8711,-7161,26972),
(8487,1,0,8718,-7137,26972),
(8487,1,1,8748,-7137,26972),
(8487,1,2,8871,-7052,26972),
(8487,1,3,8781,-6971,26972),
(8487,1,4,8643,-6983,26972),
(8487,1,5,8700,-7102,26972),
(8487,2,0,8711,-7161,26972);

-- quest 8884: client QuestPOIBlob 28937, 28938, 399760
DELETE FROM world.quest_poi WHERE QuestID = 8884;
DELETE FROM world.quest_poi_points WHERE QuestID = 8884;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(8884,0,0,-1,0,0,530,462,0,0,1,0,0,0,0,26972),
(8884,0,1,0,259418,21757,530,462,0,0,1,0,0,0,0,26972),
(8884,0,2,32,0,0,530,462,0,0,0,0,0,127199,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(8884,0,0,9126,-5976,26972),
(8884,1,0,9084,-5884,26972),
(8884,1,1,9206,-5861,26972),
(8884,1,2,9214,-5814,26972),
(8884,1,3,9182,-5782,26972),
(8884,1,4,9011,-5680,26972),
(8884,1,5,8621,-5621,26972),
(8884,1,6,8587,-5655,26972),
(8884,1,7,8611,-5682,26972),
(8884,1,8,8783,-5775,26972),
(8884,1,9,9028,-5871,26972),
(8884,2,0,9126,-5976,26972);

-- quest 8885: client QuestPOIBlob 28939, 28940, 399761
DELETE FROM world.quest_poi WHERE QuestID = 8885;
DELETE FROM world.quest_poi_points WHERE QuestID = 8885;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(8885,0,0,-1,0,0,530,462,0,0,1,0,0,0,0,26972),
(8885,0,1,0,260328,21770,530,462,0,0,1,0,0,0,0,26972),
(8885,0,2,32,0,0,530,462,0,0,0,0,0,127199,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(8885,0,0,9126,-5976,26972),
(8885,1,0,8620,-5668,26972),
(8885,2,0,9126,-5976,26972);

-- quest 8887: client QuestPOIBlob 28943, 37595, 422945
DELETE FROM world.quest_poi WHERE QuestID = 8887;
DELETE FROM world.quest_poi_points WHERE QuestID = 8887;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(8887,0,0,-1,0,0,530,462,0,0,1,0,0,0,0,26972),
(8887,0,1,0,260364,21776,530,462,0,0,0,0,0,0,0,26972),
(8887,0,2,32,0,0,530,462,0,0,2,0,0,0,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(8887,0,0,8854,-6278,26972),
(8887,1,0,9084,-5884,26972),
(8887,1,1,9206,-5861,26972),
(8887,1,2,9214,-5814,26972),
(8887,1,3,9182,-5782,26972),
(8887,1,4,9011,-5680,26972),
(8887,1,5,8621,-5621,26972),
(8887,1,6,8587,-5655,26972),
(8887,1,7,8611,-5682,26972),
(8887,1,8,8783,-5775,26972),
(8887,1,9,9028,-5871,26972),
(8887,2,0,9003,-5780,26972);

-- quest 8889: client QuestPOIBlob 28945, 28946, 28947, 28948, 399764
DELETE FROM world.quest_poi WHERE QuestID = 8889;
DELETE FROM world.quest_poi_points WHERE QuestID = 8889;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(8889,0,0,-1,0,0,530,462,0,0,1,0,0,0,0,26972),
(8889,0,1,0,259331,180916,530,462,0,0,1,0,0,0,0,26972),
(8889,0,2,1,259332,180919,530,462,0,0,1,0,0,0,0,26972),
(8889,0,3,2,259333,180920,530,462,0,0,1,0,0,0,0,26972),
(8889,0,4,32,0,0,530,462,0,0,0,0,0,127279,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(8889,0,0,9186,-7827,26972),
(8889,1,0,9336,-7884,26972),
(8889,2,0,9336,-7884,26972),
(8889,3,0,9290,-7917,26972),
(8889,4,0,9186,-7827,26972);

-- quest 8894: client QuestPOIBlob 28955, 28956, 28957, 399768
DELETE FROM world.quest_poi WHERE QuestID = 8894;
DELETE FROM world.quest_poi_points WHERE QuestID = 8894;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(8894,0,0,-1,0,0,530,462,0,0,1,0,0,0,0,26972),
(8894,0,1,0,252830,15966,530,462,0,0,1,0,0,0,0,26972),
(8894,0,2,1,252831,15967,530,462,0,0,1,0,0,0,0,26972),
(8894,0,3,32,0,0,530,462,0,0,0,0,0,127483,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(8894,0,0,9500,-7871,26972),
(8894,1,0,9485,-7951,26972),
(8894,1,1,9515,-7946,26972),
(8894,1,2,9580,-7881,26972),
(8894,1,3,9581,-7853,26972),
(8894,1,4,9581,-7818,26972),
(8894,1,5,9581,-7789,26972),
(8894,1,6,9485,-7785,26972),
(8894,1,7,9416,-7786,26972),
(8894,1,8,9250,-7856,26972),
(8894,1,9,9315,-7897,26972),
(8894,1,10,9389,-7943,26972),
(8894,1,11,9450,-7950,26972),
(8894,2,0,9485,-7951,26972),
(8894,2,1,9515,-7946,26972),
(8894,2,2,9580,-7912,26972),
(8894,2,3,9614,-7883,26972),
(8894,2,4,9614,-7852,26972),
(8894,2,5,9581,-7789,26972),
(8894,2,6,9451,-7784,26972),
(8894,2,7,9250,-7856,26972),
(8894,2,8,9315,-7897,26972),
(8894,2,9,9389,-7943,26972),
(8894,2,10,9450,-7950,26972),
(8894,3,0,9500,-7871,26972);

-- quest 9062: client QuestPOIBlob 29237, 29238, 399789
DELETE FROM world.quest_poi WHERE QuestID = 9062;
DELETE FROM world.quest_poi_points WHERE QuestID = 9062;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9062,0,0,-1,0,0,530,462,0,0,1,0,0,0,0,26972),
(9062,0,1,0,260447,22414,530,462,0,0,1,0,0,0,0,26972),
(9062,0,2,32,0,0,530,462,0,0,0,0,0,127313,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9062,0,0,9038,-6698,26972),
(9062,1,0,9006,-6671,26972),
(9062,2,0,9038,-6698,26972);

-- quest 9067: client QuestPOIBlob 29247, 29248, 29249, 29250, 399793
DELETE FROM world.quest_poi WHERE QuestID = 9067;
DELETE FROM world.quest_poi_points WHERE QuestID = 9067;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9067,0,0,-1,0,0,530,462,0,0,1,0,0,0,0,26972),
(9067,0,1,0,258190,22775,530,462,0,0,1,0,0,0,0,26972),
(9067,0,2,1,258191,22776,530,462,0,0,1,0,0,0,0,26972),
(9067,0,3,2,258192,22777,530,462,0,0,1,0,0,0,0,26972),
(9067,0,4,32,0,0,530,462,0,0,0,0,0,129039,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9067,0,0,8627,-6366,26972),
(9067,1,0,9682,-7364,26972),
(9067,2,0,8991,-7463,26972),
(9067,3,0,8732,-6656,26972),
(9067,4,0,8627,-6366,26972);

-- quest 9076: client QuestPOIBlob 29275, 29276, 399794
DELETE FROM world.quest_poi WHERE QuestID = 9076;
DELETE FROM world.quest_poi_points WHERE QuestID = 9076;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9076,0,0,-1,0,0,530,462,0,0,1,0,0,0,0,26972),
(9076,0,1,0,258429,22487,530,462,0,0,1,0,0,0,0,26972),
(9076,0,2,32,0,0,530,462,0,0,0,0,0,122305,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9076,0,0,8849,-6278,26972),
(9076,1,0,8763,-6103,26972),
(9076,2,0,8849,-6278,26972);

-- quest 9352: client QuestPOIBlob 29755, 29756, 399922
DELETE FROM world.quest_poi WHERE QuestID = 9352;
DELETE FROM world.quest_poi_points WHERE QuestID = 9352;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9352,0,0,-1,0,0,530,462,0,0,1,0,0,0,0,26972),
(9352,0,1,0,261039,15968,530,462,0,0,0,0,0,0,0,26972),
(9352,0,2,32,0,0,530,462,0,0,0,0,0,122182,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9352,0,0,9156,-6295,26972),
(9352,1,0,9005,-6194,26972),
(9352,1,1,9121,-6171,26972),
(9352,1,2,9090,-6127,26972),
(9352,2,0,9531,-6860,26972);

-- #84: quests without client blobs (8325, 9402, 9403, 9404, 12816): keep the 23877 rows (each Idx1 with its own
-- 23877 points) and the 26124 quest-giver row (ObjectiveIndex 32, its Idx1 is not used by a 23877 row); drop the
-- other 26124 rows (duplicates of the 23877 objectives that drew the points of the 23877 row at their Idx1) and the
-- 26124 points merged into Idx1 values owned by 23877 rows.
-- quest 8325: 26124 points at Idx1 1 = the tail of the objective polygon on the turn-in.
DELETE FROM world.quest_poi WHERE QuestID = 8325 AND VerifiedBuild = 26124 AND ObjectiveIndex <> 32;
DELETE FROM world.quest_poi_points WHERE QuestID = 8325 AND Idx1 = 1 AND VerifiedBuild = 26124;

-- quest 9402: no merged points (the 26124 objective row showed the turn-in point).
DELETE FROM world.quest_poi WHERE QuestID = 9402 AND VerifiedBuild = 26124 AND ObjectiveIndex <> 32;

-- quest 9403: no merged points (the 26124 objective row doubled the 23877 objective).
DELETE FROM world.quest_poi WHERE QuestID = 9403 AND VerifiedBuild = 26124 AND ObjectiveIndex <> 32;

-- quest 9404: 26124 points at Idx1 1 = the tail of the objective polygon on the turn-in.
DELETE FROM world.quest_poi WHERE QuestID = 9404 AND VerifiedBuild = 26124 AND ObjectiveIndex <> 32;
DELETE FROM world.quest_poi_points WHERE QuestID = 9404 AND Idx1 = 1 AND VerifiedBuild = 26124;

-- quest 12816 (objective 0 has an area in 8 zones on maps 0, 1 and 530): the 23877 rows Idx1 0-7 each keep their own
-- zone's 23877 points; the 26124 points at Idx1 2, 5, 7 and 9 are tails of the neighbouring zone's polygon (Tirisfal
-- in Azuremyst, Dun Morogh in Mulgore, Durotar in Teldrassil) and of the Eversong objective on the turn-in.
-- The 23877 row of objective 1 (QuestObjectiveID 263010, the Eversong area) had ObjectiveIndex 0; the 26124 row and
-- quest_objectives (StorageIndex 1) say 1.
DELETE FROM world.quest_poi WHERE QuestID = 12816 AND VerifiedBuild = 26124 AND ObjectiveIndex <> 32;
DELETE FROM world.quest_poi_points WHERE QuestID = 12816 AND Idx1 IN (2, 5, 7, 9) AND VerifiedBuild = 26124;
UPDATE world.quest_poi SET ObjectiveIndex = 1 WHERE QuestID = 12816 AND BlobIndex = 8 AND Idx1 = 8 AND QuestObjectiveID = 263010;
