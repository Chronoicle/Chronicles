-- #166 (Claude, dev-owner): dungeon/raid bosses without CC immunity (mechanic_immune_mask 0) could be stunned,
-- feared, rooted, polymorphed ... Give them the mask 609 other bosses use (617299803: stun/fear/root/silence/
-- poly/incap/etc.; interrupts, bleeds, grips and disarms still work). Halls of Valor, Maw of Souls, Violet Hold,
-- Court of Stars, Karazhan, Cathedral, Seat of the Triumvirate, Dragon Soul.
UPDATE world.creature_template SET mechanic_immune_mask = 617299803 WHERE mechanic_immune_mask = 0 AND entry IN (55309,55310,55311,55313,55314,55315,57409,57771,57772,94960,95674,95675,95676,95833,96754,96756,96759,99868,101950,101951,101976,101995,102246,102387,102431,102446,104215,104217,104218,113971,114247,114251,114252,114260,114261,114264,114284,114312,114328,114329,114330,114350,114522,114790,114895,116944,117193,117194,118804,122056,122313,122316,124729,128311);
-- Fenryr's first form (before he runs to his den) had IMMUNE_TO_PC: "Invalid target" although he fights back.
UPDATE world.creature_template SET unit_flags = unit_flags & ~256 WHERE entry = 95674;
