-- Undo of sql/custom/fix_azsuna_stellagosa_fel_chain.sql: the Chain Bunnies channel Cosmetic Chains 65612 again and
-- Stellagosa's free-herself check looks for 65612. Restores the rows as they were on live on 2026-10-01.
-- Live with a worldserver restart (no .reload).
UPDATE world.smart_scripts SET action_param1 = 65612
WHERE entryorguid = 90578 AND source_type = 0 AND id IN (0, 2) AND action_type = 11 AND action_param1 = 180291;

UPDATE world.conditions SET ConditionValue1 = 65612, Comment = 'SAI only if player have quest'
WHERE SourceTypeOrReferenceId = 22 AND SourceGroup = 3 AND SourceEntry = 90546 AND SourceId = 0
  AND ConditionTypeOrReference = 1 AND ConditionValue1 = 180291 AND NegativeCondition = 1;
