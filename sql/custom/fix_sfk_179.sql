-- Shadowfang Keep (map 33), issue #179 (reporter tyrvana). help-helper (Claude, Pro) 2026-10-04. DRAFT, NOT RUN: diagnostics first, test on a copy, deploy TOGETHER with the
-- C++ of PR helper/179-sfk (instance script shows the group of the player's faction). Apply right before a restart (no .reload). Undo: undo_sfk_179.sql.
--
-- CAUSE: the DB has BOTH factions' escort NPCs at every stop for everyone (no phases) and the old instance script additionally turned Belmont 47293 into Ivar 47006 and the Horde
-- guards 47030/47031 into Berserkers 47027 for Alliance players: Ivar twice at the entrance, "Packleader Ivar" (47293 converted) next to Baron Ashbury, guards that should come after
-- Ashbury standing at the entrance. CPP/TrinityCore split them with spawn groups 412-432 (our core has none): here every escort creature carries
-- creature.phaseMask = 1 << (4 + stop) (hidden, 16-bit safe; the Alliance and Horde variants of a stop share the tag) and the instance script sets it to 1 for the members of the player's faction when the stop is due.
--
-- DIAGNOSTIC (read-only):
--   SELECT id, COUNT(*) FROM world.creature WHERE map = 33 AND id IN (47006,47027,47030,47031,47293,47294) GROUP BY id;       -- ours; CPP: 47006 x6, 47027 x37, 47030 x20, 47031 x10, 47293 x6, 47294 x2 (81 rows)
--   SELECT guid,id,position_x,position_y,position_z,phaseMask,MovementType,spawndist FROM world.creature WHERE map = 33 AND id IN (47006,47027,47030,47031,47293,47294) ORDER BY id, position_z;
--   SELECT * FROM world.creature_addon WHERE guid IN (SELECT guid FROM world.creature WHERE map = 33 AND id IN (47006,47027,47030,47031,47293,47294));
--   SELECT entryorguid, source_type, COUNT(*) FROM world.smart_scripts WHERE entryorguid IN (47006,47027,47030,47031,47293,47294) OR entryorguid < 0 AND -entryorguid IN (SELECT guid FROM world.creature WHERE map = 33 AND id IN (47006,47027,47030,47031,47293,47294)) GROUP BY 1, 2;

-- 1) backup + delete the old escort rows (OWNER OK needed: deletes spawn data; the new rows below replace them)
CREATE TABLE IF NOT EXISTS world.bak_sfk179_creature LIKE world.creature;
INSERT INTO world.bak_sfk179_creature SELECT * FROM world.creature WHERE map = 33 AND id IN (47006, 47027, 47030, 47031, 47293, 47294) AND guid NOT IN (SELECT guid FROM world.bak_sfk179_creature);
CREATE TABLE IF NOT EXISTS world.bak_sfk179_addon LIKE world.creature_addon;
INSERT INTO world.bak_sfk179_addon SELECT * FROM world.creature_addon WHERE guid IN (SELECT guid FROM world.bak_sfk179_creature) AND guid NOT IN (SELECT guid FROM world.bak_sfk179_addon);
DELETE FROM world.creature_addon WHERE guid IN (SELECT guid FROM world.bak_sfk179_creature);
DELETE FROM world.creature WHERE guid IN (SELECT guid FROM world.bak_sfk179_creature);


-- 2) the CPP rows (81): entry, position, stop tag in phaseMask. spawnMask 6 like the old rows (check diagnostic), zone/area 209, static (CPP: MovementType 0).
CREATE TABLE IF NOT EXISTS world.bak_sfk179_base (name VARCHAR(20) PRIMARY KEY, val BIGINT NOT NULL);
SET @SFK179 := (SELECT MAX(guid) FROM world.creature);
INSERT IGNORE INTO world.bak_sfk179_base (name, val) VALUES ('base', @SFK179);
INSERT INTO world.creature (guid, id, map, zoneId, areaId, spawnMask, phaseMask, PhaseId, modelid, equipment_id, position_x, position_y, position_z, orientation, spawntimesecs, spawndist, currentwaypoint, curhealth, curmana, MovementType, npcflag, npcflag2, unit_flags, dynamicflags)
SELECT @SFK179 := @SFK179 + 1, r.id, 33, 209, 209, 6, r.pm, 0, 0, 0, r.x, r.y, r.z, r.o, 7200, 0, 0, 0, 0, 0, 0, 0, 0, 0 FROM (
SELECT 47027 id, 16 pm, -215.484 x, 2126.58 y, 80.70493 z, 4.468043 o -- CPP group 412
  UNION ALL SELECT 47027 id, 16 pm, -225.997 x, 2135.15 y, 80.93173 z, 4.660029 o -- CPP group 412
  UNION ALL SELECT 47027 id, 16 pm, -216.786 x, 2121.5 y, 80.34393 z, 4.468043 o -- CPP group 412
  UNION ALL SELECT 47027 id, 16 pm, -214.123 x, 2132.59 y, 80.90813 z, 4.468043 o -- CPP group 412
  UNION ALL SELECT 47027 id, 16 pm, -227.486 x, 2124.11 y, 80.37684 z, 4.660029 o -- CPP group 412
  UNION ALL SELECT 47027 id, 16 pm, -226.573 x, 2128.72 y, 80.74143 z, 4.660029 o -- CPP group 412
  UNION ALL SELECT 47006 id, 16 pm, -219.417 x, 2137.05 y, 80.97094 z, 4.485496 o -- CPP group 412
  UNION ALL SELECT 47031 id, 16 pm, -225.693 x, 2136.02 y, 80.95454 z, 4.677482 o -- CPP group 413
  UNION ALL SELECT 47031 id, 16 pm, -214.486 x, 2134.03 y, 80.94864 z, 4.485496 o -- CPP group 413
  UNION ALL SELECT 47030 id, 16 pm, -228.497 x, 2122.73 y, 80.25184 z, 4.782202 o -- CPP group 413
  UNION ALL SELECT 47030 id, 16 pm, -216.899 x, 2120.18 y, 80.24763 z, 4.276057 o -- CPP group 413
  UNION ALL SELECT 47030 id, 16 pm, -217.365 x, 2122.68 y, 80.41753 z, 4.34587 o -- CPP group 413
  UNION ALL SELECT 47030 id, 16 pm, -226.722 x, 2124.83 y, 80.44633 z, 4.625123 o -- CPP group 413
  UNION ALL SELECT 47293 id, 16 pm, -220.958 x, 2129.48 y, 80.78983 z, 4.607669 o -- CPP group 413
  UNION ALL SELECT 47027 id, 1024 pm, -76.5694 x, 2138.99 y, 154.2303 z, 0.296706 o -- CPP group 419
  UNION ALL SELECT 47027 id, 1024 pm, -87.4427 x, 2152.68 y, 145.0043 z, 3.141593 o -- CPP group 419
  UNION ALL SELECT 47027 id, 1024 pm, -92.4045 x, 2141.42 y, 145.0043 z, 0.296706 o -- CPP group 419
  UNION ALL SELECT 47027 id, 1024 pm, -74.6024 x, 2152.2 y, 155.7893 z, 2.827433 o -- CPP group 419
  UNION ALL SELECT 47027 id, 1024 pm, -94.9236 x, 2128.72 y, 145.0043 z, 3.665191 o -- CPP group 419
  UNION ALL SELECT 47027 id, 1024 pm, -109.05 x, 2132.08 y, 145.0043 z, 1.710423 o -- CPP group 419
  UNION ALL SELECT 47031 id, 1024 pm, -87.6441 x, 2126.23 y, 145.0043 z, 2.443461 o -- CPP group 420
  UNION ALL SELECT 47031 id, 1024 pm, -102.142 x, 2123.2 y, 155.7383 z, 5.864306 o -- CPP group 420
  UNION ALL SELECT 47030 id, 1024 pm, -111.995 x, 2133.53 y, 145.0043 z, 1.692969 o -- CPP group 420
  UNION ALL SELECT 47030 id, 1024 pm, -94.2517 x, 2138.56 y, 145.0043 z, 5.148721 o -- CPP group 420
  UNION ALL SELECT 47030 id, 1024 pm, -75.3976 x, 2143.99 y, 155.6093 z, 3.577925 o -- CPP group 420
  UNION ALL SELECT 47030 id, 1024 pm, -91.5174 x, 2148.32 y, 145.0043 z, 0.0 o -- CPP group 420
  UNION ALL SELECT 47294 id, 1024 pm, -110.026 x, 2158.99 y, 155.7623 z, 6.178465 o -- CPP group 420
  UNION ALL SELECT 47027 id, 32 pm, -235.01 x, 2136.48 y, 87.09804 z, 4.719248 o -- CPP group 421
  UNION ALL SELECT 47027 id, 32 pm, -247.602 x, 2112.6 y, 87.09563 z, 2.775074 o -- CPP group 421
  UNION ALL SELECT 47027 id, 32 pm, -246.389 x, 2112.02 y, 87.09373 z, 2.775074 o -- CPP group 421
  UNION ALL SELECT 47027 id, 32 pm, -229.707 x, 2144.31 y, 90.70734 z, 2.792527 o -- CPP group 421
  UNION ALL SELECT 47027 id, 32 pm, -248.965 x, 2113.26 y, 87.09624 z, 2.984513 o -- CPP group 421
  UNION ALL SELECT 47027 id, 32 pm, -227.457 x, 2149.91 y, 90.70734 z, 2.792527 o -- CPP group 421
  UNION ALL SELECT 47006 id, 32 pm, -239.936 x, 2116.16 y, 87.08714 z, 2.740167 o -- CPP group 421
  UNION ALL SELECT 47030 id, 32 pm, -237.592 x, 2150.78 y, 90.70734 z, 4.555309 o -- CPP group 422
  UNION ALL SELECT 47030 id, 32 pm, -233.04 x, 2149.04 y, 90.70734 z, 4.34587 o -- CPP group 422
  UNION ALL SELECT 47030 id, 32 pm, -233.597 x, 2140.91 y, 87.09624 z, 4.39823 o -- CPP group 422
  UNION ALL SELECT 47030 id, 32 pm, -240.047 x, 2143.16 y, 87.09624 z, 4.45059 o -- CPP group 422
  UNION ALL SELECT 47031 id, 32 pm, -218.477 x, 2146.08 y, 90.70734 z, 2.897247 o -- CPP group 422
  UNION ALL SELECT 47031 id, 32 pm, -220.705 x, 2140.32 y, 90.70734 z, 2.75762 o -- CPP group 422
  UNION ALL SELECT 47293 id, 32 pm, -240.5535 x, 2130.556 y, 87.04115 z, 4.047379 o -- CPP group 422
  UNION ALL SELECT 47027 id, 64 pm, -287.359 x, 2313.4 y, 92.71404 z, 4.39823 o -- CPP group 423
  UNION ALL SELECT 47027 id, 64 pm, -293.95 x, 2316.14 y, 92.78304 z, 4.433136 o -- CPP group 423
  UNION ALL SELECT 47027 id, 64 pm, -292.418 x, 2310.59 y, 90.83453 z, 4.34587 o -- CPP group 423
  UNION ALL SELECT 47027 id, 64 pm, -216.639 x, 2279.1 y, 95.98424 z, 2.986222 o -- CPP group 423
  UNION ALL SELECT 47027 id, 64 pm, -231.135 x, 2275.78 y, 96.04263 z, 2.454399 o -- CPP group 423
  UNION ALL SELECT 47027 id, 64 pm, -242.517 x, 2281.8 y, 96.40804 z, 2.64016 o -- CPP group 423
  UNION ALL SELECT 47006 id, 64 pm, -276.547 x, 2298.07 y, 96.82654 z, 5.873963 o -- CPP group 423
  UNION ALL SELECT 47031 id, 64 pm, -223.637 x, 2275.91 y, 77.13573 z, 5.585053 o -- CPP group 424
  UNION ALL SELECT 47031 id, 64 pm, -217.88 x, 2285.48 y, 77.13573 z, 1.448623 o -- CPP group 424
  UNION ALL SELECT 47030 id, 64 pm, -288.9552 x, 2300.522 y, 89.72758 z, 4.921014 o -- CPP group 424
  UNION ALL SELECT 47030 id, 64 pm, -285.8244 x, 2304.515 y, 89.64634 z, 0.6435287 o -- CPP group 424
  UNION ALL SELECT 47030 id, 64 pm, -287.1191 x, 2305.041 y, 89.74182 z, 0.5727214 o -- CPP group 424
  UNION ALL SELECT 47030 id, 64 pm, -287.7312 x, 2299.908 y, 89.64044 z, 4.768981 o -- CPP group 424
  UNION ALL SELECT 47293 id, 64 pm, -260.385 x, 2290.04 y, 75.08263 z, 2.775074 o -- CPP group 424
  UNION ALL SELECT 47027 id, 128 pm, -263.906 x, 2269.6 y, 97.62373 z, 5.88176 o -- CPP group 425
  UNION ALL SELECT 47027 id, 128 pm, -262.012 x, 2268.67 y, 98.67534 z, 5.934119 o -- CPP group 425
  UNION ALL SELECT 47027 id, 128 pm, -259.929 x, 2267.86 y, 99.79284 z, 5.934119 o -- CPP group 425
  UNION ALL SELECT 47027 id, 256 pm, -220.9429 x, 2223.227 y, 105.8726 z, 4.528842 o -- CPP group 426
  UNION ALL SELECT 47027 id, 256 pm, -226.6541 x, 2222.231 y, 106.2409 z, 4.48631 o -- CPP group 426
  UNION ALL SELECT 47006 id, 256 pm, -241.7395 x, 2217.392 y, 106.464 z, 4.622139 o -- CPP group 426
  UNION ALL SELECT 47027 id, 256 pm, -234.9143 x, 2216.633 y, 106.979 z, 4.32102 o -- CPP group 426
  UNION ALL SELECT 47027 id, 512 pm, -156.882 x, 2177.6 y, 128.7793 z, 5.864306 o -- CPP group 427
  UNION ALL SELECT 47027 id, 512 pm, -148.575 x, 2178.92 y, 128.2843 z, 5.078908 o -- CPP group 427
  UNION ALL SELECT 47027 id, 512 pm, -136.068 x, 2168.84 y, 128.7793 z, 2.722714 o -- CPP group 427
  UNION ALL SELECT 47027 id, 512 pm, -151.531 x, 2162.95 y, 128.7793 z, 1.082104 o -- CPP group 427
  UNION ALL SELECT 47027 id, 512 pm, -152.111 x, 2170.61 y, 128.2843 z, 0.3665192 o -- CPP group 427
  UNION ALL SELECT 47027 id, 512 pm, -141.684 x, 2183.09 y, 128.7793 z, 4.29351 o -- CPP group 427
  UNION ALL SELECT 47027 id, 512 pm, -143.906 x, 2167.56 y, 128.2843 z, 1.972222 o -- CPP group 427
  UNION ALL SELECT 47006 id, 512 pm, -172.833 x, 2178.76 y, 129.3383 z, 0.6615827 o -- CPP group 427
  UNION ALL SELECT 47030 id, 4096 pm, -136.833 x, 2161.72 y, 138.7803 z, 2.059489 o -- CPP group 428
  UNION ALL SELECT 47030 id, 4096 pm, -134.288 x, 2164.36 y, 138.7803 z, 2.373648 o -- CPP group 428
  UNION ALL SELECT 47030 id, 4096 pm, -131.498 x, 2170.57 y, 138.7803 z, 3.124139 o -- CPP group 428
  UNION ALL SELECT 47030 id, 4096 pm, -131.438 x, 2174.3 y, 138.7803 z, 3.473205 o -- CPP group 428
  UNION ALL SELECT 47031 id, 4096 pm, -131.734 x, 2167.9 y, 138.7803 z, 2.80998 o -- CPP group 428
  UNION ALL SELECT 47031 id, 4096 pm, -132.72 x, 2166.21 y, 138.7803 z, 2.80998 o -- CPP group 428
  UNION ALL SELECT 47294 id, 4096 pm, -137.918 x, 2169.69 y, 136.6613 z, 2.775074 o -- CPP group 428
  UNION ALL SELECT 47293 id, 128 pm, -264.7126 x, 2269.896 y, 97.17555 z, 5.929502 o -- CPP group 429
  UNION ALL SELECT 47293 id, 512 pm, -171.7906 x, 2180.634 y, 129.2917 z, 1.069335 o -- CPP group 430
  UNION ALL SELECT 47006 id, 2048 pm, -160.621 x, 2178.69 y, 152.376 z, 5.883088 o -- CPP group 431
  UNION ALL SELECT 47293 id, 2048 pm, -168.978 x, 2185.792 y, 151.9715 z, 4.799315 o -- CPP group 432
) r;

-- stop tags: 0 entrance=16 (CPP 412/413), 1 Ashbury=32 (421/422), 2 Silverlaine=64 (423/424), 3 Springvale=128 (425/429), 4 outside=256 (426, Alliance), 5 Walden=512 (427/430),
-- 6 Godfrey dead troops=1024 (419/420), 7 Godfrey intro Ivar/Belmont=2048 (431/432), 8 Horde Springvale-or-Walden troop=4096 (428).
-- NOT covered (no CPP source in the repo: its TDB world database is not in git): the other ~350 static spawns of the dungeon and the patrol paths. CPP's SFK escort NPCs are static; the
-- CPP SmartAI of the group members (Belmont/Cromush talk + summon, Ivar talk every 60 s, Berserker jump-to-position/eat emote) is not ported. Disease clouds (CPP groups 414-418,
-- Horde only, 23837 with aura 88198) are not ported (visual only).
