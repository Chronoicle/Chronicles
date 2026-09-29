-- #125 (tyrvana, owner OK 2026-09-29; Claude desktop team subagent): Shadowglen / Shadowthread Cave (Teldrassil).
-- Tarindrella (49480) should go with you through the cave during The Woodland Protector (28725) / Webwood Corruption
-- (28726) / Vile Touch (28727) until you take Signs of Things to Come (28728), which teleports you out (SmartAI id 0).
-- Undo: sql/custom/undo_tarindrella_follow_125.sql. Live with a worldserver restart (no .reload).
--
-- Cause: nothing summoned her. Retail (Cataclysm data, also TrinityCore's spell_area reference row
-- 92237/257/28725/28727/autocast 1/74/11): "Summon Tarindrella Aura" 92237 is put on the player in Shadowthread Cave
-- (area 257) from taking 28725 until 28727 is turned in. It casts "Summon Tarindrella" 92238 at once and every 10 s:
-- a copy of 49480 behind the player (SummonProperties 2996: ally guardian, quest slot, only the summoner sees it) that
-- follows and fights with the player and can take the turn-ins. 92237/92238/92239 are limited by the client data to
-- area group 2918 = Shadowthread Cave only, so the copy unsummons itself 2 s after it leaves the cave
-- (TempSummon::CheckLocation), e.g. when 28728 teleports the player out.
-- This core has no server script for 92238 (effect 0 is a script effect on every unit within 100 yd) and the quest slot
-- keeps the old summon, so every 10 s tick would add one more Tarindrella. Instead the copy casts "Tarindrella Guardian
-- Aura" 92239 on itself (area aura: it also sits on her owner within 100 yd) and 92238 is not cast while the player
-- has 92239. A blocked 10 s tick ends 92237; the next area or quest change (entering the cave, login, taking /
-- completing / turning in / abandoning 28725 or 28727) puts it back, which only summons her again if she died.

-- 1) The aura in Shadowthread Cave (retail row).
DELETE FROM world.spell_area WHERE spell = 92237 AND area = 257;
INSERT INTO world.spell_area (spell, area, quest_start, quest_end, aura_spell, racemask, classmask, active_event, gender, autocast, quest_start_status, quest_end_status) VALUES
(92237, 257, 28725, 28727, 0, 0, 0, 0, 2, 1, 74, 11);

-- 2) One Tarindrella per player: no Summon Tarindrella while the player has her Guardian Aura; its effect 0 only hits
--    the caster's own summons (not every unit in 100 yd, which could pull the player into other fights).
DELETE FROM world.conditions WHERE SourceTypeOrReferenceId IN (13, 17) AND SourceEntry = 92238;
INSERT INTO world.conditions (SourceTypeOrReferenceId, SourceGroup, SourceEntry, SourceId, ElseGroup, ConditionTypeOrReference, ConditionTarget, ConditionValue1, ConditionValue2, ConditionValue3, NegativeCondition, ErrorTextId, ScriptName, Comment) VALUES
(17, 0, 92238, 0, 0, 1, 0, 92239, 0, 0, 1, 0, '', 'Summon Tarindrella - caster must not have Tarindrella Guardian Aura (already has her)'),
(13, 1, 92238, 0, 0, 33, 0, 1, 5, 0, 0, 0, '', 'Summon Tarindrella effect 0 - only units created by the caster');

-- 3) The summoned copy marks its owner (the static spawn is never "just summoned").
DELETE FROM world.smart_scripts WHERE entryorguid = 49480 AND source_type = 0 AND id = 1;
INSERT INTO world.smart_scripts (entryorguid, source_type, id, link, Difficulties, event_type, event_phase_mask, event_chance, event_flags, event_param1, event_param2, event_param3, event_param4, event_param5, action_type, action_param1, action_param2, action_param3, action_param4, action_param5, action_param6, target_type, target_param1, target_param2, target_param3, target_param4, target_x, target_y, target_z, target_o, comment) VALUES
(49480,0,1,0,'',54,0,100,0,0,0,0,0,0,11,92239,2,0,0,0,0,1,0,0,0,0,0,0,0,0,'Tarindrella - On Just Summoned - Cast Tarindrella Guardian Aura (marks her owner)');
