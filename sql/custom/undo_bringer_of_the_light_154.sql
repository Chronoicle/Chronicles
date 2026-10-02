-- Undo for fix_bringer_of_the_light_154.sql (restores the exact before-state)
UPDATE world.smart_scripts SET action_type = 85, action_param1 = 223356, action_param2 = 0, target_type = 7,
       target_param1 = 0, comment = 'Link - ICS'
WHERE entryorguid = 111593 AND source_type = 0 AND id = 8 AND action_type = 56 AND action_param1 = 140319 AND target_type = 18;
