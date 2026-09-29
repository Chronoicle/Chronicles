-- The Arcway bosses Ivanyr, General Xakal, Nal'tira and Advisor Vandros had mechanic_immune_mask 0: players could stun,
-- fear, root and interrupt-by-CC them (Refs #40, Claude Pi team 2026-09-29). Corstilax is in fix_arcway_corstilax_40.sql.
-- Same standard boss mask as fix_raid_boss_cc_immunity_81.sql. Checked: Vandros's own Banish in Time stun 203922 and the
-- other self-cast spells in these scripts have no mechanic, so the mask does not block them.
UPDATE world.creature_template SET mechanic_immune_mask = mechanic_immune_mask | 617299839 WHERE entry IN (98203, 98206, 98207, 98208);
