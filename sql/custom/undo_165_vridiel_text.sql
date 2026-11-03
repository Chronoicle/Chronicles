-- undo #165 Vridiel gossip option text (apply with mysql --default-character-set=utf8mb4)
UPDATE world.gossip_menu_option SET OptionText = 'Позволь взглянуть на твои товары.' WHERE MenuID = 19601 AND OptionID = 1;
