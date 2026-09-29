-- Undo #40 (Nal'tira movement): neither creature had a creature_template_movement row before.
DELETE FROM world.creature_template_movement WHERE CreatureId IN (98207, 98759);
