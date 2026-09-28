-- #78 (James, Claude 2026-09-28): Recruiter Lee's (107934) "Skip the Legion introductory quests" option was gated by
-- CONDITION_QUESTREWARDED (8) on quest 60008: per character, and 60008 is never rewarded here. Retail: another character
-- of the account finished the Broken Shore scenario = CONDITION_ACOUNT_QUEST (67) on 42740 The Battle for Broken Shore.
-- Undo: undo_recruiter_lee_skip_78.sql
UPDATE world.conditions SET ConditionTypeOrReference = 67, ConditionValue1 = 42740
WHERE SourceTypeOrReferenceId = 15 AND SourceGroup = 20486 AND SourceEntry = 0 AND ConditionTypeOrReference = 8 AND ConditionValue1 = 60008;
