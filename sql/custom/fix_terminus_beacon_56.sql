-- #56 (Pi team / Claude 2026-09-29): Terminus Signaling Beacon (item 151969, on use 255724 Legion Bombardment) never
-- dealt damage: areatrigger 11885 (created at the target by 253248) had no rows and the Legion Cruiser 129063 (255713,
-- 9 s) had no creature_template.
-- Retail behaviour (SimulationCraft legion_bombardment_t): 6 pulses of 257376 ~1 s apart, each hits every enemy within
-- 12 yd for the full amount of 256325 effect 0 (item-scaled; the trinket's equip aura). Implemented as: the areatrigger
-- (8 s, from 253248) casts 257376 at its own position every 1000 ms, 6 charges then it despawns; the amount is set by
-- spell_item_terminus_legion_bombardment (spell_item.cpp) from the caster's 256325 aura.
-- Deviations (ponytail): the first pulse lands on creation, not after the ship's 2 s travel time; the retail
-- "point-blank use = only 3 pulses" rule is not implemented. Haste shortens the pulse interval (253248 has
-- SPELL_ATTR5_HASTE_AFFECT_TICK_AND_CASTTIME) but the 6 charges cap the total.
-- The ship is decoration only: not selectable/attackable, faction 35. customEntry 1188500 = entry*100 (the DB's
-- convention for unknown ids, like 11772 -> 1177200). Undo: undo_terminus_beacon_56.sql (none of these rows existed).
DELETE FROM world.areatrigger_template WHERE entry = 11885;
INSERT INTO world.areatrigger_template (entry, spellId, customEntry, VisualID, Radius, RadiusTarget, comment)
VALUES (11885, 253248, 1188500, 253248, 12, 12, 'Legion Bombardment (Terminus Signaling Beacon, #56)');
DELETE FROM world.areatrigger_data WHERE entry = 11885;
INSERT INTO world.areatrigger_data (entry, spellId, customEntry, updateDelay)
VALUES (11885, 253248, 1188500, 1000);
DELETE FROM world.areatrigger_actions WHERE entry = 11885;
INSERT INTO world.areatrigger_actions (entry, customEntry, id, moment, actionType, targetFlags, spellId, maxCharges, comment)
VALUES (11885, 1188500, 0, 1024, 0, 32, 257376, 6, 'Legion Bombardment pulse at the AT position, 6 times (#56)');
DELETE FROM world.spell_script_names WHERE spell_id = 257376 AND ScriptName = 'spell_item_terminus_legion_bombardment';
INSERT INTO world.spell_script_names (spell_id, ScriptName) VALUES (257376, 'spell_item_terminus_legion_bombardment');
-- Legion Cruiser: copy of the Ravager summon row (76168), level 110, Legion health scaling, not selectable/attackable.
DELETE FROM world.creature_template WHERE entry = 129063;
CREATE TEMPORARY TABLE tmp_ct_56 AS SELECT * FROM world.creature_template WHERE entry = 76168;
UPDATE tmp_ct_56 SET entry = 129063, minlevel = 110, maxlevel = 110, HealthScalingExpansion = 6, unit_class = 1,
  unit_flags = 33555202, AIName = '', ScriptName = '';
INSERT INTO world.creature_template SELECT * FROM tmp_ct_56;
DROP TEMPORARY TABLE tmp_ct_56;
