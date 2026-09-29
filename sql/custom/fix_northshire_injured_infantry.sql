-- chronwastaken: the Injured Stormwind Infantry in Northshire (50047, 18 spawns, quest "Fear No Evil": click to revive)
-- stand upright; they should lie hurt on the ground. No per-spawn creature_addon rows, so the template addon decides.
-- Stand state 7 (lying, like the Wounded Stormwind Infantry 19624 and other spellclick "Injured ..." NPCs here).
-- The revived soldier that runs off is a separate creature (50378), it keeps standing.
-- Undo: undo_northshire_injured_infantry.sql
UPDATE world.creature_template_addon SET bytes1 = 7 WHERE entry = 50047;
