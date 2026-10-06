-- Undo fix_humanoids_hovering_188.sql
UPDATE world.creature_template_movement m JOIN world.bak_humanoids_hovering_188 b ON b.CreatureId = m.CreatureId
SET m.Ground = b.Ground, m.Swim = b.Swim, m.Flight = b.Flight;
