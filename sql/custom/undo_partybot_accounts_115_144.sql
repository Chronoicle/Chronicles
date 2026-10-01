-- Undo fix_partybot_accounts_115_144.sql. First `.partybot dungeontest stop`; level-bot characters on these accounts stay
-- in characters.characters without an account (delete them in game with .character erase before this).
DELETE FROM auth.account WHERE username REGEXP '^PARTYBOT(11[5-9]|1[23][0-9]|14[0-4])@BOT$';
