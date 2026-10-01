-- Owner 2026-10-01 ("How do I even set myself as admin on the site"): the website's admin pages (/admin/..., incl.
-- /admin/botwatch) read website.user_currencies.role, not the game GM level. Account 2 (the owner's, character Chron,
-- GM level 3) had 'player'. Undo: undo_website_owner_admin.sql
UPDATE website.user_currencies SET role = 'admin' WHERE account_id = 2;
