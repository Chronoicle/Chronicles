-- undo fix_forging_new_strength_192.sql
UPDATE world.quest_template SET RewardArtifactXP = 0, RewardArtifactXPMultiplier = 1, RewardArtifactCategoryID = 0 WHERE ID = 38566;
