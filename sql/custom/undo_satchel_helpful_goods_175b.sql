-- Undo fix_satchel_helpful_goods_175b.sql
UPDATE world.item_loot_template SET GroupId = 1 WHERE Entry BETWEEN 51999 AND 52005 AND GroupId = 0;
