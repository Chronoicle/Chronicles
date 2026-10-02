-- Undo #153 (restores the row as it was on 2026-10-02; the C++ script stays compiled but unused).
UPDATE world.creature_template SET ScriptName = '' WHERE entry = 100333 AND ScriptName = 'npc_q38728_skittering_broodling';
