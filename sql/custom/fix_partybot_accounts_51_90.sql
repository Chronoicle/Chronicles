-- Owner 2026-10-01 ("Create 40 more random bots, and raise the cap to 50"): 40 more bot accounts PARTYBOT51@BOT ..
-- PARTYBOT90@BOT for parallel quest-test runs (#138); partybot1..50 (auth ids 10-59) hold the 36+ party bots.
-- Same columns the core's account create fills (username, sha_pass_hash, joindate). The hash is random, so no password
-- logs in: bot sessions have no socket and never authenticate. Picked up live (FreeBotAccount reads auth.account).
-- Undo: undo_partybot_accounts_51_90.sql
INSERT IGNORE INTO auth.account (username, sha_pass_hash, joindate)
WITH RECURSIVE n AS (SELECT 51 AS i UNION ALL SELECT i + 1 FROM n WHERE i < 90)
SELECT CONCAT('PARTYBOT', i, '@BOT'), UPPER(SHA2(CONCAT(UUID(), RAND()), 256)), NOW() FROM n;
