-- Undo fix_quest_event_flag_smartai.sql (all 10 had SpecialFlags 0 before)
UPDATE world.quest_template_addon SET SpecialFlags = SpecialFlags & ~2 WHERE ID IN (14390,14430,25189,26232,29100,29219,30515,38035,46213,46941);
