-- #92 follow-up: the Dalaran class hall messengers spoke Russian (gabrielf03d). Undo: undo_classhall_messengers_english_92.sql
-- CreatureTextMgr sends the client's English BroadcastText when BroadcastTextID is set (Russian `Text` is then only a
-- fallback); these lines had BroadcastTextID 0 (or a wrong one), so the Russian `Text` went out as is. Checked all 20
-- messenger entries (spell_area 7502/7581 summons); the others already point at valid broadcast texts or say nothing.
-- IDs matched in hotfixes.broadcast_text (Text1 = female line; these speakers are female, Hamuul and Ritssyn male).
SET NAMES utf8mb4;

-- Demon Hunter, Kor'vas Bloodthorn: greeting had two random variants (machine English + Russian, both id 0) -> retail line
DELETE FROM world.creature_text WHERE CreatureID = 99343 AND GroupID = 1;
INSERT INTO world.creature_text (CreatureID, GroupID, ID, Text, Type, Language, Probability, Emote, Duration, Sound, BroadcastTextID, MinTimer, MaxTimer, SpellID, comment) VALUES
(99343, 1, 0, '$n, I need to speak with you.', 12, 0, 100, 0, 0, 0, 100926, 0, 0, 0, 'Kor''vas Bloodthorn to Player');

-- Druid, Archdruid Hamuul Runetotem: greeting
UPDATE world.creature_text SET Text = 'Greetings, $n. It is fortunate I found you. Your presence is requested at Moonglade.', BroadcastTextID = 103448
WHERE CreatureID = 101061 AND GroupID = 0 AND ID = 0 AND BroadcastTextID = 0;

-- Priest, Hooded Priestess: line after accepting Priestly Matters
UPDATE world.creature_text SET Text = 'Excellent, you can take the portal to Dalaran Crater and just fly north. He will be expecting you soon!', BroadcastTextID = 103669
WHERE CreatureID = 101344 AND GroupID = 0 AND ID = 0 AND BroadcastTextID = 0;

-- Rogue, Ravenholdt Courier: line after accepting (group 0) and greeting (group 1); group 2 "Farewell." already has 121070
UPDATE world.creature_text SET Text = 'This is for your eyes only. Once you''ve read it, destroy it.', BroadcastTextID = 104305
WHERE CreatureID = 102018 AND GroupID = 0 AND ID = 0 AND BroadcastTextID = 0;
UPDATE world.creature_text SET Text = '$p, a moment, please. I bear an urgent message for you.', BroadcastTextID = 104300
WHERE CreatureID = 102018 AND GroupID = 1 AND ID = 0 AND BroadcastTextID = 0;

-- Warlock, Ritssyn Flamescowl: pointed at Akazamzarak's line 105637 ("Let's keep the show moving!") and its sound 61694
UPDATE world.creature_text SET Text = 'Join us at the Circle of Wills in Dalaran''s underbelly, warlock. My portal will take you there directly. We will be waiting.', BroadcastTextID = 104179, Sound = 63919
WHERE CreatureID = 103506 AND GroupID = 0 AND ID = 0 AND BroadcastTextID = 105637;
