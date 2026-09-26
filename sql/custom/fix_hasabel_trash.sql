-- Antorus: trash before Hasabel had no AI (Claude, 2026-09-26, #29). Undo: ~/undo_hasabel_trash.sql
UPDATE creature_template SET AIName="SmartAI" WHERE entry IN (125545,125549);
DELETE FROM smart_scripts WHERE entryorguid IN (125545,125549) AND source_type=0;
INSERT INTO smart_scripts (entryorguid,source_type,id,link,event_type,event_param1,event_param2,event_param3,event_param4,action_type,action_param1,target_type,comment) VALUES
(125545,0,0,0,0,2000,4000,12000,14000,11,249210,1,"Blazing Imp - in combat - cast Fiery Detonation (explodes, kills itself)"),
(125549,0,0,0,0,4000,6000,10000,14000,11,249212,1,"Hungering Stalker - in combat - cast Howling Shadows (raid damage + interrupt)");
