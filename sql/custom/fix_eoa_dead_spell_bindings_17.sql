-- Issue #17: remove spell bindings for scripts absent from the core.
DELETE FROM spell_script_names
WHERE (spell_id, ScriptName) IN (
    (192705, 'spell_wrath_of_azshara_arcane_bomb_target'),
    (193018, 'aura_king_deepbeard_gaseous_bubbles'),
    (193245, 'aura_king_deepbeard_gain_energy'),
    (196290, 'spell_eye_of_azshara_roiling_storm'),
    (196293, 'spell_eye_of_azshara_roiling_storm_script'),
    (196296, 'spell_eye_of_azshara_roiling_storm'),
    (196299, 'spell_eye_of_azshara_roiling_storm_script'),
    (197134, 'spell_dungeon_azshara_shelter'),
    (202314, 'spell_eye_of_azshara_vile_blood')
);
