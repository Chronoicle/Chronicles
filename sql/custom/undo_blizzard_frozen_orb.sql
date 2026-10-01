-- Undo fix_blizzard_frozen_orb.sql (Blizzard no longer sends Frozen Orbs)
DELETE FROM world.spell_script_names WHERE spell_id = 190357 AND ScriptName = 'spell_mage_blizzard_frozen_orb';
