-- The Arcway (map 1516) trash, issue #40 (reporter gabrielf03d). Claude 2026-09-29.
-- Undo: undo_arcway_trash_40.sql (before-state checked 2026-09-29).
-- Spells come from each creature's own creature_template_spell rows (sniffed list). Creatures with SmartAI ignore that
-- list, so the Mythic-only spells (mask 4 there) were never cast. New SmartAI timers are estimates (no sniff timers).

-- 1) Withered Corpse 105493 (31 decorative corpses) was selectable/attackable with a health bar (unit_flags 0).
--    Same flags as its twin entry 102541 "Withered Corpse" and the other Arcway corpses (not selectable, immune).
UPDATE world.creature_template SET unit_flags = 570721024 WHERE entry = 105493;

-- 2) Warp Shade 106059: Arcane Reconstitution 226206 (2 s cast, heals 100%) on Mythic / Mythic Keystone, below 50% health.
DELETE FROM world.smart_scripts WHERE entryorguid IN (106059, 98756) AND source_type = 0 AND id = 2;
DELETE FROM world.smart_scripts WHERE entryorguid = 105682 AND source_type = 0 AND id = 2;
INSERT INTO world.smart_scripts (entryorguid, source_type, id, link, Difficulties, event_type, event_phase_mask, event_chance,
 event_flags, event_param1, event_param2, event_param3, event_param4, event_param5, action_type, action_param1, action_param2,
 action_param3, action_param4, action_param5, action_param6, target_type, target_param1, target_param2, target_param3,
 target_param4, target_x, target_y, target_z, target_o, comment) VALUES
(106059, 0, 2, 0, '8,23', 2, 0, 100, 0, 0, 50, 15000, 20000, 0, 11, 226206, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Warp Shade - HP below 50% - cast Arcane Reconstitution (Mythic) #40'),
-- 3) Arcane Anomaly 98756: same Arcane Reconstitution.
(98756, 0, 2, 0, '8,23', 2, 0, 100, 0, 0, 50, 15000, 20000, 0, 11, 226206, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Arcane Anomaly - HP below 50% - cast Arcane Reconstitution (Mythic) #40'),
-- 4) Felguard Destroyer 105682: Mortal Strike 16856 (in its spell list, never cast).
(105682, 0, 2, 0, '', 0, 0, 100, 0, 5000, 8000, 10000, 14000, 0, 11, 16856, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Felguard Destroyer - IC - cast Mortal Strike #40');

-- 5) Arcane Anomaly: Arcane Slicer 211217 targets the spot in front of the caster (dest caster front), but SmartAI cast it
--    on the victim, so the caster focused the player and snapped to face it when the cast finished (Spell::cast SetInFront).
--    Cast on self: the line goes where the anomaly faced when the cast started.
UPDATE world.smart_scripts SET target_type = 1 WHERE entryorguid = 98756 AND source_type = 0 AND id = 0 AND action_param1 = 211217;

-- 6) Priestess of Misery 105706 (default AI casts Felstorm 211917 from its spell list): 211917 ticks 211933, a dummy on
--    enemies within 23 yd whose value is 211919 (Felstorm missile -> 211921 damage), but nothing handled the dummy.
DELETE FROM world.spell_dummy_trigger WHERE spell_id = 211933 AND spell_trigger = 211919;
INSERT INTO world.spell_dummy_trigger (spell_id, spell_trigger, `option`, target, caster, targetaura, bp0, bp1, bp2, effectmask, handlemask, aura, `group`, comment)
VALUES (211933, 211919, 6, 0, 0, 0, 0, 0, 0, 1, 8, 0, 0, 'Arcway Priestess of Misery Felstorm: dummy hit -> Felstorm missile at each enemy #40');
