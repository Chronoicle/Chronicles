-- Undo for fix_deadmines_176b.sql
UPDATE world.creature_template t JOIN world.bak_dm176b_template b ON b.entry = t.entry SET t.AIName = b.AIName;
INSERT IGNORE INTO world.smart_scripts SELECT * FROM world.bak_dm176b_smart;
UPDATE world.creature_template_addon a JOIN world.bak_dm176b_addon b ON b.entry = a.entry SET a.emote = b.emote;
INSERT IGNORE INTO world.creature SELECT * FROM world.bak_dm176b_creature;
UPDATE world.creature c JOIN world.bak_dm176b_movers b ON b.guid = c.guid SET c.MovementType = b.MovementType, c.spawndist = b.spawndist;
