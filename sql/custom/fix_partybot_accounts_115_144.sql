-- Owner 2026-10-01 ("make some more bots, some tanks and healers and some dps"): 30 more bot accounts PARTYBOT115@BOT ..
-- PARTYBOT144@BOT. Every bot character needs its own account; dungeon runs create their tank/healer/DPS level bots on
-- them (CreateLevelBot) when no idle bot of that level fits. Same columns as fix_partybot_accounts_95_114.sql; random
-- password hash. Picked up live. Undo: undo_partybot_accounts_115_144.sql
INSERT IGNORE INTO auth.account (username, sha_pass_hash, joindate)
WITH RECURSIVE n AS (SELECT 115 AS i UNION ALL SELECT i + 1 FROM n WHERE i < 144)
SELECT CONCAT('PARTYBOT', i, '@BOT'), UPPER(SHA2(CONCAT(UUID(), RAND()), 256)), NOW() FROM n;
