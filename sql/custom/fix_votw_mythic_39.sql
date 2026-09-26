-- Vault of the Wardens (Refs #39, Claude 2026-09-26). Backups in world.bak_votw_39_*; undo: undo_votw_mythic_39.sql
-- Dreadlord Mendacius 99649 and Grimhorn the Enslaver 102566 had no AI: the default AI cast every spell on
-- cooldown (Summon Grimguard every 5 s) and their dummy spells (Meteor 196249, Imprison 202614) had no handler.
-- Timers are estimates (grimguard every 30 s as reported).
DROP TABLE IF EXISTS world.bak_votw_39_template;
CREATE TABLE world.bak_votw_39_template AS SELECT entry, AIName, ScriptName FROM world.creature_template WHERE entry IN (99649, 102566);
DROP TABLE IF EXISTS world.bak_votw_39_creature;
CREATE TABLE world.bak_votw_39_creature AS SELECT guid, orientation FROM world.creature WHERE id = 96657 AND map = 1493;

UPDATE world.creature_template SET AIName = 'SmartAI', ScriptName = '' WHERE entry IN (99649, 102566);
DELETE FROM world.smart_scripts WHERE entryorguid IN (99649, 102566) AND source_type = 0;
INSERT INTO world.smart_scripts (entryorguid, source_type, id, link, Difficulties, event_type, event_phase_mask, event_chance, event_flags, event_param1, event_param2, event_param3, event_param4, event_param5, action_type, action_param1, action_param2, action_param3, action_param4, action_param5, action_param6, target_type, target_param1, target_param2, target_param3, target_param4, target_x, target_y, target_z, target_o, comment) VALUES
(99649, 0, 0, 0, '', 0, 0, 100, 0,  5000,  8000, 14000, 18000, 0, 11, 196242, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Dreadlord Mendacius - IC - Cast Thunderclap'),
(99649, 0, 1, 0, '', 0, 0, 100, 0, 10000, 12000, 20000, 25000, 0, 11, 196249, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Dreadlord Mendacius - IC - Cast Meteor'),
(99649, 0, 2, 0, '', 31, 0, 100, 0, 196249, 0, 0, 0, 0, 11, 199870, 2, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Dreadlord Mendacius - Meteor hit player - Cast Meteor missile'),
(99649, 0, 3, 0, '', 0, 0, 100, 0, 15000, 15000, 30000, 30000, 0, 11, 202728, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Dreadlord Mendacius - IC - Cast Summon Grimguard'),
(102566, 0, 0, 0, '', 0, 0, 100, 0,  4000,  6000, 14000, 16000, 0, 11, 202608, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 'Grimhorn the Enslaver - IC - Cast Anguished Souls on random'),
(102566, 0, 1, 0, '', 0, 0, 100, 0,  9000, 11000, 18000, 22000, 0, 11, 202614, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Grimhorn the Enslaver - IC - Cast Imprison'),
(102566, 0, 2, 0, '', 31, 0, 100, 0, 202614, 0, 0, 0, 0, 11, 202615, 2, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Grimhorn the Enslaver - Imprison hit player - Cast Torment');

-- Blade Dancer Illianna faced the wrong way: turn 180 degrees
UPDATE world.creature SET orientation = orientation - PI() WHERE id = 96657 AND map = 1493 AND orientation >= PI();
