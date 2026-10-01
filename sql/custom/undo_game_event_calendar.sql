-- Undo for sql/custom/fix_game_event_calendar.sql (#139): restores the exact previous start_time, end_time and occurence
-- of every game_event row the fix touches, taken from the live world DB on 2026-10-01 before the fix. Needs a restart.
UPDATE world.game_event SET start_time = '2019-06-21 10:00:00', end_time = '2030-07-05 00:10:00', occurence = 525600 WHERE eventEntry = 1;  -- Midsummer Fire Festival
UPDATE world.game_event SET start_time = '2019-12-16 10:00:00', end_time = '2030-01-02 06:00:00', occurence = 525600 WHERE eventEntry = 2;  -- Winter Veil
UPDATE world.game_event SET start_time = '2019-01-05 00:01:00', end_time = '2030-12-31 00:01:00', occurence = 43200 WHERE eventEntry = 3;  -- Darkmoon Faire (Building)
UPDATE world.game_event SET start_time = '2019-07-04 10:00:00', end_time = '2030-07-05 10:00:00', occurence = 525600 WHERE eventEntry = 5;  -- Fireworks Spectacular
UPDATE world.game_event SET start_time = '2019-04-22 10:00:00', end_time = '2030-04-24 10:00:00', occurence = 524160 WHERE eventEntry = 9;  -- Noblegarden
UPDATE world.game_event SET start_time = '2019-04-29 10:00:00', end_time = '2030-05-08 10:00:00', occurence = 525600 WHERE eventEntry = 10;  -- Children's Week
UPDATE world.game_event SET start_time = '2019-10-18 10:00:00', end_time = '2030-11-01 11:00:00', occurence = 525600 WHERE eventEntry = 12;  -- Hallow's End
UPDATE world.game_event SET start_time = '2018-12-31 18:00:00', end_time = '2035-01-01 06:00:00', occurence = 525600 WHERE eventEntry = 13;  -- Fireworks Celebration
UPDATE world.game_event SET start_time = '2019-09-20 10:00:00', end_time = '2030-10-06 10:00:00', occurence = 525600 WHERE eventEntry = 24;  -- Brewfest
UPDATE world.game_event SET start_time = '2008-01-03 00:00:00', end_time = '2020-12-31 08:00:00', occurence = 1440 WHERE eventEntry = 25;  -- Nights
UPDATE world.game_event SET start_time = '2019-09-19 10:00:00', end_time = '2030-09-20 10:00:00', occurence = 525600 WHERE eventEntry = 50;  -- Pirates' Day
UPDATE world.game_event SET start_time = '2019-11-01 10:00:00', end_time = '2030-11-03 10:00:00', occurence = 525600 WHERE eventEntry = 51;  -- Day of the Dead
UPDATE world.game_event SET start_time = '2018-12-25 10:00:00', end_time = '2030-01-03 10:00:00', occurence = 525600 WHERE eventEntry = 52;  -- Winter Veil: Gifts
UPDATE world.game_event SET start_time = '2019-02-23 10:00:00', end_time = '2025-02-24 00:00:00', occurence = 525600 WHERE eventEntry = 69;  -- Hatching of the Hippogryphs
UPDATE world.game_event SET start_time = '2019-04-28 12:00:00', end_time = '2025-04-29 12:00:00', occurence = 525600 WHERE eventEntry = 70;  -- Volunteer Guard Day
UPDATE world.game_event SET start_time = '2018-05-01 00:10:00', end_time = '2025-06-01 00:10:00', occurence = 60 WHERE eventEntry = 71;  -- Darkmoon Concert "Blight Boar" Preparation 20 min
UPDATE world.game_event SET start_time = '2018-05-01 00:20:00', end_time = '2025-06-01 00:20:00', occurence = 60 WHERE eventEntry = 72;  -- Darkmoon Concert "Blight Boar" Preparation 10 min
UPDATE world.game_event SET start_time = '2018-05-01 00:29:00', end_time = '2025-06-01 00:29:00', occurence = 60 WHERE eventEntry = 73;  -- Darkmoon Concert "Blight Boar" Preparation 1 min
UPDATE world.game_event SET start_time = '2018-05-01 00:00:00', end_time = '2025-06-01 00:00:00', occurence = 60 WHERE eventEntry = 74;  -- Darkmoon Concert "Blight Boar" Preparation 30 min
UPDATE world.game_event SET start_time = '2019-01-06 00:01:00', end_time = '2025-03-01 00:00:00', occurence = 43680 WHERE eventEntry = 75;  -- Darkmoon Faire
UPDATE world.game_event SET start_time = '2019-01-21 00:01:00', end_time = '2030-01-24 00:01:00', occurence = 525600 WHERE eventEntry = 78;  -- Call of the Scarab
UPDATE world.game_event SET start_time = '2018-05-01 00:30:00', end_time = '2025-06-01 00:30:00', occurence = 60 WHERE eventEntry = 79;  -- Darkmoon Concert "Blight Boar"
UPDATE world.game_event SET start_time = '2019-01-31 10:00:00', end_time = '2025-07-31 10:00:00', occurence = 262800 WHERE eventEntry = 86;  -- Kirin Tor Tavern Crawl
UPDATE world.game_event SET start_time = '2018-05-10 00:00:00', end_time = '2025-05-13 00:00:00', occurence = 525600 WHERE eventEntry = 87;  -- Spring Balloon Festival
UPDATE world.game_event SET start_time = '2018-03-28 02:00:00', end_time = '2020-03-28 02:00:00', occurence = 90720 WHERE eventEntry = 90;  -- Northrend Timewalking Dungeon Event
UPDATE world.game_event SET start_time = '2018-04-18 02:00:00', end_time = '2020-03-28 02:00:00', occurence = 90720 WHERE eventEntry = 91;  -- World Quest Bonus Event
UPDATE world.game_event SET start_time = '2018-04-04 02:00:00', end_time = '2020-03-28 02:00:00', occurence = 90720 WHERE eventEntry = 92;  -- Battleground Bonus Event
UPDATE world.game_event SET start_time = '2018-05-23 02:00:00', end_time = '2020-03-28 02:00:00', occurence = 90720 WHERE eventEntry = 93;  -- Pet Battle Bonus Event
UPDATE world.game_event SET start_time = '2018-04-25 02:00:00', end_time = '2020-03-28 02:00:00', occurence = 90720 WHERE eventEntry = 94;  -- Cataclysm Timewalking Dungeon Event
UPDATE world.game_event SET start_time = '2018-05-02 02:00:00', end_time = '2020-03-28 02:00:00', occurence = 90720 WHERE eventEntry = 95;  -- Arena Skirmish Bonus Event
UPDATE world.game_event SET start_time = '2018-04-11 02:00:00', end_time = '2020-03-28 02:00:00', occurence = 90720 WHERE eventEntry = 96;  -- Outland Timewalking Dungeon Event
UPDATE world.game_event SET start_time = '2018-05-16 02:00:00', end_time = '2020-03-28 02:00:00', occurence = 90720 WHERE eventEntry = 97;  -- Legion Dungeon Event
UPDATE world.game_event SET start_time = '2018-05-09 02:00:00', end_time = '2020-03-28 02:00:00', occurence = 90720 WHERE eventEntry = 98;  -- Mists of Pandaria Timewalking Dungeon Event
UPDATE world.game_event SET start_time = '2019-11-12 00:01:00', end_time = '2025-11-12 00:01:00', occurence = 525600 WHERE eventEntry = 299;  -- Moonkin Festival
UPDATE world.game_event SET start_time = '2019-07-22 00:01:00', end_time = '2025-07-22 00:01:00', occurence = 525600 WHERE eventEntry = 300;  -- Auction House Dance Studio
UPDATE world.game_event SET start_time = '2018-05-27 12:00:00', end_time = '2025-05-28 12:00:00', occurence = 525600 WHERE eventEntry = 301;  -- Glowcap Festival
UPDATE world.game_event SET start_time = '2018-08-17 00:01:00', end_time = '2025-08-21 23:59:00', occurence = 525600 WHERE eventEntry = 302;  -- Trial of Style (August)
UPDATE world.game_event SET start_time = '2018-03-05 00:01:00', end_time = '2025-03-09 23:59:00', occurence = 525600 WHERE eventEntry = 303;  -- Trial of Style (March)
UPDATE world.game_event SET start_time = '2019-10-13 00:01:00', end_time = '2025-10-13 00:01:00', occurence = 525600 WHERE eventEntry = 304;  -- The Great Gnomeregan Run
UPDATE world.game_event SET start_time = '2019-04-05 00:01:00', end_time = '2025-04-05 00:01:00', occurence = 525600 WHERE eventEntry = 305;  -- March of the Tadpoles
UPDATE world.game_event SET start_time = '2019-01-24 00:00:00', end_time = '2030-01-24 00:01:00', occurence = 525600 WHERE eventEntry = 306;  -- Call of the Scarab - Event for choose Winner
UPDATE world.game_event SET start_time = '2019-06-06 00:01:00', end_time = '2030-06-08 00:01:00', occurence = 525600 WHERE eventEntry = 307;  -- Thousand Boat Bash
UPDATE world.game_event SET start_time = '2019-07-23 00:00:58', end_time = '2025-07-23 00:00:59', occurence = 525600 WHERE eventEntry = 313;  -- Auction House Dance Studio: Return Phase Mask
