-- .challenge (#57, help-helper subagent, Claude): 1v1 arena challenge between two players (players). Undo: undo_challenge_command_57.sql
-- Optional: the command works without this row (security comes from the script); the row adds the .help text.
DELETE FROM world.command WHERE name = 'challenge';
INSERT INTO world.command (name, security, help) VALUES
('challenge', 0, 'Syntax: .challenge $player | accept | decline\n\nChallenge an online player to an unrated 1v1 arena (no rating, honor, conquest or rewards). The other player answers with .challenge accept or .challenge decline within 60 seconds.');
