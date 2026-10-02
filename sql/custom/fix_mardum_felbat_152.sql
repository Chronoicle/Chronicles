-- #152 Mardum, On Felbat Wings (39663): Kayn, Kor'vas, Cyana and Allari (summoned by npc_93127 on quest accept) take off
-- on their felbats at the flight master instead of running up into the sky on their Nightsabers.
-- Undo: undo_mardum_felbat_152.sql. Live with a worldserver restart (waypoint_data_script is loaded at startup).

-- Path 10267121 (waypoint_data_script, only used by npc_93127): points 1-9 run on the ground to Izal Whitemoon, where
-- point 9's action 340 (waypoint_scripts: SCRIPT_COMMAND_MOUNT 68161) swaps the Nightsaber for a felbat; points 10-22
-- then climb to z 283 along the Fel Hammer flight route, all move_type 1 (run), so they ran through the air in the
-- ground animation. Point 10 as takeoff (move_type 3): WaypointMovementGenerator sends that leg with AnimTier::Hover,
-- which the unit keeps for the rest of the path.
UPDATE world.waypoint_data_script SET move_type = 3 WHERE id = 10267121 AND point = 10 AND move_type = 1;
