-- #192 (Claude, dev-owner): Paladin class hall chain A United Force 38566 -> Forging New Strength 39722 ("empower your artifact"
-- = buy a trait, ArtifactHandler OPEN_ARTIFACT_POWERS). Nothing on this server gave the first 100 Artifact Power
-- (GtArtifactLevelXP rank 1), so the quest could not be finished. 38566 now rewards 100 AP (category 0 = no Artifact Knowledge bonus).
UPDATE world.quest_template SET RewardArtifactXP = 100, RewardArtifactXPMultiplier = 1, RewardArtifactCategoryID = 0
WHERE ID = 38566 AND RewardArtifactXP = 0;
