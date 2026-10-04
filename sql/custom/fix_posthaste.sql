-- Claude (dev-owner) 2026-10-04, owner request (missing class scripts): Posthaste (Hunter talent 109215). Disengage with the
-- talent already removes movement impairing effects (spell_linked_spell 781 -> 781 type 6 action 9); the speed buff 118922
-- (+60 % for 4 s) was never cast. Cast it on Disengage when the talent is known.
DELETE FROM world.spell_linked_spell WHERE spell_trigger = 781 AND spell_effect = 118922;
INSERT INTO world.spell_linked_spell (spell_trigger, spell_effect, type, caster, target, hastype, hastalent, hasparam, hastype2, hastalent2, hasparam2, chance, cooldown, duration, hitmask, removeMask, effectMask, targetCountType, targetCount, actiontype, `group`, param, randList, comment)
VALUES (781, 118922, 0, 0, 0, 0, 109215, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, '', 'Disengage - Posthaste speed (talent 109215)');
