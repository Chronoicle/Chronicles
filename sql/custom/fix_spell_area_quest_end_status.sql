-- Claude (dev-owner) 2026-10-04, owner request (item 4). This core reads spell_area.quest_end_status as the ALLOWED states
-- of quest_end (SpellMgr.cpp:1189), TrinityCore as the FORBIDDEN ones. 81 rows (63 autocast phase/quest auras, Draenor and
-- Legion) use the same quest for start and end with masks that share no bit: in this core they can never pass, so the spell
-- was never applied. They are TrinityCore-style; convert to this core: allowed = all states (0x7F) minus the forbidden ones.
-- Rows with a different end quest (198) are left alone (meaning not certain, per-row fixes like #110 / #160).
CREATE TABLE IF NOT EXISTS world.bak_spell_area_end_status AS
SELECT spell, area, quest_start, aura_spell, racemask, classmask, gender, active_event, quest_end, quest_end_status
FROM world.spell_area WHERE quest_end <> 0 AND quest_start = quest_end AND (quest_start_status & quest_end_status) = 0;
UPDATE world.spell_area s JOIN world.bak_spell_area_end_status b
  ON b.spell = s.spell AND b.area = s.area AND b.quest_start = s.quest_start AND b.aura_spell = s.aura_spell
 AND b.racemask = s.racemask AND b.classmask = s.classmask AND b.gender = s.gender AND b.active_event = s.active_event
SET s.quest_end_status = 127 & ~b.quest_end_status;
