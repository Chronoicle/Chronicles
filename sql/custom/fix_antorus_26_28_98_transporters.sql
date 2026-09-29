-- Antorus (map 1712), issues #28 and #98. #26 (High Command platform) is a core change only (StaticTransport).
-- Undo: undo_antorus_26_28_98_transporters.sql

-- #98 Garothi Worldbreaker: the Lightforged Teleport Pod 130137 (the yellow wisp) had no spawn and no path anywhere
-- (retail spell 257872 wants path 631108, missing in our DB, the upstream dump and the client). Owner OK (2026-09-29):
-- a simple straight flight. The pod stands with the Lightforged forces at the south end of Garothi's arena, hidden
-- until Garothi dies (instance_antorus introFirstBossGuids), and flies the clicker to the Lightforged Beacon hub
-- (-3437.5, 10156.9, -150.0), like the bridge pods 128289 (script npt_atbt_teleport, Gateway aura 253773).
-- Spawn row copied from the bridge pod 12898411 (same map, spawn mask, flags).
INSERT INTO world.creature (guid,id,map,zoneId,areaId,spawnMask,phaseMask,PhaseId,modelid,equipment_id,position_x,position_y,position_z,orientation,spawntimesecs,spawndist,currentwaypoint,curhealth,curmana,MovementType,npcflag,npcflag2,unit_flags,dynamicflags,AiID,MovementID,MeleeID,isActive,skipClone,personal_size,isTeemingSpawn,unit_flags3)
SELECT 146940137,130137,map,zoneId,9280,spawnMask,phaseMask,PhaseId,modelid,equipment_id,-3296.0,9752.0,-62.2,1.91,spawntimesecs,spawndist,currentwaypoint,curhealth,curmana,MovementType,npcflag,npcflag2,unit_flags,dynamicflags,AiID,MovementID,MeleeID,isActive,skipClone,personal_size,isTeemingSpawn,unit_flags3
FROM world.creature WHERE guid=12898411;

UPDATE world.creature_template SET ScriptName='npt_atbt_teleport' WHERE entry=130137;

-- lift off, straight over the arena, down to the beacon hub, land on the beacon's own teleport spot (~478 yd, 30 yd/s)
INSERT INTO world.waypoint_data_script (id,point,position_x,position_y,position_z,orientation,delay,move_type,speed,action,action_chance,entry,wpguid) VALUES
(13013700,1,-3300.0,9775.0,-40.0,0,0,0,30,0,100,0,0),
(13013700,2,-3366.8,9954.5,-45.0,0,0,0,30,0,100,0,0),
(13013700,3,-3437.5,10156.9,-125.0,0,0,0,30,0,100,0,0),
(13013700,4,-3437.5,10156.9,-150.022,0,0,0,30,0,100,0,0);

-- #28 Defensive Countermeasures 254219: temporary diagnostic log (server.antoran) for every cast that reaches the server
INSERT INTO world.spell_script_names (spell_id, ScriptName) VALUES (254219, 'spell_command_defensive_countermeasures');
