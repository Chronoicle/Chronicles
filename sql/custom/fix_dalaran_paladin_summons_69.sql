-- #69 Dalaran: Lord Maxwell Tyrosus (190886 -> 92909, offers quest 38710) and Justicar Julia Celeste (224350 -> 112701,
-- offers 42844) were summoned AFTER their quest was taken/rewarded, every visit (and again on each re-entry), and never
-- before. SpellArea::IsFitToRequirements applies the spell only when the quest_end status IS in quest_end_status, so 74
-- (complete | incomplete | rewarded) was backwards. 1 = only while the quest is not taken yet.
-- Undo: undo_dalaran_paladin_summons_69.sql
UPDATE spell_area SET quest_end_status = 1 WHERE spell = 190886 AND area = 7502 AND quest_end = 38710;
UPDATE spell_area SET quest_end_status = 1 WHERE spell = 224350 AND area = 7581 AND quest_end = 42844;
