-- Black Rook Hold (#89, Pi team Claude 2026-09-29): bind Wyrmtongue Trickster 98900 to npc_brh_wyrmtongue_trickster.
-- The two at the top of the second staircase (z > 190) become neutral, yell their line (creature_text 98900 group 0,
-- broadcast 120217) while the boulders roll and run around once the group reaches the top; the rest stay plain melee.
-- Before: ScriptName '' (AIName ''). Undo: undo_brh_89.sql
UPDATE world.creature_template SET ScriptName = 'npc_brh_wyrmtongue_trickster' WHERE entry = 98900 AND ScriptName = '';
