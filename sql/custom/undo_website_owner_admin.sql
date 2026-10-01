-- Undo fix_website_owner_admin.sql
UPDATE website.user_currencies SET role = 'player' WHERE account_id = 2;
