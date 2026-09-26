UPDATE creature_template SET AIName="" WHERE entry IN (125545,125549);
DELETE FROM smart_scripts WHERE entryorguid IN (125545,125549) AND source_type=0;
