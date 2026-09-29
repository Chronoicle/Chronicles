-- Undo for fix_azsuna_from_within.sql (#122 part A): the values before the fix, 2026-09-29.
UPDATE world.spell_area SET quest_end_status = 66
WHERE spell = 178860 AND area = 0 AND quest_start = 36920 AND quest_end = 37449 AND quest_end_status = 9;
UPDATE world.smart_scripts SET action_param1 = 150096, action_param2 = 0, comment = 'update phases'
WHERE entryorguid = 90255 AND source_type = 0 AND id = 0 AND event_type = 20 AND event_param1 = 36920
  AND action_type = 85 AND action_param1 = 178860;
UPDATE world.creature_template_wdb SET Name1 = 'Demon Hunter', Displayid1 = 61909, Displayid2 = 61911, Displayid3 = 61906, Displayid4 = 61908
WHERE Entry = 90474;
UPDATE world.creature_template_wdb_locale SET Name1 = 'Demon Hunter' WHERE ID = 90474 AND Locale = 'enUS';
UPDATE world.creature_template_addon SET mount = 67597, bytes1 = 16777216 WHERE entry = 90474;
UPDATE world.gameobject_template SET StateWorldEffectID = 0 WHERE entry = 240123 AND StateWorldEffectID = 2100;
