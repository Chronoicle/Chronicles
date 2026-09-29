-- Undo #91 (restores the rows as they were on 2026-09-29).
UPDATE world.gossip_menu_option SET OptionNpc = 0, BoxMoney = 0, BoxText = '' WHERE MenuID = 10638 AND OptionID = 0;
DELETE FROM world.gossip_menu_option WHERE MenuID = 10638 AND OptionID = 1;
UPDATE world.creature_template SET gossip_menu_id = 0 WHERE entry = 35365;
