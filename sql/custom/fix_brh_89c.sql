-- Black Rook Hold #89 round 3 (desktop team, Claude subagent, 2026-09-30). Undo: undo_brh_89c.sql
-- Goes with the C++ change (first-staircase boulder path, first-staircase trickster, Amalgam soul positions).

-- 1) Boulder 111706: back to the player-invisible stalker model (display 11686 + trigger flag), as in the upstream
--    LegionCore data. #20 (f404d17, an audit, never checked in game) made display 64055 visible, but 64055 is a
--    0.25-scale fel Infernal (model 9462 = the Legion Infernal, same textures as display 62196 "Infernal"), the
--    placeholder Blizzard also gives Sand Dune 97853 and Clear Platform 107937 (both 64055 + an invisible display).
--    The rock is the Boulder Crush aura's visual (222378 -> SpellVisualKitModelAttach 331189: Boulder_Missile.m2,
--    +-0.27 yd, at scale 10 = ~5.4 yd, matching the 2.55 yd areatrigger), so players saw a small infernal in every
--    boulder and standing where it broke (James's screenshot). GMs with .gm on still see the infernal (core shows
--    triggers' first visible model to GMs). Before: flags_extra 0, Displayid2 0.
UPDATE world.creature_template SET flags_extra = flags_extra | 128 WHERE entry = 111706 AND (flags_extra & 128) = 0;
UPDATE world.creature_template_wdb SET Displayid2 = 11686 WHERE Entry = 111706 AND Displayid2 = 0;

-- 2) Wyrmtongue Trickster at the top of the first staircase (retail spawn point, missing here; floor 129.97 on the
--    navmesh, 3.8 yd from where the left boulders start). npc_brh_wyrmtongue_trickster makes it passive while the
--    boulders roll and has it yell the retreat line (creature_text 98900 group 1) once someone reaches the top of
--    the first staircase, then cower, like the two at the top of the second. Free guid inside the BRH block.
INSERT INTO world.creature (guid, id, map, zoneId, areaId, spawnMask, phaseMask, PhaseId, position_x, position_y, position_z, orientation, spawntimesecs)
VALUES (11565685, 98900, 1501, 7805, 7805, 8388870, 1, '', 3175.74, 7314.63, 129.81, 4.29, 14400);
