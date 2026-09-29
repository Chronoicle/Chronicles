-- Undo for fix_xalatath_portal_106.sql (both templates had no state anim kit before, 2026-09-29)
UPDATE world.gameobject_template SET SpellStateAnimKitID = 0 WHERE entry IN (247351, 251699);
