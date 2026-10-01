-- Undo sql/custom/fix_azsuna_dark_revelations.sql (#122, Dark Revelations). Restores the rows as they were on
-- 2026-10-02. Live with a worldserver restart (no .reload).

DELETE FROM world.smart_scripts WHERE entryorguid = 90474 AND source_type = 0 AND id = 1;
DELETE FROM world.smart_scripts WHERE entryorguid = 9047400 AND source_type = 9;

UPDATE world.spell_area SET quest_end_status = 9
WHERE spell = 178860 AND area = 0 AND quest_start = 36920 AND quest_end = 37449 AND quest_end_status = 1;

DELETE FROM world.npc_spellclick_spells WHERE npc_entry = 90623 AND spell_id = 46598;
DELETE FROM world.conditions WHERE SourceTypeOrReferenceId = 18 AND SourceGroup = 90623 AND SourceEntry IN (46598, 178923);

UPDATE world.smart_scripts SET target_type = 18, target_param1 = 10, comment = 'data ts'
WHERE entryorguid = 9062100 AND source_type = 9 AND id = 3 AND action_type = 49 AND target_type = 21 AND target_param1 = 40;
UPDATE world.smart_scripts SET event_param2 = 3
WHERE entryorguid = 90622 AND source_type = 0 AND id = 0 AND event_type = 10 AND event_param2 = 20;
