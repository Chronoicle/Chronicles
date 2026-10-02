-- #153 (help-helper, Claude 2026-10-02): The Keystone (38728). 24 of the 48 Skittering Broodling (100333) spawns in
-- Tyranna's lair (area 7749) are at z 275-277, ~32 yd above the floor (z 243). The entry had no AI, no flight data and
-- no web aura (template aura 123978 is only a scale mod), so they stayed in the air: melee "out of range", no aggro.
-- Fix: the new C++ AI npc_q38728_skittering_broodling (mardum.cpp) drops them to the ground when a player comes within
-- 15 yd or pulls them. Fiendish Creeper 99759 (SmartAI, area 7821) is not touched. Undo: undo_mardum_broodlings_153.sql
UPDATE world.creature_template SET ScriptName = 'npc_q38728_skittering_broodling' WHERE entry = 100333 AND ScriptName = '' AND AIName = '';

-- Same-spot duplicate spawns, LISTED ONLY for the owner (nothing deleted). Format: entry, rounded x,y,z: guids.
-- 100333, all pairs share PhaseId "5837 5324 5322 5056":
--   1526,1383,243: 368907 368939 | 1522,1435,243: 368908 368940 | 1521,1390,243: 368909 368941 | 1526,1443,243: 368910 368942
--   1515,1403,275: 368913 368935 | 1540,1432,277: 368914 368934 | 1512,1417,275: 368917 368937 | 1544,1428,278: 368918 368936
--   1602,1443,243: 368920 368949 | 1607,1393,244: 368921 368950 | 1603,1435,244: 368922 368951 | 1600,1381,243: 368923 368952
--   1602,1420,276: 368926 368945 | 1605,1406,276: 368928 368955 | 1590,1428,277: 368931 368944
--   1562,1414,237 (Tyranna's own spot, z 237.13): 368911 368912 368932 368943 368953 368954 (six stacked; look like sniffed
--   copies of her temporary summons rather than static spawns)
-- 99759 (area 7821, z ~105): 1187,1296,105: 368300 368349 368354 368364 | 1183,1296,106: 368301 368327 368355 |
--   1176,1302,105: 368304 368347 | 1181,1297,106: 368348 368350 | 1182,1297,106: 368353 368363
--   (368300/368301/368304/368327 carry PhaseIds 5120+5115 that the others lack, so part of these may be phase variants)
