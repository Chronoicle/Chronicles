-- Undo fix_ravager_trail_51.sql
UPDATE world.creature_template_addon SET auras = '' WHERE entry = 76168 AND auras = '177466';
