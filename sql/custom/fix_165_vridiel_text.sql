-- #165 (Claude dev-helper 2026-11-03): Arcanomancer Vridiel 106655 vendor option in gossip menu 19601 was Russian.
UPDATE world.gossip_menu_option SET OptionText = 'Let me browse your goods.' WHERE MenuID = 19601 AND OptionID = 1;
