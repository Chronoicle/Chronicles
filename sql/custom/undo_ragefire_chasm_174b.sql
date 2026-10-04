-- Undo fix_ragefire_chasm_174b.sql
UPDATE world.creature_template SET faction = 2238 WHERE entry = 61404;
UPDATE world.creature_template SET faction = 2211 WHERE entry IN (61716, 61724);
UPDATE world.creature_model_info SET CombatReach = 1.5, BoundingRadius = 1.5 WHERE DisplayID = 42247;
