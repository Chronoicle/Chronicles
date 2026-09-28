-- Antorus: Imonar and the other Antorus bosses could be stunned (and feared, rooted, polymorphed ...): all had
-- mechanic_immune_mask 0 (Refs #81, Claude 2026-09-28). Same standard boss mask as the Vault of the Wardens fix (#39):
-- charm, disorient, disarm, distract, fear, grip, root, silence, sleep, snare, stun, freeze, knockout, polymorph,
-- banish, shackle, turn, horror, daze, sapped. One entry per boss serves every difficulty on this core.
-- Aggramar 121975, Hasabel 122104, Shatug 122135, Erodus 122333, Varimathras 122366, Svirax 122367, Ishkar 122369,
-- Garothi Worldbreaker 122450, Asara 122467, Noura 122468, Diima 122469, F'harg 122477, Kin'garoth 122578,
-- Imonar 124158, Argus 124828, Thu'raya 125436. (Essence of Eonar 122500 is the friendly NPC and stays as it is.)
-- Undo: undo_imonar_81.sql (all 16 were 0 before).
UPDATE world.creature_template SET mechanic_immune_mask = mechanic_immune_mask | 617299839
 WHERE entry IN (121975,122104,122135,122333,122366,122367,122369,122450,122467,122468,122469,122477,122578,124158,124828,125436);
