-- #110 follow-up (Claude, dev-owner): Ireroot Seeds (46716, spell 65455 Nature's Fury) still said "wrong zone" while on
-- Nature's Reprisal (13946). This core reads spell_area.quest_end_status as the ALLOWED states (SpellMgr.cpp:1189,
-- see #160): 66 = complete|rewarded, so the incomplete quest (status 3) was refused (GM mode skips the check).
-- Allow incomplete + complete (bits 3 and 1) for both checks.
UPDATE world.spell_area SET quest_start_status = 10, quest_end_status = 10 WHERE spell = 65455 AND area = 141 AND quest_start = 13946;
