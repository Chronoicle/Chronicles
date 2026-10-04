-- #174 follow-up (Claude, dev-owner). IMMUNE_TO_PC did not stop them: this core only checks it when a PLAYER attacks
-- (Unit::_IsValidAttackTarget), a creature with the flag still attacks players. Friendly to all (35): Horde can still
-- talk to them / take their (Horde-only) quests, Alliance groups are left alone.
UPDATE world.creature_template SET faction = 35 WHERE entry IN (61404, 61716, 61724);
-- Slagmaw (61463, model 42247) stays in his lava holes (no combat movement since #174): combat reach 1.5 left him out of
-- melee range from the edge.
UPDATE world.creature_model_info SET CombatReach = 7, BoundingRadius = 3 WHERE DisplayID = 42247;
