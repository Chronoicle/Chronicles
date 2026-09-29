-- Undo for fix_challenge_command_57.sql
DELETE FROM world.command WHERE name = 'challenge';
