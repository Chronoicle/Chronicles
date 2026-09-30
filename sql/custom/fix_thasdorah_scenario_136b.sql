-- #136 (gabrielf03d), Marksmanship artifact scenario 972 (map 1489), stages after the Herald. Desktop team (Claude subagent,
-- 2026-10-01). Undo: undo_thasdorah_scenario_136b.sql

-- 1) Vereesa Windrunner (100397) never fought: her template has UNIT_FLAG_IMMUNE_TO_NPC (512), every SmartAI "start WP"
-- sets react state 0 (passive), and id 58 disables evade. Now, when she starts following the player (id 20, after the
-- summoners' door opens), she loses IMMUNE_TO_NPC, turns aggressive, can evade again (evade = back to following), can't
-- drop below 5% health, and casts her Black Arrow in combat. The 10039702 walk near Orestes keeps her aggressive.
-- Steps 1-2 (her own escort paths) stay as they were: a path start is ignored while in combat (SmartAI::StartPath).
-- Every one-shot event gets DONT_RESET (0x100): an evade calls SmartScript::OnReset, which re-arms one-shot events, and
-- the Inquisitor/Orestes/Herald resend their data every second.
UPDATE world.smart_scripts SET event_flags = event_flags | 256 WHERE entryorguid = 100397 AND source_type = 0 AND id <= 58;
UPDATE world.smart_scripts SET link = 59 WHERE entryorguid = 100397 AND source_type = 0 AND id = 20 AND link = 0;
UPDATE world.smart_scripts SET action_param6 = 2 WHERE entryorguid = 100397 AND source_type = 0 AND id = 23;
-- The Inquisitor's capture (data 9 9): she turns IMMUNE_TO_NPC again (she is held for the whole fight, and the path
-- start must not be lost to combat), evades out of any fight, then walks to the capture spot 1 s later.
UPDATE world.smart_scripts SET action_type = 18, action_param1 = 512, action_param2 = 0,
       comment = 'Update Data 9 9 - Set IMMUNE_TO_NPC (captured)'
    WHERE entryorguid = 100397 AND source_type = 0 AND id = 30 AND action_type = 53;
-- Conversation 1556 starts: tell the Inquisitor to step forward (data 2 2); the capture's data 1 1 reaches him up to 100 yd.
UPDATE world.smart_scripts SET link = 64 WHERE entryorguid = 100397 AND source_type = 0 AND id = 33 AND link = 0;
UPDATE world.smart_scripts SET target_param2 = 100 WHERE entryorguid = 100397 AND source_type = 0 AND id = 37 AND target_param1 = 101269;

DELETE FROM world.smart_scripts WHERE (entryorguid = 100397 AND source_type = 0 AND id BETWEEN 59 AND 65)
    OR (entryorguid = 10039706 AND source_type = 9) OR (entryorguid = 101269 AND source_type = 0 AND id BETWEEN 13 AND 15);
INSERT INTO world.smart_scripts (entryorguid, source_type, id, link, event_type, event_flags, event_param1, event_param2,
       event_param3, event_param4, action_type, action_param1, action_param2, target_type, target_param1,
       target_x, target_y, target_z, comment) VALUES
(100397,   0, 59, 60, 61, 256, 0,    0,    0,    0,     19, 512,      0, 1,  0,      0, 0, 0, 'Link - Remove IMMUNE_TO_NPC (helps the player)'),
(100397,   0, 60, 61, 61, 256, 0,    0,    0,    0,     117, 0,       0, 1,  0,      0, 0, 0, 'Link - Enable evade (back to following)'),
(100397,   0, 61, 62, 61, 256, 0,    0,    0,    0,     42, 0,        5, 1,  0,      0, 0, 0, 'Link - Invincible below 5% HP'),
(100397,   0, 62, 0,  61, 256, 0,    0,    0,    0,     8,  2,        0, 1,  0,      0, 0, 0, 'Link - React aggressive'),
(100397,   0, 63, 0,  0,  0,   2000, 4000, 8000, 12000, 11, 205763,   0, 2,  0,      0, 0, 0, 'IC - Cast Black Arrow'),
(100397,   0, 64, 0,  61, 256, 0,    0,    0,    0,     45, 2,        2, 19, 101269, 0, 0, 0, 'Link - Send Data 2 2 to the Inquisitor'),
(100397,   0, 65, 0,  38, 257, 9,    9,    0,    0,     80, 10039706, 2, 1,  0,      0, 0, 0, 'Data Set 9 9 - Run TS (capture walk)'),
(10039706, 9, 0,  0,  0,  0,   0,    0,    0,    0,     24, 0,        0, 1,  0,      0, 0, 0, 'TS - Evade (leave any fight)'),
(10039706, 9, 1,  0,  0,  0,   3000, 3000, 0,    0,     53, 1,        10039703, 1, 0, 0, 0, 0, 'TS - Start WP to the capture spot'),
-- 2) High Inquisitor Qormaladon (101269) stood at his spawn through his whole dialogue and never came for the player
-- (spawn MovementType 2 without any waypoint path). Now he talks and walks towards Vereesa when she arrives, and attacks
-- the closest player once he is attackable (data 1 1).
(101269,   0, 13, 0,  61, 1,   0,    0,    0,    0,     49, 0,        0, 21, 100,    0, 0, 0, 'Link - Attack closest player'),
(101269,   0, 14, 15, 38, 1,   2,    2,    0,    0,     5,  1,        0, 1,  0,      0, 0, 0, 'Data Set 2 2 - Emote talk'),
(101269,   0, 15, 0,  61, 1,   0,    0,    0,    0,     69, 1,        0, 8,  0,      187.494, 1295.63, -59.0451, 'Link - Walk towards Vereesa');
-- dev-check: explicit 100 yd for the closest-Inquisitor search (target 19 param2 = distance)
UPDATE world.smart_scripts SET target_param2 = 100 WHERE entryorguid = 100397 AND source_type = 0 AND id = 64;
UPDATE world.smart_scripts SET link = 13 WHERE entryorguid = 101269 AND source_type = 0 AND id = 1 AND link = 0;
UPDATE world.creature SET MovementType = 0 WHERE guid = 370739 AND id = 101269;

-- Now that Vereesa can land the killing blow, "invoker" credits would go to her and be lost (CSC only credits players):
-- Herald Xarbizuld's step-5 credit and conversations, and Mistress Torvis's death conversation go to the closest player.
-- Same for the Inquisitor's step-6 credit (a hunter pet's killing blow lost it too).
UPDATE world.smart_scripts SET target_type = 21, target_param1 = 100
    WHERE entryorguid = 100836 AND source_type = 0 AND id IN (3, 6, 8) AND target_type = 7;
UPDATE world.smart_scripts SET target_type = 21, target_param1 = 100
    WHERE entryorguid = 101269 AND source_type = 0 AND id = 10 AND target_type = 7;
UPDATE world.smart_scripts SET target_type = 21, target_param1 = 100
    WHERE entryorguid = 100749 AND source_type = 0 AND id = 4 AND target_type = 7;

-- 3) The bow: creature 101487 has displays 61698 (Kayn Sunfury, a demon hunter placeholder) and 65966 (Thas'dorah);
-- CreatureTemplate::GetRandomValidModelId picks one at random, so half the time a demon hunter stood on the altar.
-- The artifact pickup itself is gameobject 248419 (chest, lock 1691, loot = Thas'dorah, SmartAI credits step 8), whose
-- name was Russian. Same placeholder on the four Ashbringer display creatures (map 0): pin their real model too.
UPDATE world.creature c JOIN world.creature_template_wdb w ON w.Entry = c.id
    SET c.modelid = w.Displayid2
    WHERE w.Displayid1 = 61698 AND w.Displayid2 <> 0 AND c.modelid = 0
      AND c.guid IN (370756, 11546505, 11546526, 11546527, 11546528);
UPDATE world.gameobject_template SET name = 'Thas''dorah, Legacy of the Windrunners', castBarCaption = 'Retrieving'
    WHERE entry = 248419;
