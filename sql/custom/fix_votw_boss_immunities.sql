-- Vault of the Wardens: bosses could be feared, stunned, slowed, rooted etc. (Refs #39, Claude 2026-09-26)
-- Standard boss mechanic immunity mask (charm, disorient, disarm, distract, fear, grip, root, silence, sleep,
-- snare, stun, freeze, knockout, polymorph, banish, shackle, turn, horror, daze, sapped).
-- Tirathon 95885, Ash'golm 95886, Glazer 95887, Cordana 95888, Inquisitor Tormentorum 96015.
-- Undo: undo_votw_boss_immunities.sql (restores the saved values).
DROP TABLE IF EXISTS world.bak_votw_boss_immunities;
CREATE TABLE world.bak_votw_boss_immunities AS SELECT entry, mechanic_immune_mask FROM world.creature_template WHERE entry IN (95885,95886,95887,95888,96015);
UPDATE world.creature_template SET mechanic_immune_mask = mechanic_immune_mask | 617299839 WHERE entry IN (95885,95886,95887,95888,96015);
