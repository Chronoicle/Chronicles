-- Undo fix_shop_catalog2_64.sql (#64 phase 2): removes exactly the services, mounts, achievements and titles it added.
-- Categories were not changed by the fix, so nothing to restore there.
DELETE FROM auth.donate_products WHERE id BETWEEN 2000 AND 2999 AND id IN (2000,2001,2002,2003,
    2100,2101,2102,2103,2104,2105,2106,2107,2108,2109,2110,2111,2112,2113,2114,2115,2116,2117,2118,2119,2120,2121,2122,2123,2124,2125,2126,2127,
    2200,2201,2202,2203,2204,2205,
    2300,2301,2302,2303,2304,2305,2306,2307,2308,2309,2310);

-- Vicious War Bear faction change pair back to the way it was
DELETE FROM world.player_factionchange_spells WHERE (alliance_id = 229486 AND horde_id = 229487) OR (alliance_id = 229487 AND horde_id = 229486);
INSERT INTO world.player_factionchange_spells (alliance_id, horde_id) VALUES (229486, 229487);
