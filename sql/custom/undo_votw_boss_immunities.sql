-- Undo fix_votw_boss_immunities.sql (Refs #39)
UPDATE world.creature_template ct JOIN world.bak_votw_boss_immunities b ON b.entry = ct.entry SET ct.mechanic_immune_mask = b.mechanic_immune_mask;
DROP TABLE world.bak_votw_boss_immunities;
