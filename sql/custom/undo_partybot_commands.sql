-- Undo for fix_partybot_commands.sql
DELETE FROM world.command WHERE name IN ('partybot', 'partybot add', 'partybot remove', 'partybot list');
