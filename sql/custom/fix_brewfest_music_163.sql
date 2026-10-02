-- Brewfest music follows the player (#163, desktop team Claude subagent 2026-10-02).
-- The Durotar Brewfest camp's World Trigger (Infinite AOI) (36171, guid 340466, event 24) plays a random camp tune
-- (SoundKit 33398/33399/33400, zone-music emitters: 60/60/200 yd cutoff, duck the zone music) via the timed action
-- lists 3617100-3617102. SMART_ACTION_SOUND plays the sound from its target, and the target was 7 (ACTION_INVOKER =
-- the player who walked in), so the tune was anchored to the player: full volume wherever they went, Orgrimmar's
-- music muted, until the track ended. Target 1 (SELF) plays it from the trigger, so it fades as you leave the camp.
-- Before: target_type 7. Undo: undo_brewfest_music_163.sql
UPDATE world.smart_scripts SET target_type = 1
WHERE entryorguid IN (3617100, 3617101, 3617102) AND source_type = 9 AND id = 0 AND action_type = 4 AND target_type = 7;
