-- Undo #40 Ivanyr Nether Link: none of these rows existed before.
DELETE FROM world.spell_script_names WHERE spell_id IN (196804, 196805);
DELETE FROM world.areatrigger_scripts WHERE entry = 10007;
DELETE FROM world.areatrigger_actions WHERE entry = 5285 AND customEntry = 0;
