-- Undo fix_posthaste.sql
DELETE FROM world.spell_linked_spell WHERE spell_trigger = 781 AND spell_effect = 118922;
