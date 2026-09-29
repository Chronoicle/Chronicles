-- Issue #88 (follow-up to #83/#84): Eversong Woods (zone 3430) and Ghostlands (3433) quests.
-- Undo: sql/custom/undo_eversong_ghostlands_quests_88.sql. Goes live with a worldserver restart (no .reload).
-- Players need to clear the client's Cache folder to see the quest-mob change (creature cache).

-- 1) Quest mobs not highlighted (no "0/N" tooltip, no glow): same cause as #83, creature_template_wdb.QuestItemN
-- did not list the quest item these mobs drop (creature_loot_template). QuestItem1..10 were all 0 before.
-- Every creature that drops an item objective of a zone 3430/3433 quest was checked; quest-starter items (8474,
-- 8482, 8887, 9175, 9360) are left out. 22644 (Crunchy Spider Leg) only on the Ghostlands spiders.
UPDATE world.creature_template_wdb SET QuestItem1 = 22641 WHERE Entry IN (16301, 16302); -- 9216/9217 Rotting Heart
UPDATE world.creature_template_wdb SET QuestItem1 = 22642 WHERE Entry IN (16303, 16305, 16307, 16308); -- 9218/9219 Spinal Dust
UPDATE world.creature_template_wdb SET QuestItem1 = 22580 WHERE Entry IN (16304, 16310); -- 9150 Crystallized Mana Essence
UPDATE world.creature_template_wdb SET QuestItem1 = 22566 WHERE Entry IN (16323); -- 9140 Phantasmal Substance
UPDATE world.creature_template_wdb SET QuestItem1 = 22567 WHERE Entry IN (16324); -- 9140 Gargoyle Fragment
UPDATE world.creature_template_wdb SET QuestItem1 = 22634 WHERE Entry IN (16334, 16335, 16337); -- 9207 Underlight Ore
UPDATE world.creature_template_wdb SET QuestItem1 = 22639 WHERE Entry IN (16340, 16341); -- 9143 Zeb'Sora Troll Ear
UPDATE world.creature_template_wdb SET QuestItem1 = 22633 WHERE Entry IN (16342, 16343); -- 9199 Troll Juju
UPDATE world.creature_template_wdb SET QuestItem1 = 23165 WHERE Entry IN (16344); -- 9214 Headhunter Axe
UPDATE world.creature_template_wdb SET QuestItem1 = 22677 WHERE Entry IN (16345); -- 9214 Catlord Claws
UPDATE world.creature_template_wdb SET QuestItem1 = 23166 WHERE Entry IN (16346); -- 9214 Hexxer Stave
UPDATE world.creature_template_wdb SET QuestItem1 = 22570 WHERE Entry IN (16347, 16348, 16349, 16353, 16354, 33711); -- 9147 Plagued Blood Sample
UPDATE world.creature_template_wdb SET QuestItem1 = 22570, QuestItem2 = 22644 WHERE Entry IN (16350, 16351, 16352); -- 9147 Plagued Blood Sample; 9171 Crunchy Spider Leg
UPDATE world.creature_template_wdb SET QuestItem1 = 22579 WHERE Entry IN (16402, 16403); -- 9149 Plagued Murloc Spine
UPDATE world.creature_template_wdb SET QuestItem1 = 23167 WHERE Entry IN (16469); -- 9214 Shadowcaster Mace
-- Ghostlands Copper Vein 181248 drops Underlight Ore (9207) like Tin Vein 181249, which already lists it.
UPDATE world.gameobject_template SET questItem1 = 22634 WHERE entry = 181248;

-- 2) Wrong map markers / areas: 33 quests had the same two merged sniff imports as #84 (builds 23877 + 26124, for
-- 8468 a 24015 row with garbage points, for 8488 duplicate 22522/23877 rows). Rebuilt from the 7.3.5 client's
-- QuestPOIBlob.db2 / QuestPOIPoint.db2 exactly like #84 (same generator: it reproduces all 27 #84 quests row for
-- row). Not rebuilt: 9170 (only 23877 rows, the client blobs give all four lieutenants objective 0).

-- quest 8468: client QuestPOIBlob 28470, 28471, 364840
DELETE FROM world.quest_poi WHERE QuestID = 8468;
DELETE FROM world.quest_poi_points WHERE QuestID = 8468;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(8468,0,0,-1,0,0,530,462,0,0,0,0,0,137202,0,26972),
(8468,0,1,0,259624,21781,530,462,0,0,0,0,0,127321,0,26972),
(8468,0,2,32,0,0,530,462,0,0,0,0,0,127320,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(8468,0,0,9512,-6840,26972),
(8468,1,0,9805,-6705,26972),
(8468,2,0,9521,-6860,26972);

-- quest 8488: client QuestPOIBlob 28509, 44284
DELETE FROM world.quest_poi WHERE QuestID = 8488;
DELETE FROM world.quest_poi_points WHERE QuestID = 8488;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(8488,0,0,-1,0,0,530,462,0,0,1,0,0,0,0,26972),
(8488,0,1,32,0,0,530,462,0,0,0,0,0,0,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(8488,0,0,8711,-7161,26972),
(8488,1,0,8711,-7161,26972);

-- quest 8490: client QuestPOIBlob 28511, 40451, 399560
DELETE FROM world.quest_poi WHERE QuestID = 8490;
DELETE FROM world.quest_poi_points WHERE QuestID = 8490;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(8490,0,0,-1,0,0,530,463,0,0,1,0,0,0,0,26972),
(8490,0,1,0,260059,16364,530,462,0,0,1,0,0,0,0,26972),
(8490,0,2,32,0,0,530,463,0,0,0,0,0,129820,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(8490,0,0,8236,-6664,26972),
(8490,1,0,8282,-7216,26972),
(8490,2,0,8236,-6664,26972);

-- quest 9138: client QuestPOIBlob 29417, 29418, 29419, 399802
DELETE FROM world.quest_poi WHERE QuestID = 9138;
DELETE FROM world.quest_poi_points WHERE QuestID = 9138;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9138,0,0,-1,0,0,530,463,0,0,1,0,0,0,0,26972),
(9138,0,1,0,260362,16313,530,463,0,0,1,0,0,0,0,26972),
(9138,1,2,0,260362,16313,530,463,0,0,1,0,0,0,0,26972),
(9138,0,3,32,0,0,530,463,0,0,0,0,0,129260,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9138,0,0,7644,-6803,26972),
(9138,1,0,8016,-7415,26972),
(9138,1,1,8050,-7414,26972),
(9138,1,2,8087,-7380,26972),
(9138,1,3,8083,-7253,26972),
(9138,1,4,8076,-7210,26972),
(9138,1,5,8051,-7186,26972),
(9138,1,6,7987,-7182,26972),
(9138,1,7,7920,-7217,26972),
(9138,1,8,7882,-7250,26972),
(9138,1,9,7879,-7285,26972),
(9138,1,10,7913,-7352,26972),
(9138,1,11,7943,-7388,26972),
(9138,2,0,8146,-7614,26972),
(9138,2,1,8155,-7549,26972),
(9138,2,2,8149,-7486,26972),
(9138,2,3,8119,-7483,26972),
(9138,2,4,8084,-7487,26972),
(9138,2,5,8054,-7512,26972),
(9138,2,6,8024,-7548,26972),
(9138,2,7,8049,-7578,26972),
(9138,2,8,8119,-7612,26972),
(9138,3,0,7644,-6803,26972);

-- quest 9139: client QuestPOIBlob 29420, 29421, 29422, 399803
DELETE FROM world.quest_poi WHERE QuestID = 9139;
DELETE FROM world.quest_poi_points WHERE QuestID = 9139;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9139,0,0,-1,0,0,530,463,0,0,1,0,0,0,0,26972),
(9139,0,1,0,257233,16325,530,463,0,0,1,0,0,0,0,26972),
(9139,0,2,1,257234,16326,530,463,0,0,1,0,0,0,0,26972),
(9139,0,3,32,0,0,530,463,0,0,0,0,0,129260,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9139,0,0,7644,-6803,26972),
(9139,1,0,7918,-6286,26972),
(9139,1,1,7945,-6271,26972),
(9139,1,2,7984,-6182,26972),
(9139,1,3,8018,-6079,26972),
(9139,1,4,7983,-6051,26972),
(9139,1,5,7882,-6047,26972),
(9139,1,6,7851,-6084,26972),
(9139,1,7,7905,-6259,26972),
(9139,2,0,7945,-6271,26972),
(9139,2,1,7983,-6212,26972),
(9139,2,2,8018,-6079,26972),
(9139,2,3,7917,-6051,26972),
(9139,2,4,7851,-6084,26972),
(9139,2,5,7850,-6144,26972),
(9139,2,6,7884,-6219,26972),
(9139,2,7,7905,-6259,26972),
(9139,2,8,7925,-6265,26972),
(9139,3,0,7644,-6803,26972);

-- quest 9140: client QuestPOIBlob 29423, 29424, 29425, 399804
DELETE FROM world.quest_poi WHERE QuestID = 9140;
DELETE FROM world.quest_poi_points WHERE QuestID = 9140;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9140,0,0,-1,0,0,530,463,0,0,1,0,0,0,0,26972),
(9140,0,1,0,262570,22566,530,463,0,0,1,0,0,0,0,26972),
(9140,0,2,1,262571,22567,530,463,0,0,1,0,0,0,0,26972),
(9140,0,3,32,0,0,530,463,0,0,0,0,0,129260,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9140,0,0,7644,-6803,26972),
(9140,1,0,7217,-5979,26972),
(9140,1,1,7337,-5956,26972),
(9140,1,2,7329,-5841,26972),
(9140,1,3,7319,-5818,26972),
(9140,1,4,7277,-5831,26972),
(9140,1,5,7190,-5935,26972),
(9140,1,6,7174,-5961,26972),
(9140,1,7,7200,-5975,26972),
(9140,2,0,7249,-6019,26972),
(9140,2,1,7286,-6011,26972),
(9140,2,2,7347,-5983,26972),
(9140,2,3,7365,-5966,26972),
(9140,2,4,7383,-5946,26972),
(9140,2,5,7347,-5851,26972),
(9140,2,6,7320,-5815,26972),
(9140,2,7,7279,-5814,26972),
(9140,2,8,7190,-5822,26972),
(9140,2,9,7060,-5855,26972),
(9140,2,10,7082,-5882,26972),
(9140,2,11,7172,-5988,26972),
(9140,3,0,7644,-6803,26972);

-- quest 9143: client QuestPOIBlob 29428, 29429, 399805
DELETE FROM world.quest_poi WHERE QuestID = 9143;
DELETE FROM world.quest_poi_points WHERE QuestID = 9143;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9143,0,0,-1,0,0,530,463,0,0,1,0,0,0,0,26972),
(9143,0,1,0,260290,22639,530,463,0,0,1,0,0,0,0,26972),
(9143,0,2,32,0,0,530,463,0,0,0,0,0,129300,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9143,0,0,7933,-7574,26972),
(9143,1,0,8055,-7865,26972),
(9143,1,1,8082,-7816,26972),
(9143,1,2,8081,-7784,26972),
(9143,1,3,8015,-7714,26972),
(9143,1,4,7950,-7716,26972),
(9143,1,5,7948,-7755,26972),
(9143,1,6,7988,-7849,26972),
(9143,2,0,7933,-7574,26972);

-- quest 9149: client QuestPOIBlob 29442, 29443, 399811
DELETE FROM world.quest_poi WHERE QuestID = 9149;
DELETE FROM world.quest_poi_points WHERE QuestID = 9149;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9149,0,0,-1,0,0,530,463,0,0,1,0,0,0,0,26972),
(9149,0,1,0,259508,22579,530,463,0,0,1,0,0,0,0,26972),
(9149,0,2,32,0,0,530,463,0,0,0,0,0,129465,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9149,0,0,7500,-6856,26972),
(9149,1,0,7514,-6045,26972),
(9149,1,1,8119,-5914,26972),
(9149,1,2,8143,-5898,26972),
(9149,1,3,8124,-5883,26972),
(9149,1,4,7550,-5682,26972),
(9149,1,5,7519,-5681,26972),
(9149,1,6,7485,-5681,26972),
(9149,1,7,7450,-5682,26972),
(9149,1,8,7418,-5683,26972),
(9149,1,9,7319,-5716,26972),
(9149,1,10,7220,-5750,26972),
(9149,2,0,7500,-6856,26972);

-- quest 9150: client QuestPOIBlob 29444, 29445, 399812
DELETE FROM world.quest_poi WHERE QuestID = 9150;
DELETE FROM world.quest_poi_points WHERE QuestID = 9150;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9150,0,0,-1,0,0,530,463,0,0,1,0,0,0,0,26972),
(9150,0,1,0,261470,22580,530,463,0,0,1,0,0,0,0,26972),
(9150,0,2,32,0,0,530,463,0,0,0,0,0,129467,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9150,0,0,7564,-6802,26972),
(9150,1,0,7550,-6482,26972),
(9150,1,1,7580,-6480,26972),
(9150,1,2,7609,-6420,26972),
(9150,1,3,7621,-6348,26972),
(9150,1,4,7624,-6309,26972),
(9150,1,5,7582,-6286,26972),
(9150,1,6,7546,-6286,26972),
(9150,1,7,7487,-6314,26972),
(9150,1,8,7453,-6348,26972),
(9150,1,9,7445,-6384,26972),
(9150,1,10,7452,-6416,26972),
(9150,1,11,7483,-6446,26972),
(9150,2,0,7564,-6802,26972);

-- quest 9152: client QuestPOIBlob 29447, 29448, 399814
DELETE FROM world.quest_poi WHERE QuestID = 9152;
DELETE FROM world.quest_poi_points WHERE QuestID = 9152;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9152,0,0,-1,0,0,530,463,0,0,1,0,0,0,0,26972),
(9152,0,1,0,261346,22583,530,463,0,0,1,0,0,0,0,26972),
(9152,0,2,32,0,0,530,463,0,0,0,0,0,129323,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9152,0,0,7638,-6843,26972),
(9152,1,0,7683,-6391,26972),
(9152,2,0,7638,-6843,26972);

-- quest 9155: client QuestPOIBlob 29451, 29452, 29453, 399826
DELETE FROM world.quest_poi WHERE QuestID = 9155;
DELETE FROM world.quest_poi_points WHERE QuestID = 9155;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9155,0,0,-1,0,0,530,463,0,0,1,0,0,0,0,26972),
(9155,0,1,0,259646,16301,530,463,0,0,1,0,0,0,0,26972),
(9155,0,2,1,259647,16309,530,463,0,0,1,0,0,0,0,26972),
(9155,0,3,32,0,0,530,463,0,0,0,0,0,129768,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9155,0,0,7528,-6802,26972),
(9155,1,0,7567,-6647,26972),
(9155,1,1,7618,-6639,26972),
(9155,1,2,7619,-6584,26972),
(9155,1,3,7587,-6556,26972),
(9155,1,4,7421,-6522,26972),
(9155,1,5,7216,-6517,26972),
(9155,1,6,7288,-6580,26972),
(9155,1,7,7462,-6623,26972),
(9155,2,0,7612,-6642,26972),
(9155,2,1,7619,-6584,26972),
(9155,2,2,7553,-6556,26972),
(9155,2,3,7421,-6522,26972),
(9155,2,4,7352,-6519,26972),
(9155,2,5,7253,-6518,26972),
(9155,2,6,7255,-6551,26972),
(9155,2,7,7288,-6580,26972),
(9155,2,8,7559,-6641,26972),
(9155,3,0,7528,-6802,26972);

-- quest 9156: client QuestPOIBlob 29454, 29455, 29456, 399827
DELETE FROM world.quest_poi WHERE QuestID = 9156;
DELETE FROM world.quest_poi_points WHERE QuestID = 9156;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9156,0,0,-1,0,0,530,463,0,0,1,0,0,0,0,26972),
(9156,0,1,0,259786,22894,530,463,0,0,2,0,0,0,0,26972),
(9156,0,2,1,259787,22893,530,463,0,0,2,0,0,0,0,26972),
(9156,0,3,32,0,0,530,463,0,0,0,0,0,129641,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9156,0,0,7528,-6802,26972),
(9156,1,0,7159,-6684,26972),
(9156,1,1,7204,-6682,26972),
(9156,1,2,7238,-6632,26972),
(9156,1,3,7254,-6537,26972),
(9156,1,4,7256,-6524,26972),
(9156,1,5,7263,-6447,26972),
(9156,1,6,7260,-6374,26972),
(9156,1,7,7201,-6368,26972),
(9156,1,8,7163,-6465,26972),
(9156,1,9,7161,-6474,26972),
(9156,1,10,7145,-6567,26972),
(9156,1,11,7143,-6628,26972),
(9156,2,0,7183,-6680,26972),
(9156,2,1,7215,-6666,26972),
(9156,2,2,7242,-6618,26972),
(9156,2,3,7263,-6424,26972),
(9156,2,4,7267,-6388,26972),
(9156,2,5,7240,-6363,26972),
(9156,2,6,7204,-6375,26972),
(9156,2,7,7165,-6499,26972),
(9156,2,8,7154,-6546,26972),
(9156,2,9,7150,-6576,26972),
(9156,2,10,7150,-6605,26972),
(9156,2,11,7154,-6664,26972),
(9156,3,0,7570,-6879,26972);

-- quest 9157: client QuestPOIBlob 29457, 29458, 399828
DELETE FROM world.quest_poi WHERE QuestID = 9157;
DELETE FROM world.quest_poi_points WHERE QuestID = 9157;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9157,0,0,-1,0,0,530,463,0,0,1,0,0,0,0,26972),
(9157,0,1,0,259714,22674,530,463,0,0,1,0,0,0,0,26972),
(9157,0,2,32,0,0,530,463,0,0,0,0,0,129683,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9157,0,0,7847,-7669,26972),
(9157,1,0,7793,-7716,26972),
(9157,1,1,7862,-7708,26972),
(9157,1,2,7964,-7632,26972),
(9157,1,3,7965,-7614,26972),
(9157,1,4,7853,-7580,26972),
(9157,1,5,7805,-7591,26972),
(9157,1,6,7628,-7635,26972),
(9157,1,7,7642,-7659,26972),
(9157,1,8,7659,-7678,26972),
(9157,1,9,7724,-7706,26972),
(9157,1,10,7778,-7715,26972),
(9157,2,0,7847,-7669,26972);

-- quest 9160: client QuestPOIBlob 29473, 29474, 29475, 399831
DELETE FROM world.quest_poi WHERE QuestID = 9160;
DELETE FROM world.quest_poi_points WHERE QuestID = 9160;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9160,0,0,-1,0,0,530,463,0,0,1,0,0,0,0,26972),
(9160,0,1,0,261660,16330,530,463,0,0,1,0,0,0,0,26972),
(9160,0,2,1,261661,-1,530,463,0,0,1,0,0,0,0,26972),
(9160,0,3,32,0,0,530,463,0,0,0,0,0,129385,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9160,0,0,7552,-6764,26972),
(9160,1,0,7946,-6579,26972),
(9160,1,1,7978,-6554,26972),
(9160,1,2,8011,-6467,26972),
(9160,1,3,8006,-6451,26972),
(9160,1,4,7942,-6424,26972),
(9160,1,5,7884,-6488,26972),
(9160,1,6,7885,-6515,26972),
(9160,1,7,7889,-6546,26972),
(9160,2,0,7923,-6536,26972),
(9160,2,1,7957,-6502,26972),
(9160,2,2,7923,-6468,26972),
(9160,2,3,7889,-6502,26972),
(9160,3,0,7552,-6764,26972);

-- quest 9163: client QuestPOIBlob 29478, 29479, 29480, 29481, 399834
DELETE FROM world.quest_poi WHERE QuestID = 9163;
DELETE FROM world.quest_poi_points WHERE QuestID = 9163;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9163,0,0,-1,0,0,530,463,0,0,1,0,0,0,0,26972),
(9163,0,1,0,259554,22590,530,463,0,0,0,0,0,129368,0,26972),
(9163,0,2,1,259555,22591,530,463,0,0,0,0,0,129369,0,26972),
(9163,0,3,2,259556,22592,530,463,0,0,0,0,0,129370,0,26972),
(9163,0,4,32,0,0,530,463,0,0,0,0,0,129385,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9163,0,0,7552,-6764,26972),
(9163,1,0,7683,-5697,26972),
(9163,2,0,7715,-5706,26972),
(9163,3,0,7770,-5628,26972),
(9163,4,0,7552,-6764,26972);

-- quest 9164: client QuestPOIBlob 29482, 29483, 29484, 29485, 399835
DELETE FROM world.quest_poi WHERE QuestID = 9164;
DELETE FROM world.quest_poi_points WHERE QuestID = 9164;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9164,0,0,-1,0,0,530,463,0,0,1,0,0,0,0,26972),
(9164,0,1,0,259722,16208,530,463,0,0,0,0,0,0,0,26972),
(9164,0,2,1,259723,16206,530,463,0,0,0,0,0,0,0,26972),
(9164,0,3,2,259724,16209,530,463,0,0,0,0,0,0,0,26972),
(9164,0,4,32,0,0,530,463,0,0,0,0,0,129643,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9164,0,0,7203,-7093,26972),
(9164,1,0,6640,-6344,26972),
(9164,2,0,6436,-6636,26972),
(9164,3,0,6288,-6365,26972),
(9164,4,0,7203,-7093,26972);

-- quest 9167: client QuestPOIBlob 29489, 29490, 399837
DELETE FROM world.quest_poi WHERE QuestID = 9167;
DELETE FROM world.quest_poi_points WHERE QuestID = 9167;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9167,0,0,-1,0,0,530,463,0,0,1,0,0,0,0,26972),
(9167,0,1,0,259795,22653,530,463,0,0,1,0,0,0,0,26972),
(9167,0,2,32,0,0,530,463,0,0,0,0,0,129640,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9167,0,0,7192,-7101,26972),
(9167,1,0,6479,-6374,26972),
(9167,2,0,7192,-7101,26972);

-- quest 9169: client QuestPOIBlob 29493, 29494, 29495, 399838
DELETE FROM world.quest_poi WHERE QuestID = 9169;
DELETE FROM world.quest_poi_points WHERE QuestID = 9169;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9169,0,0,-1,0,0,530,463,0,0,1,0,0,0,0,26972),
(9169,0,1,0,259852,181359,530,463,0,2,1,0,0,0,0,26972),
(9169,0,2,27,0,0,530,463,0,1,1,0,0,0,0,26972),
(9169,0,3,32,0,0,530,463,0,0,0,0,0,129372,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9169,0,0,7483,-7273,26972),
(9169,1,0,6834,-7203,26972),
(9169,2,0,6818,-7247,26972),
(9169,2,1,6849,-7245,26972),
(9169,2,2,6882,-7214,26972),
(9169,2,3,6892,-7118,26972),
(9169,2,4,6865,-7111,26972),
(9169,2,5,6748,-7143,26972),
(9169,2,6,6754,-7181,26972),
(9169,2,7,6784,-7224,26972),
(9169,3,0,7483,-7273,26972);

-- quest 9171: client QuestPOIBlob 29501, 37596, 37597, 37598, 37599, 37600, 37601, 399839
DELETE FROM world.quest_poi WHERE QuestID = 9171;
DELETE FROM world.quest_poi_points WHERE QuestID = 9171;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9171,0,0,-1,0,0,530,463,0,0,1,0,0,0,0,26972),
(9171,0,1,0,259986,22644,530,463,0,0,1,0,0,0,0,26972),
(9171,1,2,0,259986,22644,530,463,0,0,1,0,0,0,0,26972),
(9171,2,3,0,259986,22644,530,463,0,0,1,0,0,0,0,26972),
(9171,3,4,0,259986,22644,530,463,0,0,1,0,0,0,0,26972),
(9171,4,5,0,259986,22644,530,463,0,0,1,0,0,0,0,26972),
(9171,5,6,0,259986,22644,530,463,0,0,1,0,0,0,0,26972),
(9171,0,7,32,0,0,530,463,0,0,0,0,0,129390,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9171,0,0,7586,-6881,26972),
(9171,1,0,7050,-6419,26972),
(9171,1,1,7114,-6312,26972),
(9171,1,2,7113,-6147,26972),
(9171,1,3,6917,-5819,26972),
(9171,1,4,6853,-5816,26972),
(9171,1,5,6782,-5815,26972),
(9171,1,6,6796,-6057,26972),
(9171,1,7,6810,-6229,26972),
(9171,1,8,6850,-6281,26972),
(9171,1,9,6884,-6316,26972),
(9171,1,10,6919,-6351,26972),
(9171,1,11,6983,-6415,26972),
(9171,2,0,6852,-6916,26972),
(9171,2,1,6851,-6850,26972),
(9171,2,2,6684,-6820,26972),
(9171,2,3,6714,-6844,26972),
(9171,3,0,7716,-6285,26972),
(9171,3,1,7586,-6088,26972),
(9171,3,2,7521,-6158,26972),
(9171,3,3,7582,-6218,26972),
(9171,3,4,7652,-6283,26972),
(9171,4,0,6882,-7084,26972),
(9171,4,1,6950,-7081,26972),
(9171,4,2,6982,-6982,26972),
(9171,4,3,6950,-6817,26972),
(9171,4,4,6885,-7016,26972),
(9171,5,0,7785,-6481,26972),
(9171,5,1,7817,-6449,26972),
(9171,5,2,7849,-6416,26972),
(9171,5,3,7807,-6288,26972),
(9171,5,4,7788,-6348,26972),
(9171,5,5,7783,-6415,26972),
(9171,6,0,7383,-6482,26972),
(9171,6,1,7415,-6451,26972),
(9171,6,2,7467,-6269,26972),
(9171,6,3,7450,-6016,26972),
(9171,6,4,7216,-6050,26972),
(9171,6,5,7184,-6085,26972),
(9171,7,0,7586,-6881,26972);

-- quest 9174: client QuestPOIBlob 29506, 29507, 399842
DELETE FROM world.quest_poi WHERE QuestID = 9174;
DELETE FROM world.quest_poi_points WHERE QuestID = 9174;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9174,0,0,-1,0,0,530,463,0,0,1,0,0,0,0,26972),
(9174,0,1,0,259168,16292,530,463,0,0,1,0,0,0,0,26972),
(9174,0,2,32,0,0,530,463,0,0,0,0,0,129683,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9174,0,0,7847,-7669,26972),
(9174,1,0,7946,-7637,26972),
(9174,2,0,7847,-7669,26972);

-- quest 9176: client QuestPOIBlob 29509, 29510, 29511, 399843
DELETE FROM world.quest_poi WHERE QuestID = 9176;
DELETE FROM world.quest_poi_points WHERE QuestID = 9176;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9176,0,0,-1,0,0,530,463,0,0,1,0,0,0,0,26972),
(9176,0,1,0,259764,22599,530,463,0,0,1,0,0,0,0,26972),
(9176,0,2,1,259765,22598,530,463,0,0,1,0,0,0,0,26972),
(9176,0,3,32,0,0,530,463,0,0,0,0,0,129640,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9176,0,0,7192,-7101,26972),
(9176,1,0,7172,-6616,26972),
(9176,2,0,7218,-6415,26972),
(9176,3,0,7192,-7101,26972);

-- quest 9192: client QuestPOIBlob 29527, 29528, 29529, 29530, 29531, 399846
DELETE FROM world.quest_poi WHERE QuestID = 9192;
DELETE FROM world.quest_poi_points WHERE QuestID = 9192;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9192,0,0,-1,0,0,530,463,0,0,1,0,0,0,0,26972),
(9192,0,1,0,260830,16334,530,463,0,0,1,0,0,0,0,26972),
(9192,0,2,1,260831,16335,530,463,0,0,1,0,0,0,0,26972),
(9192,0,3,2,260832,16337,530,463,0,0,1,0,0,0,0,26972),
(9192,1,4,2,260832,16337,530,463,0,0,1,0,0,0,0,26972),
(9192,0,5,32,0,0,530,463,0,0,0,0,0,129634,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9192,0,0,7556,-6760,26972),
(9192,1,0,7293,-6321,26972),
(9192,1,1,7321,-6249,26972),
(9192,1,2,7314,-6221,26972),
(9192,1,3,7247,-6155,26972),
(9192,1,4,7187,-6152,26972),
(9192,1,5,7071,-6186,26972),
(9192,1,6,7019,-6235,26972),
(9192,1,7,6997,-6270,26972),
(9192,1,8,7009,-6284,26972),
(9192,2,0,7248,-6298,26972),
(9192,2,1,7311,-6280,26972),
(9192,2,2,7283,-6214,26972),
(9192,2,3,7216,-6143,26972),
(9192,2,4,7184,-6115,26972),
(9192,2,5,7001,-6249,26972),
(9192,2,6,6996,-6265,26972),
(9192,2,7,7058,-6279,26972),
(9192,3,0,6997,-6270,26972),
(9192,3,1,7063,-6229,26972),
(9192,3,2,7019,-6235,26972),
(9192,3,3,6996,-6265,26972),
(9192,4,0,7249,-6331,26972),
(9192,4,1,7317,-6252,26972),
(9192,4,2,7229,-6204,26972),
(9192,4,3,7139,-6190,26972),
(9192,4,4,7152,-6238,26972),
(9192,5,0,7556,-6760,26972);

-- quest 9193: client QuestPOIBlob 29532, 29533, 29534, 399847
DELETE FROM world.quest_poi WHERE QuestID = 9193;
DELETE FROM world.quest_poi_points WHERE QuestID = 9193;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9193,0,0,-1,0,0,530,463,0,0,1,0,0,0,0,26972),
(9193,0,1,0,260453,181148,530,463,0,0,0,0,0,0,0,26972),
(9193,0,2,2,260455,-1,530,463,0,0,0,0,0,0,0,26972),
(9193,0,3,32,0,0,530,463,0,0,0,0,0,129715,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9193,0,0,7549,-7658,26972),
(9193,1,0,7631,-7459,26972),
(9193,1,1,7645,-7458,26972),
(9193,1,2,7663,-7313,26972),
(9193,1,3,7663,-7305,26972),
(9193,1,4,7661,-7217,26972),
(9193,1,5,7653,-7207,26972),
(9193,1,6,7598,-7238,26972),
(9193,1,7,7587,-7249,26972),
(9193,1,8,7550,-7350,26972),
(9193,1,9,7550,-7360,26972),
(9193,1,10,7550,-7370,26972),
(9193,2,0,7568,-7393,26972),
(9193,2,1,7602,-7359,26972),
(9193,2,2,7568,-7325,26972),
(9193,2,3,7534,-7359,26972),
(9193,3,0,7549,-7658,26972);

-- quest 9199: client QuestPOIBlob 29540, 29541, 399848
DELETE FROM world.quest_poi WHERE QuestID = 9199;
DELETE FROM world.quest_poi_points WHERE QuestID = 9199;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9199,0,0,-1,0,0,530,463,0,0,1,0,0,0,0,26972),
(9199,0,1,0,262251,22633,530,463,0,0,0,0,0,0,0,26972),
(9199,0,2,32,0,0,530,463,0,0,0,0,0,134957,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9199,0,0,7572,-7680,26972),
(9199,1,0,7697,-7541,26972),
(9199,1,1,7756,-7171,26972),
(9199,1,2,7761,-7134,26972),
(9199,1,3,7656,-7149,26972),
(9199,1,4,7642,-7176,26972),
(9199,1,5,7598,-7261,26972),
(9199,1,6,7557,-7356,26972),
(9199,1,7,7622,-7529,26972),
(9199,1,8,7626,-7532,26972),
(9199,2,0,7572,-7680,26972);

-- quest 9214: client QuestPOIBlob 29555, 29556, 29557, 29558, 29559, 29560, 29561, 399851
DELETE FROM world.quest_poi WHERE QuestID = 9214;
DELETE FROM world.quest_poi_points WHERE QuestID = 9214;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9214,0,0,-1,0,0,530,463,0,0,1,0,0,0,0,26972),
(9214,0,1,0,261332,23165,530,463,0,0,1,0,0,0,0,26972),
(9214,0,2,1,261333,23167,530,463,0,0,1,0,0,0,0,26972),
(9214,0,3,2,261334,22677,530,463,0,0,1,0,0,0,0,26972),
(9214,1,4,2,261334,22677,530,463,0,0,1,0,0,0,0,26972),
(9214,0,5,3,261335,23166,530,463,0,0,1,0,0,0,0,26972),
(9214,1,6,3,261335,23166,530,463,0,0,1,0,0,0,0,26972),
(9214,0,7,32,0,0,530,463,0,0,0,0,0,129302,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9214,0,0,7615,-7671,26972),
(9214,1,0,7405,-7990,26972),
(9214,1,1,7451,-7978,26972),
(9214,1,2,7517,-7950,26972),
(9214,1,3,7513,-7820,26972),
(9214,1,4,7280,-7721,26972),
(9214,1,5,7241,-7761,26972),
(9214,1,6,7244,-7799,26972),
(9214,2,0,7405,-7990,26972),
(9214,2,1,7451,-7978,26972),
(9214,2,2,7517,-7950,26972),
(9214,2,3,7513,-7820,26972),
(9214,2,4,7280,-7721,26972),
(9214,2,5,7241,-7761,26972),
(9214,2,6,7244,-7799,26972),
(9214,3,0,6813,-7437,26972),
(9214,3,1,6831,-7437,26972),
(9214,3,2,6844,-7410,26972),
(9214,3,3,6815,-7316,26972),
(9214,3,4,6649,-7287,26972),
(9214,3,5,6593,-7331,26972),
(9214,3,6,6654,-7406,26972),
(9214,3,7,6743,-7430,26972),
(9214,4,0,7136,-7581,26972),
(9214,4,1,7149,-7514,26972),
(9214,4,2,7117,-7481,26972),
(9214,4,3,6948,-7448,26972),
(9214,4,4,6951,-7480,26972),
(9214,4,5,6986,-7540,26972),
(9214,5,0,6501,-7456,26972),
(9214,5,1,6813,-7437,26972),
(9214,5,2,6844,-7410,26972),
(9214,5,3,6849,-7386,26972),
(9214,5,4,6815,-7316,26972),
(9214,5,5,6586,-7283,26972),
(9214,5,6,6502,-7445,26972),
(9214,6,0,7034,-7541,26972),
(9214,6,1,7065,-7540,26972),
(9214,6,2,7117,-7481,26972),
(9214,6,3,7083,-7451,26972),
(9214,6,4,7018,-7450,26972),
(9214,6,5,6951,-7480,26972),
(9214,6,6,6986,-7540,26972),
(9214,7,0,7615,-7671,26972);

-- quest 9215: client QuestPOIBlob 29562, 29563, 399852
DELETE FROM world.quest_poi WHERE QuestID = 9215;
DELETE FROM world.quest_poi_points WHERE QuestID = 9215;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9215,0,0,-1,0,0,530,463,0,0,1,0,0,0,0,26972),
(9215,0,1,0,261147,22640,530,463,0,0,1,0,0,0,0,26972),
(9215,0,2,32,0,0,530,463,0,0,0,0,0,129717,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9215,0,0,7615,-7671,26972),
(9215,1,0,6519,-7438,26972),
(9215,2,0,7581,-7667,26972);

-- quest 9216: client QuestPOIBlob 41051, 41052, 41053, 399853
DELETE FROM world.quest_poi WHERE QuestID = 9216;
DELETE FROM world.quest_poi_points WHERE QuestID = 9216;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9216,0,0,-1,0,0,530,463,0,0,1,0,0,0,0,26972),
(9216,0,1,0,260641,22641,530,463,0,0,1,0,0,0,0,26972),
(9216,1,2,0,260641,22641,530,463,0,0,1,0,0,0,0,26972),
(9216,0,3,32,0,0,530,463,0,0,0,0,0,129639,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9216,0,0,7578,-6898,26972),
(9216,1,0,7567,-6647,26972),
(9216,1,1,7618,-6639,26972),
(9216,1,2,7619,-6584,26972),
(9216,1,3,7587,-6556,26972),
(9216,1,4,7421,-6522,26972),
(9216,1,5,7317,-6520,26972),
(9216,1,6,7255,-6551,26972),
(9216,1,7,7288,-6580,26972),
(9216,1,8,7462,-6623,26972),
(9216,2,0,7018,-6580,26972),
(9216,2,1,7047,-6579,26972),
(9216,2,2,7147,-6550,26972),
(9216,2,3,7115,-6519,26972),
(9216,2,4,6783,-6477,26972),
(9216,2,5,6751,-6482,26972),
(9216,2,6,6721,-6511,26972),
(9216,2,7,6919,-6579,26972),
(9216,3,0,7578,-6898,26972);

-- quest 9218: client QuestPOIBlob 29566, 37605, 37606, 399855
DELETE FROM world.quest_poi WHERE QuestID = 9218;
DELETE FROM world.quest_poi_points WHERE QuestID = 9218;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9218,0,0,-1,0,0,530,463,0,0,1,0,0,0,0,26972),
(9218,0,1,0,260572,22642,530,463,0,0,1,0,0,0,0,26972),
(9218,1,2,0,260572,22642,530,463,0,0,1,0,0,0,0,26972),
(9218,0,3,32,0,0,530,463,0,0,0,0,0,129639,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9218,0,0,7578,-6898,26972),
(9218,1,0,6987,-6583,26972),
(9218,1,1,7047,-6579,26972),
(9218,1,2,7147,-6550,26972),
(9218,1,3,7115,-6519,26972),
(9218,1,4,6728,-6460,26972),
(9218,1,5,6702,-6490,26972),
(9218,1,6,6702,-6515,26972),
(9218,1,7,6919,-6579,26972),
(9218,2,0,7914,-6712,26972),
(9218,2,1,7945,-6679,26972),
(9218,2,2,7912,-6654,26972),
(9218,2,3,7718,-6583,26972),
(9218,2,4,7696,-6582,26972),
(9218,2,5,7672,-6605,26972),
(9218,2,6,7675,-6634,26972),
(9218,2,7,7689,-6646,26972),
(9218,3,0,7578,-6898,26972);

-- quest 9220: client QuestPOIBlob 29568, 29569, 29570, 29571, 29572, 29573, 29574, 29575, 399857
DELETE FROM world.quest_poi WHERE QuestID = 9220;
DELETE FROM world.quest_poi_points WHERE QuestID = 9220;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9220,0,0,-1,0,0,530,463,0,0,1,0,0,0,0,26972),
(9220,0,1,0,260683,16320,530,463,0,0,1,0,0,0,0,26972),
(9220,0,2,1,260684,16319,530,463,0,0,1,0,0,0,0,26972),
(9220,1,3,1,260684,16319,530,463,0,0,1,0,0,0,0,26972),
(9220,2,4,1,260684,16319,530,463,0,0,1,0,0,0,0,26972),
(9220,0,5,2,260685,16321,530,463,0,0,1,0,0,0,0,26972),
(9220,1,6,2,260685,16321,530,463,0,0,1,0,0,0,0,26972),
(9220,2,7,2,260685,16321,530,463,0,0,1,0,0,0,0,26972),
(9220,0,8,32,0,0,530,463,0,0,0,0,0,129767,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9220,0,0,7199,-7094,26972),
(9220,1,0,6311,-6459,26972),
(9220,1,1,6650,-6382,26972),
(9220,1,2,6633,-6323,26972),
(9220,1,3,6520,-6290,26972),
(9220,1,4,6272,-6376,26972),
(9220,2,0,6516,-6586,26972),
(9220,2,1,6577,-6547,26972),
(9220,2,2,6613,-6514,26972),
(9220,2,3,6581,-6485,26972),
(9220,3,0,6366,-6545,26972),
(9220,3,1,6413,-6519,26972),
(9220,3,2,6384,-6482,26972),
(9220,3,3,6354,-6483,26972),
(9220,3,4,6269,-6496,26972),
(9220,4,0,6256,-6312,26972),
(9220,4,1,6385,-6250,26972),
(9220,4,2,6450,-6217,26972),
(9220,4,3,6452,-6187,26972),
(9220,4,4,6318,-6215,26972),
(9220,4,5,6271,-6235,26972),
(9220,5,0,6442,-6406,26972),
(9220,5,1,6437,-6361,26972),
(9220,5,2,6350,-6366,26972),
(9220,5,3,6272,-6376,26972),
(9220,5,4,6285,-6383,26972),
(9220,6,0,6527,-6542,26972),
(9220,6,1,6534,-6520,26972),
(9220,6,2,6518,-6448,26972),
(9220,6,3,6451,-6515,26972),
(9220,7,0,6581,-6416,26972),
(9220,7,1,6607,-6338,26972),
(9220,7,2,6603,-6333,26972),
(9220,7,3,6518,-6349,26972),
(9220,8,0,7199,-7094,26972);

-- quest 9274: client QuestPOIBlob 29645, 29646, 29647, 399888
DELETE FROM world.quest_poi WHERE QuestID = 9274;
DELETE FROM world.quest_poi_points WHERE QuestID = 9274;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9274,0,0,-1,0,0,530,463,0,0,1,0,0,0,0,26972),
(9274,0,1,0,257680,16327,530,463,0,0,1,0,0,0,0,26972),
(9274,0,2,1,257681,16328,530,463,0,0,1,0,0,0,0,26972),
(9274,0,3,32,0,0,530,463,0,0,0,0,0,140471,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9274,0,0,7612,-7666,26972),
(9274,1,0,7816,-7743,26972),
(9274,1,1,7850,-7714,26972),
(9274,1,2,7885,-7684,26972),
(9274,1,3,7918,-7652,26972),
(9274,1,4,7947,-7615,26972),
(9274,1,5,7852,-7586,26972),
(9274,1,6,7784,-7588,26972),
(9274,1,7,7644,-7655,26972),
(9274,1,8,7681,-7686,26972),
(9274,1,9,7751,-7741,26972),
(9274,2,0,7816,-7743,26972),
(9274,2,1,7850,-7714,26972),
(9274,2,2,7885,-7684,26972),
(9274,2,3,7918,-7652,26972),
(9274,2,4,7947,-7615,26972),
(9274,2,5,7852,-7586,26972),
(9274,2,6,7784,-7588,26972),
(9274,2,7,7644,-7655,26972),
(9274,2,8,7681,-7686,26972),
(9274,2,9,7751,-7741,26972),
(9274,3,0,7612,-7666,26972);

-- quest 9275: client QuestPOIBlob 29648, 29649, 29650, 29651, 399889
DELETE FROM world.quest_poi WHERE QuestID = 9275;
DELETE FROM world.quest_poi_points WHERE QuestID = 9275;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9275,0,0,-1,0,0,530,463,0,0,1,0,0,0,0,26972),
(9275,0,1,0,257899,181250,530,463,0,0,0,0,0,0,0,26972),
(9275,0,2,1,257900,181251,530,463,0,0,0,0,0,0,0,26972),
(9275,0,3,2,257901,181252,530,463,0,0,0,0,0,0,0,26972),
(9275,0,4,32,0,0,530,463,0,0,0,0,0,134957,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9275,0,0,7572,-7680,26972),
(9275,1,0,6798,-7432,26972),
(9275,2,0,6617,-7364,26972),
(9275,3,0,6996,-7536,26972),
(9275,4,0,7572,-7680,26972);

-- quest 9276: client QuestPOIBlob 29652, 29653, 29654, 399893
DELETE FROM world.quest_poi WHERE QuestID = 9276;
DELETE FROM world.quest_poi_points WHERE QuestID = 9276;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9276,0,0,-1,0,0,530,463,0,0,1,0,0,0,0,26972),
(9276,0,1,0,257554,16469,530,463,0,0,1,0,0,0,0,26972),
(9276,0,2,1,257555,16344,530,463,0,0,1,0,0,0,0,26972),
(9276,0,3,32,0,0,530,463,0,0,0,0,0,135023,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9276,0,0,7579,-7670,26972),
(9276,1,0,7405,-7990,26972),
(9276,1,1,7451,-7978,26972),
(9276,1,2,7517,-7950,26972),
(9276,1,3,7513,-7820,26972),
(9276,1,4,7280,-7721,26972),
(9276,1,5,7241,-7761,26972),
(9276,1,6,7244,-7799,26972),
(9276,2,0,7405,-7990,26972),
(9276,2,1,7451,-7978,26972),
(9276,2,2,7517,-7950,26972),
(9276,2,3,7513,-7820,26972),
(9276,2,4,7280,-7721,26972),
(9276,2,5,7241,-7761,26972),
(9276,2,6,7244,-7799,26972),
(9276,3,0,7579,-7670,26972);

-- quest 9277: client QuestPOIBlob 29655, 29656, 29657, 29658, 29659, 399894
DELETE FROM world.quest_poi WHERE QuestID = 9277;
DELETE FROM world.quest_poi_points WHERE QuestID = 9277;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9277,0,0,-1,0,0,530,463,0,0,1,0,0,0,0,26972),
(9277,0,1,0,258943,16345,530,463,0,0,1,0,0,0,0,26972),
(9277,1,2,0,258943,16345,530,463,0,0,1,0,0,0,0,26972),
(9277,0,3,1,258944,16346,530,463,0,0,1,0,0,0,0,26972),
(9277,1,4,1,258944,16346,530,463,0,0,1,0,0,0,0,26972),
(9277,0,5,32,0,0,530,463,0,0,0,0,0,135023,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9277,0,0,7579,-7670,26972),
(9277,1,0,6813,-7437,26972),
(9277,1,1,6831,-7437,26972),
(9277,1,2,6844,-7410,26972),
(9277,1,3,6815,-7316,26972),
(9277,1,4,6649,-7287,26972),
(9277,1,5,6593,-7331,26972),
(9277,1,6,6654,-7406,26972),
(9277,1,7,6743,-7430,26972),
(9277,2,0,7136,-7581,26972),
(9277,2,1,7149,-7514,26972),
(9277,2,2,7117,-7481,26972),
(9277,2,3,6948,-7448,26972),
(9277,2,4,6951,-7480,26972),
(9277,2,5,6986,-7540,26972),
(9277,3,0,6501,-7456,26972),
(9277,3,1,6813,-7437,26972),
(9277,3,2,6844,-7410,26972),
(9277,3,3,6849,-7386,26972),
(9277,3,4,6815,-7316,26972),
(9277,3,5,6586,-7283,26972),
(9277,3,6,6502,-7445,26972),
(9277,4,0,7034,-7541,26972),
(9277,4,1,7065,-7540,26972),
(9277,4,2,7117,-7481,26972),
(9277,4,3,7083,-7451,26972),
(9277,4,4,7018,-7450,26972),
(9277,4,5,6951,-7480,26972),
(9277,4,6,6986,-7540,26972),
(9277,5,0,7579,-7670,26972);

-- 3) Quests without client blobs, merged 23877 + 26124 (as 8325/9402/12816 in #84): keep the 23877 rows and the
-- 26124 quest-giver row (ObjectiveIndex 32), drop the other 26124 rows and the 26124 points merged into Idx1 values
-- owned by 23877 rows. 23877 rows of a second objective carried ObjectiveIndex 0: set to quest_objectives.StorageIndex.

-- quest 9147
DELETE FROM world.quest_poi WHERE QuestID = 9147 AND VerifiedBuild = 26124 AND ObjectiveIndex <> 32;
DELETE FROM world.quest_poi_points WHERE QuestID = 9147 AND Idx1 IN (2, 3, 5, 7) AND VerifiedBuild = 26124;
-- quest 9158
DELETE FROM world.quest_poi WHERE QuestID = 9158 AND VerifiedBuild = 26124 AND ObjectiveIndex <> 32;
DELETE FROM world.quest_poi_points WHERE QuestID = 9158 AND Idx1 IN (1, 2, 3) AND VerifiedBuild = 26124;
-- quest 9159
DELETE FROM world.quest_poi WHERE QuestID = 9159 AND VerifiedBuild = 26124 AND ObjectiveIndex <> 32;
DELETE FROM world.quest_poi_points WHERE QuestID = 9159 AND Idx1 IN (1, 4, 6, 8, 9) AND VerifiedBuild = 26124;
UPDATE world.quest_poi SET ObjectiveIndex = 1 WHERE QuestID = 9159 AND BlobIndex = 7 AND Idx1 = 7 AND QuestObjectiveID = 259591;
UPDATE world.quest_poi SET ObjectiveIndex = 1 WHERE QuestID = 9159 AND BlobIndex = 8 AND Idx1 = 8 AND QuestObjectiveID = 259591;
-- quest 9173
DELETE FROM world.quest_poi WHERE QuestID = 9173 AND VerifiedBuild = 26124 AND ObjectiveIndex <> 32;
DELETE FROM world.quest_poi_points WHERE QuestID = 9173 AND Idx1 IN (2) AND VerifiedBuild = 26124;
UPDATE world.quest_poi SET ObjectiveIndex = 1 WHERE QuestID = 9173 AND BlobIndex = 1 AND Idx1 = 1 AND QuestObjectiveID = 260007;
-- quest 9207
DELETE FROM world.quest_poi WHERE QuestID = 9207 AND VerifiedBuild = 26124 AND ObjectiveIndex <> 32;
DELETE FROM world.quest_poi_points WHERE QuestID = 9207 AND Idx1 IN (1) AND VerifiedBuild = 26124;
-- quest 9212
DELETE FROM world.quest_poi WHERE QuestID = 9212 AND VerifiedBuild = 26124 AND ObjectiveIndex <> 32;
-- quest 9217
DELETE FROM world.quest_poi WHERE QuestID = 9217 AND VerifiedBuild = 26124 AND ObjectiveIndex <> 32;
DELETE FROM world.quest_poi_points WHERE QuestID = 9217 AND Idx1 IN (2) AND VerifiedBuild = 26124;
-- quest 9281
DELETE FROM world.quest_poi WHERE QuestID = 9281 AND VerifiedBuild = 26124 AND ObjectiveIndex <> 32;
DELETE FROM world.quest_poi_points WHERE QuestID = 9281 AND Idx1 IN (1, 4, 6) AND VerifiedBuild = 26124;
UPDATE world.quest_poi SET ObjectiveIndex = 1 WHERE QuestID = 9281 AND BlobIndex = 3 AND Idx1 = 3 AND QuestObjectiveID = 261942;
UPDATE world.quest_poi SET ObjectiveIndex = 1 WHERE QuestID = 9281 AND BlobIndex = 4 AND Idx1 = 4 AND QuestObjectiveID = 261942;
UPDATE world.quest_poi SET ObjectiveIndex = 1 WHERE QuestID = 9281 AND BlobIndex = 5 AND Idx1 = 5 AND QuestObjectiveID = 261942;
-- quest 9315
DELETE FROM world.quest_poi WHERE QuestID = 9315 AND VerifiedBuild = 26124 AND ObjectiveIndex <> 32;
DELETE FROM world.quest_poi_points WHERE QuestID = 9315 AND Idx1 IN (1) AND VerifiedBuild = 26124;

-- 4) Powering our Defenses (8490): the Infused Crystal (16364) runs timed action list 1636400, whose six wave rows
-- called a random timed action list (action 87) on the crystal itself. SmartScript::SetScript9 refuses to replace a
-- timed action list from inside one ("trying to overwrite timed action list from a timed action", Server.log
-- 2026-09-28 23:25), so no Enraged Wraith (17086) ever spawned. The rows now summon directly (same summon as
-- the 1636401-1636413 lists: 17086, type 6, 60 s), 3 per wave at fixed spots out of those lists.
UPDATE world.smart_scripts SET action_type = 12, action_param1 = 17086, action_param2 = 6, action_param3 = 60000, action_param4 = 0, action_param5 = 0, action_param6 = 0, target_type = 8, target_x = 8270.68, target_y = -7188.53, target_z = 139.619 WHERE entryorguid = 1636400 AND source_type = 9 AND id = 0;
UPDATE world.smart_scripts SET action_type = 12, action_param1 = 17086, action_param2 = 6, action_param3 = 60000, action_param4 = 0, action_param5 = 0, action_param6 = 0, target_type = 8, target_x = 8278.51, target_y = -7242.13, target_z = 139.162 WHERE entryorguid = 1636400 AND source_type = 9 AND id = 1;
UPDATE world.smart_scripts SET action_type = 12, action_param1 = 17086, action_param2 = 6, action_param3 = 60000, action_param4 = 0, action_param5 = 0, action_param6 = 0, target_type = 8, target_x = 8261.87, target_y = -7197.2, target_z = 139.395 WHERE entryorguid = 1636400 AND source_type = 9 AND id = 2;
UPDATE world.smart_scripts SET action_type = 12, action_param1 = 17086, action_param2 = 6, action_param3 = 60000, action_param4 = 0, action_param5 = 0, action_param6 = 0, target_type = 8, target_x = 8297.43, target_y = -7193.53, target_z = 139.603 WHERE entryorguid = 1636400 AND source_type = 9 AND id = 3;
UPDATE world.smart_scripts SET action_type = 12, action_param1 = 17086, action_param2 = 6, action_param3 = 60000, action_param4 = 0, action_param5 = 0, action_param6 = 0, target_type = 8, target_x = 8303.5, target_y = -7201.96, target_z = 139.577 WHERE entryorguid = 1636400 AND source_type = 9 AND id = 4;
UPDATE world.smart_scripts SET action_type = 12, action_param1 = 17086, action_param2 = 6, action_param3 = 60000, action_param4 = 0, action_param5 = 0, action_param6 = 0, target_type = 8, target_x = 8308.2, target_y = -7221.22, target_z = 139.595 WHERE entryorguid = 1636400 AND source_type = 9 AND id = 5;
