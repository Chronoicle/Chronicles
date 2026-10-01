-- Undo for fix_skyhold_valkyr_1479_145.sql: restores the values from before the fix
UPDATE world.creature SET position_z = CASE guid
    WHEN 340185   THEN 98.2015
    WHEN 11078327 THEN 106.602
    WHEN 11078325 THEN 99.8003
    WHEN 11078328 THEN 97.8056
    END
WHERE map = 1479 AND guid IN (340185, 11078327, 11078325, 11078328);
