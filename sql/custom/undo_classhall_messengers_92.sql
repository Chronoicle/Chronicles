-- Undo for fix_classhall_messengers_92.sql (restores the exact before-state)
UPDATE world.spell_area SET quest_end_status = 74 WHERE area = 7502 AND quest_end_status = 1 AND (spell, quest_end, classmask) IN (
  (216443, 41052, 1), (196908, 40384, 4), (201208, 40832, 8), (226409, 40705, 16), (200023, 40714, 32),
  (195356, 41035, 128), (204860, 40716, 256), (193978, 12103, 512), (199277, 40643, 1024), (195286, 39047, 2048));
UPDATE world.spell_area SET quest_end_status = 74 WHERE area = 7581 AND quest_end_status = 1 AND (spell, quest_end, classmask) IN (
  (224250, 42597, 1), (224263, 44090, 4), (224286, 43007, 8), (224339, 44100, 16), (227342, 44550, 32),
  (227324, 44544, 64), (224338, 44099, 256), (224344, 42186, 512), (224335, 42516, 1024), (224244, 42666, 2048));
DELETE FROM world.smart_scripts WHERE entryorguid = 101344 AND source_type = 0 AND id IN (1, 2, 3, 4);
UPDATE world.smart_scripts SET event_param1 = 40716 WHERE entryorguid = 93775 AND source_type = 0 AND id = 2 AND event_type = 19 AND event_param1 = 41052;
