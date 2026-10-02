-- Undo for fix_eredar_mage_demon_stone_154.sql (restores the exact before-state)
UPDATE world.smart_scripts SET action_type = 85, action_param1 = 226138, action_param2 = 0, target_type = 7,
       target_param1 = 0, comment = 'On Death - Send Data'
WHERE entryorguid = 107800 AND source_type = 0 AND id = 2 AND action_type = 56 AND action_param1 = 141330 AND target_type = 18;
