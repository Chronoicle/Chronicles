-- #50 retest (Claude, dev-owner): Sharpen Blade's Mortal Strike (198819, -50 % healing for 4 s) did not replace Mortal Wounds
-- (115804, -25 %) when the target still had it from an earlier Mortal Strike, so both were on the target. On hit, 198819 now
-- removes Mortal Wounds from the target (spell_linked_spell type 1 ON_HIT, negative effect = remove; the hit unit is the
-- default unit for ON_HIT links). The earlier fix (no new Mortal Wounds while Sharpen Blade is up) stays.
DELETE FROM world.spell_linked_spell WHERE spell_trigger = 198819 AND spell_effect = -115804;
INSERT INTO world.spell_linked_spell (spell_trigger, spell_effect, type, caster, target, hastype, hastalent, hasparam, hastype2, hastalent2, hasparam2, chance, cooldown, duration, hitmask, removeMask, effectMask, targetCountType, targetCount, actiontype, `group`, param, randList, comment)
VALUES (198819, -115804, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, '', 'Sharpen Blade Mortal Strike replaces Mortal Wounds (#50)');
