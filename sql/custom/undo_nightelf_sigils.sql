-- Undo for fix_nightelf_sigils.sql (issue #105). Restores the state before the fix (worldserver restart, no .reload).
-- Before the fix the seven Sigil quests had no quest_poi / quest_poi_points rows at all.
DELETE FROM world.quest_poi WHERE QuestID IN (3116, 3117, 3118, 3119, 3120, 26841, 31168);
DELETE FROM world.quest_poi_points WHERE QuestID IN (3116, 3117, 3118, 3119, 3120, 26841, 31168);

-- The two disables rows, exactly as they were.
DELETE FROM world.disables WHERE sourceType = 1 AND entry IN (3119, 3120);
INSERT INTO world.disables (sourceType, entry, flags, params_0, params_1, comment) VALUES
(1, 3119, 0, '', '', 'Deprecated quest'),
(1, 3120, 0, '', '', 'Deprecated quest');
