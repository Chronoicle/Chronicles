-- #30 Eonar (Claude 2026-09-27). Undo: undo_eonar_30.sql
-- Door X (garden side, 273687) had flags 0, so players could click it shut and nobody could reopen it.
-- Same flags as its twin 273688: 48 = not selectable + no despawn.
UPDATE world.gameobject_template SET flags = flags | 48 WHERE entry = 273687;

-- Focusing Crystal beams (259468/69/70/72) are dummy auras on the nearest Focus NPC 125930. There was one, 113 yd
-- above the ship centre, so all four beams met above the Inquisitor. On retail each beam goes straight up:
-- one Focus above each crystal.
UPDATE world.creature SET position_x = -4240.0, position_y = -10658.1 WHERE guid = 14568233;
DELETE FROM world.creature WHERE guid IN (146929295, 146929296, 146929297);
INSERT INTO world.creature (guid, id, map, zoneId, areaId, spawnMask, phaseMask, PhaseId, position_x, position_y, position_z, orientation, spawntimesecs) VALUES
(146929295, 125930, 1712, 8638, 8681, 245760, 1, '', -4249.0, -10734.1, 841.704, 0, 120),
(146929296, 125930, 1712, 8638, 8681, 245760, 1, '', -4174.0, -10741.9, 841.704, 0, 120),
(146929297, 125930, 1712, 8638, 8681, 245760, 1, '', -4165.0, -10666.4, 841.704, 0, 120);
