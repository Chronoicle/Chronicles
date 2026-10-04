-- Undo fix_patrols_without_path.sql
DELETE w FROM world.waypoint_data w JOIN world.bak_patrols_without_path b ON b.new_path = w.id WHERE b.new_path > 0;
UPDATE world.creature c JOIN world.bak_patrols_without_path b ON b.guid = c.guid SET c.MovementType = b.MovementType, c.spawndist = b.spawndist;
UPDATE world.creature_addon a JOIN world.bak_patrols_without_path b ON b.guid = a.guid AND b.had_addon = 1 SET a.path_id = b.path_id;
DELETE a FROM world.creature_addon a JOIN world.bak_patrols_without_path b ON b.guid = a.guid AND b.had_addon = 0;
