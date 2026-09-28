-- #82 (Claude): trash Garothi Annihilator 127230 before Kin'garoth. Its impact 252743 had no script, so an unsoaked
-- circle never cast the raid-wide blast 252744 (SpellXSpellVisual 67248, the big green shockwave, same visual as the
-- boss blast 246666). Needs the core change in boss_kingaroth.cpp (252743 -> 252744 in spell_kingaroth_annihilation_dmg).
-- Undo: undo_kingaroth_trash_visual_82.sql
DELETE FROM world.spell_script_names WHERE spell_id = 252743 AND ScriptName = 'spell_kingaroth_annihilation_dmg';
INSERT INTO world.spell_script_names (spell_id, ScriptName) VALUES (252743, 'spell_kingaroth_annihilation_dmg');
