-- Undo for fix_sfk_179.sql
DELETE FROM world.creature_addon WHERE guid > (SELECT val FROM world.bak_sfk179_base WHERE name = 'base') AND guid <= (SELECT val + 81 FROM world.bak_sfk179_base WHERE name = 'base');
DELETE FROM world.creature WHERE map = 33 AND guid > (SELECT val FROM world.bak_sfk179_base WHERE name = 'base') AND guid <= (SELECT val + 81 FROM world.bak_sfk179_base WHERE name = 'base');
INSERT INTO world.creature SELECT * FROM world.bak_sfk179_creature;
INSERT INTO world.creature_addon SELECT * FROM world.bak_sfk179_addon;
-- drop the bak_sfk179_* tables by hand when sure. NOTE: with the old rows back the C++ of PR helper/179-sfk shows nothing hidden: revert it too (or the old UpdateEntry hack is gone).
