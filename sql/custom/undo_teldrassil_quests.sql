-- Undo fix_teldrassil_quests.sql (old values: 2561 Flags 0; spell_area 65455 area 258; no scaling rows and
-- SandboxScalingID 0 for 1993, 3569, 7318, 14430).
UPDATE world.quest_template SET Flags = 0 WHERE ID = 2561 AND Flags = 2;
UPDATE world.spell_area SET area = 258 WHERE spell = 65455 AND area = 141 AND quest_start = 13946;
DELETE FROM world.creature_template_scaling WHERE Entry IN (1993, 3569, 7318, 14430);
UPDATE world.creature_template SET SandboxScalingID = 0 WHERE entry IN (1993, 3569, 7318, 14430) AND SandboxScalingID = 81;
