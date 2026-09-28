-- Undo for fix_dalaran_paladin_summons_69.sql
UPDATE spell_area SET quest_end_status = 74 WHERE spell = 190886 AND area = 7502 AND quest_end = 38710;
UPDATE spell_area SET quest_end_status = 74 WHERE spell = 224350 AND area = 7581 AND quest_end = 42844;
