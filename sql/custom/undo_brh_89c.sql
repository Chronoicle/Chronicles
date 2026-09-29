-- Undo fix_brh_89c.sql (Black Rook Hold #89 round 3): restores the exact before-state.
UPDATE world.creature_template SET flags_extra = flags_extra & ~128 WHERE entry = 111706;
UPDATE world.creature_template_wdb SET Displayid2 = 0 WHERE Entry = 111706;
DELETE FROM world.creature WHERE guid = 11565685;
