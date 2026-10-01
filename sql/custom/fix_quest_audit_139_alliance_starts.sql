-- Issue #139 (static quest audit levels 1-10, docs/quest_audit_1_10.md): the BLOCKERs of Northshire/Elwynn,
-- Coldridge/New Tinkertown/Dun Morogh and Shadowglen/Teldrassil (desktop team Claude subagent, 2026-10-01).
-- Undo: sql/custom/undo_quest_audit_139_alliance_starts.sql. Live after a worldserver restart (no .reload).
-- Retail order from the 7.3.5 client (QuestLineXQuest 566 Elwynn, 568 Teldrassil) and Wowhead (Cataclysm+ chains).
-- 47709 The Great Gnomeregan Run needs no change here (see the report): its credits come from spell effect 90.

-- 1) 59 Cloth and Leather Armor (Elwynn) needed 39 Deliver Thomas' Report, which Blizzard removed (QUEST_FLAGS
--    UNAVAILABLE, no giver). 7.3.5: Report to Thomas (71) -> Cloth and Leather Armor (71 already has RewardNextQuest 59).
UPDATE world.quest_template_addon SET PrevQuestID = 71 WHERE ID = 59 AND PrevQuestID = 39;

-- 2) 33416 South Sprint 12 (Northshire): unused WoD race test quest, reachable only through 33398 (no giver) and
--    handed in to South Race Official 74796, who is never spawned. Not in a 7.3.5 QuestLine: disable it.
INSERT INTO world.disables (sourceType, entry, flags, params_0, params_1, comment) VALUES
(1, 33416, 0, '', '', 'Deprecated quest: South Sprint 12 (unused race test, ender 74796 never spawned; #139)');

-- 3) 316930 Julia Stevens: a bogus copy of the pet tamer quest 31693 (not in QuestV2.db2, no ender, so it could be
--    accepted but never handed in). Julia Stevens (64330) keeps the real 31693.
DELETE FROM world.creature_queststarter WHERE id = 64330 AND quest = 316930;

-- 4) 308 Distracting Jarven / 311 Return to Marleth (Kharanos): the Thunderbrew rivalry chain was removed in
--    Cataclysm; its first quest 310 Bitter Rivals has no giver and the Unguarded Thunder Ale Barrel (270) that gives
--    311 is never spawned. Disabled like the other removed Kharanos quests (287, 317, 400, 419).
INSERT INTO world.disables (sourceType, entry, flags, params_0, params_1, comment) VALUES
(1, 308, 0, '', '', 'Deprecated quest: Distracting Jarven (removed in Cataclysm, 310 has no giver; #139)'),
(1, 311, 0, '', '', 'Deprecated quest: Return to Marleth (removed in Cataclysm, barrel 270 never spawned; #139)');

-- 5) 26208 The Fight Continues (New Tinkertown): gnome hunters had no class chain. The hunter versions exist
--    (41217 The Future of Gnomeregan -> 41218 Meet the High Tinker, Legion) but nobody offered them, they were open to
--    every class, and their trainer Muffinus Chromebrew (103614) was not spawned. Spawn at Wowhead's 42.0, 31.4 on
--    New Tinkertown (WorldMapArea 895), on the platform there (z of the two objects beside it).
INSERT INTO world.creature (guid, id, map, zoneId, areaId, spawnMask, phaseMask, PhaseId, position_x, position_y, position_z, orientation, spawntimesecs) VALUES
(146941391, 103614, 0, 6457, 133, 1, 1, '', -5115.6, 429.25, 402.95, 2.64, 120);
INSERT INTO world.creature_queststarter (id, quest) VALUES (42396, 41217), (103614, 41218);
UPDATE world.quest_template_addon SET AllowableClasses = 4 WHERE ID IN (41217, 41218) AND AllowableClasses = 0;

-- 6) Pet battle starters (31822 Level Up! in Kharanos, 31555 Got one! in Dolanaar were behind quests nobody gave):
--    every other battle pet trainer offers its own whole set; Grady Bannson (63075) and Valeena (63070) missed three.
INSERT INTO world.creature_queststarter (id, quest) VALUES
(63075, 31548), (63075, 31549), (63075, 31551),   -- Learning the Ropes, On The Mend, Got one!
(63070, 31552), (63070, 31553), (63070, 31826);   -- Learning the Ropes, On The Mend, Level Up!

-- 7) Teldrassil lore chain. The DB had the pre-Cataclysm order (929 -> 933 -> 7383 -> 935); since 4.0.3 it is
--    929 The Refusal of the Aspects -> 7383 The Burden of the Kaldorei -> 933 The Coming Dawn -> 14005 The Vengeance of
--    Elune -> 935 The Waters of Teldrassil (QuestLine 568, quest texts, Wowhead series). 7383 needed 933 while its
--    RewardNextQuest is 933, so Player::SatisfyQuestNextChain always refused it.
UPDATE world.quest_template_addon SET NextQuestID = 7383 WHERE ID = 929 AND NextQuestID = 933;
UPDATE world.quest_template_addon SET PrevQuestID = 929, NextQuestID = 933 WHERE ID = 7383 AND PrevQuestID = 933 AND NextQuestID = 935;
UPDATE world.quest_template_addon SET PrevQuestID = 7383, NextQuestID = 14005 WHERE ID = 933 AND PrevQuestID = 929 AND NextQuestID = 7383;
UPDATE world.quest_template_addon SET PrevQuestID = 14005 WHERE ID = 935 AND PrevQuestID = 7383;

-- 8) 2518 Tears of the Moon needed 2519 The Temple of the Moon (removed in Cataclysm, disabled); it has no
--    prerequisite since. 2519's NextQuestID is cleared too so no tool counts it as a previous quest.
UPDATE world.quest_template_addon SET PrevQuestID = 0 WHERE ID = 2518 AND PrevQuestID = 2519;
UPDATE world.quest_template_addon SET NextQuestID = 0 WHERE ID = 2519 AND NextQuestID = 2518;

-- 9) 2499 Oakenscowl needed 2498 Return to Denalan (removed: QUEST_FLAGS_UNAVAILABLE, no giver); since 4.0.3 it
--    opens after 923 Mossy Tumors (Denalan waits beside Rellian at Wellspring Hovel). Oakenscowl (2166), who drops the
--    Gargantuan Tumor (loot row exists, 91.7% quest drop), was not spawned: spawn at Wowhead's 47.6, 35.4 on Teldrassil
--    ("a nook to the northeast"), terrain height from the .map file, and scale him like the other Teldrassil mobs.
UPDATE world.quest_template_addon SET PrevQuestID = 923 WHERE ID = 2499 AND PrevQuestID = 2498;
INSERT INTO world.creature (guid, id, map, zoneId, areaId, spawnMask, phaseMask, PhaseId, position_x, position_y, position_z, orientation, spawntimesecs) VALUES
(146941392, 2166, 1, 141, 141, 1, 1, '', 10461.4, 1438.9, 1326.7, 3.9, 120);
INSERT INTO world.creature_template_scaling (Entry, LevelScalingMin, LevelScalingMax, LevelScalingDeltaMin, LevelScalingDeltaMax, LevelScalingDuration, VerifiedBuild) VALUES
(2166, 5, 20, 0, 0, 0, NULL);
UPDATE world.creature_template SET SandboxScalingID = 81 WHERE entry = 2166 AND SandboxScalingID = 0;
