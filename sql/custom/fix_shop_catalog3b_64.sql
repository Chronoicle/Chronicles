-- #64 shop phase 3 catalogue fixes (patriarch8809, Claude desktop team dev-owner, 2026-09-29).
-- Undo: undo_shop_catalog3b_64.sql
-- The six Prestigious Coursers and Spirit of Eche'ro are ground mounts, not flying: all seven to Ground (after the
-- Vicious mounts, sort 12-18 stays), and the then empty Flying tab is hidden.
UPDATE auth.donate_products SET category = 601 WHERE id BETWEEN 2121 AND 2127 AND category = 602;
UPDATE auth.donate_categories SET enable = 0 WHERE id = 602;
-- 10000 gold for 10 in Services (phase 1) doubled the Currency tab's 10,000 gold (50): off.
UPDATE auth.donate_products SET enable = 0 WHERE id = 2 AND type = 6;
