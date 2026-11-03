-- undo #197 Rook Spinner jump trigger
UPDATE world.smart_scripts SET event_type = 38, event_param1 = 1, event_param2 = 1, event_param3 = 0, event_param4 = 0, event_flags = 1 WHERE entryorguid = -262905 AND source_type = 0 AND id = 0;
UPDATE world.smart_scripts SET event_type = 38, event_param1 = 1, event_param2 = 1, event_param3 = 0, event_param4 = 0, event_flags = 0 WHERE entryorguid = 98681 AND source_type = 0 AND id = 0;
