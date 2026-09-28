-- Undo fix_broken_shore_intro_77.sql
UPDATE world.gossip_menu_option SET OptionText = 'Я $gготов:готова;, пойти в атаку.' WHERE MenuID = 20974 AND OptionID = 0;
UPDATE world.spell_target_position SET target_position_x = -835.73, target_position_y = 4244.73, target_position_z = 776 WHERE id = 240161;
