-- Dungeon bots (#140, owner request 2026-10-01): 20 more bot accounts PARTYBOT95@BOT .. PARTYBOT114@BOT. All 94 bot
-- accounts hold a character (44 party bots, 50 quest-test characters) and a dungeon run needs 5 accounts (up to 4 runs).
-- Same columns as fix_partybot_accounts_51_94.sql; random password hash (bot sessions have no socket). Picked up live.
-- Undo: undo_partybot_accounts_95_114.sql
INSERT IGNORE INTO auth.account (username, sha_pass_hash, joindate)
WITH RECURSIVE n AS (SELECT 95 AS i UNION ALL SELECT i + 1 FROM n WHERE i < 114)
SELECT CONCAT('PARTYBOT', i, '@BOT'), UPPER(SHA2(CONCAT(UUID(), RAND()), 256)), NOW() FROM n;
