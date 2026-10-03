-- Undo fix_satchel_helpful_goods_175.sql
UPDATE world.item_loot_template SET GroupId = 0 WHERE Entry BETWEEN 51999 AND 52005 AND GroupId = 1;
