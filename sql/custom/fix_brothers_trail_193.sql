-- #193 The Brother's Trail 42377 (Paladin, Dragonblight; help-helper, Claude Pro, 2026-10-08). Undo:
-- sql/custom/undo_brothers_trail_193.sql (needs the bak_bt193_* tables created here). Live with a worldserver restart
-- (no .reload). Run ONCE: a second run would overwrite the bak_bt193_* backups with the fixed rows.
--
-- 1) Objectives: "Campfire Investigated" 113913, "Broken Sword Found" 113914, "Broken Statue Investigated" 113915 (all
--    hidden + optional) and the visible "Find clues to Galford's location" 107295 all had StorageIndex 2, i.e. ONE
--    counter (Player::KilledMonsterCredit reads/writes the slot, objective done = slot >= Amount): the first clue
--    completed the visible objective and opened the next, and a second click on the same clue was credited again.
--    The three clues get their own slots 7/8/9 (6 is the highest in use), 107295 keeps 2.
-- 2) Credits: each clue goober's event now credits ITS OWN objective (event_scripts command 8, personal credit); the
--    summons (Lurking Void Wraith 107329 60 s, Friendly Taunka Spirit 107314 12 s) wait 1 s so the credit lands first.
--    107314 no longer credits the clues at random (TS 10731400-02 keep only their say text); on summon it credits 107295
--    only for a player who has all three clues (SmartAI condition source 22).
-- 3) The three clue goobers get quest 42377 (Data1: quest sparkle only while the quest is open; the event itself still
--    fires for anyone, as for every goober in this core) and English names (Russian in the DB).
-- 4) Gossip 19700 option 0 (Lanigosa's answer) was Russian.

-- backups for the undo
DROP TABLE IF EXISTS world.bak_bt193_quest_objectives;
CREATE TABLE world.bak_bt193_quest_objectives AS SELECT * FROM world.quest_objectives WHERE QuestID = 42377;
DROP TABLE IF EXISTS world.bak_bt193_smart_scripts;
CREATE TABLE world.bak_bt193_smart_scripts AS SELECT * FROM world.smart_scripts
WHERE (source_type = 0 AND entryorguid = 107314) OR (source_type = 9 AND entryorguid IN (10731400, 10731401, 10731402));
DROP TABLE IF EXISTS world.bak_bt193_event_scripts;
CREATE TABLE world.bak_bt193_event_scripts AS SELECT * FROM world.event_scripts WHERE id IN (51128, 51140, 51142);
DROP TABLE IF EXISTS world.bak_bt193_gameobject_template;
CREATE TABLE world.bak_bt193_gameobject_template AS SELECT entry, name, Data1 FROM world.gameobject_template WHERE entry IN (250295, 250364, 250367);
DROP TABLE IF EXISTS world.bak_bt193_gossip_option;
CREATE TABLE world.bak_bt193_gossip_option AS SELECT * FROM world.gossip_menu_option WHERE MenuID = 19700;

-- 1) own counter per clue
UPDATE world.quest_objectives SET StorageIndex = 7 WHERE ID = 284163 AND QuestID = 42377 AND ObjectID = 113913;
UPDATE world.quest_objectives SET StorageIndex = 8 WHERE ID = 284164 AND QuestID = 42377 AND ObjectID = 113914;
UPDATE world.quest_objectives SET StorageIndex = 9 WHERE ID = 284165 AND QuestID = 42377 AND ObjectID = 113915;

-- 2) one credit per clue, summons 1 s later
UPDATE world.event_scripts SET delay = 1 WHERE id IN (51128, 51140, 51142) AND command = 10;
DELETE FROM world.event_scripts WHERE id IN (51128, 51140, 51142) AND command = 8;
INSERT INTO world.event_scripts (id, delay, command, datalong, datalong2, dataint, x, y, z, o) VALUES
(51128, 0, 8, 113913, 0, 0, 0, 0, 0, 0),
(51140, 0, 8, 113914, 0, 0, 0, 0, 0, 0),
(51142, 0, 8, 113915, 0, 0, 0, 0, 0, 0);

DELETE FROM world.smart_scripts WHERE source_type = 9 AND entryorguid = 10731400 AND id IN (1, 2, 3, 4) AND action_type = 33;
DELETE FROM world.smart_scripts WHERE source_type = 9 AND entryorguid IN (10731401, 10731402) AND id IN (1, 2, 3) AND action_type = 33;

DELETE FROM world.smart_scripts WHERE source_type = 0 AND entryorguid = 107314 AND id = 2;
INSERT INTO world.smart_scripts (entryorguid, source_type, id, link, Difficulties, event_type, event_phase_mask, event_chance, event_flags, event_param1, event_param2, event_param3, event_param4, event_param5, action_type, action_param1, action_param2, action_param3, action_param4, action_param5, action_param6, target_type, target_param1, target_param2, target_param3, target_param4, target_x, target_y, target_z, target_o, comment) VALUES
(107314, 0, 2, 0, '', 54, 0, 100, 0, 0, 0, 0, 0, 0, 33, 107295, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Just Summoned - Kill Credit Find clues to Galford''s location (only with all 3 clues)');

DELETE FROM world.conditions WHERE SourceTypeOrReferenceId = 22 AND SourceGroup = 3 AND SourceEntry = 107314 AND SourceId = 0;
INSERT INTO world.conditions (SourceTypeOrReferenceId, SourceGroup, SourceEntry, SourceId, ElseGroup, ConditionTypeOrReference, ConditionTarget, ConditionValue1, ConditionValue2, ConditionValue3, NegativeCondition, ErrorTextId, ScriptName, Comment) VALUES
(22, 3, 107314, 0, 0, 41, 0, 42377, 113913, 1, 0, 0, '', 'Taunka Spirit credits 107295 only after the campfire clue'),
(22, 3, 107314, 0, 0, 41, 0, 42377, 113914, 1, 0, 0, '', 'Taunka Spirit credits 107295 only after the broken sword clue'),
(22, 3, 107314, 0, 0, 41, 0, 42377, 113915, 1, 0, 0, '', 'Taunka Spirit credits 107295 only after the broken statue clue');

-- 3) goobers: quest sparkle + English names
UPDATE world.gameobject_template SET Data1 = 42377, name = 'Old Campfire' WHERE entry = 250295;
UPDATE world.gameobject_template SET Data1 = 42377, name = 'Broken Sword' WHERE entry = 250364;
UPDATE world.gameobject_template SET Data1 = 42377, name = 'Broken Statue' WHERE entry = 250367;

-- 4) Lanigosa's answer in English (broadcast text 111589: if the client still shows Russian, the broadcast_text row itself is Russian)
UPDATE world.gossip_menu_option SET OptionText = 'Honestly, I do not know. But I will find him.' WHERE MenuID = 19700 AND OptionID = 0;
