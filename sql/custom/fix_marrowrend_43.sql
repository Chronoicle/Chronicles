-- #43 (Claude): Marrowrend (195182) gave one extra Bone Shield stack whenever Mouth of Hell (192570) was known, even without
-- Dancing Rune Weapon. spell_dk_marrowrend now adds 3 stacks per active rune weapon. Undo: undo_marrowrend_43.sql
DELETE FROM world.spell_linked_spell WHERE spell_trigger = 195182 AND spell_effect = 195181 AND type = 1 AND hastalent = 192570;
