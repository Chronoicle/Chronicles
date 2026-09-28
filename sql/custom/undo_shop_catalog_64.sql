-- Undo fix_shop_catalog_64.sql: Premium back under Services (1), no "Premium" category, the test product enabled again
UPDATE auth.donate_products SET category = 1 WHERE category = 21 AND type = 7;
DELETE FROM auth.donate_categories WHERE id = 21;
UPDATE auth.donate_products SET enable = 1 WHERE name = 'Refreshing Spring Water (test)';
