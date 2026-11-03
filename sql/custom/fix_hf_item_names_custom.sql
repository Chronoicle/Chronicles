-- Custom/hotfix-only item_sparse rows: Russian Display/Description translated to English (dev-helper). Apply with mysql --default-character-set=utf8mb4.
-- GUESS = display name is my best guess from the Russian, NOT verified on wowhead; NOTFOUND = Display left unchanged.
UPDATE hotfixes.item_sparse SET Display='Sylvanas''s Bow (Custom bow)', Description='Only for transmog by donate' WHERE ID=42775; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Fallen Clansman''s Token', Description='Crafted by Frostwolf orcs, this token is an honored remembrance of its fallen owner.' WHERE ID=100899; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Kukuru''s Treasure Key' WHERE ID=101538; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Rolo''s Riddle' WHERE ID=102225;
UPDATE hotfixes.item_sparse SET Display='Oath of the Firekeeper' WHERE ID=102463; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Marsh Firefly Pollen', Description='Glowing.' WHERE ID=104350; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Sylena''s Amulet of Illusions' WHERE ID=107076; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Vial of Toad Slime', Description='Glowing.' WHERE ID=110723; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Pure Starlily', Description='A translucent, weightless flower that grows only under starlight.' WHERE ID=111024; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Elixir of Clear Sight' WHERE ID=111591; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Feather of Sith', Description='Followers of Ruhmar prefer cremation, while outcast arakkoa spend' WHERE ID=111850; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Star Chart', Description='A detailed map of the sky.' WHERE ID=112385; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Shard of Anguish' WHERE ID=112386; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Lytik''s Bracer', Description='The bracer blessed by Lytik has a special connection to Terokk' WHERE ID=113010; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Eye of Anzu', Description='A focus of enchantments from Terokk''s dark past' WHERE ID=113282;
UPDATE hotfixes.item_sparse SET Display='Oiled Shieldbearer''s Cloak' WHERE ID=121566; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Swift Quill Cloak' WHERE ID=121640; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Stoneblood Harpy Cloak' WHERE ID=121645; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Iron Warrior''s Ring' WHERE ID=121718; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Rivermane Protective Wrap' WHERE ID=121719; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Rock Crawler Spine' WHERE ID=121720; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Sealed Container' WHERE ID=122702; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Shakama''s Relic', Description='A simple carved figurine of a cat.' WHERE ID=123868; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Inky Black Potion', Description='Mix two parts ground dried crickets, one part squid ink' WHERE ID=124640; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Prison Keys', Description='A set of long keys adorned with bones, on a silver chain.' WHERE ID=127863; -- GUESS
UPDATE hotfixes.item_sparse SET Description='On one side it looks like a bear, but on the other it has a beak...' WHERE ID=129148; -- NOTFOUND
UPDATE hotfixes.item_sparse SET Display='Colorful Pathfinder''s Jacket' WHERE ID=130213; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Driftwood', Description='A piece of sun-bleached wood.' WHERE ID=132371; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Valarjar Aspirant''s Cuirass' WHERE ID=133627; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Moonguard Seal', Description='Painted talismans like this are usually owned only by the most talented.' WHERE ID=133675; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Darklight''s Fishing Pole' WHERE ID=133755; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Trap Rune' WHERE ID=133882; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Moonguard Anthology', Description='The personal files of every member of the Moonguard since its founding. The list is very old.' WHERE ID=133898; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Moon''s Arcane Manifesto', Description='A well-thumbed tome describing in detail how the potency of various spells depends on the phases of the moon.' WHERE ID=133899; -- GUESS
UPDATE hotfixes.item_sparse SET Display='"Aftermath of the Battle for the Well"', Description='A handwritten summary of the most significant events that took place after the Sundering.' WHERE ID=133900; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Stargazer''s Key' WHERE ID=133924; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Unstable Spell Focus', Description='Hums steadily, radiating energy.' WHERE ID=133956; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Stormy Mead Recipe', Description='The recipe is a complex diagram with many notes and drawings.' WHERE ID=133995; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Inert Crystal' WHERE ID=133999; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Odyn''s Cauldron', Description='A huge cauldron, lined with ancient runes.' WHERE ID=134005; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Tear of Elune', Description='The hardened tear lying in your palm feels completely weightless.' WHERE ID=136409; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Commander Domitille''s Helm' WHERE ID=136851; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Crown of the Forgotten King', Description='King Svergan Stormveil once wore this simple but well-made crown. The dried blood on it means a violent end.' WHERE ID=137182; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Stormveil Signet', Description='Mark of the storm clan.' WHERE ID=137183; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Dragonrider''s Medallion', Description='The wings of a Storm Drake rest on a bright gem in the medallion.' WHERE ID=137184; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Bottle of Arcane Wine' WHERE ID=137295; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Svergan''s Belongings' WHERE ID=138204; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Gjallarhorn', Description='Carved from the tusk of a great beast, this impressive horn bears deep angular runes.' WHERE ID=138205; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Flask of Mana Wine', Description='There is ridiculously little wine, but for many even that is the limit of their dreams.' WHERE ID=138308; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Arcane Amplifier', Description='Usually used to amplify the wielder''s spells' WHERE ID=138391; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Seeds of the Dream' WHERE ID=139380; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Frostcliff Tribe Drums' WHERE ID=139501; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Stylish Spy Goggles' WHERE ID=140395; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Twilight Lily Sigil' WHERE ID=142065; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Small Boat' WHERE ID=143931; -- GUESS
UPDATE hotfixes.item_sparse SET Description='Like a minion of Illidan, you leave a burning trail of Fel behind you...' WHERE ID=160000;
UPDATE hotfixes.item_sparse SET Description='The power of Xuen will always be with you. You do not need a cloak for that...' WHERE ID=160001;
UPDATE hotfixes.item_sparse SET Description='The kindness of Chi-Ji will always be with you. You do not need a cloak for that...' WHERE ID=160002;
UPDATE hotfixes.item_sparse SET Description='The breath of Yu''lon will always be with you. You do not need a cloak for that...' WHERE ID=160003;
UPDATE hotfixes.item_sparse SET Description='The fortitude of Niuzao will always be with you. You do not need a cloak for that...' WHERE ID=160004;
UPDATE hotfixes.item_sparse SET Display='Shirt of Shadowmourne (Custom trans only)', Description='When you put on this shirt, you shiver. You feel its dark power.' WHERE ID=160005;
UPDATE hotfixes.item_sparse SET Description='Raven spirits surround you. The birds clearly know something.' WHERE ID=160006;
UPDATE hotfixes.item_sparse SET Description='Stars fall at your feet. Hurry and make a wish.' WHERE ID=160007;
UPDATE hotfixes.item_sparse SET Description='You look splendid. Your charm attracts even butterflies.' WHERE ID=160008;
UPDATE hotfixes.item_sparse SET Display='Shirt of Shadowmourne (Custom trans only)', Description='When you put on this shirt, you feel a shiver. You feel its dark power.' WHERE ID=160009;
UPDATE hotfixes.item_sparse SET Description='Your character will leave a blooming trail behind.' WHERE ID=160011;
UPDATE hotfixes.item_sparse SET Description='The shirt is filled with strong love!' WHERE ID=160021;
UPDATE hotfixes.item_sparse SET Description='Legend has it that unicorns themselves wore it!' WHERE ID=160026;
UPDATE hotfixes.item_sparse SET Description='Like a minion of Illidan, you leave a burning trail of Fel behind you...' WHERE ID=160032;
UPDATE hotfixes.item_sparse SET Description='New Year will find you even in Azeroth!' WHERE ID=160035;
UPDATE hotfixes.item_sparse SET Description='Darkness itself swallows you!' WHERE ID=160049;
UPDATE hotfixes.item_sparse SET Description='You look as if you have become half ghost!' WHERE ID=160053;
UPDATE hotfixes.item_sparse SET Display='Stormheart Headpiece (Custom without type)', Description='Only for transmog by donate' WHERE ID=160077; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Cloak of the Destroyer''s Embrace', Description='This item''s power is boundless. From time to time Wrathion''s wings appear behind you.' WHERE ID=166000; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Shirt of the Destroyer''s Embrace', Description='This item''s power is boundless. From time to time Wrathion''s wings appear behind you.' WHERE ID=166001; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Cloak of the Endless Rainbow', Description='Wherever you go, a rainbow follows you.' WHERE ID=166002; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Shirt of the Endless Rainbow', Description='Wherever you go, a rainbow follows you.' WHERE ID=166003; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Cloak of Flaming Wings', Description='When you put on this cloak, you feel flaming wings sprout from you.' WHERE ID=166004; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Shirt of Flaming Wings', Description='When you put on this shirt, you feel flaming wings sprout from you.' WHERE ID=166005; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Cloak of Soap Bubbles', Description='When you put on this cloak, you start blowing soap bubbles from time to time.' WHERE ID=166006; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Shirt of Soap Bubbles', Description='When you put on this cloak, you start blowing soap bubbles from time to time.' WHERE ID=166007; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Father''s Sock', Description='Just pick it up... and you begin to feel freer...' WHERE ID=166008; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Father''s Sock', Description='Just pick it up... and you begin to feel freer...' WHERE ID=166009; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Void-Touched Firebird' WHERE ID=166509; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Blue Phoenix' WHERE ID=166510; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Flaming Phoenix' WHERE ID=166511; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Reins of the Felclaw' WHERE ID=166512; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Child of Xuen' WHERE ID=166513; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Reins of Loque''nahak' WHERE ID=166514; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Illidari Felstalker' WHERE ID=166515; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Ghostly Hippogryph' WHERE ID=166516; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Kul Tiran Charger' WHERE ID=166517; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Zuldazar Raptor' WHERE ID=166518; -- GUESS
UPDATE hotfixes.item_sparse SET Display='Shu-zen, the Divine Sentinel' WHERE ID=166519;
UPDATE hotfixes.item_sparse SET Display='Lilac Phoenix' WHERE ID=166520; -- GUESS
