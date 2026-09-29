-- Issue #105 (tyrvana): night elf class letters in Shadowglen (the Sigil quests from Melithar Staghelm / Ilthalaine).
-- Undo: sql/custom/undo_nightelf_sigils.sql. Goes live with a worldserver restart (no .reload).
-- Note: TrinityCore (2017_06_18_00_world) and Ashamane/DestinyCore disable every Shadowglen Sigil quest as removed in
-- Legion; this server kept five of them live, so the owner chose to make all seven work instead.

-- 1) Hallowed Sigil (priest) and Verdant Sigil (druid) were in `disables` as "Deprecated quest" (the other five Sigils
-- were not), so priests and druids never got their class letter. Their follow-ups keep their current state
-- (26949 Learning the Word is enabled, 26948 Moonfire stays disabled).
DELETE FROM world.disables WHERE sourceType = 1 AND entry IN (3119, 3120);

-- 2) No turn-in marker: none of the seven Sigil quests had any quest_poi / quest_poi_points row, and the 7.3.5 client
-- has no QuestPOIBlob for them either. One turn-in POI each (ObjectiveIndex -1) at the class trainer, same layout as
-- the retail 23877 letter POIs (e.g. 3082, 3112): map 1, WorldMapArea 888 (Shadowglen, like 28713/28714), Flags 1.
DELETE FROM world.quest_poi WHERE QuestID IN (3116, 3117, 3118, 3119, 3120, 26841, 31168);
DELETE FROM world.quest_poi_points WHERE QuestID IN (3116, 3117, 3118, 3119, 3120, 26841, 31168);
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(3116, 0, 0, -1, 0, 0, 1, 888, 0, 0, 1, 0, 0, 0, 0, 26972),
(3117, 0, 0, -1, 0, 0, 1, 888, 0, 0, 1, 0, 0, 0, 0, 26972),
(3118, 0, 0, -1, 0, 0, 1, 888, 0, 0, 1, 0, 0, 0, 0, 26972),
(3119, 0, 0, -1, 0, 0, 1, 888, 0, 0, 1, 0, 0, 0, 0, 26972),
(3120, 0, 0, -1, 0, 0, 1, 888, 0, 0, 1, 0, 0, 0, 0, 26972),
(26841, 0, 0, -1, 0, 0, 1, 888, 0, 0, 1, 0, 0, 0, 0, 26972),
(31168, 0, 0, -1, 0, 0, 1, 888, 0, 0, 1, 0, 0, 0, 0, 26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(3116, 0, 0, 10527, 778, 26972),  -- Alyissia (3593), warrior
(3117, 0, 0, 10448, 778, 26972),  -- Ayanna Everstride (3596), hunter
(3118, 0, 0, 10519, 778, 26972),  -- Frahun Shadewhisper (3594), rogue
(3119, 0, 0, 10459, 802, 26972),  -- Shanda (3595), priest
(3120, 0, 0, 10486, 816, 26972),  -- Mardant Strongoak (3597), druid
(26841, 0, 0, 10456, 805, 26972), -- Rhyanda (43006), mage
(31168, 0, 0, 10529, 785, 26972); -- Laoxi (63331), monk
