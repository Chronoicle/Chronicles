-- #64 (Claude): catalogue for the ChroniclesShop addon. Premium 30/90/180 days get their own top-level category
-- "Premium" (21, last in the list; they sat under Services, 1), and the test product "Refreshing Spring Water (test)"
-- (1 token) is switched off. The Donate Vendor shows the same change.
-- Undo: undo_shop_catalog_64.sql
-- Check first (id 21 must be free, the INSERT stops on a duplicate id):
--   SELECT id, parent, sort, name, faction, enable FROM auth.donate_categories WHERE parent = 0 OR id = 21 ORDER BY sort, id;
--   SELECT id, category, sort, name, type, token, enable FROM auth.donate_products WHERE type = 7 OR name = 'Refreshing Spring Water (test)';
INSERT INTO auth.donate_categories (id, parent, sort, name)
SELECT 21, 0, MAX(sort) + 1, 'Premium' FROM auth.donate_categories WHERE parent = 0;
UPDATE auth.donate_products SET category = 21 WHERE category = 1 AND type = 7;
UPDATE auth.donate_products SET enable = 0 WHERE name = 'Refreshing Spring Water (test)';
