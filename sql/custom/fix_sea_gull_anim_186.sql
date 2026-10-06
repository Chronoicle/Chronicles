-- #186 (Claude, dev-owner): Sea Gull 44880 had bytes1 0x03000000 (AnimTier fly) in its template addon, so the 184 perched
-- gulls (Stormwind 58, Kalimdor, Draenor ...; all static) flapped in place on ledges. Ground tier like retail's perched gulls.
UPDATE world.creature_template_addon SET bytes1 = 0 WHERE entry = 44880 AND bytes1 = 50331648;
