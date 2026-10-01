-- Undo fix_instance_encounter_memory.sql (all five scripts were empty; 1144 credited 44254 with lastEncounterDungeon 12)
UPDATE world.instance_template SET script = '' WHERE map IN (34, 546, 553, 557, 558);
UPDATE world.instance_encounters SET creditEntry = 44254, lastEncounterDungeon = 12 WHERE entry = 1144;
UPDATE world.instance_encounters SET lastEncounterDungeon = 0 WHERE entry = 1146;
