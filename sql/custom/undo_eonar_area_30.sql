-- Undo fix_eonar_area_30.sql: none of these spawns had a creature_movement_override row before.
DELETE FROM world.creature_movement_override WHERE SpawnId IN (12899127, 12899142, 12899143);
