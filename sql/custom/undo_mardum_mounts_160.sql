-- Undo #160 (restores the row as it was on 2026-10-02).
UPDATE world.spell_area SET quest_end_status = 64 WHERE spell = 179665 AND area = 7705 AND quest_start = 0 AND quest_end = 40077 AND quest_end_status = 11;
