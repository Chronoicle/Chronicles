-- Neltharion's Lair, James's list (Refs #13; desktop team, Claude subagent, 2026-09-30). Undo: undo_neltharions_lair_13_4_bosses_drummers.sql
-- 1. Rokmora 91003, Ularogg Cragshaper 91004, Naraxas 91005, Dargrul 91007 could be slowed and stunned: standard boss
--    immunity mask 617299839 (charm, disorient, disarm, distract, fear, grip, root, silence, sleep, snare, stun, freeze,
--    knockout, polymorph, banish, shackle, turn, horror, daze, sapped), as for Vault of the Wardens (#39) and the raids
--    (#81). None of the spells these bosses cast on themselves (intro, stance, energy, frenzy) has a mechanic
--    (SpellCategories / SpellEffect and the hotfixes tables checked), so the mask blocks nothing of their own.
-- 2. Vileshard Hulk 91000 (617299699 since fix_nl_james.sql): the same mask on top (adds disarm, distract, silence).
-- 3. Understone Drummers back on their own spots (the positions fix_nl_drummers_13.sql replaced, = LegionCore's spawns):
--    they only go to their drum to play War Drums (script, boss_ularogg_cragshaper.cpp).
DROP TABLE IF EXISTS world.bak_nl_13_4_template;
CREATE TABLE world.bak_nl_13_4_template AS SELECT entry, mechanic_immune_mask FROM world.creature_template WHERE entry IN (91000, 91003, 91004, 91005, 91007);
DROP TABLE IF EXISTS world.bak_nl_13_4_drummers;
CREATE TABLE world.bak_nl_13_4_drummers AS SELECT guid, position_x, position_y, position_z, orientation FROM world.creature WHERE guid IN (11566198, 11566199);

UPDATE world.creature_template SET mechanic_immune_mask = mechanic_immune_mask | 617299839 WHERE entry IN (91000, 91003, 91004, 91005, 91007);
UPDATE world.creature SET position_x = 2553.12, position_y = 1500.03, position_z = -54.2467, orientation = 4.35817 WHERE guid = 11566198 AND id = 92610;
UPDATE world.creature SET position_x = 2646.54, position_y = 1592.12, position_z = -54.3942, orientation = 4.11995 WHERE guid = 11566199 AND id = 92610;
