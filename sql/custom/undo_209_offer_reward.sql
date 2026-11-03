-- undo #209 offer_reward (apply with mysql --default-character-set=utf8mb4)
UPDATE world.quest_offer_reward_locale l JOIN world.bak_209_offer_reward_loc b ON b.ID=l.ID AND b.Locale=l.Locale SET l.OfferRewardText=b.OfferRewardText WHERE l.Locale='enUS';
UPDATE world.quest_offer_reward SET RewardText='Так... Батарея зарядилась полностью. Отлично.$B$BДальше нам понадобится антенна...' WHERE ID=38058;
UPDATE world.quest_offer_reward SET RewardText='<Лампочки передатчика загораются. Вы слышите встревоженный голос.>$B$BЕсть кто на связи? Слышно меня? (Свет мне свидетель, как же я ненавижу эти штуки.)$B$BГоворит Мишка. Пропавшие солдаты 7-го легиона вернулись в лагерь. Вроде все на месте.$B$BЭ-э... у меня все. Конец связи.$B$BВсего доброго.$B$BКонец сооб... <Связь внезапно прерывается.>' WHERE ID=38059;
UPDATE world.quest_offer_reward SET RewardText='<В конечном итоге это было сделано для их же блага.>' WHERE ID=42220;
DROP TABLE world.bak_209_offer_reward_loc;
