-- Eye of Azshara: remove the 11 spell_script_names rows that name scripts which do not exist in the core
-- (startup: "ScriptName '...' is referenced by the database, but does not exist in the core!"). They came in with
-- ~/destiny_dungeons.sql (DestinyCore port, names DestinyCore's SQL used but its C++ never had) and
-- survived the revert to LegionCore's scripts. None of them ever ran, so removing them changes no behaviour:
-- every mechanic is already wired by LegionCore's script, the boss AI or the DB (Refs #17, Claude 2026-09-29).
--   191850 Rampage (Serpentrix)          -> boss_serpentrix SpellHitTarget (MaxTargets 1)
--   192705 Arcane Bomb (Wrath)            -> spell_dummy_trigger 192705->192706 + boss AI summons the bomb
--   193018 Gaseous Bubbles (Deepbeard)    -> spell_deepbeard_gaseous_explosion stays on the same spell
--   193245 Gain Energy                    -> Rokmora's spell (Neltharion's Lair), spell_rokmora_gain_energy stays
--   193611 Focused Lightning (Hatecoil)   -> plain effects: damage + force-cast 193624/193625 (sand dunes)
--   193698 Curse of the Witch aura        -> spell_hatecoil_curse_of_the_witch stays on the same spell
--   193712/193716 Curse of the Witch      -> boss_lady_hatecoil SpellHitTarget casts 193698 (MaxTargets 1/3)
--   196624 Monsoon target                 -> spell_dummy_trigger 196624->196622 + npc_hatecoil_monsoon
--   197134 Shelter                        -> applied/removed by instance_eye_of_azshara (dummy aura)
--   197324 Crackling Thunder              -> spell_crackling_thunder_filter stays on the same spell
-- Undo: undo_eoa_bindings_17.sql
DELETE FROM world.spell_script_names WHERE (spell_id, ScriptName) IN (
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
(197324, 'spell_lady_hatecoil_crackling_thunder'));
