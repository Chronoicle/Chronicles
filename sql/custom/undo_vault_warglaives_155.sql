-- Undo for fix_vault_warglaives_155.sql: restores the values from before the fix (apply with --default-character-set=utf8mb4)
SET NAMES utf8mb4;
UPDATE world.gameobject_template SET name = 'Боевые клинки иллидари' WHERE entry = 241553 AND name = 'Illidari Warglaives';
UPDATE world.gameobject_template SET Data8 = 0 WHERE entry = 241553 AND Data8 = 38669;
UPDATE world.gameobject_template SET castBarCaption = 'Извлечение' WHERE entry = 241553 AND castBarCaption = '';
