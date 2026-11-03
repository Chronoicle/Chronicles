-- #198 item 10 (Claude dev-owner 2026-11-03): the Aegis of Aggramar sat inside its pedestal in Cathedral of Eternal Night.
-- 118884 (before Domatrax) already hovers but only 1 yd; 118418 (after Domatrax) did not hover. Both 2.5 yd (estimate, check in game).
UPDATE world.creature_template SET HoverHeight = 2.5 WHERE entry IN (118884, 118418);
UPDATE world.creature_template_addon SET bytes1 = 50331648 WHERE entry = 118418;
