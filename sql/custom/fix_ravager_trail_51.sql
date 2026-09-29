-- #51 (Claude): Ravager (76168, from 227876) showed only the spinning weapon. Its display 56304 is
-- Warrior_Ravager_notrail.m2 (no ribbon, no particles); the red trail, ground circle and particles are in
-- Warrior_Ravager.m2 (display 55644: WeaponTrail_WarriorFury_fa / T_VFX_HERO_CIRCLE_WarriorFury textures).
-- LegionCore swaps the display with aura 177466 (script spell_warr_ravager_visual -> SetDisplayId(55644)), listed in
-- spell_pet_auras, but spell_pet_auras only works for real pets and the Ravager is a guardian, so it never applied.
-- Give the summon the aura through its (empty) template addon. Undo: undo_ravager_trail_51.sql
UPDATE world.creature_template_addon SET auras = '177466' WHERE entry = 76168 AND auras = '';
