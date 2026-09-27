-- Undo fix_shop_to_donate_vendor.sql (and set Bpay.Enabled = 1 in worldserver.conf again)
DELETE FROM auth.donate_products WHERE category BETWEEN 401 AND 412;
DELETE FROM auth.donate_categories WHERE id BETWEEN 401 AND 412;
DELETE FROM auth.donate_products WHERE category = 1 AND type = 7;
