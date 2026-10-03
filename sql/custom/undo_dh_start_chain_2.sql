-- Undo fix_dh_start_chain_2.sql
DELETE FROM world.conditions WHERE SourceTypeOrReferenceId = 19 AND SourceEntry = 39663 AND ConditionTypeOrReference = 8 AND ConditionValue1 IN (38727, 38819);
UPDATE world.quest_template_addon SET NextQuestID = 0 WHERE ID IN (39689, 39690);
