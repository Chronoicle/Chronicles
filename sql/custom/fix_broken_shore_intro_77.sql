-- #77 Broken Shore intro (James, Claude 2026-09-28). Undo: undo_broken_shore_intro_77.sql
-- Khadgar (120215) gossip option 0 was only stored in Russian with no broadcast text, so the client showed the Russian.
UPDATE world.gossip_menu_option SET OptionText = 'I''m ready to begin the attack.' WHERE MenuID = 20974 AND OptionID = 0;
-- Seamless Transfer 240161 put the player 30 yd above the edge of the Kirin Tor ship's deck, so they often fell past it
-- into the water. Now on the deck next to Khadgar and the Kirin Tor mages.
UPDATE world.spell_target_position SET target_position_x = -836.0, target_position_y = 4265.0, target_position_z = 746.6 WHERE id = 240161;
