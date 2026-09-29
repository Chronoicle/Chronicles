-- Undo fix_brh_89.sql: Wyrmtongue Trickster 98900 had no ScriptName.
UPDATE world.creature_template SET ScriptName = '' WHERE entry = 98900 AND ScriptName = 'npc_brh_wyrmtongue_trickster';
