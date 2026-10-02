-- Refs #154 (help-helper, Claude 2026-10-02): Daio the Decrepit (42477) needs the Demon Stone (item 141330, objective
-- 286563). The Eredar Mage (107800) gave it only through an invoker cast of 226138 on death (SAI id 2, linked from id 1):
-- a killing blow by a pet, an NPC or another group member gave the player nothing. Same bug as Khadgar's Beacon in
-- fix_bringer_of_the_light_154.sql: now every player within 100 yards gets the stone.
-- Undo: undo_eredar_mage_demon_stone_154.sql
UPDATE world.smart_scripts SET action_type = 56, action_param1 = 141330, action_param2 = 1, target_type = 18,
       target_param1 = 100, comment = 'Link - Add Item Demon Stone to players (#154)'
WHERE entryorguid = 107800 AND source_type = 0 AND id = 2 AND action_type = 85 AND action_param1 = 226138 AND target_type = 7;
