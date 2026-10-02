-- #156 (gabrielf03d, approved reporter; Claude desktop team subagent, 2026-10-02): Priest class hall, The Best and
-- Brightest (43373), "Find Zabra Hexx in Azsuna". Clicking the petrified Zabra Hexx (110751, guid 267939, the quest's
-- objective) casts Mass Dispel 223947 on him (npc_spellclick_spells), but nothing gave the credit or made him talk.
-- Undo: sql/custom/undo_zabra_hexx_156.sql. Live with a worldserver restart (no .reload).
--
-- 223947 is only a dummy effect (client data: effect 3 on target 25) and nothing handled it (no spell script, no
-- linked/dummy trigger, and 110751 had no AI). He now gets SmartAI: hit by 223947 -> objective credit 110751 for the
-- clicker, then his line 118831 ("It feels like these bones of mine haven't moved in years! Come, let's find some place
-- to talk where we won't be caught by a basilisk's gaze.", creature_text group 3, already in the DB). The quest is
-- turned in at the free Zabra Hexx (110686) nearby, as before. He stays where he is (one shared spawn), so the next
-- player can click him too.

UPDATE world.creature_template SET AIName = 'SmartAI' WHERE entry = 110751 AND AIName = '';

DELETE FROM world.smart_scripts WHERE entryorguid = 110751 AND source_type = 0 AND id IN (0, 1);
INSERT INTO world.smart_scripts (entryorguid, source_type, id, link, Difficulties, event_type, event_phase_mask, event_chance, event_flags,
  event_param1, event_param2, event_param3, event_param4, event_param5, action_type, action_param1, action_param2, action_param3,
  action_param4, action_param5, action_param6, target_type, target_param1, target_param2, target_param3, target_param4,
  target_x, target_y, target_z, target_o, comment) VALUES
(110751, 0, 0, 1, '', 8, 0, 100, 0, 223947, 0, 0, 0, 0, 33, 110751, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Zabra Hexx (petrified) - Spell Hit Mass Dispel - Quest Credit The Best and Brightest (#156)'),
(110751, 0, 1, 0, '', 61, 0, 100, 0, 0, 0, 0, 0, 0, 1, 3, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Zabra Hexx (petrified) - Link - Say Line 3 (#156)');
