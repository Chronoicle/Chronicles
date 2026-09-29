-- Undo of fix_dalaran_scouting_map_messengers.sql (#92 follow-up). The core part (Player.cpp HasSpellAreaSpell) is undone
-- by reverting its commit.
UPDATE world.spell_area SET quest_start = 0, quest_start_status = 0
WHERE spell = 195286 AND area = 7502 AND quest_start = 39261 AND quest_start_status = 1 AND quest_end = 39047;
UPDATE world.smart_scripts SET event_param1 = 39047, action_param1 = 1
WHERE entryorguid = 99343 AND source_type = 0 AND id = 2 AND event_type = 19 AND event_param1 = 0 AND action_type = 1 AND action_param1 = 0;
UPDATE world.smart_scripts SET action_param1 = 0
WHERE entryorguid = 99343 AND source_type = 0 AND id = 1 AND event_type = 61 AND action_type = 1 AND action_param1 = 1;
DELETE FROM world.conditions WHERE SourceTypeOrReferenceId = 17 AND ConditionTypeOrReference = 27
AND SourceEntry IN (224250, 224350, 224263, 224286, 224339, 227342, 227324, 224338, 224344, 224335, 224244);
