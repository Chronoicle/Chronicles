-- Undo fix_teldrassil_movement.sql: put MovementType / spawndist back for exactly the spawns it changed
-- (only where they still hold the fix's values), then drop the backup table.
UPDATE world.creature c JOIN world.bak_teldrassil_movement b ON b.guid = c.guid
SET c.MovementType = b.MovementType, c.spawndist = b.spawndist
WHERE c.MovementType = 1 AND c.spawndist = b.new_spawndist;
DROP TABLE world.bak_teldrassil_movement;
