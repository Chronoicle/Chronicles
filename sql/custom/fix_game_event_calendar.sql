-- #139 (owner OK 2026-10-01, Claude subagent): holiday / recurring world event calendar.
-- The core (GameEventMgr::CheckOneGameEvent) only uses start_time + n * occurence (minutes) for length minutes, never
-- after end_time; it does NOT take dates from Holidays.db2 (no SetHolidayEventTime / holiday_dates in this core).
-- 1) Restores recurring retail 7.3.5 events whose end_time had passed (2020/2025): Darkmoon Faire + Blight Boar
--    concert, the Legion micro-holidays, the weekly bonus event / Timewalking rotation, Dalaran lamplighter (Nights).
-- 2) Re-anchors the yearly holidays to their 2026 slot (same month/day/time as before): the 2019 anchors with a
--    525600-minute year had drifted 2 days early (leap days 2020 + 2024), e.g. Hallow's End would start on Oct 16.
-- end_time 2030-12-31 23:59:59 for every row touched (13 keeps its 2035 end). Times are server local time like the
-- rest of the table. The 525600 year drifts 1 day early again after 29 Feb 2028: re-anchor once then.
-- Darkmoon Faire: retail = first Sunday of each month for 7 days; a fixed period cannot hit that exactly, so 43829
-- minutes (average month) from Sun 2026-10-04 keeps it in the first week of each month (Building the day before).
-- Not changed: which creatures/objects/quests belong to the events. Undo: undo_game_event_calendar.sql
-- Needs a worldserver restart (game_event is read at startup).

-- 1) restored (end_time was in the past)
UPDATE world.game_event SET start_time = '2026-10-04 00:01:00', occurence = 43829, end_time = '2030-12-31 23:59:59' WHERE eventEntry = 75;  -- Darkmoon Faire (first Sunday of the month)
UPDATE world.game_event SET start_time = '2026-10-03 00:01:00', occurence = 43829, end_time = '2030-12-31 23:59:59' WHERE eventEntry = 3;   -- Darkmoon Faire (Building), the day before 75
UPDATE world.game_event SET end_time = '2030-12-31 23:59:59' WHERE eventEntry IN (71, 72, 73, 74, 79);  -- Darkmoon Concert "Blight Boar" (hourly, DarkMoonConcertBlightBoar.cpp)
UPDATE world.game_event SET end_time = '2030-12-31 23:59:59' WHERE eventEntry IN (90, 91, 92, 93, 94, 95, 96, 97, 98);  -- weekly bonus event / Timewalking rotation (9 weeks, one per week)
UPDATE world.game_event SET end_time = '2030-12-31 23:59:59' WHERE eventEntry = 25;  -- Nights (Windle Sparkshine lights the Dalaran lamps)
UPDATE world.game_event SET start_time = '2026-02-23 10:00:00', end_time = '2030-12-31 23:59:59' WHERE eventEntry = 69;   -- Hatching of the Hippogryphs
UPDATE world.game_event SET start_time = '2026-04-28 12:00:00', end_time = '2030-12-31 23:59:59' WHERE eventEntry = 70;   -- Volunteer Guard Day
UPDATE world.game_event SET start_time = '2026-01-31 10:00:00', end_time = '2030-12-31 23:59:59' WHERE eventEntry = 86;   -- Kirin Tor Tavern Crawl (twice a year)
UPDATE world.game_event SET start_time = '2026-05-10 00:00:00', end_time = '2030-12-31 23:59:59' WHERE eventEntry = 87;   -- Spring Balloon Festival
UPDATE world.game_event SET start_time = '2026-11-12 00:01:00', end_time = '2030-12-31 23:59:59' WHERE eventEntry = 299;  -- Moonkin Festival
UPDATE world.game_event SET start_time = '2026-07-22 00:01:00', end_time = '2030-12-31 23:59:59' WHERE eventEntry = 300;  -- Auction House Dance Studio
UPDATE world.game_event SET start_time = '2026-07-23 00:00:58', end_time = '2030-12-31 23:59:59' WHERE eventEntry = 313;  -- Auction House Dance Studio: Return Phase Mask
UPDATE world.game_event SET start_time = '2026-05-27 12:00:00', end_time = '2030-12-31 23:59:59' WHERE eventEntry = 301;  -- Glowcap Festival
UPDATE world.game_event SET start_time = '2026-08-17 00:01:00', end_time = '2030-12-31 23:59:59' WHERE eventEntry = 302;  -- Trial of Style (August)
UPDATE world.game_event SET start_time = '2026-03-05 00:01:00', end_time = '2030-12-31 23:59:59' WHERE eventEntry = 303;  -- Trial of Style (March)
UPDATE world.game_event SET start_time = '2026-10-13 00:01:00', end_time = '2030-12-31 23:59:59' WHERE eventEntry = 304;  -- The Great Gnomeregan Run
UPDATE world.game_event SET start_time = '2026-04-05 00:01:00', end_time = '2030-12-31 23:59:59' WHERE eventEntry = 305;  -- March of the Tadpoles

-- 2) re-anchored (were still running, but 2 days early)
UPDATE world.game_event SET start_time = '2026-06-21 10:00:00', end_time = '2030-12-31 23:59:59' WHERE eventEntry = 1;    -- Midsummer Fire Festival
UPDATE world.game_event SET start_time = '2026-12-16 10:00:00', end_time = '2030-12-31 23:59:59' WHERE eventEntry = 2;    -- Winter Veil
UPDATE world.game_event SET start_time = '2026-07-04 10:00:00', end_time = '2030-12-31 23:59:59' WHERE eventEntry = 5;    -- Fireworks Spectacular
UPDATE world.game_event SET start_time = '2026-10-18 10:00:00', end_time = '2030-12-31 23:59:59' WHERE eventEntry = 12;   -- Hallow's End
UPDATE world.game_event SET start_time = '2026-12-31 18:00:00' WHERE eventEntry = 13;                                     -- Fireworks Celebration (end 2035 kept)
UPDATE world.game_event SET start_time = '2026-09-20 10:00:00', end_time = '2030-12-31 23:59:59' WHERE eventEntry = 24;   -- Brewfest
UPDATE world.game_event SET start_time = '2026-09-19 10:00:00', end_time = '2030-12-31 23:59:59' WHERE eventEntry = 50;   -- Pirates' Day
UPDATE world.game_event SET start_time = '2026-11-01 10:00:00', end_time = '2030-12-31 23:59:59' WHERE eventEntry = 51;   -- Day of the Dead
UPDATE world.game_event SET start_time = '2026-12-25 10:00:00', end_time = '2030-12-31 23:59:59' WHERE eventEntry = 52;   -- Winter Veil: Gifts
UPDATE world.game_event SET start_time = '2026-01-21 00:01:00', end_time = '2030-12-31 23:59:59' WHERE eventEntry = 78;   -- Call of the Scarab
UPDATE world.game_event SET start_time = '2026-01-24 00:00:00', end_time = '2030-12-31 23:59:59' WHERE eventEntry = 306;  -- Call of the Scarab - choose winner (end of 78)
UPDATE world.game_event SET start_time = '2026-06-06 00:01:00', end_time = '2030-12-31 23:59:59' WHERE eventEntry = 307;  -- Thousand Boat Bash
-- moving dates: next retail date (Noblegarden = Easter Monday 2027-03-29; Children's Week = Monday of the week of May 1)
UPDATE world.game_event SET start_time = '2027-03-29 10:00:00', end_time = '2030-12-31 23:59:59' WHERE eventEntry = 9;    -- Noblegarden (was 2027-04-12)
UPDATE world.game_event SET start_time = '2027-04-26 10:00:00', end_time = '2030-12-31 23:59:59' WHERE eventEntry = 10;   -- Children's Week (was 2027-04-27)
