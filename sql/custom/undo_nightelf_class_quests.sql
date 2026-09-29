-- Undo for fix_nightelf_class_quests.sql (exact state before the fix, from SELECTs on 2026-09-29; restart, no .reload).
-- The npc_training_dummy spell cases are C++ (revert that commit separately).

-- 1) the three disables rows, exactly as they were
DELETE FROM world.disables WHERE sourceType = 1 AND entry IN (26946, 26948, 31169);
INSERT INTO world.disables (sourceType, entry, flags, params_0, params_1, comment) VALUES
(1, 26946, 0, '', '', 'Deprecated quest'),
(1, 26948, 0, '', '', 'Deprecated quest'),
(1, 31169, 0, '', '', 'Deprecated quest');

-- 2) learn-spell objectives (no Type 5 row used 196819 or 100780 before the fix)
UPDATE world.quest_objectives SET ObjectID = 2098 WHERE Type = 5 AND ObjectID = 196819
  AND ID IN (261653, 264733, 255014, 252666, 263474, 256064, 264945, 265943, 266221, 267272);
UPDATE world.quest_objectives SET ObjectID = 100787 WHERE Type = 5 AND ObjectID = 100780 AND ID IN (268169, 268201);

-- 3) 26945 had no quest_objectives rows (253520/253521 did not exist)
DELETE FROM world.quest_objectives WHERE ID IN (253520, 253521);

-- 4) Frost Nova 26940 starter: Aggra 45006 only (Rhyanda 43006 did not start it)
DELETE FROM world.creature_queststarter WHERE id = 43006 AND quest = 26940;
INSERT IGNORE INTO world.creature_queststarter (id, quest) VALUES (45006, 26940);

-- 5) chain link to Priestess of the Moon
UPDATE world.quest_template SET RewardNextQuest = 28723
WHERE ID IN (26940, 26945, 26946, 26947, 26948, 26949, 31169, 28715) AND RewardNextQuest = 0;

-- 6) Ilthalaine's Sigil starter rows
INSERT IGNORE INTO world.creature_queststarter (id, quest) VALUES
(2079, 3116), (2079, 3117), (2079, 3118), (2079, 3119), (2079, 3120), (2079, 26841);
