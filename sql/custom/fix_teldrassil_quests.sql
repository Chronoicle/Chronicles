-- Teldrassil quest reports by tyrvana (desktop team 2026-09-29). Undo: undo_teldrassil_quests.sql. Live after a restart.
-- (Mossy Tumors 923, "cannot turn in", is a core fix in DB2Stores.cpp: hunters fit none of its dagger/mace rewards.)

-- 1) Druid of the Claw (2561) shows as completed right after pickup. It has no objectives: the Voodoo Charm's spell
-- 10617 completes it (SPELL_EFFECT_QUEST_COMPLETE + Rageclaw's SmartAI), SpecialFlags 2 keeps it incomplete on the
-- server, but without quest flag 0x2 (completion by event) the client treats a quest without objectives as done.
-- Every other event quest of the zone has the flag (Mist 938, Sathrah's Sacrifice 2520, 423 in the DB).
UPDATE world.quest_template SET Flags = Flags | 2 WHERE ID = 2561 AND Flags = 0;

-- 2) Ireroot Seeds (46716, spell 65455 Nature's Fury, quest 13946 Nature's Reprisal): "You are in the wrong zone".
-- spell_area allowed it only in the Fel Rock subzone (258), but a third of the Fel Rock sprites stand in plain
-- Teldrassil (area 141) around it. Allow it in the whole zone while the quest is in progress (unchanged: only the
-- sprites' SmartAI gives credit).
UPDATE world.spell_area SET area = 141 WHERE spell = 65455 AND area = 258 AND quest_start = 13946;

-- 3) Greenpaw (1993) and Rageclaw (7318) do not scale with the player: no creature_template_scaling row and
-- SandboxScalingID 0, unlike every other Teldrassil mob (5-20, sandbox 81). Same gap on the rare Duskstalker (14430)
-- and Bogling (3569).
INSERT INTO world.creature_template_scaling (Entry, LevelScalingMin, LevelScalingMax, LevelScalingDeltaMin, LevelScalingDeltaMax, LevelScalingDuration, VerifiedBuild) VALUES
(1993, 5, 20, 0, 0, 0, NULL),
(3569, 5, 20, 0, 0, 0, NULL),
(7318, 5, 20, 0, 0, 0, NULL),
(14430, 5, 20, 0, 0, 0, NULL);
UPDATE world.creature_template SET SandboxScalingID = 81 WHERE entry IN (1993, 3569, 7318, 14430) AND SandboxScalingID = 0;
