-- #79 retest (James 2026-09-29 01:55 UTC: Alliance intro movie still loops, server lag). Pi team (Claude).
-- Undo: undo_broken_shore_alliance_79.sql. Needs the core with the #79 change in broken_islands.cpp
-- (spell_bi_intro_scene once per player for both spells, spell_bi_enter_stage1 ports each player once).
-- 225150 is a second "Intro Scene" (same effects as 199357: movie 486 + trigger 217781), also autocast by spell_area
-- in areas 8290 / 8455 for everyone. The first fix only scripted 199357, so 225150 kept playing the movie on every
-- area update and re-applied 217781, which ported the whole map again. Same once-per-player guard on it.
DELETE FROM world.spell_script_names WHERE spell_id = 225150 AND ScriptName = 'spell_bi_intro_scene';
INSERT INTO world.spell_script_names (spell_id, ScriptName) VALUES (225150, 'spell_bi_intro_scene');
