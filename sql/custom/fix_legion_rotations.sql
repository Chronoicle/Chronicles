-- Owner OK 2026-10-01 ("I want those too", #139 calendar follow-up): three LegionCore rotations ended on 2020-01-01;
-- same starts (rotation and weekdays kept), end 2030 like fix_game_event_calendar.sql / fix_world_boss_rotation.sql.
-- 105-116 Val'sharah outposts (Gilnean / Forsaken camps, Alliance and Horde version every 6 h)
-- 117-125 Sentinax over the Broken Shore: 9 places, 3 h each (world state 13321 + map marker, QuestHandler.cpp)
-- 126-137 Mythic+ affix weeks (12 weeks from Wed 05:00): ChallengeMgr::GetActiveAffixe reads them at the weekly key
--         reset (Wed 11:00), so the affixes change at the next reset, not at the restart (now: Raging/Volcanic/Tyrannical
--         every week, the "no event" default). Week of 2026-09-30 = 132, so 2026-10-07 = 133 Bolstering/Skittish/Fortified.
-- 155-167 weekly archaeology quests from Dariness the Learned (93538), 13 weeks from Wed 02:00
-- Needs a worldserver restart (game_event is read at startup). Undo: undo_legion_rotations.sql
UPDATE world.game_event SET end_time = '2030-12-31 23:59:59' WHERE eventEntry BETWEEN 105 AND 137 OR eventEntry BETWEEN 155 AND 167;
