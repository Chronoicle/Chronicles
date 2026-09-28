-- Party bots (#65, owner report 2026-09-28): bots set up before the class hall talent fix were missing their second
-- legendary (one empty slot each). Setup runs again at their next login: talent first, then the gear set.
-- Undo: nothing to undo (setup only re-equips the set); to skip it: UPDATE characters.partybot_characters SET setup = 1 WHERE guid IN (46,47,48,49,67);
UPDATE characters.partybot_characters SET setup = 0 WHERE setup = 1;
