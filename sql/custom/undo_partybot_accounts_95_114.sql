-- Undo fix_partybot_accounts_95_114.sql. First `.partybot dungeontest stop`; level-bot characters on these accounts stay
-- in characters.characters without an account (delete them in game with .character erase before this).
DELETE FROM auth.account WHERE username REGEXP '^PARTYBOT(9[5-9]|10[0-9]|11[0-4])@BOT$';
