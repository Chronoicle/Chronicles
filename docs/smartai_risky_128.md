# SmartAI risky rows of 128 disabled templates (help-helper, 2026-10-04)

Rules used: ENABLE = every risky row is bound to a player/combat/death/quest trigger of the creature itself (combat summons/casts, emotes, credit on death/spell/gossip, escort ends in despawn, proximity quest credit). SKIP = it would act on its own (despawn/faction/flags on respawn, OOC, distance or HP without a trigger), sets data into other creatures/scripts, needs a controller or partners, or runs timed action lists (source_type 9) that are not in the dump.
Enum check against our `SmartScriptMgr.h`: **event 79 = SCENE_TRIGGER** (the dump's rows with event 79 and params `0, entry, dist` are DISTANCE_CREATURE-style rows from another numbering): in our enum they never fire (inert), so they neither help nor harm (17102, 34487, 34594, 38560, 39365, 39589, 44164, 52386). Our event 66 is DUMMY_EFFECT, action 27 PLAY_SPELL_VISUAL_KIT, action 46 MOVE_FORWARD (TC 3.3.5 meanings differ); comments were used for intent.

| entry | name | verdict | reason |
|---|---|---|---|
| 483 | Elaine Trias | ENABLE | emote when a player is seen |
| 523 | Thor | ENABLE | on aggro summons the enraged gryphon/wyvern/felbat (+ say) (combat) |
| 952 | Brother Neals | ENABLE | buffs a player missing Fortitude in sight |
| 1548 | Cursed Darkhound | SKIP | at 40-70% HP casts then force-despawns the hound mid-combat (no trigger) |
| 1549 | Ravenous Darkhound | SKIP | despawn/die rows on HP and spell hit (hound vanishes in combat) |
| 2859 | Gyll | ENABLE | on aggro summons the enraged gryphon/wyvern/felbat (+ say) (combat) |
| 4316 | Kolkar Packhound | ENABLE | follows a nearby creature on respawn (no-op without it) |
| 4980 | Paval Reethe | SKIP | quest scene, timed action lists 498000, 498001 not in the dump |
| 4983 | Ogron | SKIP | escort + FAIL_QUEST on death + action lists 498300, 498301 not in the dump |
| 5917 | Clara Charles | ENABLE | summons a Defias Ambusher when a player comes into sight (quest ambush) |
| 7024 | Agent Kearnen | SKIP | repeatedly casts 79526 on another creature (entry 42656) while a player is in sight |
| 10583 | Gryfe | ENABLE | on aggro summons the enraged gryphon/wyvern/felbat (+ say) (combat) |
| 12636 | Georgia | ENABLE | on aggro summons the enraged gryphon/wyvern/felbat (+ say) (combat) |
| 14394 | Major Mattingly | ENABLE | emote when a player is seen |
| 17102 | Angry Murloc | SKIP | faction change + despawn on a distance event (event 79 is SCENE_TRIGGER in our enum) |
| 17117 | Injured Night Elf Priestess | ENABLE | emote when summoned (escort quest NPC) |
| 17214 | Anchorite Fateema | ENABLE | emote when summoned |
| 17241 | Priestess Kyleen Il'dinare | ENABLE | emote when summoned |
| 17242 | Archaeologist Adamant Ironheart | ENABLE | emote when summoned |
| 17246 | Cookie McWeaksauce | ENABLE | emote when summoned |
| 17649 | Kessel | ENABLE | emote when summoned |
| 17701 | Lord Xiz | ENABLE | summons the quest object (GO 19464, 60 s) on its own death |
| 17843 | Vindicator Kuros | SKIP | quest-turn-in scene that sets data on partner NPCs (Matis/Velen image), waypoints: enable with 17865+17874 together after a test |
| 17865 | Matis | SKIP | scene actor: data set from 17843, waypoints, ends in despawn; needs the controller |
| 17874 | Image of Velen | SKIP | scene actor (Image of Velen): data set from the controller |
| 22160 | Bloodmaul Taskmaster | ENABLE | random emotes out of combat |
| 22384 | Bloodmaul Soothsayer | ENABLE | random emotes out of combat |
| 22484 | Zeppit | ENABLE | follows its invoker when summoned |
| 22931 | Gorrim | ENABLE | on aggro summons the enraged gryphon/wyvern/felbat (+ say) (combat) |
| 24938 | Shattered Sun Marksman | ENABLE | ranged combat AI (shoot, stay at range) |
| 24979 | Dawnblade Marksman | ENABLE | ranged combat AI + arrows |
| 25063 | Dawnblade Hawkrider | ENABLE | attack cast at hostile in sight (hostile mob) |
| 25975 | Master Fire Eater | ENABLE | proximity event-quest credit (Midsummer), per player within 10 yd |
| 26113 | Master Flame Eater | ENABLE | proximity event-quest credit (Midsummer) |
| 26401 | Summer Scorchling | ENABLE | proximity event-quest credit (Midsummer) |
| 27680 | Dahlia Suntouch | ENABLE | ranged AI, curses, summon remnant on death |
| 28095 | Tracker Gekgek | ENABLE | say + Flip Attack in combat |
| 28212 | Bythius the Flesh-Shaper | ENABLE | summons its adds on aggro, poison spray |
| 28465 | Heb'Drakkar Striker | ENABLE | strike/rabies, dismounts on aggro |
| 28557 | Scarlet Peasant | ENABLE | civilian panic AI (phases, emotes, sounds); no world change |
| 28559 | Citizen of New Avalon | ENABLE | civilian panic AI + quest credit on death |
| 28560 | Citizen of New Avalon | ENABLE | civilian panic AI + quest credit on death |
| 29093 | Ian Drake | ENABLE | emote when a player is seen |
| 29102 | Hearthglen Crusader | ENABLE | arrow cast + quest credit on death |
| 29103 | Tirisfal Crusader | ENABLE | arrow cast + quest credit on death |
| 29319 | Icepaw Bear | SKIP | faction restore on reset, run-script on spell hit, gossip random action lists 2931901, 2931902, 2931903, despawn |
| 29480 | Grimwing | ENABLE | on aggro summons the enraged gryphon/wyvern/felbat (+ say) (combat) |
| 29548 | Aimee | ENABLE | emote when a player is seen |
| 29715 | Fialla Sweetberry | ENABLE | emote when a player is seen |
| 31689 | Gnome Diver | ENABLE | answers player emotes with emotes |
| 34258 | Halga Bloodeye | ENABLE | player gossip: summons a kodo / offers quest 860 |
| 34487 | Razormane Raider | SKIP | faction + aura + distance row with event 79 (inert) -> would never work as written |
| 34594 | Burning Blade Raider | SKIP | faction + aura + event 79 (inert) |
| 34651 | Sashya | SKIP | data set + action list 3465100 |
| 34774 | Fire Pillar Controller Bunny | SKIP | action list 3477400 |
| 34851 | Panicked Citizen | ENABLE | civilian panic AI (phases, emotes, sounds) |
| 34874 | Megs Dreadshredder | SKIP | sets unit flags on itself after a quest summon |
| 35064 | Eye of Frost | SKIP | repeating action list 3506400 |
| 36337 | Image of Archmage Xylem | SKIP | data set runs action list 3633700 |
| 36361 | Image of Archmage Xylem | ENABLE | texts on quest accept/reward + proximity credit |
| 36436 | Spirit of Azuregos | ENABLE | event credit by proximity and on gossip |
| 36599 | Arcane Construct | ENABLE | gossip starts its short path, ends by dying (escort end) |
| 36638 | Twilight Lord Katrana | SKIP | sets data on a nearby creature on death |
| 36640 | Sable Drake | SKIP | spell-hit chain into action list 3664000 |
| 36843 | Runestone Bunny | SKIP | despawns on data set from another script (Patch) |
| 36922 | Wounded Soldier | SKIP | data set -> credit + despawn (needs the sender) |
| 36925 | Bilgewater Soldier | SKIP | attacks nearest creature every 2 s (target 11), scene fighter |
| 36958 | Hulking Labgoblin | SKIP | scene with action list 3695800, data sets and credit |
| 36973 | Patch | SKIP | scene controller (data set, text) |
| 36976 | Ticker | SKIP | ranged AI + scene data/text for 36958 group |
| 37139 | Wings of Steel | ENABLE | vehicle ride: waypoints on boarding, despawn at the end |
| 37145 | Military Gyrocopter | ENABLE | vehicle ride: waypoints on boarding, despawn at the end |
| 37888 | Frax Bucketdrop | ENABLE | on aggro summons the enraged gryphon/wyvern/felbat (+ say) (combat) |
| 38560 | Spitescale Flag Bunny | SKIP | inert event 79 + despawn |
| 38808 | Gaahl | ENABLE | zombie transform aura on aggro + combat casts |
| 38809 | Malmo | ENABLE | zombie transform aura on aggro + combat casts |
| 38810 | Teloch | ENABLE | zombie transform aura on aggro + combat casts |
| 38850 | Volcanoth Champion | ENABLE | toggles auto attack only |
| 39069 | Alliance Paratrooper | SKIP | sets/removes unit flags on range and follows a player |
| 39325 | Grandmatron Tekla | SKIP | escort that sets data on a nearby creature and gives credit at the end; verify partner first |
| 39337 | Wayward Plainstrider | ENABLE | combat charge; at 15% credit + flee + despawn (quest rescue) |
| 39365 | The Kodo | SKIP | scene: texts, teleport, inert event 79 |
| 39589 | Brute Bodyguard | ENABLE | combat spells (ev79 row is inert in our enum) |
| 40950 | Captain Tharran | ENABLE | talk sequence when a player is in sight |
| 40951 | Quartermaster Glynna | ENABLE | talk sequence when a player is in sight |
| 41309 | Erunak Vision Area Trigger Bunny | ENABLE | proximity quest credit |
| 41335 | Covert Operative | ENABLE | talk sequence when a player is in sight |
| 42983 | Bartlett the Brave | ENABLE | emote when a player is seen |
| 43173 | Redridge Garrison Watchman | ENABLE | emote when a player is seen |
| 44049 | Giant Mushroom | ENABLE | credit on death, despawn after death |
| 44164 | Sunscale Ravager | ENABLE | combat casts (ev79 despawn row is inert in our enum) |
| 44569 | Sand Lasher | ENABLE | combat cast + ground emote bytes (self-contained) |
| 44573 | Dune Worm | ENABLE | submerge visuals OOC, flags cleared on aggro / restored on evade (combat-bound) |
| 44598 | Desert Bloom | ENABLE | combat cast + ground emote bytes |
| 44694 | Noxious Tunneler | ENABLE | submerge visuals OOC, flags cleared on aggro / restored on evade (combat-bound) |
| 44879 | Ogre Bodyguard | ENABLE | proximity quest credit |
| 44894 | Armoire | ENABLE | passenger boarded: summons + cast (vehicle quest) |
| 45417 | Fiona | SKIP | caravan quest scene: data sets between Fiona/Preston/Argyle/caravan |
| 45429 | Tarenar Sunstrike | SKIP | caravan quest scene actor (data set loops) |
| 45431 | Gidwin Goldbraids | SKIP | caravan quest scene actor (data set loops) |
| 45433 | Preston | SKIP | caravan quest scene actor |
| 45434 | Argyle | SKIP | caravan quest scene actor |
| 45547 | Fiona's Caravan | SKIP | caravan: boarded -> sets data on partners, credit, despawn |
| 45893 | Corpsebeast (Dog) | ENABLE | at 3 stacks casts + despawns itself |
| 45947 | Jon-Jon Jellyneck | ENABLE | player gossip: credit + summons wind raiders |
| 46416 | Twilight Skyterror | ENABLE | kill credit on death |
| 47391 | Highland Black Drake | ENABLE | at 50% summons, credit, despawns (quest fight) |
| 47427 | Grisly Gryphon Guts | SKIP | summons a black drake on its own spawn (no trigger) |
| 47747 | Whisperwind Lasher | ENABLE | combat cast + ground emote bytes |
| 49528 | Arcane Guest Registry | ENABLE | proximity quest credit |
| 49874 | Blackrock Spy | SKIP | reset runs random action lists 4987400, 4987401 |
| 49893 | Lisa McKeever | ENABLE | emote when a player is seen |
| 51193 | Wild Camel | ENABLE | on spell hit: credit, new camel, despawn (quest) |
| 52207 | Nagala Whipshank | ENABLE | player gossip: cast + summons |
| 52211 | Crossroads Caravan Cart | SKIP | cart: data set from Balgor starts it, then despawn |
| 52227 | Balgor Whipshank | SKIP | Balgor scene: data sets to the cart |
| 52386 | Burning Blade Windrider | SKIP | faction change + inert event 79 |
| 61142 | Snake | SKIP | despawns when a player comes into sight |
| 94151 | Pinerock Elderhorn | SKIP | sets data on creatures on death |
| 95319 | Xandris the Dishonored | SKIP | casts + HP action list 9531900 |
| 96949 | Farseer Lopaa | SKIP | OOC repeating action list 9694900 (Dalaran emote event) |
| 106813 | Darkfiend Zealot | ENABLE | proximity quest credit |
| 107987 | Hymdall | SKIP | data-set scene (cast, summon) needs its controller |
| 115325 | Dawnguard Bloodknight | SKIP | attacks nearest creature when a player is in sight |
| 115453 | Shipwrecked Grunt | SKIP | data set runs action list 11545300 |
| 115454 | Shipwrecked Soldier | SKIP | data set runs action list 11545400 |
| 115455 | Shipwrecked Soldier | SKIP | data set runs action list 11545500 |
| 118201 | Ox Style Master | ENABLE | random emotes out of combat |

**ENABLE (79):** 483, 523, 952, 2859, 4316, 5917, 10583, 12636, 14394, 17117, 17214, 17241, 17242, 17246, 17649, 17701, 22160, 22384, 22484, 22931, 24938, 24979, 25063, 25975, 26113, 26401, 27680, 28095, 28212, 28465, 28557, 28559, 28560, 29093, 29102, 29103, 29480, 29548, 29715, 31689, 34258, 34851, 36361, 36436, 36599, 37139, 37145, 37888, 38808, 38809, 38810, 38850, 39337, 39589, 40950, 40951, 41309, 41335, 42983, 43173, 44049, 44164, 44569, 44573, 44598, 44694, 44879, 44894, 45893, 45947, 46416, 47391, 47747, 49528, 49893, 51193, 52207, 106813, 118201

**SKIP (49):** 1548, 1549, 4980, 4983, 7024, 17102, 17843, 17865, 17874, 29319, 34487, 34594, 34651, 34774, 34874, 35064, 36337, 36638, 36640, 36843, 36922, 36925, 36958, 36973, 36976, 38560, 39069, 39325, 39365, 45417, 45429, 45431, 45433, 45434, 45547, 47427, 49874, 52211, 52227, 52386, 61142, 94151, 95319, 96949, 107987, 115325, 115453, 115454, 115455

## Entries that call action lists not in the dump (source_type 9)
Run `SELECT * FROM world.smart_scripts WHERE source_type = 9 AND entryorguid IN (<ids>)` before ever enabling:
- 4980 Paval Reethe: 498000, 498001
- 4983 Ogron: 498300, 498301
- 17865 Matis: 1786500
- 29319 Icepaw Bear: 2931901, 2931902, 2931903
- 34651 Sashya: 3465100
- 34774 Fire Pillar Controller Bunny: 3477400
- 35064 Eye of Frost: 3506400
- 36337 Image of Archmage Xylem: 3633700
- 36640 Sable Drake: 3664000
- 36958 Hulking Labgoblin: 3695800
- 49874 Blackrock Spy: 4987400, 4987401
- 95319 Xandris the Dishonored: 9531900
- 96949 Farseer Lopaa: 9694900
- 115453 Shipwrecked Grunt: 11545300
- 115454 Shipwrecked Soldier: 11545400
- 115455 Shipwrecked Soldier: 11545500

## Notes
- To enable (after your OK): `UPDATE world.creature_template SET AIName = 'SmartAI' WHERE entry IN (<ENABLE list>) AND AIName = '' AND ScriptName = '';` undo = set back to ''.
- Proximity-credit rows (25975, 26113, 26401, 41309, 44879, 49528, 106813, 36361, 36436) credit players within 10 yd every 0.1-5 s; they only count for players who have the quest (intended design of those rows).