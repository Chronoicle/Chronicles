-- Undo fix_brh_89b.sql (Black Rook Hold #89 round 2): restores the exact before-state.
DELETE FROM world.creature_text WHERE CreatureID = 98900 AND GroupID = 1;
DELETE FROM world.smart_scripts WHERE entryorguid IN (-11565649, -11565658, -11565659) AND source_type = 0 AND id BETWEEN 10 AND 15;
UPDATE world.smart_scripts SET event_flags = 1 WHERE entryorguid IN (-11565649, -11565658, -11565659) AND source_type = 0 AND id = 0 AND event_type = 38 AND event_flags = 257;
DELETE FROM world.waypoint_data WHERE id = 10278100;
DELETE FROM world.creature_formations WHERE leaderGUID = 14507227;
UPDATE world.creature SET MovementType = 2 WHERE guid = 14507226;
UPDATE world.creature_addon SET path_id = 12909860 WHERE guid = 14507226;
