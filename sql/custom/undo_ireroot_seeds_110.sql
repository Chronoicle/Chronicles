-- Undo fix_ireroot_seeds_110.sql
UPDATE world.spell_area SET quest_start_status = 74, quest_end_status = 66 WHERE spell = 65455 AND area = 141 AND quest_start = 13946;
