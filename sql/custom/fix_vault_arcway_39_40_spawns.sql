-- Spawn removals for #39 / #40. Desktop team (Claude subagent) 2026-09-30. DELETES 7 creature spawns: apply only with the
-- owner's OK (AGENTS.md: ask before deleting data), right before a worldserver restart. Undo: undo_vault_arcway_39_40_spawns.sql
-- (re-inserts the exact rows). None of the 7 has creature_addon, formation, pool, event, linked-respawn or SmartAI rows.

-- #39 Vault of the Wardens: the pack of 2 Fel Scorchers + 2 Malignant Defilers in the room between the Demon Ward's south
-- door (246110, y -535) and Glazer's door (246084, y -577). Reporter (screenshots on Discord): these 4 should not be there;
-- only Blade Dancer Illianna's own pack (the other 2 + 2 around her, y -519..-528) belongs in front of Glazer.
DELETE FROM world.creature WHERE guid IN (11565810, 11565811, 11565820, 11565821) AND map = 1493;

-- #40 The Arcway: 3 static Dread Felbats 100393 hanging in the air ~26 yd above General Xakal's room ("random bats around
-- that aren't enemies"). 100393 is Xakal's own add: he summons it during the fight, and npc_xakal_dread_felbat only
-- activates on that summon, so these static copies stayed passive forever. The 7 unselectable ambient bats (98772) are
-- left alone (see the report).
DELETE FROM world.creature WHERE guid IN (263257, 263258, 263259) AND id = 100393;
