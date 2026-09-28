-- Party bots (#65, Claude): bot characters made by .partybot create, with the spec they play.
-- They live on the accounts partybot1@bot .. partybot50@bot (made by the owner). Undo: undo_partybot_characters.sql
CREATE TABLE IF NOT EXISTS characters.partybot_characters (
  guid INT UNSIGNED NOT NULL,
  account INT UNSIGNED NOT NULL,
  spec SMALLINT UNSIGNED NOT NULL,
  setup TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '1 = level, spec and gear done at the first login',
  PRIMARY KEY (guid)
);
