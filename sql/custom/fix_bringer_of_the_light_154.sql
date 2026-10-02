-- #154 (gabrielf03d, Claude 2026-10-02): Bringer of the Light (44004), Battle for the Exodar scenario (map 1624).
-- When the Fel Annihilator (111593) dies, Khadgar's Beacon (140319, "Teleport: Dalaran") was made only by whoever
-- landed the killing blow (invoker cast of 223356): a pet, Velen or another group member got nothing for the player.
-- Now every player within 100 yards gets the beacon. (The final Velen dialogue being cut off after 35 s is fixed in
-- Conversation.cpp.)
-- Undo: undo_bringer_of_the_light_154.sql
UPDATE world.smart_scripts SET action_type = 56, action_param1 = 140319, action_param2 = 1, target_type = 18,
       target_param1 = 100, comment = 'Link - Add Item Khadgar''s Beacon to players (#154)'
WHERE entryorguid = 111593 AND source_type = 0 AND id = 8 AND action_type = 85 AND action_param1 = 223356 AND target_type = 7;
