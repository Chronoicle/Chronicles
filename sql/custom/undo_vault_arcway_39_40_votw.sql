-- Undo fix_vault_arcway_39_40_votw.sql (#39). Before-state checked on live 2026-09-30. Apply with a worldserver restart.
UPDATE world.creature_template SET AIName = '' WHERE entry IN (99956, 102572) AND AIName = 'SmartAI';
DELETE FROM world.smart_scripts WHERE entryorguid IN (99956, 102572) AND source_type = 0;
DELETE FROM world.areatrigger_actions WHERE entry = 5283 AND customEntry = 0;
DELETE FROM world.smart_scripts WHERE entryorguid = 102566 AND source_type = 0 AND id = 3;
DELETE FROM world.conditions WHERE SourceTypeOrReferenceId = 13 AND SourceEntry = 202634;
UPDATE world.creature SET position_x = 4450.76, position_y = -344.46, position_z = 126.077, orientation = 4.64525 WHERE guid = 14507265;
DELETE FROM world.creature WHERE guid = 146907099;
DELETE FROM world.creature_summon_groups WHERE summonerId = 95888 AND summonerType = 0 AND id = 1;
INSERT INTO world.creature_summon_groups (summonerId, id, summonerType, groupId, entry, position_x, position_y, position_z,
 orientation, count, actionType, distance, summonType, summonTime) VALUES
(95888, 1, 0, 0, 100525, 4482.64, -334.073, -240.317, 2.41779, 0, 0, 0, 8, 0);
