-- Owner OK 2026-10-01 ("yes turn the world boss rotation on again", #139 calendar follow-up): the 3-week Legion /
-- Draenor world boss rotation (events 102-104: one week each, every 3 weeks, Monday 00:00 server time) ended on
-- 2020-01-01, so none of its bosses spawned (Humongris, Nithogg, Kazzak, Levantus, the Broken Shore and Argus bosses...).
-- Same starts (the rotation and its weekdays are kept), end 2030 like fix_game_event_calendar.sql. Week of 2026-09-28: 102.
-- Spawns, respawn times and the bosses' world quests are not changed. Needs a worldserver restart (game_event is read
-- at startup). Undo: undo_world_boss_rotation.sql
UPDATE world.game_event SET end_time = '2030-12-31 23:59:59' WHERE eventEntry IN (102, 103, 104);
