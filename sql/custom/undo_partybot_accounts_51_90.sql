-- Undo fix_partybot_accounts_51_90.sql. First `.partybot questtest stop`; a Qt* test character still on one of these
-- accounts stays in characters.characters without an account (delete it in game with .character erase before this).
DELETE FROM auth.account WHERE username REGEXP '^PARTYBOT(5[1-9]|[6-8][0-9]|90)@BOT$';
