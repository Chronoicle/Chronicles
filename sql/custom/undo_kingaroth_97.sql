-- Undo fix_kingaroth_97.sql (#97): before-state captured 2026-09-29: name 'Проводник' (UTF-8 hex below, so the client
-- charset cannot mangle it), flags 0, for all four entries.
UPDATE world.gameobject_template SET name = CONVERT(0xD09FD180D0BED0B2D0BED0B4D0BDD0B8D0BA USING utf8mb3), flags = 0 WHERE entry IN (276474, 276475, 276476, 276477);
