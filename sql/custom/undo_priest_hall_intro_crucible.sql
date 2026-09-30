-- Undo fix_priest_hall_intro_crucible.sql
SET NAMES utf8mb4;
USE world; -- the multi-table DELETE below needs a default database

-- 1) Remove the SourceId-13 copies (only rows that have an identical SourceId-10 twin).
DELETE c13 FROM world.conditions c13
JOIN world.conditions c10 ON c10.SourceTypeOrReferenceId = 22 AND c10.SourceId = 10
    AND c10.SourceGroup = c13.SourceGroup AND c10.SourceEntry = c13.SourceEntry AND c10.ElseGroup = c13.ElseGroup
    AND c10.ConditionTypeOrReference = c13.ConditionTypeOrReference AND c10.ConditionTarget = c13.ConditionTarget
    AND c10.ConditionValue1 = c13.ConditionValue1 AND c10.ConditionValue2 = c13.ConditionValue2 AND c10.ConditionValue3 = c13.ConditionValue3
WHERE c13.SourceTypeOrReferenceId = 22 AND c13.SourceId = 13;

-- 2) GM Island: gameobject out, the two creature 126700 spawns back, Russian template names back.
DELETE FROM world.gameobject WHERE guid = 25683648 AND id = 273271;
INSERT INTO world.creature (guid, id, map, zoneId, areaId, spawnMask, phaseMask, PhaseId, modelid, equipment_id, position_x, position_y,
    position_z, orientation, spawntimesecs, spawndist, currentwaypoint, curhealth, curmana, MovementType, npcflag, npcflag2, unit_flags,
    dynamicflags, AiID, MovementID, MeleeID, isActive, skipClone, personal_size, isTeemingSpawn, unit_flags3) VALUES
(146902887, 126700, 1, 876, 876, 1, 65535, '', 0, 0, 16274.7, 16313.6, 13.4512, 3.12867, 300, 0, 0, 1039267, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(146902889, 126700, 1, 876, 876, 1, 65535, '', 0, 0, 16274, 16313.5, 13.5384, 2.67942, 300, 0, 0, 1039267, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
UPDATE world.gameobject_template SET name = 'Тигель света Пустоты' WHERE entry IN (273271, 273272, 273273);
