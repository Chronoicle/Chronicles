-- Undo fix_smartai_on_batch1_revert6.sql
UPDATE world.creature_template SET AIName = 'SmartAI' WHERE entry IN (10461, 24083, 36558, 57475, 54638, 73678) AND AIName = '';
