-- Priest class hall intro replay + GM Island Netherlight Crucible (gabrielf03d, desktop team, Claude subagent 2026-09-30).
-- Undo: undo_priest_hall_intro_crucible.sql
SET NAMES utf8mb4;

-- 1) Netherlight Temple (map 1512): every visit replayed "The Light and the Void" (40938): eventobject 119 at the
--    entrance casts 202457 Priest Order Formation (scene 1191: the order lines up, Alonsus Faol's speech), eventobject 120
--    in the circle casts 202835 (Dark Drain / ritual spell bar). Their conditions (has 40938, not all objectives done)
--    sit on smart-event SourceId 10, but sql/updates/world/2024_10_29_smart_script_cleanup.sql moved eventobject
--    scripts to source_type 13 and left the conditions behind, so every eventobject script on the server
--    (311 condition rows, 239 eventobjects) ran with no condition at all. Copy each SourceId-10 condition to
--    SourceId 13 where a source_type-13 script row with that entry and event id exists.
INSERT INTO world.conditions (SourceTypeOrReferenceId, SourceGroup, SourceEntry, SourceId, ElseGroup, ConditionTypeOrReference,
    ConditionTarget, ConditionValue1, ConditionValue2, ConditionValue3, NegativeCondition, ErrorTextId, ScriptName, Comment)
SELECT 22, c.SourceGroup, c.SourceEntry, 13, c.ElseGroup, c.ConditionTypeOrReference,
    c.ConditionTarget, c.ConditionValue1, c.ConditionValue2, c.ConditionValue3, c.NegativeCondition, c.ErrorTextId, c.ScriptName, c.Comment
FROM world.conditions c
WHERE c.SourceTypeOrReferenceId = 22 AND c.SourceId = 10
  AND EXISTS (SELECT 1 FROM world.smart_scripts s WHERE s.source_type = 13 AND s.entryorguid = c.SourceEntry AND s.id = c.SourceGroup - 1);

-- 2) GM Island: the two "Netherlight Crucible" spawns were creature 126700, the Vindicaar quest click target
--    (spell click 251479 Infuse Light), not the relic forge. The real Crucible is gameobject 273271 (type 47 artifact
--    forge, ForgeType 1 = relic forge, PlayerCondition 53200 like on the Vindicaar). Its template name was Russian.
DELETE FROM world.creature WHERE guid IN (146902887, 146902889) AND id = 126700;
INSERT INTO world.gameobject (guid, id, map, zoneId, areaId, spawnMask, phaseMask, PhaseId, position_x, position_y, position_z,
    orientation, rotation0, rotation1, rotation2, rotation3, spawntimesecs, animprogress, state, isActive, personal_size) VALUES
(25683648, 273271, 1, 876, 876, 1, 65535, '', 16274.3, 16313.55, 13.45, 3.12867, 0, 0, 0.99998, 0.00646, 180, 255, 1, 0, 0);
UPDATE world.gameobject_template SET name = 'Netherlight Crucible' WHERE entry IN (273271, 273272, 273273);
