-- Shadowy Insight (talent 21755, spell 162452 -> buff 124430): the buff now resets Mind Blast's cooldown when it is
-- applied (spell_pri_shadowy_insight in spell_priest.cpp); before, a proc only made the next Mind Blast instant while
-- Mind Blast stayed on cooldown. Needs the build with the script and a restart. Undo: undo_shadowy_insight.sql
DELETE FROM world.spell_script_names WHERE spell_id = 124430 AND ScriptName = 'spell_pri_shadowy_insight';
INSERT INTO world.spell_script_names (spell_id, ScriptName) VALUES (124430, 'spell_pri_shadowy_insight');
-- 8092 Mind Blast named a script that doesn't exist (spell_pri_mind_blast, an error line at every startup)
DELETE FROM world.spell_script_names WHERE spell_id = 8092 AND ScriptName = 'spell_pri_mind_blast';
