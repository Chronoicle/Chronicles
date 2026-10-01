-- Undo of sql/custom/fix_quest_audit_139_draenei_eversong.sql (#139): restores the rows exactly as they were on live
-- (2026-10-01). Live with a worldserver restart (no .reload).

-- 1) Ammen Vale main chain
UPDATE world.quest_template_addon SET PrevQuestID = 9280 WHERE ID = 9369 AND PrevQuestID = 0;
UPDATE world.quest_template_addon SET NextQuestID = 9369 WHERE ID = 9280 AND NextQuestID = 9409;
UPDATE world.quest_template SET RewardNextQuest = 0 WHERE ID = 9280 AND RewardNextQuest = 9409;

-- 2) draenei class training quests
DELETE FROM world.creature_queststarter WHERE (id, quest) IN ((16503, 9289), (16499, 9288), (16501, 9287), (63335, 31172));

-- 3) Paladin Training / Ways of the Light
UPDATE world.quest_template_addon SET PrevQuestID = 8328 WHERE ID = 10069 AND PrevQuestID = 9676;
DELETE FROM world.quest_template_addon WHERE ID = 9676;
INSERT IGNORE INTO world.disables (sourceType, entry, flags, params_0, params_1, comment) VALUES (1, 9676, 0, '', '', 'Deprecated quest: Paladin Training');

-- 4) Delios Silverblade spawn
DELETE FROM world.creature WHERE guid = 146913901;

-- 5) Rite of Wisdom
UPDATE world.quest_template_addon SET PrevQuestID = 772 WHERE ID = 773 AND PrevQuestID = 20441;

-- 6) kill credit template 88872
DELETE FROM world.creature_template WHERE entry = 88872;
