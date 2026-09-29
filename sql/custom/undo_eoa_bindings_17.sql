-- Undo for fix_eoa_bindings_17.sql: puts the 11 dead Eye of Azshara spell_script_names rows back (Refs #17).
INSERT IGNORE INTO world.spell_script_names (spell_id, ScriptName) VALUES
(191850, 'spell_serpentix_rampage_aura'),
(192705, 'spell_wrath_of_azshara_arcane_bomb_target'),
(193018, 'aura_king_deepbeard_gaseous_bubbles'),
(193245, 'aura_king_deepbeard_gain_energy'),
(193611, 'spell_lady_hatecoil_focused_lightning'),
(193698, 'aura_lady_hatecoil_curse_of_the_witch'),
(193712, 'spell_lady_hatecoil_curse_of_the_witch'),
(193716, 'spell_lady_hatecoil_curse_of_the_witch'),
(196624, 'spell_lady_hatecoil_monsoon_target'),
(197134, 'spell_dungeon_azshara_shelter'),
(197324, 'spell_lady_hatecoil_crackling_thunder');
