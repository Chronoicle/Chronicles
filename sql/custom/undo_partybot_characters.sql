-- Undo for fix_partybot_characters.sql (the bot characters themselves stay; delete them with .character erase)
DROP TABLE IF EXISTS characters.partybot_characters;
