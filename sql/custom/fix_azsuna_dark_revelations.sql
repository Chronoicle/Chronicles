-- #122 (gabrielf03d, approved reporter; Claude desktop team subagent, 2026-10-02): Azsuna, Dark Revelations (37449).
-- "Kor'vas disappears when you reach the quest area, and Nightglaive the Traitor stands in one spot and doesn't run
-- to attack you." Undo: sql/custom/undo_azsuna_dark_revelations.sql. Live with a worldserver restart (no .reload).
--
-- Retail: when you accept the quest, Kor'vas says "I have to find Stellagosa and Cyana Nightglaive." / "Meet me up at
-- the overlook. We will finish this business together." and leaves. At Traitor's Overlook (area 7497) Cordana Felsong
-- talks, orders Nightglaive to attack, leaves, and Nightglaive rushes you. Kor'vas arrives on Stellagosa (90623, her
-- rider 90624), and afterwards you ride back with them.

-- 1) Kor'vas left without a word. The follower 90474 comes from "Faronaar: Summon Kor'vas Bloodthorn" 178860, which
--    only works inside Faronaar's area group 4243; Traitor's Overlook is not in it, so she was unsummoned on arrival.
--    Now she says her two retail lines (BroadcastText 93018 / 93019) when you accept the quest and leaves.
DELETE FROM world.smart_scripts WHERE entryorguid = 90474 AND source_type = 0 AND id = 1;
DELETE FROM world.smart_scripts WHERE entryorguid = 9047400 AND source_type = 9;
INSERT INTO world.smart_scripts (entryorguid, source_type, id, link, Difficulties, event_type, event_phase_mask, event_chance, event_flags, event_param1, event_param2, event_param3, event_param4, event_param5, action_type, action_param1, action_param2, action_param3, action_param4, action_param5, action_param6, target_type, target_param1, target_param2, target_param3, target_param4, target_x, target_y, target_z, target_o, comment) VALUES
(90474, 0, 1, 0, '', 19, 0, 100, 0, 37449, 0, 0, 0, 0, 80, 9047400, 0, 2, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Kor''vas Bloodthorn - On Quest Dark Revelations Accepted - Run Actionlist (#122)'),
(9047400, 9, 0, 0, '', 0, 0, 100, 0, 0, 0, 0, 0, 0, 1, 12, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Kor''vas Bloodthorn - Say: I have to find Stellagosa and Cyana (#122)'),
(9047400, 9, 1, 0, '', 0, 0, 100, 0, 4000, 4000, 0, 0, 0, 1, 13, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Kor''vas Bloodthorn - Say: Meet me up at the overlook (#122)'),
(9047400, 9, 2, 0, '', 0, 0, 100, 0, 4000, 4000, 0, 0, 0, 41, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Kor''vas Bloodthorn - Despawn (#122)');

--    The follower spell_area row (fixed in fix_azsuna_from_within.sql) summoned her again while Dark Revelations was
--    in progress (on entering Faronaar or logging in there). 9 (NONE|INCOMPLETE) -> 1 (NONE): she follows you from the
--    From Within turn-in until you accept Dark Revelations; during the quest she is at the overlook.
UPDATE world.spell_area SET quest_end_status = 1
WHERE spell = 178860 AND area = 0 AND quest_start = 36920 AND quest_end = 37449 AND quest_end_status = 9;

-- 2) No Kor'vas at the overlook either: Stellagosa there (90623, vehicle 4034) has her rider Kor'vas 90624 as a
--    vehicle accessory, but the core seats an accessory through the vehicle's spellclick spells (Vehicle::
--    InstallAccessory -> HandleSpellClick), and 90623 only has the player's 178923 "Summon Stellagosa Ride", which is
--    no ride spell (DBErrors: "Spell 178923 ... is not a valid vehicle enter aura!"). Kor'vas never got on her back and
--    stood hidden inside the dragon. Add the generic ride spell 46598 for the rider only (same pattern as 27587).
DELETE FROM world.npc_spellclick_spells WHERE npc_entry = 90623 AND spell_id = 46598;
INSERT INTO world.npc_spellclick_spells (npc_entry, spell_id, cast_flags, user_type, add_npc_flag) VALUES
(90623, 46598, 1, 0, 1);
DELETE FROM world.conditions WHERE SourceTypeOrReferenceId = 18 AND SourceGroup = 90623 AND SourceEntry IN (46598, 178923);
INSERT INTO world.conditions (SourceTypeOrReferenceId, SourceGroup, SourceEntry, SourceId, ElseGroup, ConditionTypeOrReference, ConditionTarget, ConditionValue1, ConditionValue2, ConditionValue3, NegativeCondition, ErrorTextId, ScriptName, Comment) VALUES
(18, 90623, 46598, 0, 0, 31, 0, 3, 90624, 0, 0, 0, '', 'Stellagosa (Traitor''s Overlook): only her rider Kor''vas boards with the ride spell, players get the ride summon'),
(18, 90623, 178923, 0, 0, 31, 0, 4, 0, 0, 0, 0, '', 'Stellagosa (Traitor''s Overlook): the ride summon only for players (her rider would log a not-a-vehicle-aura error, dev-check)');

-- 3) Nightglaive (90621) stood still: she is protected (unit flags + Fel Protection 148951) until Cordana's scene, and
--    at its end she only attacked a player within 10 yd of herself. The scene starts when a hostile quest holder is
--    within 3 yd of Cordana (90622), who stands ~14 yd from her, so nobody was in range and she just stood there.
--    Now she attacks the closest player within 40 yd (target 21), and Cordana starts the scene when you arrive
--    (20 yd instead of 3; it still needs line of sight and the quest).
UPDATE world.smart_scripts SET target_type = 21, target_param1 = 40, comment = 'Nightglaive the Traitor - Attack closest player within 40 yd (#122)'
WHERE entryorguid = 9062100 AND source_type = 9 AND id = 3 AND action_type = 49 AND target_type = 18 AND target_param1 = 10;
UPDATE world.smart_scripts SET event_param2 = 20
WHERE entryorguid = 90622 AND source_type = 0 AND id = 0 AND event_type = 10 AND event_param2 = 3;
