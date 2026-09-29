-- #40 The Arcway, Ivanyr: Nether Link (Pi team, Claude)
-- 196804 links 3 players (196805, 5 s); when the links expire, 196806 creates areatrigger 5285 (customEntry 10007,
-- polygon) between them; players inside get 196824 (periodic damage from the client data), removed on leave/despawn.
-- Before: no spell_script_names for 196804/196805, no areatrigger_scripts row 10007, no areatrigger_actions for 5285.
DELETE FROM world.spell_script_names WHERE spell_id IN (196804, 196805);
INSERT INTO world.spell_script_names (spell_id, ScriptName) VALUES
(196804, 'spell_ivanyr_nether_link'),
(196805, 'spell_ivanyr_nether_link_aura');

DELETE FROM world.areatrigger_scripts WHERE entry = 10007;
INSERT INTO world.areatrigger_scripts (entry, ScriptName) VALUES (10007, 'at_ivanyr_nether_link');

DELETE FROM world.areatrigger_actions WHERE entry = 5285 AND customEntry = 0;
INSERT INTO world.areatrigger_actions (entry, customEntry, id, moment, actionType, targetFlags, spellId, comment) VALUES
(5285, 0, 0, 1, 0, 4096, 196824, 'Ivanyr - Nether Link: enter = damage aura (#40)'),
(5285, 0, 1, 42, 1, 8, 196824, 'Ivanyr - Nether Link: leave/despawn/remove = remove damage aura (#40)');
