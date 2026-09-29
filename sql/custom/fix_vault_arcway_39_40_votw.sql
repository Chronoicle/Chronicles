-- Vault of the Wardens (map 1493), issue #39 (reporter gabrielf03d). Desktop team (Claude subagent) 2026-09-30.
-- Apply right before a worldserver restart (no .reload). Undo: undo_vault_arcway_39_40_votw.sql (before-state checked on live).
-- Goes with the #39 C++ (worldserver build): SpellMgr.cpp (Torment 202635 split damage), instance_vault_of_the_wardens.cpp
-- (corridor statue keeps its light), boss_tirathon_saltheril.cpp (Glayvianna Swoop). Without the build the SQL is harmless.
-- Timers marked "estimate" have no retail log behind them.

-- 1) Fel-Infused Fury 99956 (2 spawns on the path to Glayvianna) had no AI: the default AI never cast Metamorphosis 196787
--    or Unleash Fury 196799. Retail (guides, GuabinaCore #2946): Metamorphosis at 50% health (+50% damage), Unleash Fury from
--    20% health (5 s cast, fire damage to the whole party: stun, interrupt or kill it). Both casts interrupt a running Fel Gaze
--    so the one-time Metamorphosis is never lost. Fel Gaze stays a frontal beam: its sniffed areatrigger 5283 is a 35 x 3 yd
--    polygon in front of the caster, not a circle. That areatrigger had no action, so the beam hit nobody: an enemy entering
--    it now takes Fel Gaze 196797. (No knockback: the client spell has no knockback effect.)
UPDATE world.creature_template SET AIName = 'SmartAI' WHERE entry = 99956 AND AIName = '' AND ScriptName = '';
DELETE FROM world.smart_scripts WHERE entryorguid = 99956 AND source_type = 0;
INSERT INTO world.smart_scripts (entryorguid, source_type, id, link, Difficulties, event_type, event_phase_mask, event_chance,
 event_flags, event_param1, event_param2, event_param3, event_param4, event_param5, action_type, action_param1, action_param2,
 action_param3, action_param4, action_param5, action_param6, target_type, target_param1, target_param2, target_param3,
 target_param4, target_x, target_y, target_z, target_o, comment) VALUES
(99956, 0, 0, 0, '', 0, 0, 100, 0, 5000, 7000, 13000, 16000, 0, 11, 196796, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Fel-Infused Fury - IC - cast Fel Gaze (timer estimate) #39'),
(99956, 0, 1, 0, '', 2, 0, 100, 1, 0, 50, 0, 0, 0, 11, 196787, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Fel-Infused Fury - HP below 50% - cast Metamorphosis (once) #39'),
(99956, 0, 2, 0, '', 2, 0, 100, 0, 0, 20, 10000, 12000, 0, 11, 196799, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Fel-Infused Fury - HP below 20% - cast Unleash Fury (recast after a kick) #39');
DELETE FROM world.areatrigger_actions WHERE entry = 5283 AND customEntry = 0;
INSERT INTO world.areatrigger_actions (entry, customEntry, id, moment, actionType, targetFlags, spellId, comment) VALUES
(5283, 0, 0, 1, 0, 4096, 196797, 'Fel-Infused Fury Fel Gaze beam: enemy enters -> Fel Gaze damage 196797 #39');

-- 2) Grimhorn the Enslaver 102566: Torment rooted the player but had no cage, no beam and no damage. Client data chain:
--    Imprison 202614 (one random enemy) -> Torment 202615 (6 s root, kept from affe7ba) + Imprisonment 202622 = summon Cage
--    102572 at the victim (9 s). The cage casts Jailer's Cage 202621 (cage visual); its effect 2 force-casts Torment 202634 on
--    the cage's summoner: Grimhorn channels 202634 at the cage for 6 s (the beam from his hand), which every second deals
--    Torment 202635 fire damage divided among all players within 5 yd of the cage (the split is the SpellMgr.cpp change;
--    guides: stand with the imprisoned player to share the damage). 202634 picks its target by entry: condition = the Cage.
DELETE FROM world.smart_scripts WHERE entryorguid = 102566 AND source_type = 0 AND id = 3;
INSERT INTO world.smart_scripts (entryorguid, source_type, id, link, Difficulties, event_type, event_phase_mask, event_chance,
 event_flags, event_param1, event_param2, event_param3, event_param4, event_param5, action_type, action_param1, action_param2,
 action_param3, action_param4, action_param5, action_param6, target_type, target_param1, target_param2, target_param3,
 target_param4, target_x, target_y, target_z, target_o, comment) VALUES
(102566, 0, 3, 0, '', 31, 0, 100, 0, 202614, 0, 0, 0, 0, 11, 202622, 2, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Grimhorn the Enslaver - Imprison hit player - summon Cage (Imprisonment) #39');
UPDATE world.creature_template SET AIName = 'SmartAI' WHERE entry = 102572 AND AIName = '' AND ScriptName = '';
DELETE FROM world.smart_scripts WHERE entryorguid = 102572 AND source_type = 0;
INSERT INTO world.smart_scripts (entryorguid, source_type, id, link, Difficulties, event_type, event_phase_mask, event_chance,
 event_flags, event_param1, event_param2, event_param3, event_param4, event_param5, action_type, action_param1, action_param2,
 action_param3, action_param4, action_param5, action_param6, target_type, target_param1, target_param2, target_param3,
 target_param4, target_x, target_y, target_z, target_o, comment) VALUES
(102572, 0, 0, 0, '', 54, 0, 100, 0, 0, 0, 0, 0, 0, 11, 202621, 2, 0, 0, 0, 0, 23, 0, 0, 0, 0, 0, 0, 0, 0, 'Cage (Grimhorn) - just summoned - cast Jailer''s Cage at summoner (he channels Torment) #39');
DELETE FROM world.conditions WHERE SourceTypeOrReferenceId = 13 AND SourceEntry = 202634;
INSERT INTO world.conditions (SourceTypeOrReferenceId, SourceGroup, SourceEntry, SourceId, ElseGroup, ConditionTypeOrReference,
 ConditionTarget, ConditionValue1, ConditionValue2, ConditionValue3, NegativeCondition, ErrorTextId, ScriptName, Comment) VALUES
(13, 1, 202634, 0, 0, 31, 0, 3, 102572, 0, 0, 0, '', 'Grimhorn Torment channel: only on his Cage #39');

-- 3) Grimhorn stood 22 yd behind the Demon Ward's north door (Tormentorum door 246112, y -366.9), out of reach until
--    Tormentorum died. Reporter + wiki ("at a doorway before the Fallen Passage"): in front of the door. Moved ~3.6 yd in
--    front of the door plane on the ward's ring (z of the ring floor), facing into the ward. Kept that close to the door so
--    he stays ~23 yd from Tormentorum's spawn (4450.8, -393.6) and is not pulled into that fight.
UPDATE world.creature SET position_x = 4450.8, position_y = -370.5, position_z = 126.08, orientation = 4.71239 WHERE guid = 14507265 AND id = 102566;

-- 4) Vault of the Betrayer: the corridor's Glowing Sentry (by the elevator, 4482.6 -334.1 -240.3) only existed as a
--    temporary summon of Cordana's reset group ~450 yd away (gone once its grid unloaded) and Cordana's reset took its light
--    away right after summoning it (fixed in instance_vault_of_the_wardens.cpp), so it was dark and could not be clicked.
--    Now a normal spawn at the same spot (lit by its script: statues above z -270 start lit; click = Elune's Light 192656);
--    its summon-group row is removed so it does not appear twice. Cordana's four room statues are unchanged.
DELETE FROM world.creature_summon_groups WHERE summonerId = 95888 AND summonerType = 0 AND id = 1 AND entry = 100525;
DELETE FROM world.creature WHERE guid = 146907099;
INSERT INTO world.creature (guid, id, map, zoneId, areaId, spawnMask, phaseMask, PhaseId, modelid, equipment_id, position_x,
 position_y, position_z, orientation, spawntimesecs, spawndist, currentwaypoint, curhealth, curmana, MovementType, npcflag,
 npcflag2, unit_flags, dynamicflags, AiID, MovementID, MeleeID, isActive, skipClone, personal_size, isTeemingSpawn, unit_flags3)
VALUES (146907099, 100525, 1493, 7787, 7787, 8388870, 1, '', 0, 0, 4482.64, -334.073, -240.317, 2.41779, 7200, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
