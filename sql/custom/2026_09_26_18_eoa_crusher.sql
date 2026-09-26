-- Refs #18: stationary fallback for a Crusher with no waypoint path.
UPDATE creature SET MovementType = 0 WHERE guid = 14507329 AND id = 91782 AND map = 1456 AND MovementType = 2;
