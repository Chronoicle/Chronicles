-- Undo for fix_murloc_cage_158.sql (#158): the Murloc Cage had no ScriptName before (2026-10-02).
UPDATE world.gameobject_template SET ScriptName = '' WHERE entry = 252158 AND ScriptName = 'go_murloc_cage_43374';
