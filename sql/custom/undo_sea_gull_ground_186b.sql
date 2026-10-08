-- undo fix_sea_gull_ground_186b.sql
UPDATE world.creature_template_movement SET Ground = 0, Swim = 0, Flight = 1 WHERE CreatureId = 44880;
