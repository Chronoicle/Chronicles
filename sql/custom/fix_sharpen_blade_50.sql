-- #50 (Claude): Sharpen Blade (198817, Arms PvP talent) should replace Mortal Wounds, not stack with it. Mortal Strike's
-- dummy (spell_dummy_trigger) cast Mortal Wounds 115804 (-25% healing) always and Sharpen Blade's 198819 (-50%) on top.
-- Negative aura = only when the caster does NOT have it. Undo: undo_sharpen_blade_50.sql
UPDATE world.spell_dummy_trigger SET aura = -198817 WHERE spell_id = 12294 AND spell_trigger = 115804 AND aura = 0;
