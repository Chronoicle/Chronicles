-- #30 (Claude, Pi team): Eonar area. Three Daughters of Eonar (126982) are spawned 25-90 yd above the floor next to the
-- stalkers they beam at (Cosmetic Life Beam 253438), but the entry has no creature_template_movement row, so
-- Creature::UpdateMovementFlags keeps gravity on every update and they stand in mid-air with the ground animation.
-- Per-spawn override Flight = 1 (DisableGravity) for those three only: UpdateMovementFlags turns gravity off only while
-- they are really in the air, so nothing changes if one stands on a ledge. The other six (on the floor, one walks a path)
-- are not touched. Ground/Swim/Rooted/Random stay NULL = template defaults.
-- Before: no creature_movement_override rows for these spawns. Undo: undo_eonar_area_30.sql
DELETE FROM world.creature_movement_override WHERE SpawnId IN (12899127, 12899142, 12899143);
INSERT INTO world.creature_movement_override (SpawnId, Ground, Swim, Flight, Rooted, Random, InteractionPauseTimer) VALUES
(12899127, NULL, NULL, 1, NULL, NULL, NULL),
(12899142, NULL, NULL, 1, NULL, NULL, NULL),
(12899143, NULL, NULL, 1, NULL, NULL, NULL);
