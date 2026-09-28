-- Undo fix_shop_new_flag_64.sql: drops donate_products.added (the worldserver from the shop phase 2 build needs it:
-- its shop lists would come back empty, so only undo this together with reverting that build). Idempotent.
SET @present = (SELECT COUNT(*) > 0 FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = 'auth' AND TABLE_NAME = 'donate_products' AND COLUMN_NAME = 'added');
SET @q = IF(@present, 'ALTER TABLE auth.donate_products DROP COLUMN `added`', 'DO 0');
PREPARE s FROM @q; EXECUTE s; DEALLOCATE PREPARE s;
