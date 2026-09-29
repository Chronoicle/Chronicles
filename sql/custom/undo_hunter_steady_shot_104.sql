-- Undo #104 (exact: none of these rows mentioned Cobra Shot before, and Tiki Target 38038 had only SmartAI row 0).
UPDATE world.quest_objectives SET ObjectID = 56641 WHERE ID IN (252668, 265173, 266521) AND Type = 5 AND ObjectID = 193455;
DELETE FROM world.smart_scripts WHERE entryorguid = 38038 AND source_type = 0 AND id IN (1, 2) AND event_type = 8 AND event_param1 IN (193455, 185358);
UPDATE world.quest_template SET LogDescription = REPLACE(LogDescription, 'Cobra Shot', 'Steady Shot')
WHERE ID IN (10070, 14007, 14276, 24530, 24778, 24964, 25139, 26917, 26947, 26963, 27021);
UPDATE world.quest_objectives SET Description = REPLACE(Description, 'Cobra Shot', 'Steady Shot') WHERE ID IN (262512, 265381, 265513);
