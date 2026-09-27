-- #44 (Claude 2026-09-27): Mindbender gave no Insanity / mana. Its passive Mana Leech 123050 is listed in spell_pet_auras,
-- but only real Pet objects apply those and Mindbender is summoned as a guardian, so it never had the aura.
-- spell_trigger already turns 123050's melee proc into 123051 (0.5% mana) and 200010 (8 Insanity) on the owner.
-- Undo: undo_mindbender_44.sql
DELETE FROM world.creature_template_addon WHERE entry IN (62982, 67236);
INSERT INTO world.creature_template_addon (entry, path_id, mount, bytes1, bytes2, emote, auras) VALUES
(62982, 0, 0, 0, 1, 0, '123050'),
(67236, 0, 0, 0, 1, 0, '123050');
