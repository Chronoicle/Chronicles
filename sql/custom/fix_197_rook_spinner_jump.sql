-- #197 (Claude dev-owner 2026-11-03): Rook Spinner 98681 (guid 262905) only jumped onto the stairs on SetData(1,1),
-- which nothing sends; it now jumps when it first sees a hostile player within 30 yd (out of combat, once).
UPDATE world.smart_scripts SET event_type = 10, event_flags = 1, event_param1 = 0, event_param2 = 30, event_param3 = 0, event_param4 = 0
WHERE entryorguid IN (98681, -262905) AND source_type = 0 AND id = 0;
