-- Undo fix_vault_arcway_39_40_arcway.sql (#40). Before-state checked on live 2026-09-30. Apply with a worldserver restart.
UPDATE world.creature_template SET AIName = '' WHERE entry = 113699 AND AIName = 'SmartAI';
DELETE FROM world.smart_scripts WHERE entryorguid = 113699 AND source_type = 0;
DELETE FROM world.creature_formations WHERE leaderGUID = 11566143 OR memberGUID IN (11566143, 11566141);
UPDATE world.creature SET MovementType = 2 WHERE guid = 11566141;
UPDATE world.creature_addon SET path_id = 12909877 WHERE guid = 11566141;
