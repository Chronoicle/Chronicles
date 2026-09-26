-- Undo fix_votw_mythic_39.sql (Refs #39)
DELETE FROM world.smart_scripts WHERE entryorguid IN (99649, 102566) AND source_type = 0;
UPDATE world.creature_template t JOIN world.bak_votw_39_template b ON b.entry = t.entry SET t.AIName = b.AIName, t.ScriptName = b.ScriptName;
UPDATE world.creature c JOIN world.bak_votw_39_creature b ON b.guid = c.guid SET c.orientation = b.orientation;
DROP TABLE world.bak_votw_39_template;
DROP TABLE world.bak_votw_39_creature;
