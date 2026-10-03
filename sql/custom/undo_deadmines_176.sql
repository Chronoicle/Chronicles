-- Undo for fix_deadmines_176.sql (run right after a backup of world.creature / creature_addon / waypoint_data if anything was changed since).
DELETE FROM world.waypoint_data WHERE id IN (SELECT id FROM world.bak_dm176_wp_ids);
UPDATE world.creature c JOIN world.bak_dm176_creature b ON b.guid = c.guid SET c.MovementType = b.MovementType, c.spawndist = b.spawndist;
UPDATE world.creature_addon a JOIN world.bak_dm176_addon b ON b.guid = a.guid AND b.had_row = 1 SET a.path_id = b.path_id;
DELETE a FROM world.creature_addon a JOIN world.bak_dm176_addon b ON b.guid = a.guid AND b.had_row = 0;
DELETE FROM world.creature WHERE map = 36 AND id = 48266 AND guid > (SELECT val FROM world.bak_dm176_base WHERE name = 'cannon_base') AND guid <= (SELECT val + 8 FROM world.bak_dm176_base WHERE name = 'cannon_base');
-- afterwards (by hand, when sure): DROP TABLE world.bak_dm176_creature, world.bak_dm176_addon, world.bak_dm176_wp_ids, world.bak_dm176_base;
UPDATE world.creature_template SET AIName = '' WHERE entry = 48284;
DELETE FROM world.smart_scripts WHERE entryorguid = 48284 AND source_type = 0 AND id = 4;
UPDATE world.creature_template SET ScriptName = '' WHERE entry = 47404;
