-- Undo fix_ragefire_chasm_174c.sql (back to fix_ragefire_chasm_174b values)
UPDATE world.creature_model_info SET CombatReach = 7, BoundingRadius = 3 WHERE DisplayID = 42247;
