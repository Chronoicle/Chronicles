-- #175 (Claude, dev-owner): Satchel of Helpful Goods 51999-52005 (Dungeon Finder satchels): every item sat in group 0
-- with chances adding up to ~100 %, so each was rolled on its own and ~1 in 4 satchels came out empty. One group = exactly one item.
UPDATE world.item_loot_template SET GroupId = 1 WHERE Entry BETWEEN 51999 AND 52005 AND GroupId = 0 AND Reference = 0;
