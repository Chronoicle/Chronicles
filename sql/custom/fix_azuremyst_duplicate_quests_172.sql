-- #172 (Claude, dev-owner): Inoculation (9303 / 37444) and Spare Parts (9305 / 37445) were both offered by Zalduun 16535 /
-- Technician Zhanaa 17071 (same races, level, ender). Keep the chain versions 9303/9305 (PrevQuestID 10304/9294) as the
-- offered ones, 37444/37445 can still be turned in by players who have them, and each pair is one exclusive group so a
-- player who already did one copy is not offered the other.
DELETE FROM world.creature_queststarter WHERE (id = 16535 AND quest = 37444) OR (id = 17071 AND quest = 37445);
UPDATE world.quest_template_addon SET ExclusiveGroup = 9303 WHERE ID IN (9303, 37444);
UPDATE world.quest_template_addon SET ExclusiveGroup = 9305 WHERE ID IN (9305, 37445);
