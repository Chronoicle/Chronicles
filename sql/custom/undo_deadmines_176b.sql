-- Undo for fix_deadmines_176b.sql
UPDATE world.creature_template t JOIN world.bak_dm176b_template b ON b.entry = t.entry SET t.AIName = b.AIName;
INSERT IGNORE INTO world.smart_scripts SELECT * FROM world.bak_dm176b_smart;
UPDATE world.creature_template_addon a JOIN world.bak_dm176b_addon b ON b.entry = a.entry SET a.emote = b.emote;
-- (if the 3586 delete block was enabled: INSERT INTO world.creature SELECT * FROM world.bak_dm176b_creature;)
UPDATE world.creature c JOIN world.bak_dm176b_rats b ON b.guid = c.guid SET c.MovementType = b.MovementType, c.spawndist = b.spawndist;
DELETE FROM world.waypoint_data WHERE id IN (SELECT id FROM world.bak_dm176b_wp_ids);
UPDATE world.creature_addon a JOIN world.bak_dm176b_addon2 b ON b.guid = a.guid AND b.had_row = 1 SET a.path_id = b.path_id;
DELETE a FROM world.creature_addon a JOIN world.bak_dm176b_addon2 b ON b.guid = a.guid AND b.had_row = 0;
UPDATE world.creature c JOIN world.bak_dm176b_movers b ON b.guid = c.guid SET c.MovementType = b.MovementType, c.spawndist = b.spawndist;
-- note: the second-pass creatures were MovementType 2 already (kept). Drop the bak_dm176b_* tables by hand when sure.
