-- Claude (dev-owner) 2026-10-04, owner request (missing class scripts, PR #181): Comet Storm 153595 pointed at the
-- non-existent spell_monk_comet_storm; the launch and the comet missile 228601 get the new mage scripts.
DELETE FROM world.spell_script_names WHERE spell_id IN (153595, 228601) AND ScriptName IN ('spell_monk_comet_storm', 'spell_mage_comet_storm', 'spell_mage_comet_storm_damage');
INSERT INTO world.spell_script_names (spell_id, ScriptName) VALUES (153595, 'spell_mage_comet_storm'), (228601, 'spell_mage_comet_storm_damage');
