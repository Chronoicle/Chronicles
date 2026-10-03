-- Claude (dev-owner) 2026-10-03, DH start audit (Mardum). Retail: Fel Secrets (40051) -> read the Tome of Fel Secrets,
-- choose a spec (player choice 231: 194939 Havoc -> tracking quest 39517, 194940 Vengeance -> tracking quest 39518)
-- -> Cry Havoc and Let Slip the Illidari! (39516, Havoc) or Vengeance Will Be Mine! (39515, Vengeance) -> On Felbat Wings.
-- Here 39515 had no prerequisite: Kayn offered it at once and every player so far skipped the middle of Mardum
-- (Orders for Your Captains .. Fel Secrets: 0 completions, while 3 players did On Felbat Wings).
UPDATE world.quest_template_addon SET PrevQuestID = 40051 WHERE ID = 39515;
DELETE FROM world.conditions WHERE SourceTypeOrReferenceId = 19 AND SourceEntry IN (39515, 39516) AND ConditionTypeOrReference = 8 AND ConditionValue1 IN (39517, 39518);
INSERT INTO world.conditions (SourceTypeOrReferenceId, SourceGroup, SourceEntry, SourceId, ElseGroup, ConditionTypeOrReference, ConditionTarget, ConditionValue1, ConditionValue2, ConditionValue3, NegativeCondition, ErrorTextId, ScriptName, Comment) VALUES
(19, 0, 39516, 0, 0, 8, 0, 39517, 0, 0, 0, 0, '', 'Cry Havoc: only after choosing Havoc in Fel Secrets'),
(19, 0, 39515, 0, 0, 8, 0, 39518, 0, 0, 0, 0, '', 'Vengeance Will Be Mine!: only after choosing Vengeance in Fel Secrets');
-- the choice switches the specialization like retail (mardum.cpp)
DELETE FROM world.spell_script_names WHERE spell_id IN (194939, 194940);
INSERT INTO world.spell_script_names (spell_id, ScriptName) VALUES (194939, 'spell_legion_fel_secrets_spec_choice'), (194940, 'spell_legion_fel_secrets_spec_choice');
