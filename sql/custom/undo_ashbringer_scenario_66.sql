-- Undo fix_ashbringer_scenario_66.sql (none of these rows existed before; the changed fields were 0 / '')
DELETE FROM world.scenario_poi_points WHERE criteriaTreeId IN (42546, 42487, 45099, 45146, 49027, 45270, 45278);
DELETE FROM world.quest_poi_points WHERE QuestID = 38376 AND Idx1 = 7;
UPDATE world.quest_poi SET Idx1 = 3 WHERE QuestID = 38376 AND BlobIndex = 1 AND Idx1 = 7 AND MapID = 1500;
UPDATE world.quest_template_addon SET PrevQuestID = 0 WHERE ID = 42811 AND PrevQuestID = 38376;
UPDATE world.quest_template_addon SET ExclusiveGroup = 0 WHERE ID IN (38576, 42811, 42812) AND ExclusiveGroup = 38576;
DELETE FROM world.conditions WHERE SourceTypeOrReferenceId = 19 AND SourceEntry = 38576 AND ConditionTypeOrReference = 22 AND ConditionValue1 = 1500;
UPDATE world.creature_template SET ScriptName = '' WHERE entry = 92907 AND ScriptName = 'npc_bs_argent_hippogryph';
DELETE FROM world.waypoint_data_script WHERE id = 9290700;
DELETE FROM world.creature WHERE id = 91145 AND map = 1500;
