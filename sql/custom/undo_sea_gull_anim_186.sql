-- Undo fix_sea_gull_anim_186.sql
UPDATE world.creature_template_addon SET bytes1 = 50331648 WHERE entry = 44880 AND bytes1 = 0;
