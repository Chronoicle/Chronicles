-- Dungeon bots #140 (2026-10-01): 5 Dungeon Finder dungeons had no instance script, so boss kills were never kept and the
-- Dungeon Finder never finished them (no completion reward): Stormwind Stockade 34, The Underbog 546, The Botanica 553,
-- Mana-Tombs 557 (also Legion Timewalking), Auchenai Crypts 558. They get instance_encounter_memory.cpp's script.
-- Stormwind Stockade also had the wrong encounter data: encounter 1144 "Hogger" credited creature 44254 ("Willer", no
-- spawn) instead of Hogger 46254, and it was the one marked as finishing the dungeon (lastEncounterDungeon 12) although
-- Hogger is the first boss: the mark moves to the last boss, Randolph Moloch (1146).
-- Needs the build with instance_encounter_memory.cpp and a worldserver restart. Undo: undo_instance_encounter_memory.sql
UPDATE world.instance_template SET script = 'instance_the_stockade' WHERE map = 34 AND script = '';
UPDATE world.instance_template SET script = 'instance_the_underbog' WHERE map = 546 AND script = '';
UPDATE world.instance_template SET script = 'instance_the_botanica' WHERE map = 553 AND script = '';
UPDATE world.instance_template SET script = 'instance_mana_tombs' WHERE map = 557 AND script = '';
UPDATE world.instance_template SET script = 'instance_auchenai_crypts' WHERE map = 558 AND script = '';
UPDATE world.instance_encounters SET creditEntry = 46254, lastEncounterDungeon = 0 WHERE entry = 1144;
UPDATE world.instance_encounters SET lastEncounterDungeon = 12 WHERE entry = 1146;
