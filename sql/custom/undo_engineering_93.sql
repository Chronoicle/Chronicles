-- Undo #93 (restores the rows as they were on 2026-09-29).
UPDATE world.gameobject_template SET Data1 = 0 WHERE entry = 246519;
UPDATE world.gossip_menu_option SET OptionNpc = 6, OptionText = NULL WHERE MenuID = 10656 AND OptionID = 0;
-- Only if the Lympkin DELETE was applied:
-- INSERT INTO world.creature (guid, id, map, zoneId, areaId, spawnMask, phaseMask, PhaseId, modelid, equipment_id,
--   position_x, position_y, position_z, orientation, spawntimesecs, spawndist, currentwaypoint, curhealth, curmana,
--   MovementType, npcflag, npcflag2, unit_flags, dynamicflags, AiID, MovementID, MeleeID, isActive, skipClone,
--   personal_size, isTeemingSpawn, unit_flags3)
-- VALUES (146850828, 9859, 1220, 7502, 7596, 1, 1, '', 0, 0, -724.744, 4551.56, 729.637, 1.61371, 300, 0, 0, 11280, 0,
--   0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
