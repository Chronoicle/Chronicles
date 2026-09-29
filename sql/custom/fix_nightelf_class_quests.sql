-- Issues #104/#105 follow-up (tyrvana, owner OK; Claude desktop team subagent 2026-09-29): the night elf class quests
-- in Shadowglen (after the Sigil letters). Undo: sql/custom/undo_nightelf_class_quests.sql.
-- Live with a worldserver restart (no .reload) plus the npc_training_dummy change in npcs_special.cpp (Frost Nova 122,
-- Eviscerate 196819 and Tiger Palm 100780 now give the practice credit 44175).

-- 1) A Rogue's Advantage (26946), Moonfire (26948) and The Art of the Monk (31169) were in `disables` as "Deprecated
--    quest", so Frahun Shadewhisper, Mardant Strongoak and Laoxi never offered them.
DELETE FROM world.disables WHERE sourceType = 1 AND entry IN (26946, 26948, 31169);

-- 2) "Learn the spell" objectives still used the Mists of Pandaria spell IDs, which no 7.3.5 character can have:
--    Eviscerate was 2098 (now Run Through, Outlaw only, level 10; Eviscerate is 196819, level 3) and Tiger Palm was
--    100787 (no longer in the client; now 100780, level 1). Same fault in every start zone's rogue quest, so all rows.
UPDATE world.quest_objectives SET ObjectID = 196819 WHERE Type = 5 AND ObjectID = 2098;
UPDATE world.quest_objectives SET ObjectID = 100780 WHERE Type = 5 AND ObjectID = 100787;

-- 3) Learning New Techniques (26945, warrior) had no objectives at all, so it completed the moment it was accepted.
--    Same two objectives as the human warrior quest 26913; the IDs are the retail ones (quest_objectives_locale
--    253520 "Reach Level 3 to Learn Charge", 253521 "Practice Charge").
DELETE FROM world.quest_objectives WHERE ID IN (253520, 253521);
INSERT INTO world.quest_objectives (ID, QuestID, Type, StorageIndex, ObjectID, Amount, Flags, Flags2, TaskStep, Description, VerifiedBuild, Bugged) VALUES
(253520, 26945, 5, -1, 100, 1, 0, 0, 0, NULL, 26972, 0),     -- learn Charge
(253521, 26945, 0, 0, 44175, 1, 0, 0, 0, NULL, 26972, 0);    -- Spell Practice Credit (Charge on a Training Dummy)

-- 4) Frost Nova (26940, mage) was started by Aggra (45006, Deepholm) instead of Rhyanda (43006), the mage trainer in
--    Aldrassil who ends it and the Forbidden Sigil, so the Sigil never led to it. (Its map markers: separate fix.)
DELETE FROM world.creature_queststarter WHERE id = 45006 AND quest = 26940;
INSERT IGNORE INTO world.creature_queststarter (id, quest) VALUES (43006, 26940);

-- 5) The class quests and Demonic Thieves had RewardNextQuest = 28723 (Priestess of the Moon). The class trainers offer
--    28723 to everyone right after Fel Moss Corruption (28714 NextQuestID), and Player::SatisfyQuestNextChain refuses a
--    quest whose next chain quest is already taken or done: once 28723 was picked up at a trainer, the class quest
--    auto-offered after the Sigil was refused ("chain", the error sound) and could never be taken again; the same
--    lock could hit Demonic Thieves (needed for every Sigil). Without the chain link the quests are independent; the
--    trainer's window reopens after the class quest and still lists Priestess of the Moon.
UPDATE world.quest_template SET RewardNextQuest = 0
WHERE ID IN (26940, 26945, 26946, 26947, 26948, 26949, 31169, 28715) AND RewardNextQuest = 28723;

-- 6) Sigils: Ilthalaine (2079) offered six of the seven letters next to Melithar Staghelm (2077); the letters need
--    Demonic Thieves, which is handed in to Melithar, and the monk letter (31168) was already Melithar only. Retail
--    Cataclysm/MoP listed both NPCs (with Fel Moss Corruption as the prerequisite); here Melithar gives all seven.
DELETE FROM world.creature_queststarter WHERE id = 2079 AND quest IN (3116, 3117, 3118, 3119, 3120, 26841);
