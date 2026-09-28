-- #79 / #80 Legion intro, Alliance (James, Claude 2026-09-28). Undo: undo_broken_shore_79_80.sql
-- Needs the core with spell_bi_intro_scene (broken_islands.cpp); without it the row below is dropped at startup.

-- #79: Intro Scene 199357 (movie 486 + 217781) is autocast by spell_area in areas 8290 / 8455 of the Broken Shore
-- scenario (map 1460) on every area update (area entry, near teleport, resurrect, login). It applies no aura, so the
-- spell_area check never stops it: the intro movie replayed over and over. The script lets it cast only in scenario
-- step 0 (the arrival).
DELETE FROM world.spell_script_names WHERE spell_id = 199357 AND ScriptName = 'spell_bi_intro_scene';
INSERT INTO world.spell_script_names (spell_id, ScriptName) VALUES (199357, 'spell_bi_intro_scene');

-- #80: Genn Greymane (100395, spawn 344522) on the gunship above Stormwind Harbor is the only NPC on the deck with
-- ground movement + CanFly (creature_template_movement 1/1/2); every other deck NPC (Tess, Lorna, footmen, priests...)
-- has gravity disabled (0/0/1) and stays on the ship. With gravity on he drops through the deck into the harbor and
-- the quest can't be turned in. Same movement as his neighbours, for this spawn only.
DELETE FROM world.creature_movement_override WHERE SpawnId = 344522;
INSERT INTO world.creature_movement_override (SpawnId, Ground, Swim, Flight) VALUES (344522, 0, 0, 1);
