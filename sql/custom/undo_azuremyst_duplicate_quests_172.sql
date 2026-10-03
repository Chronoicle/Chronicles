-- Undo fix_azuremyst_duplicate_quests_172.sql
INSERT IGNORE INTO world.creature_queststarter (id, quest) VALUES (16535, 37444), (17071, 37445);
UPDATE world.quest_template_addon SET ExclusiveGroup = 0 WHERE ID IN (9303, 37444, 9305, 37445);
