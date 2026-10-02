-- #155 Vault of the Wardens, "Our Last Hope" (38669): the Illidari Warglaives rack (GO 241553, one spawn, guid 131121)
-- had a Russian name and did not light up while the quest was in progress. Undo: undo_vault_warglaives_155.sql.
-- Apply with --default-character-set=utf8mb4. Needs the worldserver with the GameObject::ActivateToQuest change
-- (#155) and a restart (the quest-object list is built at startup).
SET NAMES utf8mb4;

-- 1) English name: GO 253189 has the same ruRU name (Боевые клинки иллидари) and is "Illidari Warglaives" here.
UPDATE world.gameobject_template SET name = 'Illidari Warglaives' WHERE entry = 241553 AND name = 'Боевые клинки иллидари';

-- 2) Tie the chest to quest 38669 (data8 = chest questID) so it lights up while the quest is in progress.
UPDATE world.gameobject_template SET Data8 = 38669 WHERE entry = 241553 AND type = 3 AND Data8 = 0;

-- 3) Russian cast bar ("Извлечение"): empty like its English twin 253189 (dev-owner, after dev-check's note).
UPDATE world.gameobject_template SET castBarCaption = '' WHERE entry = 241553 AND castBarCaption = 'Извлечение';
