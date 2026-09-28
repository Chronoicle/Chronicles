-- #64 shop phase 2: donate_products.added, when a product was added. The shop addon marks products added in the
-- last 14 days as NEW (many_in_one_donate.cpp, SHOP_IS_NEW). The catalogue before phase 2 counts as old (2026-09-01),
-- so only rows added from now on are NEW. Safe with the running worldserver (it names its columns). Idempotent.
SET @missing = (SELECT COUNT(*) = 0 FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = 'auth' AND TABLE_NAME = 'donate_products' AND COLUMN_NAME = 'added');
SET @q = IF(@missing, 'ALTER TABLE auth.donate_products ADD COLUMN `added` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP', 'DO 0');
PREPARE s FROM @q; EXECUTE s; DEALLOCATE PREPARE s;
SET @q = IF(@missing, 'UPDATE auth.donate_products SET `added` = ''2026-09-01 00:00:00''', 'DO 0');
PREPARE s FROM @q; EXECUTE s; DEALLOCATE PREPARE s;
