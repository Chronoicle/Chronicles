-- #174 (Claude, dev-owner): Slagmaw still out of melee reach from the hole edge with 7 (tyrvana): double it.
UPDATE world.creature_model_info SET CombatReach = 14, BoundingRadius = 6 WHERE DisplayID = 42247;
