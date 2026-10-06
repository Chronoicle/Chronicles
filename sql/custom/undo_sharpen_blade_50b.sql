-- Undo fix_sharpen_blade_50b.sql
DELETE FROM world.spell_linked_spell WHERE spell_trigger = 198819 AND spell_effect = -115804;
