-- Owner request 2026-09-27 (Claude): everything from the in-game shop (micro bar) moves to the Donate Vendor (auth catalogue),
-- same prices in the same donate tokens. The shop itself is switched off with Bpay.Enabled = 0 in worldserver.conf.
-- Undo: undo_shop_to_donate_vendor.sql
-- Shop gear (groups 10-21, all item level 985): one Donate Vendor category per slot under "PvE equipment > 985 ilevel" (313).
DELETE FROM auth.donate_products WHERE category BETWEEN 401 AND 412;
DELETE FROM auth.donate_categories WHERE id BETWEEN 401 AND 412;
INSERT INTO auth.donate_categories (id, parent, sort, name) VALUES
(401, 313, 1, 'Head'), (402, 313, 2, 'Shoulders'), (403, 313, 3, 'Back'), (404, 313, 4, 'Chest'),
(405, 313, 5, 'Wrist'), (406, 313, 6, 'Hands'), (407, 313, 7, 'Waist'), (408, 313, 8, 'Legs'),
(409, 313, 9, 'Feet'), (410, 313, 10, 'Neck'), (411, 313, 11, 'Rings'), (412, 313, 12, 'Trinkets');
INSERT INTO auth.donate_products (category, sort, name, type, param1, param2, bonus, token)
SELECT 391 + e.GroupID, e.Ordering, '', 0, i.ItemID, 1, CONCAT('ilvl:', i.ItemLevel), p.CurrentPriceFixedPoint
FROM world.battlepay_shop_entry e
JOIN world.battlepay_product p ON p.ProductID = e.ProductID
JOIN world.battlepay_product_item i ON i.ProductID = e.ProductID
WHERE e.GroupID BETWEEN 10 AND 21;

-- Premium 30 / 90 / 180 days (shop 900-902) under Services (1).
DELETE FROM auth.donate_products WHERE category = 1 AND type = 7;
INSERT INTO auth.donate_products (category, sort, name, type, param1, token) VALUES
(1, 10, 'Premium 30 days', 7, 30, 500),
(1, 11, 'Premium 90 days', 7, 90, 1500),
(1, 12, 'Premium 180 days', 7, 180, 3000);
-- The shop's level 90 boost (100 tokens) is not moved: the vendor already sells level 110 for 50.
