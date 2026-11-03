-- WORK IN PROGRESS, DO NOT APPLY: 150 of 152 rows; rows MenuID 18778/2, 107253/1, 107253/2 have double-escaped backslashes in the FIX file (undo is ok); 20846/0 and 20886/0 are missing (see PR notes).
-- #209 gossip options (Claude dev-helper 2026-11-03): Russian OptionText/BoxText translated to English. Every row is my translation: CUSTOM.
-- Apply with mysql --default-character-set=utf8mb4.
UPDATE world.gossip_menu_option SET OptionText='Let me choose a reward.' WHERE MenuID=10 AND OptionID=0; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='I lost the Whiptail Egg Shard.' WHERE MenuID=1422 AND OptionID=0; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='I lost the Whiptail Egg Shard.' WHERE MenuID=2465 AND OptionID=0; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Tell me, friend, has anyone suspicious come around lately?' WHERE MenuID=2890 AND OptionID=2; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Dionysus? Who is that?' WHERE MenuID=2891 AND OptionID=0; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Send me to Thunderfang Camp.' WHERE MenuID=8018 AND OptionID=1; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='I need to go to Brill.' WHERE MenuID=11152 AND OptionID=1; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='I need a bat, Timothy. I''m headed to Andorhal. The Dark Lady needs help!' WHERE MenuID=11152 AND OptionID=2; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='I want to go back to the top of the temple!' WHERE MenuID=13158 AND OptionID=0; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Let me see your goods.' WHERE MenuID=13642 AND OptionID=1; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Let me see your goods.' WHERE MenuID=13686 AND OptionID=0; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Let me see your goods.' WHERE MenuID=13753 AND OptionID=0; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='There is still hope: Gorai still lives in the south. Onward!' WHERE MenuID=13803 AND OptionID=0; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='The Seven Burdens of Shaohao.' WHERE MenuID=13829 AND OptionID=7; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Yes, enter the contest.' WHERE MenuID=13872 AND OptionID=0; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Let me see your goods.' WHERE MenuID=14470 AND OptionID=0; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Reforge' WHERE MenuID=14558 AND OptionID=8; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Reforge' WHERE MenuID=14833 AND OptionID=8; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Think you can take me in a pet battle? Let''s find out!', BoxText='You are leaving the battle!' WHERE MenuID=15050 AND OptionID=1; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Reforge' WHERE MenuID=15152 AND OptionID=8; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Reforge' WHERE MenuID=15153 AND OptionID=8; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='I''d like to buy something from you.' WHERE MenuID=16296 AND OptionID=0; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Thelin, let''s turn this building into stables.', BoxText='Rebuilding the building will cost 10,000 gold.\n\nAre you sure?' WHERE MenuID=16423 AND OptionID=1; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Foreman, turn this building into a tank workshop.', BoxText='Rebuilding the building will cost 10,000 gold.\n\nAre you sure?' WHERE MenuID=16461 AND OptionID=0; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='I''d like to buy something from you.' WHERE MenuID=17041 AND OptionID=0; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='You have made a terrible mistake!' WHERE MenuID=17110 AND OptionID=0; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Tormok, return to the barracks.', BoxText='Are you sure about this?' WHERE MenuID=17111 AND OptionID=1; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Leorajh, return to the barracks.', BoxText='Are you sure about this?' WHERE MenuID=17122 AND OptionID=1; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Vivianne, return to the barracks.', BoxText='Are you sure about this?' WHERE MenuID=17124 AND OptionID=1; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='I want to build a new building.', BoxText='Rebuilding the building will cost 10,000 gold.\n\nAre you sure?' WHERE MenuID=17295 AND OptionID=0; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Portals' WHERE MenuID=17376 AND OptionID=5; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Tell me your story.' WHERE MenuID=18463 AND OptionID=2; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='I''m ready. Implant the Fel Slate shard into my shoulder.' WHERE MenuID=18475 AND OptionID=1; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='I need diamonds, Tiffany. Do you have any to spare?' WHERE MenuID=18501 AND OptionID=3; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='I want to make a choice!' WHERE MenuID=18501 AND OptionID=4; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Help me get to Serenity Peak.' WHERE MenuID=18723 AND OptionID=4; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Rethan, call your guards.\\\\n\\\\n[Cost: 50 |TInterface\\\\\\\\Icons\\\\\\\\achievement_reputation_kirintor_offensive.blp:12|t Sightless Eyes]' WHERE MenuID=18778 AND OptionID=2; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Let''s fight!' WHERE MenuID=18812 AND OptionID=0; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='<Unfortunately, you do not have 20 vials of Starrose Pollen.>' WHERE MenuID=18858 AND OptionID=2; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Here are your stands. May I have the crowbar now?' WHERE MenuID=18961 AND OptionID=2; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='If you keep silent, I will tear the answers from your soul! <Attacks>' WHERE MenuID=19059 AND OptionID=2; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='If we do nothing, Sargeras will claim this world. And then nothing will be left of your Holy Light! What will your duty be then?' WHERE MenuID=19061 AND OptionID=0; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='If we do nothing, Sargeras will claim this world. And then nothing will be left of your Holy Light! What will your duty be then?' WHERE MenuID=19061 AND OptionID=1; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='I saw the bodies of your holy warriors lying in heaps at the Tomb of Sargeras! The Legion has never had an army like that, and this time your Light alone will not save us from it!' WHERE MenuID=19062 AND OptionID=1; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Enough! Answer me or die, priest! <Attacks>' WHERE MenuID=19062 AND OptionID=2; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Here is your Diamond!' WHERE MenuID=19138 AND OptionID=2; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Learn the recipe for Silver Mackerel.', BoxText='You will be able to place another order in 4 hours. Continue?' WHERE MenuID=19241 AND OptionID=30; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Learn the recipe for Salt and Pepper Shank.', BoxText='You will be able to place another order in 4 hours. Continue?' WHERE MenuID=19241 AND OptionID=31; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Learn the recipe for Deep-Fried Mossgill.', BoxText='You will be able to place another order in 4 hours. Continue?' WHERE MenuID=19241 AND OptionID=32; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Learn the recipe for Pickled Stormray.', BoxText='You will be able to place another order in 4 hours. Continue?' WHERE MenuID=19241 AND OptionID=33; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Learn the recipe for Faronaar Fizz.', BoxText='You will be able to place another order in 4 hours. Continue?' WHERE MenuID=19241 AND OptionID=34; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Learn the recipe for Spiced Rib Roast.', BoxText='You will be able to place another order in 4 hours. Continue?' WHERE MenuID=19241 AND OptionID=35; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Learn the recipe for Barracuda Mrglgagh.', BoxText='You will be able to place another order in 4 hours. Continue?' WHERE MenuID=19241 AND OptionID=36; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Learn the recipe for Fighter Chow.', BoxText='You will be able to place another order in 4 hours. Continue?' WHERE MenuID=19241 AND OptionID=37; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Learn the recipe for Silver Mackerel.', BoxText='You will be able to place another order in 4 hours. Continue?' WHERE MenuID=19241 AND OptionID=38; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Learn the recipe for Salt and Pepper Shank.', BoxText='You will be able to place another order in 4 hours. Continue?' WHERE MenuID=19241 AND OptionID=39; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Learn the recipe for Deep-Fried Mossgill.', BoxText='You will be able to place another order in 4 hours. Continue?' WHERE MenuID=19241 AND OptionID=40; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Learn the recipe for Pickled Stormray.', BoxText='You will be able to place another order in 4 hours. Continue?' WHERE MenuID=19241 AND OptionID=41; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Learn the recipe for Faronaar Fizz.', BoxText='You will be able to place another order in 4 hours. Continue?' WHERE MenuID=19241 AND OptionID=42; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Learn the recipe for Spiced Rib Roast.', BoxText='You will be able to place another order in 4 hours. Continue?' WHERE MenuID=19241 AND OptionID=43; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Learn the recipe for Barracuda Mrglgagh.', BoxText='You will be able to place another order in 4 hours. Continue?' WHERE MenuID=19241 AND OptionID=44; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Learn the recipe for Fighter Chow.', BoxText='You will be able to place another order in 4 hours. Continue?' WHERE MenuID=19241 AND OptionID=45; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='I want to teleport to Aluriel''s Arcane Blade.' WHERE MenuID=19461 AND OptionID=3; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Pleased to meet you, Lady Li''let.' WHERE MenuID=19567 AND OptionID=0; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='I want to make a choice!' WHERE MenuID=19775 AND OptionID=0; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Let''s begin.' WHERE MenuID=19783 AND OptionID=1; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='I''m ready to fight Korin!' WHERE MenuID=19783 AND OptionID=2; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Conceal Felo''melorn''s flame orbs.' WHERE MenuID=19904 AND OptionID=1; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='What does the Windlord ask for an audience?' WHERE MenuID=20107 AND OptionID=0; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Where can I find the twelfth tome?' WHERE MenuID=20140 AND OptionID=1; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='I want to make a choice!' WHERE MenuID=20537 AND OptionID=3; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Teleport to the Sparkling Depths' WHERE MenuID=20697 AND OptionID=3; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Teleport to the palace courtyard' WHERE MenuID=20697 AND OptionID=4; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='I''m ready to go to Dalaran.' WHERE MenuID=20776 AND OptionID=1; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Activate the portal!' WHERE MenuID=20819 AND OptionID=1; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Let''s go, Velen.' WHERE MenuID=20985 AND OptionID=1; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='I want to go to the Wailing Caverns.' WHERE MenuID=21068 AND OptionID=6; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Send me to the Exodar.' WHERE MenuID=21072 AND OptionID=8; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Send me to the Exodar.' WHERE MenuID=21282 AND OptionID=2; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Teleport to Vashj''ir', BoxText='Do you really want to teleport to Vashj''ir?' WHERE MenuID=36799 AND OptionID=0; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='I need to return to Feather Moon Stronghold!' WHERE MenuID=39723 AND OptionID=0; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Show me your wares.' WHERE MenuID=53214 AND OptionID=0; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Show me your wares.' WHERE MenuID=53881 AND OptionID=0; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Show me your wares.' WHERE MenuID=53882 AND OptionID=0; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='We''re ready...' WHERE MenuID=71967 AND OptionID=0; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Gazlowe is looking for you' WHERE MenuID=86775 AND OptionID=0; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='I''m looking for Prophet Velen! Do you know where he went?' WHERE MenuID=93529 AND OptionID=0; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='I made a Brown Linen Robe.' WHERE MenuID=93976 AND OptionID=0; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='I made a White Woolen Dress.' WHERE MenuID=93976 AND OptionID=1; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='I made a Simple Black Dress.' WHERE MenuID=93976 AND OptionID=2; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='I made a Frostweave Robe.' WHERE MenuID=93976 AND OptionID=3; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='I made a Robe of Spiritual Recovery.' WHERE MenuID=93976 AND OptionID=4; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Reset Event (if it stopped working).' WHERE MenuID=100003 AND OptionID=0; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Offer: 800x |TINTERFACE\\\\ICONS\\\\INV_MISC_ANCIENT_MANA.BLP:20|t|Hcurrency:1155|h|cFFFFFFFF Ancient Mana|h|r', BoxText='Do you really want to give 800 Ancient Mana?' WHERE MenuID=107253 AND OptionID=1; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Offer: 1200x |TINTERFACE\\\\ICONS\\\\INV_MISC_ANCIENT_MANA.BLP:20|t|Hcurrency:1155|h|cFFFFFFFF Ancient Mana|h|r', BoxText='Do you really want to give 1200 Ancient Mana?' WHERE MenuID=107253 AND OptionID=2; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Do you have a spare raft I can take?' WHERE MenuID=109735 AND OptionID=0; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='<You give the orphaned Bloodgazer some Azsuna grapes.>' WHERE MenuID=115741 AND OptionID=0; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='<Let''s begin>' WHERE MenuID=116087 AND OptionID=0; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='<You bandage the wounded matriarch>' WHERE MenuID=116131 AND OptionID=0; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='<You bandage the wounded matriarch>' WHERE MenuID=116139 AND OptionID=0; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='<You bandage the wounded matriarch>' WHERE MenuID=116140 AND OptionID=0; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='<You bandage the wounded matriarch>' WHERE MenuID=116141 AND OptionID=0; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='What''s in here?' WHERE MenuID=120219 AND OptionID=0; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='We need to go!' WHERE MenuID=120219 AND OptionID=1; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Let''s get started, Alard!' WHERE MenuID=220027 AND OptionID=1; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Let''s get started, Alard!' WHERE MenuID=220027 AND OptionID=2; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Timothy, reveal the secret of the scroll!' WHERE MenuID=220028 AND OptionID=0; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Come with me!' WHERE MenuID=220034 AND OptionID=0; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Let''s jump!' WHERE MenuID=220071 AND OptionID=0; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Void-Touched Firebird' WHERE MenuID=542002 AND OptionID=0; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Blue Phoenix' WHERE MenuID=542002 AND OptionID=1; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Lilac Phoenix' WHERE MenuID=542002 AND OptionID=2; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Flaming Phoenix' WHERE MenuID=542002 AND OptionID=3; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Reins of the Felclaw' WHERE MenuID=542002 AND OptionID=4; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Reins of Loque''nahak' WHERE MenuID=542002 AND OptionID=6; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Illidari Felstalker' WHERE MenuID=542002 AND OptionID=7; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Ghostly Hippogryph' WHERE MenuID=542002 AND OptionID=8; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Kul Tiran Charger' WHERE MenuID=542002 AND OptionID=9; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Zuldazar Raptor' WHERE MenuID=542002 AND OptionID=10; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Take me to the Illidari Stronghold.' WHERE MenuID=600011 AND OptionID=1; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Grand Expedition Yak(achievementID: 7386)' WHERE MenuID=600022 AND OptionID=0; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Armored Brown Bear(achievementID: 2076)' WHERE MenuID=600022 AND OptionID=1; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Armored Brown Bear(achievementID: 2076)' WHERE MenuID=600022 AND OptionID=2; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Vial of the Sands(achievementID: 5749)' WHERE MenuID=600022 AND OptionID=3; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Woolly Mammoth(achievementID: 2077)' WHERE MenuID=600022 AND OptionID=4; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Woolly Mammoth(achievementID: 2077)' WHERE MenuID=600022 AND OptionID=5; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Traveler''s Tundra Mammoth(achievementID: 2078)' WHERE MenuID=600022 AND OptionID=6; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Traveler''s Tundra Mammoth(achievementID: 2078)' WHERE MenuID=600022 AND OptionID=7; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Not a Motorcycle, Baby(achievementID: 2097)' WHERE MenuID=600022 AND OptionID=8; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Not a Motorcycle, Baby(achievementID: 2097)' WHERE MenuID=600022 AND OptionID=9; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Ashes of Al''ar(achievementID: 2097)' WHERE MenuID=600022 AND OptionID=10; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Wanderer of the Eternal Sands(achievementID: 5767)' WHERE MenuID=600022 AND OptionID=11; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Reins of the Raven Lord(achievementID: 883)' WHERE MenuID=600022 AND OptionID=12; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Lost Paradise(questID: 39718)' WHERE MenuID=600022 AND OptionID=14; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Lonely Mountain(questID: 39733)' WHERE MenuID=600022 AND OptionID=15; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Serene Forest(questID: 39731)' WHERE MenuID=600022 AND OptionID=16; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Stormheim H(questID: 39864)' WHERE MenuID=600022 AND OptionID=17; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Stormheim A(questID: 39735)' WHERE MenuID=600022 AND OptionID=18; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Invincible''s Reins(achievementID: 4625)' WHERE MenuID=600022 AND OptionID=19; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Crazy One(achievementID: 2336)' WHERE MenuID=600022 AND OptionID=21; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Great Brewfest Kodo(achievementID: 3496)' WHERE MenuID=600022 AND OptionID=23; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Swift Brewfest Ram(achievementID: 3496)' WHERE MenuID=600022 AND OptionID=24; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Red Qiraji Resonating Crystal(achievementID: 980)' WHERE MenuID=600022 AND OptionID=25; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Harbinger of Flame(achievementID: 11425)' WHERE MenuID=600022 AND OptionID=26; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Reins of the Headless Horseman''s Mount(achievementID: 980)' WHERE MenuID=600022 AND OptionID=27; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Lost Paradise(questID: 39718)' WHERE MenuID=600123 AND OptionID=4; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Lonely Mountain(questID: 39733)' WHERE MenuID=600123 AND OptionID=5; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Serene Forest(questID: 39731)' WHERE MenuID=600123 AND OptionID=6; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Stormheim H(questID: 39864)' WHERE MenuID=600123 AND OptionID=7; -- CUSTOM
UPDATE world.gossip_menu_option SET OptionText='Stormheim A(questID: 39735)' WHERE MenuID=600123 AND OptionID=8; -- CUSTOM
