-- Hotfix-only item_sparse rows with Russian text, set to English (dev-helper). Apply with mysql --default-character-set=utf8mb4.
-- no tag = exact retail name/description from wowhead; CUSTOM = not a retail item (UWOW custom or ID not on wowhead), my translation of the Russian text.
UPDATE hotfixes.item_sparse SET Display='Sylvanas''s Bow (Custom bow)', Description='Only for transmog by donate' WHERE ID=42775; -- CUSTOM
UPDATE hotfixes.item_sparse SET Display='Fallen Frostwolf Artifact', Description='Crafted by Frostwolf orcs, this token is an honored remembrance of its fallen owner.' WHERE ID=100899; -- wowhead
UPDATE hotfixes.item_sparse SET Display='Kukuru''s Cache Key' WHERE ID=101538; -- wowhead
UPDATE hotfixes.item_sparse SET Display='Rolo''s Riddle', Description='The old piece of tattered parchment has barely survived the test of time.' WHERE ID=102225; -- wowhead
UPDATE hotfixes.item_sparse SET Display='Fire-Watcher''s Oath', Description='Ordon Fire-Watchers carry the ashes of their victims in a special pouch that keeps them smouldering.' WHERE ID=102463; -- wowhead
UPDATE hotfixes.item_sparse SET Display='Swamplighter Dust', Description='Sparkly.' WHERE ID=104350; -- wowhead
UPDATE hotfixes.item_sparse SET Display='Sylene''s Amulet of Illusion' WHERE ID=107076; -- wowhead
UPDATE hotfixes.item_sparse SET Display='Vial of Toad Juice', Description='It''s glowing.' WHERE ID=110723; -- wowhead
UPDATE hotfixes.item_sparse SET Display='Pristine Star Lily', Description='The translucent, weightless flower only grows under pure starlight.' WHERE ID=111024; -- wowhead
UPDATE hotfixes.item_sparse SET Display='Clarity Elixir' WHERE ID=111591; -- wowhead
UPDATE hotfixes.item_sparse SET Display='Feather of Syth', Description='While devotees of Rukhmar prefer cremation, the outcasts have taken to darker last rites.' WHERE ID=111850; -- wowhead
UPDATE hotfixes.item_sparse SET Display='Star Reading', Description='A detailed map of the sky.' WHERE ID=112385; -- wowhead
UPDATE hotfixes.item_sparse SET Display='Fragment of Anguish' WHERE ID=112386; -- wowhead
UPDATE hotfixes.item_sparse SET Display='Lithic''s Gift', Description='With Lithic''s blessing, this bangle holds a special connection to Terokk.' WHERE ID=113010; -- wowhead
UPDATE hotfixes.item_sparse SET Display='The Eye of Anzu', Description='A spell focus from Terokk''s darker days.' WHERE ID=113282; -- wowhead
UPDATE hotfixes.item_sparse SET Display='Oiled Shieldbearer''s Cloak' WHERE ID=121566; -- CUSTOM
UPDATE hotfixes.item_sparse SET Display='Swift Quill Cloak' WHERE ID=121640; -- CUSTOM
UPDATE hotfixes.item_sparse SET Display='Stoneblood Harpy Cloak' WHERE ID=121645; -- CUSTOM
UPDATE hotfixes.item_sparse SET Display='Iron Warrior''s Ring' WHERE ID=121718; -- CUSTOM
UPDATE hotfixes.item_sparse SET Display='Rivermane Protective Wrap' WHERE ID=121719; -- CUSTOM
UPDATE hotfixes.item_sparse SET Display='Rock Crawler Spine' WHERE ID=121720; -- CUSTOM
UPDATE hotfixes.item_sparse SET Display='Containment Unit' WHERE ID=122702; -- wowhead
UPDATE hotfixes.item_sparse SET Display='Relic of Shakama', Description='A simple carving of a cat.' WHERE ID=123868; -- wowhead
UPDATE hotfixes.item_sparse SET Display='Inky Black Potion', Description='Mix two parts crushed crickets, one part darkmoon squid ink, and three parts whispers from the Shadowlands.' WHERE ID=124640; -- wowhead
UPDATE hotfixes.item_sparse SET Display='Prison Keys', Description='A set of long, skeletal keys dangle from a silver chain.' WHERE ID=127863; -- wowhead
UPDATE hotfixes.item_sparse SET Description='On one side it looks like a bear, but on the other it has a beak...' WHERE ID=129148; -- CUSTOM
UPDATE hotfixes.item_sparse SET Display='Colorful Pathfinder''s Jacket' WHERE ID=130213; -- CUSTOM
UPDATE hotfixes.item_sparse SET Display='Driftwood', Description='A piece of sun-bleached driftwood.' WHERE ID=132371; -- wowhead
UPDATE hotfixes.item_sparse SET Display='Valarjar Aspirant''s Cuirass' WHERE ID=133627; -- CUSTOM
UPDATE hotfixes.item_sparse SET Display='Moon Guard Sigil', Description='Bearers of this inscribed talisman have proven themselves exceptionally skilled sorcerers.' WHERE ID=133675; -- wowhead
UPDATE hotfixes.item_sparse SET Display='Underlight Angler' WHERE ID=133755; -- wowhead
UPDATE hotfixes.item_sparse SET Display='Trap Rune' WHERE ID=133882; -- wowhead
UPDATE hotfixes.item_sparse SET Display='Anthology of the Guard', Description='A detailed account of all Moon Guard members from the order''s creation. Extremely old.' WHERE ID=133898; -- wowhead
UPDATE hotfixes.item_sparse SET Display='Magical Manifest of the Moon', Description='A dog-eared tome describing the complex relationship between lunar phases and spell effectiveness.' WHERE ID=133899; -- wowhead
UPDATE hotfixes.item_sparse SET Display='Aftermath of the Well', Description='A hand-written account of the events following the Sundering.' WHERE ID=133900; -- wowhead
UPDATE hotfixes.item_sparse SET Display='Astromancer''s Keystone' WHERE ID=133924; -- wowhead
UPDATE hotfixes.item_sparse SET Display='Volatile Spell Focus', Description='Hums with energy.' WHERE ID=133956; -- wowhead
UPDATE hotfixes.item_sparse SET Display='Storm Brew Recipe', Description='The recipe is a complex diagram with many notes and drawings.' WHERE ID=133995; -- wowhead
UPDATE hotfixes.item_sparse SET Display='Inert Crystal', Description='A vessel capable of drawing great power into itself.' WHERE ID=133999; -- wowhead
UPDATE hotfixes.item_sparse SET Display='Odyn''s Cauldron', Description='The enormous cauldron is lined with ancient runes.' WHERE ID=134005; -- wowhead
UPDATE hotfixes.item_sparse SET Display='Tear of Elune', Description='The hardened tear lying in your palm feels completely weightless.' WHERE ID=136409; -- CUSTOM
UPDATE hotfixes.item_sparse SET Display='Commander Domitille''s Helm' WHERE ID=136851; -- wowhead
UPDATE hotfixes.item_sparse SET Display='Crown of the Forgotten King', Description='This simple, but well-crafted crown was once worn by King Svergan Stormcloak.  The dried blood on it suggests a violent demise.' WHERE ID=137182; -- wowhead
UPDATE hotfixes.item_sparse SET Display='Stormcloak Signet', Description='The signet of the Stormcloak clan.' WHERE ID=137183; -- wowhead
UPDATE hotfixes.item_sparse SET Display='Drakerider''s Medallion', Description='The wings of a Storm Drake frame a bright gem in the medallion.' WHERE ID=137184; -- wowhead
UPDATE hotfixes.item_sparse SET Display='Bottle of Arcwine' WHERE ID=137295; -- wowhead
UPDATE hotfixes.item_sparse SET Display='Svergan''s Belongings' WHERE ID=138204; -- wowhead
UPDATE hotfixes.item_sparse SET Display='The Gjallarhorn', Description='Carved from the tusk of a great beast, this impressive horn bears deep angular runes.' WHERE ID=138205; -- wowhead
UPDATE hotfixes.item_sparse SET Display='Mana Wine Flask', Description='Pitifully small, but filled with the hopes and dreams of many.' WHERE ID=138308; -- wowhead
UPDATE hotfixes.item_sparse SET Display='Arcane Amplifier', Description='Used to strengthen the effects of one''s casting.' WHERE ID=138391; -- wowhead
UPDATE hotfixes.item_sparse SET Display='Dream Seeds' WHERE ID=139380; -- wowhead
UPDATE hotfixes.item_sparse SET Display='Frostcrag Drums' WHERE ID=139501; -- wowhead
UPDATE hotfixes.item_sparse SET Display='Stylish Spy Glasses' WHERE ID=140395; -- wowhead
UPDATE hotfixes.item_sparse SET Display='Dusk Lily Sigil', Description='A warm piece of enchanted stone carved in the shape of a lily.' WHERE ID=142065; -- wowhead
UPDATE hotfixes.item_sparse SET Display='Small Boat', Description='' WHERE ID=143931; -- wowhead
UPDATE hotfixes.item_sparse SET Description='Like a minion of Illidan, you leave a burning trail of Fel behind you...' WHERE ID=160000; -- CUSTOM
UPDATE hotfixes.item_sparse SET Description='The power of Xuen will always be with you. You do not need a cloak for that...' WHERE ID=160001; -- CUSTOM
UPDATE hotfixes.item_sparse SET Description='The kindness of Chi-Ji will always be with you. You do not need a cloak for that...' WHERE ID=160002; -- CUSTOM
UPDATE hotfixes.item_sparse SET Description='The breath of Yu''lon will always be with you. You do not need a cloak for that...' WHERE ID=160003; -- CUSTOM
UPDATE hotfixes.item_sparse SET Description='The fortitude of Niuzao will always be with you. You do not need a cloak for that...' WHERE ID=160004; -- CUSTOM
UPDATE hotfixes.item_sparse SET Display='Shirt of Shadowmourne (Custom trans only)', Description='When you put on this shirt, you shiver. You feel its dark power.' WHERE ID=160005; -- CUSTOM
UPDATE hotfixes.item_sparse SET Description='Raven spirits surround you. The birds clearly know something.' WHERE ID=160006; -- CUSTOM
UPDATE hotfixes.item_sparse SET Description='Stars fall at your feet. Hurry and make a wish.' WHERE ID=160007; -- CUSTOM
UPDATE hotfixes.item_sparse SET Description='You look splendid. Your charm attracts even butterflies.' WHERE ID=160008; -- CUSTOM
UPDATE hotfixes.item_sparse SET Display='Shirt of Shadowmourne (Custom trans only)', Description='When you put on this shirt, you feel a shiver. You feel its dark power.' WHERE ID=160009; -- CUSTOM
UPDATE hotfixes.item_sparse SET Description='Your character will leave a blooming trail behind.' WHERE ID=160011; -- CUSTOM
UPDATE hotfixes.item_sparse SET Description='The shirt is filled with strong love!' WHERE ID=160021; -- CUSTOM
UPDATE hotfixes.item_sparse SET Description='Legend has it that unicorns themselves wore it!' WHERE ID=160026; -- CUSTOM
UPDATE hotfixes.item_sparse SET Description='Like a minion of Illidan, you leave a burning trail of Fel behind you...' WHERE ID=160032; -- CUSTOM
UPDATE hotfixes.item_sparse SET Description='New Year will find you even in Azeroth!' WHERE ID=160035; -- CUSTOM
UPDATE hotfixes.item_sparse SET Description='Darkness itself swallows you!' WHERE ID=160049; -- CUSTOM
UPDATE hotfixes.item_sparse SET Description='You look as if you have become half ghost!' WHERE ID=160053; -- CUSTOM
UPDATE hotfixes.item_sparse SET Display='Stormheart Headpiece (Custom without type)', Description='Only for transmog by donate' WHERE ID=160077; -- CUSTOM
UPDATE hotfixes.item_sparse SET Display='Cloak of the Destroyer''s Embrace', Description='This item''s power is boundless. From time to time Wrathion''s wings appear behind you.' WHERE ID=166000; -- CUSTOM
UPDATE hotfixes.item_sparse SET Display='Shirt of the Destroyer''s Embrace', Description='This item''s power is boundless. From time to time Wrathion''s wings appear behind you.' WHERE ID=166001; -- CUSTOM
UPDATE hotfixes.item_sparse SET Display='Cloak of the Endless Rainbow', Description='Wherever you go, a rainbow follows you.' WHERE ID=166002; -- CUSTOM
UPDATE hotfixes.item_sparse SET Display='Shirt of the Endless Rainbow', Description='Wherever you go, a rainbow follows you.' WHERE ID=166003; -- CUSTOM
UPDATE hotfixes.item_sparse SET Display='Cloak of Flaming Wings', Description='When you put on this cloak, you feel flaming wings sprout from you.' WHERE ID=166004; -- CUSTOM
UPDATE hotfixes.item_sparse SET Display='Shirt of Flaming Wings', Description='When you put on this shirt, you feel flaming wings sprout from you.' WHERE ID=166005; -- CUSTOM
UPDATE hotfixes.item_sparse SET Display='Cloak of Soap Bubbles', Description='When you put on this cloak, you start blowing soap bubbles from time to time.' WHERE ID=166006; -- CUSTOM
UPDATE hotfixes.item_sparse SET Display='Shirt of Soap Bubbles', Description='When you put on this cloak, you start blowing soap bubbles from time to time.' WHERE ID=166007; -- CUSTOM
UPDATE hotfixes.item_sparse SET Display='Father''s Sock', Description='Just pick it up... and you begin to feel freer...' WHERE ID=166008; -- CUSTOM
UPDATE hotfixes.item_sparse SET Display='Father''s Sock', Description='Just pick it up... and you begin to feel freer...' WHERE ID=166009; -- CUSTOM
UPDATE hotfixes.item_sparse SET Display='Void-Touched Firebird' WHERE ID=166509; -- CUSTOM
UPDATE hotfixes.item_sparse SET Display='Blue Phoenix' WHERE ID=166510; -- CUSTOM
UPDATE hotfixes.item_sparse SET Display='Flaming Phoenix' WHERE ID=166511; -- CUSTOM
UPDATE hotfixes.item_sparse SET Display='Reins of the Felclaw' WHERE ID=166512; -- CUSTOM
UPDATE hotfixes.item_sparse SET Display='Child of Xuen' WHERE ID=166513; -- CUSTOM
UPDATE hotfixes.item_sparse SET Display='Reins of Loque''nahak' WHERE ID=166514; -- CUSTOM
UPDATE hotfixes.item_sparse SET Display='Illidari Felstalker' WHERE ID=166515; -- CUSTOM
UPDATE hotfixes.item_sparse SET Display='Ghostly Hippogryph' WHERE ID=166516; -- CUSTOM
UPDATE hotfixes.item_sparse SET Display='Kul Tiran Charger' WHERE ID=166517; -- CUSTOM
UPDATE hotfixes.item_sparse SET Display='Zuldazar Raptor' WHERE ID=166518; -- CUSTOM
UPDATE hotfixes.item_sparse SET Display='Shu-zen, the Divine Sentinel' WHERE ID=166519; -- CUSTOM
UPDATE hotfixes.item_sparse SET Display='Lilac Phoenix' WHERE ID=166520; -- CUSTOM
