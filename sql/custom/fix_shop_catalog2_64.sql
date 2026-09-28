-- #64 phase 2 (Claude): shop catalogue additions for the ChroniclesShop addon: character services, mounts,
-- achievements and titles (auth.donate_products ids 2000-2003, 2100-2127, 2200-2205, 2300-2310: explicit, so the undo removes exactly these).
-- Prices: services = the Service manager's prices (auth.donate_services); mounts, achievements and titles =
-- the UWOW shop screenshots the owner sent (~/reference/uwow_shop/ 24, 25, 29, 30 on the server).
-- IDs checked against the 7.3.5 client DB2s in ~/data/dbc/enUS (Mount.SourceSpellID + Spell, Achievement, CharTitles)
-- and hotfixes (no overrides for these). Faction: 1 Alliance, 2 Horde (item Flags2 of the mount's reins,
-- Achievement.Faction / achievement_reward title_A/title_H of the title), 0 both.
-- Shop only (the Donate Vendor lists only items); GM accounts until Shop.OpenToPlayers = 1.
-- Categories 1 Services, 6 Mounts, 7 Achievements, 8 Titles are already enable = 1 (not changed here).
-- Idempotent: deletes its own ids first. Undo: undo_shop_catalog2_64.sql
DELETE FROM auth.donate_products WHERE id IN (2000,2001,2002,2003,
    2100,2101,2102,2103,2104,2105,2106,2107,2108,2109,2110,2111,2112,2113,2114,2115,2116,2117,2118,2119,2120,2121,2122,2123,2124,2125,2126,2127,
    2200,2201,2202,2203,2204,2205,
    2300,2301,2302,2303,2304,2305,2306,2307,2308,2309,2310);

INSERT INTO auth.donate_products (id, category, sort, name, type, param1, token, faction) VALUES
-- Services (1): type 8, param1 = AtLoginFlags, used at the next login. After Level 110 (sort 1) and 10000 gold (2).
(2000, 1, 3, 'Change name',       8,   1, 20, 0),
(2001, 1, 4, 'Change appearance', 8,   8, 20, 0),
(2002, 1, 5, 'Change race',       8, 128, 40, 0),
(2003, 1, 6, 'Change faction',    8,  64, 50, 0),
-- Mounts (6): type 4, param1 = mount spell (Mount.db2 SourceSpellID). Vicious: Alliance/Horde counterparts share a place.
(2100, 6,  1, 'Brawler''s Burly Mushan Beast', 4, 142641, 750, 0),
(2101, 6,  2, 'Vicious War Lion',              4, 229512, 875, 1),
(2102, 6,  2, 'Vicious War Scorpion',          4, 230988, 875, 2),
(2103, 6,  3, 'Vicious War Mechanostrider',    4, 183889, 875, 1),
(2104, 6,  3, 'Vicious War Kodo',              4, 185052, 875, 2),
(2105, 6,  4, 'Vicious War Elekk',             4, 223578, 875, 1),
(2106, 6,  4, 'Vicious Warstrider',            4, 223363, 875, 2),
(2107, 6,  5, 'Vicious War Ram',               4, 171834, 875, 1),
(2108, 6,  5, 'Vicious War Raptor',            4, 171835, 875, 2),
(2109, 6,  6, 'Vicious War Turtle',            4, 232523, 875, 1),
(2110, 6,  6, 'Vicious War Turtle',            4, 232525, 875, 2),
(2111, 6,  7, 'Vicious War Bear',              4, 229487, 875, 1),
(2112, 6,  7, 'Vicious War Bear',              4, 229486, 875, 2),
(2113, 6,  8, 'Vicious War Fox',               4, 242896, 875, 1),
(2114, 6,  8, 'Vicious War Fox',               4, 242897, 875, 2),
(2115, 6,  9, 'Vicious War Steed',             4, 100332, 875, 1),
(2116, 6,  9, 'Vicious War Wolf',              4, 100333, 875, 2),
(2117, 6, 10, 'Vicious Warsaber',              4, 146615, 875, 1),
(2118, 6, 10, 'Vicious Skeletal Warhorse',     4, 146622, 875, 2),
(2119, 6, 11, 'Vicious Gilnean Warhorse',      4, 223341, 875, 1),
(2120, 6, 11, 'Vicious War Trike',             4, 223354, 875, 2),
(2121, 6, 12, 'Prestigious Azure Courser',     4, 222240, 875, 0),
(2122, 6, 13, 'Prestigious Forest Courser',    4, 222237, 875, 0),
(2123, 6, 14, 'Prestigious Bronze Courser',    4, 222202, 875, 0),
(2124, 6, 15, 'Prestigious Royal Courser',     4, 222236, 875, 0),
(2125, 6, 16, 'Prestigious Ivory Courser',     4, 222238, 875, 0),
(2126, 6, 17, 'Prestigious Midnight Courser',  4, 222241, 875, 0),
(2127, 6, 18, 'Spirit of Eche''ro',            4, 196681, 875, 0),
-- Achievements (7): type 3, param1 = Achievement ID (rewards such as For the Children's title and
-- Draenor Pathfinder's Draenor flying come with it, from world.achievement_reward)
(2200, 7, 1, 'Check Your Head',          3,   291,  500, 0),
(2201, 7, 2, 'For the Children',         3,  1793,  900, 0),
(2202, 7, 3, 'Improving on History',     3, 10459, 2500, 0),
(2203, 7, 4, 'Master Angler of Azeroth', 3,   306,  500, 0),
(2204, 7, 5, 'This Side Up',             3, 10602, 1500, 0),
(2205, 7, 6, 'Draenor Pathfinder',       3, 10018, 1000, 0),
-- Titles (8): type 2, param1 = CharTitles ID (not the MaskID). Lady of Blackrock is Lord of Blackrock's female title.
(2300, 8,  1, 'Darkspear Revolutionary', 2, 349, 1000, 2),
(2301, 8,  2, 'Conqueror',               2,  47,  700, 2),
(2302, 8,  3, 'Lord of Blackrock',       2, 434,  700, 0),
(2303, 8,  4, 'Lady of Blackrock',       2, 435,  700, 0),
(2304, 8,  5, 'Scarlet Commander',       2, 369,  700, 0),
(2305, 8,  6, 'of the Black Harvest',    2, 391, 1000, 0),
(2306, 8,  7, 'the Forsaken',            2, 119, 1000, 2),
(2307, 8,  8, 'Gnomebane',               2, 399,  600, 2),
(2308, 8,  9, 'Obsidian Slayer',         2, 139, 1000, 0),
(2309, 8, 10, 'of the Emerald Dream',    2,  87, 1000, 0),
(2310, 8, 11, 'Assassin',                2,  95, 1000, 0);
