-- #92 Dalaran (Broken Isles): no class hall messenger after the Legion intro (reported for a Priest, affects every class
-- except Paladin (fixed in #69) and Shaman (Thrall stands at Krasus' Landing, no summon)).
-- Same bug as #69: SpellArea::IsFitToRequirements applies a spell only when the quest_end status IS in quest_end_status,
-- so 74 (complete | incomplete | rewarded) summoned the messenger / showed the quest popup only AFTER the quest was taken,
-- never before. 1 = only while the quest is not taken yet.
-- Undo: undo_classhall_messengers_92.sql

-- First class hall quest, Dalaran area 7502 (messenger summon, or quest popup for Death Knight / Mage)
UPDATE world.spell_area SET quest_end_status = 1 WHERE area = 7502 AND quest_end_status = 74 AND (spell, quest_end, classmask) IN (
  (216443, 41052,    1),  -- Warrior: Eitrigg, A Desperate Plea
  (196908, 40384,    4),  -- Hunter: Snowfeather, Needs of the Hunters
  (201208, 40832,    8),  -- Rogue: Ravenholdt Courier, Call of The Uncrowned
  (226409, 40705,   16),  -- Priest: Hooded Priestess, Priestly Matters
  (200023, 40714,   32),  -- Death Knight: quest popup, The Call To War
  (195356, 41035,  128),  -- Mage: quest popup, Felstorm's Plea
  (204860, 40716,  256),  -- Warlock: Ritssyn Flamescowl, The Sixth
  (193978, 12103,  512),  -- Monk: Initiate Da-Nel, Before the Storm
  (199277, 40643, 1024),  -- Druid: Archdruid Hamuul Runetotem, A Summons From Moonglade
  (195286, 39047, 2048)); -- Demon Hunter: Kor'vas Bloodthorn, Call of the Illidari

-- Later class hall step, area 7581 (like Justicar Julia Celeste 224350 in #69): the messenger comes after quest_start is
-- rewarded and should stop once quest_end is taken, not start then.
UPDATE world.spell_area SET quest_end_status = 1 WHERE area = 7581 AND quest_start_status = 64 AND quest_end_status = 74 AND (spell, quest_end, classmask) IN (
  (224250, 42597,    1),  -- Warrior: Danica the Reclaimer, Odyn's Summons
  (224263, 44090,    4),  -- Hunter: Snowfeather, Pledge of Loyalty
  (224286, 43007,    8),  -- Rogue: Valeera Sanguinar, Return to the Chamber of Shadows
  (224339, 44100,   16),  -- Priest: Hooded Priest, Proper Introductions
  (227342, 44550,   32),  -- Death Knight: Dread Commander Thalanor, Called to Acherus
  (227324, 44544,   64),  -- Shaman: Mackay Firebeard, Call of the Earthen Ring
  (224338, 44099,  256),  -- Warlock: Black Harvest Acolyte, A Mutual Friend
  (224344, 42186,  512),  -- Monk: Initiate Da-Nel, Growing Power
  (224335, 42516, 1024),  -- Druid: Archdruid Hamuul Runetotem, Growing Power
  (224244, 42666, 2048)); -- Demon Hunter: Asha Ravensong, Return to the Fel Hammer

-- Priest messenger 101344 had no "just summoned" script: she stood where she spawned, visible to everyone, and never
-- despawned (a new one on every entry). Give her the Paladin messenger's behaviour (92909): follow the player, personal
-- visibility, despawn after 60 s, and 5 s after the quest is accepted (row 0 already links to id 1).
DELETE FROM world.smart_scripts WHERE entryorguid = 101344 AND source_type = 0 AND id IN (1, 2, 3, 4);
INSERT INTO world.smart_scripts (entryorguid, source_type, id, link, event_type, event_param1, action_type, action_param1, target_type, comment) VALUES
(101344, 0, 1, 0, 61, 0, 41,  5000, 1, 'Hooded Priestess - Link - Despawn (#92)'),
(101344, 0, 2, 3, 54, 0, 29,     0, 7, 'Hooded Priestess - Just Summoned - Follow Invoker (#92)'),
(101344, 0, 3, 4, 61, 0, 207,    0, 7, 'Hooded Priestess - Link - Set Personal Invis (#92)'),
(101344, 0, 4, 0, 61, 0, 41, 60000, 1, 'Hooded Priestess - Link - Despawn (#92)');

-- Warrior messenger Eitrigg 93775 reacted to the Warlock quest 40716 instead of his own 41052 (no thanks / 5 s despawn).
UPDATE world.smart_scripts SET event_param1 = 41052 WHERE entryorguid = 93775 AND source_type = 0 AND id = 2 AND event_type = 19 AND event_param1 = 40716;
