-- Undo for fix_paladin_libram_146.sql: restores the values from before the fix (apply with --default-character-set=utf8mb4)
SET NAMES utf8mb4;
UPDATE world.creature SET modelid = 0 WHERE guid = 11317975 AND id = 92403;
UPDATE world.gameobject_template SET name = 'Фолиант древних королей' WHERE entry = 240351;
UPDATE world.page_text SET Text = 'n questo tomo verrà trascritta la storia e il potere del tuo Artefatto man mano che aumenta il tuo livello di conoscenza.'
WHERE ID = 5121;
UPDATE world.gameobject_template SET name = 'Сказания об охоте' WHERE entry = 245039;
UPDATE world.gameobject_template SET name = 'Хроника веков' WHERE entry = 248501;
