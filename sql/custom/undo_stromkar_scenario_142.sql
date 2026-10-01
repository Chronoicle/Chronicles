-- Undo for fix_stromkar_scenario_142.sql (values as they were on live 2026-10-01). Apply with mysql --default-character-set=utf8mb4.
SET NAMES utf8mb4;
DELETE FROM world.smart_scripts WHERE (entryorguid = 247877 AND source_type = 1 AND id = 3)
    OR (entryorguid = 103151 AND source_type = 0 AND id BETWEEN 5 AND 7)
    OR (entryorguid = 104307 AND source_type = 0 AND id BETWEEN 5 AND 6);
UPDATE world.smart_scripts SET link = 0 WHERE entryorguid = 103151 AND source_type = 0 AND id = 4;
UPDATE world.smart_scripts SET link = 0 WHERE entryorguid = 247877 AND source_type = 1 AND id = 2;
UPDATE world.event_scripts SET datalong2 = 180000 WHERE id = 49110 AND command = 10 AND datalong = 104307;
UPDATE world.gameobject_template SET Data1 = 0, name = 'Стромкар', castBarCaption = 'Извлечение' WHERE entry = 247877;
UPDATE world.gameobject_template SET name = 'Феломелорн', castBarCaption = 'Извлечение' WHERE entry = 247494;
UPDATE world.gameobject_template SET name = 'Кулаки Небес', castBarCaption = 'Извлечение' WHERE entry = 248086;
UPDATE world.gameobject_template SET name = 'Панцирь Хранителя Земли' WHERE entry = 248831;
UPDATE world.gameobject_template SET name = 'Боевые мечи доблести', castBarCaption = 'Оружие в руках' WHERE entry = 248832;
UPDATE world.gameobject_template SET name = 'Клыки Пожирателя' WHERE entry = 249347;
UPDATE world.gameobject_template SET name = 'Skull of the Manari', castBarCaption = 'Извлечение' WHERE entry = 249821;
UPDATE world.gameobject_template SET name = 'Серебряная Длань', castBarCaption = 'Извлечение' WHERE entry = 249824;
UPDATE world.gameobject_template SET castBarCaption = 'Извлечение' WHERE entry IN (251049, 252054);
UPDATE world.gameobject_template SET name = 'Fu Zan, the Wanderers Companion', castBarCaption = 'Извлечение' WHERE entry = 251605;
UPDATE world.gameobject_template SET name = 'Клинки Ужаса' WHERE entry = 254087;
UPDATE world.gameobject_template SET name = 'Шей-лун', castBarCaption = 'Извлечение' WHERE entry = 256913;
