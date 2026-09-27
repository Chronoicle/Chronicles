-- Owner request 2026-09-27 (Claude): remove the two extra Balnazzar 111247 spawns in the priest class hall scenario
-- (map 1629) that were added with .npc add; the scenario's own spawn (guid 11317946) stays.
-- Undo: undo_balnazzar_extra_spawns.sql (dump of the rows made on the server before deleting)
DELETE FROM creature WHERE guid IN (146931246, 146931248) AND id = 111247;
DELETE FROM creature_addon WHERE guid IN (146931246, 146931248);
