-- #40 (Claude): The Arcway, Nal'tira (98207) and the intro Vicious Manafangs (98759) had no creature_template_movement
-- row, so Creature::UpdateMovementFlags (every update) re-enabled gravity the script turns off: Nal'tira never stayed up
-- on her web (sat on the floor in the hanging pose) and the manafang drops stuttered. Ground + DisableGravity, the same
-- movement as the in-combat Vicious Manafang (110966): gravity is off only while they are in the air.
-- Undo: undo_arcway_naltira_40.sql
DELETE FROM world.creature_template_movement WHERE CreatureId IN (98207, 98759);
INSERT INTO world.creature_template_movement (CreatureId, Ground, Swim, Flight, Rooted, Random, InteractionPauseTimer) VALUES
(98207, 1, 1, 1, 0, 0, NULL),
(98759, 1, 1, 1, 0, 0, NULL);
