-- Issue #151 (Mardum, Demon Hunter): "Vengeance Will Be Mine!" 39515 (and its twin 39516) stayed at "0/1 Kayn taught".
-- Allari, Cyana, Kor'vas and Mannethrel teach through SmartAI (gossip select -> cast their kill-credit spell). Kayn
-- Sunfury 93127 had no SmartAI rows: his C++ npc_93127 waited for gossip action 1 (the old OptionType), but the core
-- now passes the option's OptionNpc (0), so the click did nothing. The C++ handler is removed in the same commit.
-- Same rows as the siblings: menu 18435 option 1 -> cast 195020 (Kill Credit 93127 + scene) on the player, Kayn says
-- text group 3 (the line the C++ used). No rows existed for entry 93127 before (checked 2026-10-02); the DELETE only
-- makes the file re-runnable. Goes live with a worldserver restart. Undo: undo_kayn_vengeance_teach_151.sql
DELETE FROM world.smart_scripts WHERE entryorguid = 93127 AND source_type = 0 AND id IN (0, 1);
INSERT INTO world.smart_scripts (entryorguid, source_type, id, link, Difficulties, event_type, event_phase_mask, event_chance,
 event_flags, event_param1, event_param2, event_param3, event_param4, event_param5, action_type, action_param1, action_param2,
 action_param3, action_param4, action_param5, action_param6, target_type, target_param1, target_param2, target_param3,
 target_param4, target_x, target_y, target_z, target_o, comment) VALUES
(93127, 0, 0, 1, '', 62, 0, 100, 0, 18435, 1, 0, 0, 0, 11, 195020, 18, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'At gossip select Q39516 #151'),
(93127, 0, 1, 0, '', 61, 0, 100, 0, 0, 0, 0, 0, 0, 1, 3, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Kayn - linked - talk 3 #151');
