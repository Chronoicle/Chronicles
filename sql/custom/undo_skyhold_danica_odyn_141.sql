-- Undo for fix_skyhold_danica_odyn_141.sql: restores the exact rows (mysqldump before the fix)
SET NAMES utf8mb4;
UPDATE world.quest_template SET MinLevel = 100 WHERE ID = 39654;
DELETE FROM world.creature_text WHERE CreatureID = 93823 AND GroupID IN (0, 1, 3);
INSERT INTO world.creature_text (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`, `Duration`, `Sound`, `BroadcastTextID`, `MinTimer`, `MaxTimer`, `SpellID`, `comment`) VALUES
(93823,0,0,'Welcome to the Devils of Valor, where brave men live forever!',12,0,100,0,0,0,0,0,0,0,'Danica the Rebirthright to Player'),
(93823,0,0,'Добро пожаловать в Чертоги Доблести, где смельчаки живут вечно!',12,0,100,0,0,0,0,0,0,0,'Даника Возродительница to Player'),
(93823,1,0,'Behind you is the Eye of Odin, which sees all of Azeroth! And that way is the blacksmith, where Helgar, the greatest blacksmith, smokes the most powerful weapon for the Valariars.',12,0,100,0,0,0,0,0,0,0,'Danica the Rebirthright to Player'),
(93823,1,0,'За тобой находится Глаз Одина, который видит весь Азерот! А в той стороне – кузня, где Хелгар, величайший кузнец, кует самое мощное оружие для валарьяров.',12,0,100,0,0,0,0,0,0,0,'Даника Возродительница to Player'),
(93823,3,0,'Theres one in front. I will go and announce your arrival. Do not forget respect.',12,0,100,0,0,0,0,0,0,0,'Danica the Rebirthright to Player'),
(93823,3,0,'Один ждет впереди. Я пойду и объявлю о твоем прибытии. Не забывай об уважении.',12,0,100,0,0,0,0,0,0,0,'Даника Возродительница to Player');
UPDATE world.gossip_menu_option SET OptionText = 'Я хочу еще раз освежить в памяти, какое оружие нам предстоит разыскать.', OptionBroadcastTextID = 0
WHERE MenuID = 19091 AND OptionID = 0;
UPDATE world.quest_request_items SET CompletionText = 'О, ты $gвернулся:вернулась;...' WHERE ID = 40043;
