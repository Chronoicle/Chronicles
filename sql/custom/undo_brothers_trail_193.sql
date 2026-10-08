-- Undo of sql/custom/fix_brothers_trail_193.sql (needs the bak_bt193_* tables the fix created). Live with a worldserver
-- restart (no .reload).
DELETE FROM world.conditions WHERE SourceTypeOrReferenceId = 22 AND SourceGroup = 3 AND SourceEntry = 107314 AND SourceId = 0
  AND ConditionTypeOrReference = 41 AND ConditionValue1 = 42377;

DELETE FROM world.smart_scripts WHERE (source_type = 0 AND entryorguid = 107314) OR (source_type = 9 AND entryorguid IN (10731400, 10731401, 10731402));
INSERT INTO world.smart_scripts SELECT * FROM world.bak_bt193_smart_scripts;

DELETE FROM world.event_scripts WHERE id IN (51128, 51140, 51142);
INSERT INTO world.event_scripts SELECT * FROM world.bak_bt193_event_scripts;

UPDATE world.quest_objectives q JOIN world.bak_bt193_quest_objectives b ON b.ID = q.ID SET q.StorageIndex = b.StorageIndex WHERE q.QuestID = 42377;

UPDATE world.gameobject_template g JOIN world.bak_bt193_gameobject_template b ON b.entry = g.entry SET g.Data1 = b.Data1, g.name = b.name;

UPDATE world.gossip_menu_option g JOIN world.bak_bt193_gossip_option b ON b.MenuID = g.MenuID AND b.OptionID = g.OptionID SET g.OptionText = b.OptionText WHERE g.MenuID = 19700;
-- the bak_bt193_* tables can be dropped once the undo is confirmed
