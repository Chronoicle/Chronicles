-- Undo for fix_truthguard_npcs_189.sql
DELETE FROM world.creature WHERE id = 105727 AND guid > (SELECT val FROM world.bak_truthguard189 WHERE name = 'base');
DELETE FROM world.smart_scripts WHERE entryorguid = 105724 AND source_type = 0 AND action_type = 33 AND action_param1 = 105726 AND comment LIKE '%#189%';
UPDATE world.gameobject_template SET ScriptName = '' WHERE entry IN (249044, 249045, 251288) AND ScriptName = 'go_sr_gravestone';
-- (AIName of 105724 was only set when it was empty; leave it SmartAI if other rows exist.)
