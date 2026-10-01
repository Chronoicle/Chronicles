-- Azsuna, Saving Stellagosa (37450): Stellagosa showed the chains but not the green fel circle (gabrielf03d, approved
-- reporter, #122; Claude desktop team subagent). Builds on fix_azsuna_stellagosa.sql (bunny/lock phases stay as they are).
-- Undo: sql/custom/undo_azsuna_stellagosa_fel_chain.sql. Live with a worldserver restart (no .reload).
--
-- The 3 Stellagosa Chain Bunnies (90578) channelled Cosmetic Chains 65612, a generic Wrath spell whose visual is only a
-- chain beam. The client has a spell made for this scene, "Saving Stellagosa: Fel Chain" 180291 (also instant,
-- infinite, channelled, a dummy aura on the target; range 100 instead of 30): its visual has the fel chain beam plus an
-- aura kit with a model on the chained target, which is the green circle. The bunnies now channel 180291, and
-- Stellagosa's "nobody chains me any more, fly off" check (SmartAI 90546 event 2 = condition source 22 group 3) looks
-- for 180291 instead of 65612, otherwise she would free herself 35 s after spawning.
UPDATE world.smart_scripts SET action_param1 = 180291
WHERE entryorguid = 90578 AND source_type = 0 AND id IN (0, 2) AND action_type = 11 AND action_param1 = 65612;

UPDATE world.conditions SET ConditionValue1 = 180291, Comment = 'Stellagosa frees herself only when no Chain Bunny channels Saving Stellagosa: Fel Chain on her'
WHERE SourceTypeOrReferenceId = 22 AND SourceGroup = 3 AND SourceEntry = 90546 AND SourceId = 0
  AND ConditionTypeOrReference = 1 AND ConditionValue1 = 65612 AND NegativeCondition = 1;
