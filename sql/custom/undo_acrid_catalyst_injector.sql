-- Undo fix_acrid_catalyst_injector.sql (Refs #41)
DELETE FROM world.spell_script_names WHERE spell_id = 253259 AND ScriptName = 'spell_item_acrid_catalyst_injector';
