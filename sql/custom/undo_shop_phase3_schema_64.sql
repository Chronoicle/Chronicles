-- Undo fix_shop_phase3_schema_64.sql: drops the four phase 3 shop tables. This deletes the bought morphs (donate_owned,
-- character_morph) and the bundle contents: back them up first if anyone bought something. The phase 3 worldserver
-- still runs without them (its queries on them fail and log errors), so undo this together with reverting that build.
-- Idempotent.
DROP TABLE IF EXISTS auth.donate_owned;
DROP TABLE IF EXISTS characters.character_morph;
DROP TABLE IF EXISTS auth.donate_bundle_items;
DROP TABLE IF EXISTS auth.donate_ilvl_prices;
