-- The Arcway, Corstilax (Refs #40, Pi team 2026-09-29). Apply with a worldserver restart (no .reload).
-- 1) Corstilax 98205 had mechanic_immune_mask 0: player stuns/fears/silences etc. cancelled the Cleansing Force channel
--    (196115), which removes its aura before the 8 s tick, so Exterminate (damage 196142 + stun 203649) never came.
--    Standard boss mask as in fix_raid_boss_cc_immunity_81.sql (not interrupt; 196115 cannot be kicked anyway).
--    The script roots the boss with a unit state, not a mechanic aura, so nothing in the fight needs these mechanics.
UPDATE world.creature_template SET mechanic_immune_mask = mechanic_immune_mask | 617299839 WHERE entry = 98205;
-- 2) Exterminate stun 203649 only on players that still have Nightwell Energy (spell text), C++ in boss_corstilax.cpp.
DELETE FROM world.spell_script_names WHERE spell_id = 203649 AND ScriptName = 'spell_corstilax_exterminate_stun';
INSERT INTO world.spell_script_names (spell_id, ScriptName) VALUES (203649, 'spell_corstilax_exterminate_stun');
