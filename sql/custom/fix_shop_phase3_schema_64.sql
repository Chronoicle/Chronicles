-- #64 shop phase 3 (Claude subagent, desktop team): the tables the phase 3 shop code needs (many_in_one_donate.cpp).
-- Only new tables, nothing existing changes: safe with the running worldserver and before the phase 3 build.
-- The catalogue rows (products, bundle parts) come from their own catalogue SQL. Idempotent. Undo: undo_shop_phase3_schema_64.sql

-- Morphs (product type 9) the account bought: the shop marks them "Already Known", .donate morph use checks it.
CREATE TABLE IF NOT EXISTS auth.donate_owned (
  `account` int unsigned NOT NULL,
  `product` int unsigned NOT NULL COMMENT 'donate_products.id',
  `added` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`account`, `product`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='shop products an account owns (morphs)';

-- The morph a character wears, put back at every login.
CREATE TABLE IF NOT EXISTS characters.character_morph (
  `guid` int unsigned NOT NULL,
  `display` int unsigned NOT NULL COMMENT 'CreatureDisplayInfo ID',
  PRIMARY KEY (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='shop morph worn by a character (.donate morph use / remove)';

-- What a bundle (product type 11, param1 = bundle) gives, in sort order: any product type except 11 and 13 with the
-- same param1/param2/bonus meaning as donate_products, plus 100 = the Gear Master's set of the character's spec
-- (bonus 'ilvl:N' or empty) and 101 = every artifact weapon of the class. One row per (bundle, sort).
CREATE TABLE IF NOT EXISTS auth.donate_bundle_items (
  `bundle` int unsigned NOT NULL,
  `sort` smallint unsigned NOT NULL,
  `type` tinyint unsigned NOT NULL,
  `param1` int unsigned NOT NULL DEFAULT '0',
  `param2` int unsigned NOT NULL DEFAULT '1',
  `bonus` varchar(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`bundle`, `sort`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='shop bundle contents (starter packs)';

-- Item level choice for item products with bonus 'ilvl:N' (N one of these rows): the price at another item level is
-- token * percent(ilvl) / percent(N). The UWOW screenshots show the steps 915-985 but no prices below 985 (875 tokens),
-- so these percents are a first guess for the owner to tune (INSERT IGNORE keeps tuned rows on a re-run).
CREATE TABLE IF NOT EXISTS auth.donate_ilvl_prices (
  `ilvl` smallint unsigned NOT NULL,
  `percent` smallint unsigned NOT NULL COMMENT 'of the price at 985',
  PRIMARY KEY (`ilvl`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='shop price per item level';

INSERT IGNORE INTO auth.donate_ilvl_prices (`ilvl`, `percent`) VALUES
(915, 60), (930, 70), (945, 80), (960, 88), (970, 94), (985, 100);
