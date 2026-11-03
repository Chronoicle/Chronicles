-- undo #199: keystone 138019 name back to the old (Portuguese) value
UPDATE hotfixes.item_sparse SET Display = 'Pedra-chave Mítica' WHERE ID = 138019;
UPDATE hotfixes.item_sparse SET Description = 'Coloque-a no interior da Fonte de Poder que fica dentro da masmorra na dificuldade Mítica' WHERE ID = 138019;
