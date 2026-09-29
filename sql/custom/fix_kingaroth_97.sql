-- #97 Antorus, Kin'garoth room: the 4 "Проводник" objects (Wowhead object=276474 "Conduit") had only a Russian name
-- and were clickable goobers with no lock, event or spell (click did nothing). Name them Conduit and make them
-- not selectable (GO_FLAG_NOT_SELECTABLE 0x10, like the room's trap objects 276288-276294). Spawns stay.
-- 276474/276475 stand at the back wall behind Kin'garoth (Apocalypse Blast side), 276476/276477 further north.
-- Undo: undo_kingaroth_97.sql
UPDATE world.gameobject_template SET name = 'Conduit', flags = flags | 16 WHERE entry IN (276474, 276475, 276476, 276477);
