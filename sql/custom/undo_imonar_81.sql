-- Undo fix_imonar_81.sql (Refs #81): the 16 Antorus bosses had mechanic_immune_mask 0 before (checked 2026-09-28)
UPDATE world.creature_template SET mechanic_immune_mask = 0
 WHERE entry IN (121975,122104,122135,122333,122366,122367,122369,122450,122467,122468,122469,122477,122578,124158,124828,125436);
