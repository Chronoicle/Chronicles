-- Undo fix_brewfest_music_163.sql: the Brewfest camp tunes played from the invoker (target 7) again.
UPDATE world.smart_scripts SET target_type = 7
WHERE entryorguid IN (3617100, 3617101, 3617102) AND source_type = 9 AND id = 0 AND action_type = 4 AND target_type = 1;
