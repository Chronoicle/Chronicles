-- #90 (James, Claude 2026-09-29): "You do not meet the requirements for this dungeon." on Normal/Heroic, Mythic works.
-- That text is the Dungeon Finder's generic lock (INSTANCE_UNAVAILABLE_SELF_OTHER). access_requirement, lfg_entrances
-- and MapDifficulty were checked for all 13 Legion dungeons and are correct; the difficulties that exist are
-- Normal (EoA, DHT, NL, HoV, MoS, VotW, BRH, VH), Heroic (all 13 incl. Arcway, CoS, Kara, Cathedral, Seat), Mythic (all).
-- The locks come from the client's own data (LFGDungeons.RequiredPlayerConditionId, evaluated by the client):
--   * level 110 for MoS/VotW/BRH Normal and every Heroic (retail; 10 of the reporter's 11 characters are level 90-101), and
--   * achievement 11063 "Hidden Tracking - 1+ Acquisition Line Completed" (set when an artifact acquisition quest is
--     completed). Characters whose quests were filled in by SQL / tools (all 34 level-110 characters here) never got it,
--     so every Legion dungeon is locked in the Dungeon Finder for them.
-- Walking in: Heroic (and MoS/VotW/BRH Normal) need level 110 via MapDifficultyXCondition 34797; Mythic's condition
-- (46284) is not in the DB2s and Instance.IgnoreLevel = 1 skips access_requirement levels, so Mythic opens at any level.
-- Level gates are left as they are (retail); owner decision if they should go.
-- This grants 11063 to the level-110 characters that lack it. Apply with the characters offline (worldserver stopped).
-- Undo: undo_dungeon_access_90.sql
INSERT IGNORE INTO characters.character_achievement (guid, achievement, date)
SELECT guid, 11063, UNIX_TIMESTAMP() FROM characters.characters
WHERE level = 110 AND guid IN (1,5,9,13,17,20,23,25,26,27,28,34,35,36,37,38,40,46,47,48,49,50,51,52,58,59,61,67,84,85,86,87,88,96);
