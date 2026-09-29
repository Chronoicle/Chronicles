-- #93 (gabrielf03d, Claude 2026-09-29): engineering in Legion Dalaran.
-- Undo: undo_engineering_93.sql
--
-- 1) Endless Possibilities (40854): Fel Reaver Husk (gameobject 246519, chest) has chest loot id Data1 = 0, so it
--    opens empty (and despawns). Its loot rows exist under gameobject_loot_template 246519 (item 133752, quest-only).
UPDATE world.gameobject_template SET Data1 = 246519 WHERE entry = 246519 AND Data1 = 0;
--
-- 2) Engineering auction house: Reginald Arcfire <Steam-Powered Auctioneer> (35607, next to Lympkin in Like Clockwork).
--    Menu 10656's only option was OptionNpc 6 (Banker) with no text; the core hides a Banker option on an NPC without
--    the banker npcflag (he has gossip + auctioneer), so engineers only saw the text. Now OptionNpc 10 (Auctioneer).
--    The skill condition (conditions 15/10656: Engineering >= 1) is unchanged.
UPDATE world.gossip_menu_option SET OptionNpc = 10, OptionText = 'I would like to browse the auctions.'
WHERE MenuID = 10656 AND OptionID = 0;
--
-- 3) Auctioneer Lympkin (9859) is the Ironforge auctioneer (faction 55, Alliance); the Dalaran spawn 146850828 is a
--    stray copy standing 3 yards from Reginald (not on retail). Her template faction must stay Alliance for Ironforge,
--    and this core has no per-spawn faction, so the fix is removing the stray spawn.
--    Owner approved the deletion 2026-09-29 (#93).
DELETE FROM world.creature WHERE guid = 146850828 AND id = 9859 AND map = 1220;
