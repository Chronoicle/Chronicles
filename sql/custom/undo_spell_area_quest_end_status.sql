-- Undo fix_spell_area_quest_end_status.sql
UPDATE world.spell_area s JOIN world.bak_spell_area_end_status b
  ON b.spell = s.spell AND b.area = s.area AND b.quest_start = s.quest_start AND b.aura_spell = s.aura_spell
 AND b.racemask = s.racemask AND b.classmask = s.classmask AND b.gender = s.gender AND b.active_event = s.active_event
SET s.quest_end_status = b.quest_end_status;
