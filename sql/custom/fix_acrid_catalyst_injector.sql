-- Acrid Catalyst Injector (item 151955, aura 253259) had no script binding, so the trinket never procced (Refs #41, Claude 2026-09-26)
-- Effect 0 is APPLY_AURA / SPELL_AURA_DUMMY (checked in SpellEffect.db2), matching the script's hook.
-- Undo: undo_acrid_catalyst_injector.sql
DELETE FROM world.spell_script_names WHERE spell_id = 253259 AND ScriptName = 'spell_item_acrid_catalyst_injector';
INSERT INTO world.spell_script_names (spell_id, ScriptName) VALUES (253259, 'spell_item_acrid_catalyst_injector');
