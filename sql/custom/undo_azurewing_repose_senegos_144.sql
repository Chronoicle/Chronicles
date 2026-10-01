-- Undo of sql/custom/fix_azurewing_repose_senegos_144.sql (Azurewing Repose Senegos / withered phases, issue #144).
-- Restores the rows as they were on live on 2026-10-01. Live with a worldserver restart (no .reload).
SET NAMES utf8mb4;

-- 1) sick Senegos without PhaseId, healthy Senegos with the sniffed list
UPDATE world.creature SET PhaseId = '' WHERE guid = 266709 AND id = 89975;
UPDATE world.creature SET PhaseId = '7564 6884 6773 5433 4793 4270' WHERE guid = 338483 AND id = 100482;

-- 2) + 3) no The Power Within / Hunger's End conditions on phase definitions 7334/21, 22, 24
DELETE FROM world.conditions WHERE SourceTypeOrReferenceId = 23 AND SourceGroup = 7334 AND SourceId = 0
  AND ((SourceEntry = 24 AND ElseGroup = 3 AND ConditionTypeOrReference = 14 AND ConditionValue1 = 43496)
    OR (SourceEntry = 22 AND ElseGroup = 1 AND ConditionTypeOrReference = 14 AND ConditionValue1 = 43496)
    OR (SourceEntry = 21 AND ElseGroup = 1 AND ConditionTypeOrReference = 8 AND ConditionValue1 = 42756));

-- withered with the sniffed list again
UPDATE world.creature SET PhaseId = '7564 6893 6886 6646 6595 5433 4793 4436 4270'
WHERE id IN (91157, 103208) AND map = 1220 AND zoneId = 7334 AND PhaseId = '6646';
