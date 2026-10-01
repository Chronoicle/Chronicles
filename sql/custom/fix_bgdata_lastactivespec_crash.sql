-- Crash loop 2026-10-01 18:44-18:49 UTC (6 crashes, the loop stopped): Player::_LoadBGData read
-- character_battleground_data.lastActiveSpec (SMALLINT, saved with setUInt16) with GetUInt8; a specialization id > 255
-- (Rxven, guid 37: 258 Shadow) trips the truncation ASSERT at every login of that character. Until the code fix
-- (GetUInt16) is live: such values set to 0 (= no spec to restore after a battleground). Undo: undo_bgdata_lastactivespec_crash.sql
UPDATE characters.character_battleground_data SET lastActiveSpec = 0 WHERE lastActiveSpec > 255;
