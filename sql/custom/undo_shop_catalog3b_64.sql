-- Undo fix_shop_catalog3b_64.sql
UPDATE auth.donate_products SET category = 602 WHERE id BETWEEN 2121 AND 2127 AND category = 601;
UPDATE auth.donate_categories SET enable = 1 WHERE id = 602;
UPDATE auth.donate_products SET enable = 1 WHERE id = 2 AND type = 6;
