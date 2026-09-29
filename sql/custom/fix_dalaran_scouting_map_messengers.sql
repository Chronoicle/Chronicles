-- #92 follow-up (gabrielf03d, Dalaran): class hall messengers chase you through Dalaran, also after you have their quest.
-- Undo: undo_dalaran_scouting_map_messengers.sql
-- Main cause is in the core (Player.cpp HasSpellAreaSpell): spell_area only skipped a spell the player already had as an
-- aura, so pure summon spells (Eitrigg, Snowfeather, Ravenholdt Courier, Hooded Priestess, Da-Nel, Kor'vas, Danica, Valeera,
-- Asha, Lord Maxwell Tyrosus) summoned one more messenger on every zone/area update in Dalaran; the extra ones kept following
-- after the quest was taken from one of them. This file is the DB part.
-- Scouting map (same report): no change. The 7.3.5 client data (AdventureMapPOI 3/4/6/7/8 -> PlayerCondition 39935-39939 ->
-- ModifierTree 33003/33010/45204/46311) hides every zone while you are on another zone's map quest (39718/39731/39733/
-- 39735/39864), like the core's one-adventure-quest-at-a-time rule; turning it in opens the other zones again.
SET NAMES utf8mb4;

-- 1) Demon Hunter, Kor'vas Bloodthorn (99343) offers two "Call of the Illidari" quests (39047 and 39261). The summon row and
--    her quest-accept script only knew 39047, so after taking 39261 she was summoned again on every visit and never left.
--    quest_start 39261 with status 1 = 39261 must not be taken either. Her script also said the two lines swapped (group 1
--    "I need to speak with you" after accepting, group 0 "Kayn and the others ... see you there" on arrival).
UPDATE world.spell_area SET quest_start = 39261, quest_start_status = 1
WHERE spell = 195286 AND area = 7502 AND quest_start = 0 AND quest_start_status = 0 AND quest_end = 39047;
UPDATE world.smart_scripts SET event_param1 = 0, action_param1 = 0
WHERE entryorguid = 99343 AND source_type = 0 AND id = 2 AND event_type = 19 AND event_param1 = 39047 AND action_type = 1 AND action_param1 = 1;
UPDATE world.smart_scripts SET action_param1 = 1
WHERE entryorguid = 99343 AND source_type = 0 AND id = 1 AND event_type = 61 AND action_type = 1 AND action_param1 = 0;

-- 2) The later messengers in Dalaran City (area 7581) come once the level 98 class hall quest (quest_start) is done, but
--    their own quest needs level 101: at 98-100 they followed you around with a quest you could not take, again on every
--    visit. Summon only from level 101 (CONDITION_LEVEL >= 101 on the summon spell).
DELETE FROM world.conditions WHERE SourceTypeOrReferenceId = 17 AND ConditionTypeOrReference = 27
AND SourceEntry IN (224250, 224350, 224263, 224286, 224339, 227342, 227324, 224338, 224344, 224335, 224244);
INSERT INTO world.conditions (SourceTypeOrReferenceId, SourceGroup, SourceEntry, SourceId, ElseGroup, ConditionTypeOrReference, ConditionTarget, ConditionValue1, ConditionValue2, ConditionValue3, NegativeCondition, ErrorTextId, ScriptName, Comment) VALUES
(17, 0, 224250, 0, 0, 27, 0, 101, 3, 0, 0, 0, '', 'Warrior messenger Danica (Odyn''s Summons 42597) only from level 101 (#92)'),
(17, 0, 224350, 0, 0, 27, 0, 101, 3, 0, 0, 0, '', 'Paladin messenger Julia Celeste (Growing Power 42844) only from level 101 (#92)'),
(17, 0, 224263, 0, 0, 27, 0, 101, 3, 0, 0, 0, '', 'Hunter messenger Snowfeather (Pledge of Loyalty 44090) only from level 101 (#92)'),
(17, 0, 224286, 0, 0, 27, 0, 101, 3, 0, 0, 0, '', 'Rogue messenger Valeera (Return to the Chamber of Shadows 43007) only from level 101 (#92)'),
(17, 0, 224339, 0, 0, 27, 0, 101, 3, 0, 0, 0, '', 'Priest messenger Hooded Priest (Proper Introductions 44100) only from level 101 (#92)'),
(17, 0, 227342, 0, 0, 27, 0, 101, 3, 0, 0, 0, '', 'Death Knight messenger Thalanor (Called to Acherus 44550) only from level 101 (#92)'),
(17, 0, 227324, 0, 0, 27, 0, 101, 3, 0, 0, 0, '', 'Shaman messenger Mackay Firebeard (Call of the Earthen Ring 44544) only from level 101 (#92)'),
(17, 0, 224338, 0, 0, 27, 0, 101, 3, 0, 0, 0, '', 'Warlock messenger Black Harvest Acolyte (A Mutual Friend 44099) only from level 101 (#92)'),
(17, 0, 224344, 0, 0, 27, 0, 101, 3, 0, 0, 0, '', 'Monk messenger Da-Nel (Growing Power 42186) only from level 101 (#92)'),
(17, 0, 224335, 0, 0, 27, 0, 101, 3, 0, 0, 0, '', 'Druid messenger Hamuul (Growing Power 42516) only from level 101 (#92)'),
(17, 0, 224244, 0, 0, 27, 0, 101, 3, 0, 0, 0, '', 'Demon Hunter messenger Asha Ravensong (Return to the Fel Hammer 42666) only from level 101 (#92)');
