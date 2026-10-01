-- #141 Warrior class hall, Skyhold (gabrielf03d): Danica the Reclaimer and Odyn spoke Russian, Odyn and the Valarjar
-- (39654) showed only a silver "!". Undo: undo_skyhold_danica_odyn_141.sql. Live with a worldserver restart (no .reload).
SET NAMES utf8mb4;

-- 1) Odyn and the Valarjar needed level 100 while the rest of the chain is 98 (the scenario quests 41052/38904 and
--    42814/42815 before it, Weapons of Legend 40579 after it). A 98/99 warrior coming out of the intro scenario got the
--    grey "!" (quest too high level) and Danica had nothing to offer.
UPDATE world.quest_template SET MinLevel = 98 WHERE ID = 39654 AND MinLevel = 100;

-- 2) Danica's lines (quest reward 38904, then the walk to Odyn) had a machine-English and a Russian copy, both without a
--    BroadcastTextID, picked at random. One row each with the client's English broadcast text (it also brings her voice).
DELETE FROM world.creature_text WHERE CreatureID = 93823 AND GroupID IN (0, 1, 3);
INSERT INTO world.creature_text (CreatureID, GroupID, ID, Text, Type, Language, Probability, Emote, Duration, Sound, BroadcastTextID, MinTimer, MaxTimer, SpellID, comment) VALUES
(93823, 0, 0, 'Welcome to Skyhold! Here the brave live on forever!', 12, 0, 100, 0, 0, 0, 98601, 0, 0, 0, 'Danica the Reclaimer to Player'),
(93823, 1, 0, 'Behind you lies the Eye of Odyn, which peers across all of Azeroth! This way lies the Forge, where the mightiest weapons of the valarjar are crafted by Helgar, the greatest smith in the Halls.', 12, 0, 100, 0, 0, 0, 98370, 0, 0, 0, 'Danica the Reclaimer to Player'),
(93823, 3, 0, 'Odyn awaits ahead. I will go forth and announce you. Be respectful!', 12, 0, 100, 0, 0, 0, 98372, 0, 0, 0, 'Danica the Reclaimer to Player');

-- 3) Odyn's "review weapons" gossip option (after Weapons of Legend) was Russian with no broadcast text; the other class
--    hall leaders use broadcast text 102658 for the same line.
UPDATE world.gossip_menu_option SET OptionText = 'I would like to review weapons we might pursue.', OptionBroadcastTextID = 102658
WHERE MenuID = 19091 AND OptionID = 0 AND OptionBroadcastTextID = 0;

-- 4) The Hunter of Heroes (40043, turned in at Odyn): the progress text was Russian and has no enUS locale row.
UPDATE world.quest_request_items SET CompletionText = 'Ah, you have returned...' WHERE ID = 40043;
