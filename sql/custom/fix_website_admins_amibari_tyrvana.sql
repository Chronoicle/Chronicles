-- Owner 2026-10-01 ("Set amibari and tyrvana as admins too"): website admin role (website.user_currencies.role) for
-- account 4 (character Amibari) and account 60 (character Tyrvana); both are GM level 3 in game already.
-- Undo: undo_website_admins_amibari_tyrvana.sql
UPDATE website.user_currencies SET role = 'admin' WHERE account_id IN (4, 60);
