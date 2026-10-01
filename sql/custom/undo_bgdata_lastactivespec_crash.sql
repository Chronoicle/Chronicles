-- Undo fix_bgdata_lastactivespec_crash.sql (only with the GetUInt16 fix live, else the login of guid 37 crashes again)
UPDATE characters.character_battleground_data SET lastActiveSpec = 258 WHERE guid = 37;
