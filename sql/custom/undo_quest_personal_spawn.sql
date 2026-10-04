-- Undo for quest_personal_spawn.sql: remove the rows; the empty table is harmless (drop it only together with the C++ revert).
DELETE FROM world.quest_personal_spawn WHERE quest IN (39941, 48101, 48739);
-- DROP TABLE world.quest_personal_spawn;
