-- #30 (Claude, 2026-09-28): the red Focusing Crystal stands under the ship's overhang, so its beam aura 259468 on the
-- Focus NPC straight above failed the line-of-sight check (the other three crystals stand in the open). The beams are
-- visuals: all four ignore line of sight (disables flag 64 = SPELL_DISABLE_LOS). Undo: undo_eonar_crystal_beams_los.sql
DELETE FROM world.disables WHERE sourceType = 0 AND entry IN (259468, 259469, 259470, 259472);
INSERT INTO world.disables (sourceType, entry, flags, params_0, params_1, comment) VALUES
(0, 259468, 64, '', '', 'Eonar: Focusing Crystal beam (red) ignores LOS, #30'),
(0, 259469, 64, '', '', 'Eonar: Focusing Crystal beam (green) ignores LOS, #30'),
(0, 259470, 64, '', '', 'Eonar: Focusing Crystal beam (blue) ignores LOS, #30'),
(0, 259472, 64, '', '', 'Eonar: Focusing Crystal beam (yellow) ignores LOS, #30');
