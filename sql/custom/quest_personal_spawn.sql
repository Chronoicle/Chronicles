-- Personal quest spawns (PR helper/quest-personal-spawn). Apply BEFORE the restart that brings the C++ (the loader aborts on a missing table, like every world table).
-- A creature listed here is summoned for each player who has the quest in the log and still incomplete, near the spot (<= 120 yd), with private visibility
-- (only that player sees it), respawn_secs after it was killed while the quest is incomplete; it despawns when the quest is completed/abandoned/rewarded, the player
-- leaves the map / goes > 200 yd away or logs out. z = 0: ground height at spawn time. Coordinates of the first rows: wowhead map percent (g_mapperData) converted
-- with the 7.3.5 WorldMapArea box of the zone (worldY = LocLeft - px*(LocLeft-LocRight), worldX = LocTop - py*(LocTop-LocBottom)): about +-7 yd.
CREATE TABLE IF NOT EXISTS world.quest_personal_spawn (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  quest INT UNSIGNED NOT NULL,
  creature INT UNSIGNED NOT NULL,
  map INT UNSIGNED NOT NULL,
  x FLOAT NOT NULL,
  y FLOAT NOT NULL,
  z FLOAT NOT NULL DEFAULT 0,
  o FLOAT NOT NULL DEFAULT 0,
  respawn_secs INT UNSIGNED NOT NULL DEFAULT 60,
  comment VARCHAR(255) NOT NULL DEFAULT '',
  PRIMARY KEY (id),
  KEY idx_quest (quest)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DELETE FROM world.quest_personal_spawn WHERE quest IN (39941, 48101, 48739);
INSERT INTO world.quest_personal_spawn (quest, creature, map, x, y, z, o, respawn_secs, comment) VALUES
(39941, 97847, 1220, 637.5, 5350.3, 0, 0, 60, 'Control is Key: Overseer Felorax, Azsuna; wowhead npc=97847 first of 4 spawn points (68, 26.6) of zone 7334'),
(48101, 127934, 1669, 6244.8, 9897.1, 0, 0, 60, 'Bully Pulpit: Antoran Infiltrator, Antoran Wastes (zone 8701); wowhead npc=127934 cluster centre (50.6, 17.4)'),
(48739, 126910, 1669, 6301.3, 9701.6, 0, 0, 300, 'Commander Xethgar, Antoran Wastes (zone 8701); wowhead npc=126910 cluster (56.6, 14.8)');
-- not filled (ambiguous coords): 44733 Elux'ara/Thar'zul (Karazhan floors), 42969 Piet (needs the spy scene), item objectives, scene bunnies.
