-- Avenging Angel (500002): custom world boss, owner request 2026-09-27 (Claude).
-- Health (2 billion + 150 million per extra attacker), melee and spell damage are set in world_boss_avenging_angel.cpp.
-- Not spawned here. Undo: undo_world_boss_avenging_angel.sql
DELETE FROM world.creature_template WHERE entry = 500002;
INSERT INTO world.creature_template (entry, minlevel, maxlevel, HealthScalingExpansion, exp, faction, speed_walk, speed_run, scale,
    dmg_multiplier, baseattacktime, rangeattacktime, unit_class, unit_flags, unit_flags2, RegenHealth, mechanic_immune_mask, WorldEffects, PassiveSpells, ScriptName)
VALUES (500002, 113, 113, 6, 6, 14, 1, 1.14286, 3.5, 1, 2000, 2000, 1, 0, 2048, 1, 617299839, '', '', 'boss_avenging_angel');

DELETE FROM world.creature_template_wdb WHERE Entry = 500002;
INSERT INTO world.creature_template_wdb (Entry, Name1, Title, TypeFlags, Type, Classification, Displayid1, HpMulti, PowerMulti, RequiredExpansion, VerifiedBuild)
VALUES (500002, 'Avenging Angel', 'World Boss', 4, 7, 3, 35572, 1, 1, 0, 26972);

-- Monke (500003): Hyrja (114360, Trial of Valor) as the Avenging Angel's add, same look and weapons (owner request 2026-09-27).
-- Health, melee and spells (Expel Light, Shield of Light only) are set in world_boss_avenging_angel.cpp.
DELETE FROM world.creature_template WHERE entry = 500003;
INSERT INTO world.creature_template (entry, minlevel, maxlevel, HealthScalingExpansion, exp, faction, speed_walk, speed_run, scale,
    dmg_multiplier, baseattacktime, rangeattacktime, unit_class, unit_flags, unit_flags2, RegenHealth, mechanic_immune_mask, WorldEffects, PassiveSpells, ScriptName)
VALUES (500003, 113, 113, 6, 6, 14, 4.8, 1.71429, 1, 1, 1500, 2000, 1, 0, 2048, 1, 0, '', '', 'npc_avenging_angel_monke');

DELETE FROM world.creature_template_wdb WHERE Entry = 500003;
INSERT INTO world.creature_template_wdb (Entry, Name1, Title, TypeFlags, Type, Classification, Displayid1, HpMulti, PowerMulti, RequiredExpansion, VerifiedBuild)
VALUES (500003, 'Monke', '', 0, 7, 1, 65076, 1, 1, 0, 26972);

DELETE FROM world.creature_equip_template WHERE CreatureID = 500003;
INSERT INTO world.creature_equip_template (CreatureID, ID, ItemID1, ItemID3)
SELECT 500003, ID, ItemID1, ItemID3 FROM world.creature_equip_template WHERE CreatureID = 114360;

-- Expel Light 228029: the marked player blasts nearby allies (nothing linked the mark to the blast)
DELETE FROM world.spell_script_names WHERE spell_id = 228029 AND ScriptName = 'spell_avenging_angel_expel_light';
INSERT INTO world.spell_script_names (spell_id, ScriptName) VALUES (228029, 'spell_avenging_angel_expel_light');
