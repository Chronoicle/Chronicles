-- Undo fix_dh_fel_secrets_spec_quests.sql
UPDATE world.quest_template_addon SET PrevQuestID = 0 WHERE ID = 39515;
DELETE FROM world.conditions WHERE SourceTypeOrReferenceId = 19 AND SourceEntry IN (39515, 39516) AND ConditionTypeOrReference = 8 AND ConditionValue1 IN (39517, 39518);
DELETE FROM world.spell_script_names WHERE spell_id IN (194939, 194940);
