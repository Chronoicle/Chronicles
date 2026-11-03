-- undo #198 item 10 Aegis hover
UPDATE world.creature_template SET HoverHeight = 1 WHERE entry IN (118884, 118418);
UPDATE world.creature_template_addon SET bytes1 = 0 WHERE entry = 118418;
