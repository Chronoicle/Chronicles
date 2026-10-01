-- Frost Blizzard: each damage pulse (190357) has a 20% chance to send a Frozen Orb from an enemy it hit (owner request
-- 2026-10-01, Claude). Code: spell_mage_blizzard_frozen_orb in spell_mage.cpp. Undo: undo_blizzard_frozen_orb.sql
DELETE FROM world.spell_script_names WHERE spell_id = 190357 AND ScriptName = 'spell_mage_blizzard_frozen_orb';
INSERT INTO world.spell_script_names (spell_id, ScriptName) VALUES (190357, 'spell_mage_blizzard_frozen_orb');
