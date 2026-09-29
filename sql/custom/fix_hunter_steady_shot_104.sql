-- #104 (tyrvana, owner OK; Claude desktop team 2026-09-29): the hunter starter class quests still ask for Steady Shot
-- (56641), which is not a 7.3.5 spell (no SkillLineAbility/SpellLevels row; back in BfA). Hunters below 10 shoot
-- Cobra Shot (193455), so nothing counted: the 11 quests (one per starting zone) could not be completed.
-- Credit 44175 ("practice") comes from npc_training_dummy / npc_rampaging_worgen (C++, now also Cobra and Arcane Shot)
-- and, for the troll quest 24778, from Tiki Target 38038, which had no SpellHit rows at all (added here).
-- Undo: undo_hunter_steady_shot_104.sql
-- 1) "learn Steady Shot" objectives (24530, 25139, 26917) -> learn Cobra Shot (hunters know it from level 1)
UPDATE world.quest_objectives SET ObjectID = 193455 WHERE ID IN (252668, 265173, 266521) AND Type = 5 AND ObjectID = 56641;
-- 2) Tiki Target: Cobra Shot / Arcane Shot hit -> practice credit (copies of its row 0 with every used column set)
CREATE TEMPORARY TABLE tmp_ss_104 AS SELECT * FROM world.smart_scripts WHERE entryorguid = 38038 AND source_type = 0 AND id = 0;
UPDATE tmp_ss_104 SET id = 1, link = 0, event_type = 8, event_phase_mask = 0, event_chance = 100, event_flags = 0,
  event_param1 = 193455, event_param2 = 0, event_param3 = 0, event_param4 = 0, event_param5 = 0,
  action_type = 33, action_param1 = 44175, action_param2 = 0, action_param3 = 0, action_param4 = 0, action_param5 = 0,
  action_param6 = 0, target_type = 7, target_param1 = 0, target_param2 = 0, target_param3 = 0, target_param4 = 0,
  target_x = 0, target_y = 0, target_z = 0, target_o = 0, comment = 'SpellHit (Cobra Shot) - Kill Credit';
INSERT IGNORE INTO world.smart_scripts SELECT * FROM tmp_ss_104;
UPDATE tmp_ss_104 SET id = 2, event_param1 = 185358, comment = 'SpellHit (Arcane Shot) - Kill Credit';
INSERT IGNORE INTO world.smart_scripts SELECT * FROM tmp_ss_104;
DROP TEMPORARY TABLE tmp_ss_104;
-- 3) the quest log texts say Cobra Shot (none of them mentioned Cobra Shot before, so the undo can swap back)
UPDATE world.quest_template SET LogDescription = REPLACE(LogDescription, 'Steady Shot', 'Cobra Shot')
WHERE ID IN (10070, 14007, 14276, 24530, 24778, 24964, 25139, 26917, 26947, 26963, 27021);
UPDATE world.quest_objectives SET Description = REPLACE(Description, 'Steady Shot', 'Cobra Shot') WHERE ID IN (262512, 265381, 265513);
