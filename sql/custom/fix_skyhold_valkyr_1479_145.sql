-- #145 follow-up (gabrielf03d): the Val'kyr in Skyhold (map 1479) also stood half in the floor.
-- Independent of fix_skyhold_valkyr_forge_145.sql (other rows). Undo: undo_skyhold_valkyr_1479_145.sql.
-- Live with a worldserver restart (no .reload).
--
-- The Val'kyr of Odyn's own Skyhold spawn (93819, guid 12843689) is fine: it flies 30 yards up (z 129.3, floor ~99),
-- exactly as in the retail sniff. The ones in the floor are the other NPCs with the hovering Val'kyr models
-- (CreatureModelData 3533 / 8891): their spawns sit right on the floor (navmesh and neighbours), but they have no
-- hover or flight movement data, so the core never adds their hover height and the lower half of the body is under
-- the floor (same cause as the Dalaran spawns). Lift each by its creature_template HoverHeight.
UPDATE world.creature SET position_z = CASE guid
    WHEN 340185   THEN 101.0015  -- Aerylia 96679, the Skyhold Val'kyr transporter (was 98.2015, +2.8)
    WHEN 11078327 THEN 109.402   -- Danica the Reclaimer 100622, phase 5999 (was 106.602, +2.8)
    WHEN 11078325 THEN 102.8003  -- Savyn Valorborn 106460, phase 6027 (was 99.8003, +3)
    WHEN 11078328 THEN 100.8056  -- Finna Bjornsdottir 107985, phase 6002 (was 97.8056, +3)
    END
WHERE map = 1479 AND guid IN (340185, 11078327, 11078325, 11078328);
