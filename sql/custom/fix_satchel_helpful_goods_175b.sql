-- #175 follow-up (Claude, dev-owner): back to group 0. For item containers this core picks ONE usable gear item from the
-- ungrouped rows (LootTemplate::ProcessItemLoot), which is the right satchel behaviour; group 1 rolled by chance without the
-- class filter. The empty satchels came from the level/spec filter refusing every item: fixed in LootMgr.cpp (fallback).
UPDATE world.item_loot_template SET GroupId = 0 WHERE Entry BETWEEN 51999 AND 52005 AND GroupId = 1;
