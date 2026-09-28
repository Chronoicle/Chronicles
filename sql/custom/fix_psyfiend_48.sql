-- #48 (Claude 2026-09-28): Psyfiend 101398 (Shadow PvP talent 211522) was missing two retail changes the reporter listed:
-- 7.1.5 "Psyfiend can no longer be affected by Power Word: Shield": immune to the Shield mechanic (19 -> bit 1 << 18),
--       which is Power Word: Shield 17's mechanic.
-- 7.2.0 "Psyfiend can no longer be targeted by using target macros": UNIT_FLAG3_UNTARGETABLE_FROM_UI 0x8000
--       (client side: TargetUnit, StartAttack and PetAttack skip the unit; flag name from current TrinityCore).
-- Was 0 and 0. Undo: undo_psyfiend_48.sql
UPDATE world.creature_template SET mechanic_immune_mask = 262144, unit_flags3 = 32768 WHERE entry = 101398;
