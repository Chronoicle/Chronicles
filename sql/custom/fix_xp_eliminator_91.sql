-- #91 (James, Claude 2026-09-29): Experience Eliminators Slahtz (35364, Orgrimmar) and Behsten (35365, Stormwind).
-- Menu 10638 had one option with OptionNpc 0 (plain chat, no action) = clicking did nothing; Behsten had no gossip menu.
-- The core already toggles PLAYER_FLAGS_NO_XP_GAIN for OptionNpc 16 (DisableXPGain) / 17 (EnableXPGain), shows only the
-- option that fits the player's current state, and takes BoxMoney. Retail cost 10 gold each way.
-- Undo: undo_xp_eliminator_91.sql
UPDATE world.gossip_menu_option SET OptionNpc = 16, BoxMoney = 100000,
       BoxText = 'Are you certain you wish to stop gaining experience?'
WHERE MenuID = 10638 AND OptionID = 0;
DELETE FROM world.gossip_menu_option WHERE MenuID = 10638 AND OptionID = 1;
INSERT INTO world.gossip_menu_option (MenuID, OptionID, OptionNpc, OptionText, OptionBroadcastTextID, ActionMenuID,
       ActionPoiID, BoxCoded, BoxMoney, BoxText, BoxBroadcastTextID, VerifiedBuild)
VALUES (10638, 1, 17, 'I wish to start gaining experience again.', 0, 0, 0, 0, 100000,
       'Are you certain you wish to start gaining experience again?', 0, 0);
UPDATE world.creature_template SET gossip_menu_id = 10638 WHERE entry = 35365;
