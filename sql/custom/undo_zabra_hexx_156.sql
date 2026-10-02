-- Undo for fix_zabra_hexx_156.sql (#156): 110751 had no AI and no smart_scripts rows before the fix (2026-10-02).
UPDATE world.creature_template SET AIName = '' WHERE entry = 110751 AND AIName = 'SmartAI';
DELETE FROM world.smart_scripts WHERE entryorguid = 110751 AND source_type = 0 AND id IN (0, 1);
