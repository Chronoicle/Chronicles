-- Undo for fix_classhall_messengers_english_92.sql: restores the exact rows (mysqldump of creature_text before the fix)
SET NAMES utf8mb4;
DELETE FROM world.creature_text WHERE (CreatureID = 99343 AND GroupID = 1) OR (CreatureID = 101061 AND GroupID = 0)
  OR (CreatureID = 101344 AND GroupID = 0) OR (CreatureID = 102018 AND GroupID IN (0, 1)) OR (CreatureID = 103506 AND GroupID = 0);
INSERT INTO world.creature_text (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`, `Duration`, `Sound`, `BroadcastTextID`, `MinTimer`, `MaxTimer`, `SpellID`, `comment`) VALUES
(99343,1,0,'|3-6($ct) $n, We urgently need to talk!',12,0,100,0,0,0,0,0,0,0,'Kor\'vas Bloodthorn to Player'),
(99343,1,0,'|3-6($ct) $n, нам срочно нужно поговорить!',12,0,100,0,0,0,0,0,0,0,'Kor\'vas Bloodthorn to Player'),
(101061,0,0,'Привет, $n. Наконец-то мне удалось тебя найти. Тебя ждут на Лунной поляне.',12,0,100,0,0,0,0,0,0,0,'Верховный друид Хамуул Рунический Тотем to Player'),
(101344,0,0,'Отлично, теперь зайди в портал в Даларанский кратер, а затем просто лети на север. Он будет тебя ждать!',12,0,100,1,0,0,0,0,0,0,'Прячущая лицо жрица to Player'),
(102018,0,0,'Послание секретное. Прочитай его и сразу же уничтожь.',12,0,100,0,0,0,0,0,0,0,'Курьер Черного Ворона to Player'),
(102018,1,0,'$n, можно тебя на минутку? Срочное сообщение.',12,0,100,1,0,0,0,0,0,0,'Курьер Черного Ворона to Player'),
(103506,0,0,'Приходи к нам в Круг Воли, $gчернокнижник:чернокнижница;. Мой портал доставит тебя прямиком туда. Мы будем ждать.',12,0,100,1,0,61694,105637,0,0,0,'Ритссин Хмурый Огонь  to Player');
