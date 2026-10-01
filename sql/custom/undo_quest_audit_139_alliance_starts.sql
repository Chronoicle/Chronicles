-- Undo for fix_quest_audit_139_alliance_starts.sql (exact state before the fix, from SELECTs on 2026-10-01;
-- restart, no .reload). Sections match the fix.

-- 1) 59 needed 39
UPDATE world.quest_template_addon SET PrevQuestID = 39 WHERE ID = 59 AND PrevQuestID = 71;

-- 2) + 4) no disables rows for 33416, 308, 311
DELETE FROM world.disables WHERE sourceType = 1 AND entry IN (33416, 308, 311);

-- 3) Julia Stevens offered 316930
INSERT IGNORE INTO world.creature_queststarter (id, quest) VALUES (64330, 316930);

-- 5) no Muffinus spawn, no starters for 41217/41218, both open to every class
DELETE FROM world.creature WHERE guid = 146941391 AND id = 103614;
DELETE FROM world.creature_queststarter WHERE (id = 42396 AND quest = 41217) OR (id = 103614 AND quest = 41218);
UPDATE world.quest_template_addon SET AllowableClasses = 0 WHERE ID IN (41217, 41218) AND AllowableClasses = 4;

-- 6) pet battle starters
DELETE FROM world.creature_queststarter WHERE (id = 63075 AND quest IN (31548, 31549, 31551)) OR (id = 63070 AND quest IN (31552, 31553, 31826));

-- 7) Teldrassil lore chain in the old order
UPDATE world.quest_template_addon SET NextQuestID = 933 WHERE ID = 929 AND NextQuestID = 7383;
UPDATE world.quest_template_addon SET PrevQuestID = 933, NextQuestID = 935 WHERE ID = 7383 AND PrevQuestID = 929 AND NextQuestID = 933;
UPDATE world.quest_template_addon SET PrevQuestID = 929, NextQuestID = 7383 WHERE ID = 933 AND PrevQuestID = 7383 AND NextQuestID = 14005;
UPDATE world.quest_template_addon SET PrevQuestID = 7383 WHERE ID = 935 AND PrevQuestID = 14005;

-- 8) 2518 needed 2519
UPDATE world.quest_template_addon SET PrevQuestID = 2519 WHERE ID = 2518 AND PrevQuestID = 0;
UPDATE world.quest_template_addon SET NextQuestID = 2518 WHERE ID = 2519 AND NextQuestID = 0;

-- 9) 2499 needed 2498; Oakenscowl unspawned and unscaled (no creature_template_scaling row, SandboxScalingID 0)
UPDATE world.quest_template_addon SET PrevQuestID = 2498 WHERE ID = 2499 AND PrevQuestID = 923;
DELETE FROM world.creature WHERE guid = 146941392 AND id = 2166;
DELETE FROM world.creature_template_scaling WHERE Entry = 2166;
UPDATE world.creature_template SET SandboxScalingID = 0 WHERE entry = 2166 AND SandboxScalingID = 81;
