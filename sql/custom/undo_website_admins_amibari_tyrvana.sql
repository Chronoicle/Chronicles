-- Undo fix_website_admins_amibari_tyrvana.sql (both were 'player')
UPDATE website.user_currencies SET role = 'player' WHERE account_id IN (4, 60);
