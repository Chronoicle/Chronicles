-- Undo for fix_skyhold_valkyr_forge_145.sql: restores the values from before the fix
SET NAMES utf8mb4;
UPDATE world.creature SET position_z = CASE guid
    WHEN 12843688 THEN 745.833
    WHEN 12843690 THEN 139.379
    WHEN 12843691 THEN 63.534
    WHEN 12843692 THEN 141.945
    WHEN 12843693 THEN 768.373
    WHEN 12843694 THEN 132.074
    WHEN 12843695 THEN 180.882
    WHEN 12843696 THEN 1.6079
    END
WHERE id = 93819 AND guid IN (12843688, 12843690, 12843691, 12843692, 12843693, 12843694, 12843695, 12843696);
UPDATE world.gossip_menu_option SET OptionText = 'Как мне попасть в Небесную Цитадель?', OptionBroadcastTextID = 0
WHERE MenuID = 93819 AND OptionID = 0;
UPDATE world.gameobject_template SET name = 'Горнило Одина' WHERE entry = 245726;
UPDATE world.gameobject_template SET name = 'Портал в Валхаллу' WHERE entry = 244516;
UPDATE world.gameobject_template SET name = 'Сага о валарьярах' WHERE entry = 248979;
UPDATE world.gameobject_template SET name = 'Легенда об Одине' WHERE entry = 248980;
UPDATE world.gameobject_template SET name = 'Сталью и горном' WHERE entry = 248981;
UPDATE world.gameobject_template SET name = 'Данные об артефакте' WHERE entry = 252801;
UPDATE world.gameobject_template SET name = 'Благословение Мьольнира' WHERE entry = 252887;
UPDATE world.creature_text SET Text = 'О, это ты! У меня товар для тебя!', BroadcastTextID = 0, comment = 'Интендант Дернольф to Player'
WHERE CreatureID = 112392 AND GroupID = 0 AND ID = 0;
UPDATE world.creature_text SET Text = 'Слава воеводе!', BroadcastTextID = 0, comment = 'Эйтригг to Player'
WHERE CreatureID = 117480 AND GroupID = 0 AND ID = 0;
