-- Undo fix_sharpen_blade_50.sql
UPDATE world.spell_dummy_trigger SET aura = 0 WHERE spell_id = 12294 AND spell_trigger = 115804 AND aura = -198817;
