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
