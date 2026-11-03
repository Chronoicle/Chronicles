-- #199 (Claude dev-owner 2026-11-03): Mythic Keystone 138019 hotfix name was Portuguese, the client shows it
UPDATE hotfixes.item_sparse SET Display = 'Mythic Keystone' WHERE ID = 138019;
UPDATE hotfixes.item_sparse SET Description = 'Place within the Font of Power inside the dungeon on Mythic difficulty.' WHERE ID = 138019;
