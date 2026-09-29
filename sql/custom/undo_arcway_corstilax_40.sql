-- Undo fix_arcway_corstilax_40.sql (Refs #40): Corstilax 98205 had mechanic_immune_mask 0 and 203649 had no script
-- (checked 2026-09-29).
UPDATE world.creature_template SET mechanic_immune_mask = 0 WHERE entry = 98205;
DELETE FROM world.spell_script_names WHERE spell_id = 203649 AND ScriptName = 'spell_corstilax_exterminate_stun';
