-- #158 (gabrielf03d, approved reporter; Claude desktop team subagent, 2026-10-02): Priest class hall, Murloc Mind Control
-- (43374). The Murloc Cage (252158) could simply be clicked for the credit. Undo: sql/custom/undo_murloc_cage_158.sql.
-- Needs the worldserver build with go_murloc_cage_43374 (zone_azsuna.cpp); live with a restart (no .reload).
--
-- Retail: Mind Control a Salteye Tide-Shaman / Hookblade (88101 / 88099, both have Chew Cage 220326 as spell4) and use
-- Chew Cage on the cage. Chew Cage only opens the cage (ACTIVATE_OBJECT "open + unlock"), it never gave the credit, so
-- the click was the only way. The new script ignores players' clicks and gives the GO credit to the player who controls
-- the murloc when Chew Cage opens it. Its SmartGameObjectAI rows (event 72, never fired) stay; the script takes over.

UPDATE world.gameobject_template SET ScriptName = 'go_murloc_cage_43374' WHERE entry = 252158 AND ScriptName = '';
