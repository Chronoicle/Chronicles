-- #149 Mardum (Demon Hunter start zone, map 1481): Empowered Fel Crystal shown as a flying Infernal, floating Infernals
-- around Jace Darkweaver, and Wrath Warriors / Mo'arg Brutes doubled by a dead copy lying under each one.
-- Undo: undo_mardum_149.sql. Live with a worldserver restart.

-- 1) Placeholder Infernal models. These creatures list a real display plus 169 / 1126 / 27904 (all the old Infernal
--    model 24, which the client data uses as a placeholder). Without CREATURE_FLAG_EXTRA_TRIGGER,
--    CreatureTemplate::GetRandomValidModelId picks one of the listed displays at random per spawn, so about half of them
--    were Infernals: the crystal (hover height 4) floated as a flying Infernal, and the Demon Ward bunnies hanging in the
--    air around Jace (Molten Shore and Illidari camp) were small floating Infernals. Keep only the real display.
--    101704 Empowered Fel Crystal -> 59610 (the fel crystal, same as Fel Crystal 93652). The rest are invisible bunnies.
UPDATE world.creature_template_wdb SET Displayid1 = 59610, Displayid2 = 0 WHERE Entry = 101704 AND Displayid1 = 169 AND Displayid2 = 59610;
UPDATE world.creature_template_wdb SET Displayid1 = 13069, Displayid2 = 0 WHERE Entry = 95049 AND Displayid1 = 1126 AND Displayid2 = 13069;   -- Demon Ward (Jace's ward area trigger)
UPDATE world.creature_template_wdb SET Displayid1 = 65037, Displayid2 = 0 WHERE Entry = 96768 AND Displayid1 = 169 AND Displayid2 = 65037;   -- Broken
UPDATE world.creature_template_wdb SET Displayid1 = 65028, Displayid2 = 0 WHERE Entry = 93764 AND Displayid1 = 27904 AND Displayid2 = 65028; -- Shivan
UPDATE world.creature_template_wdb SET Displayid1 = 65485, Displayid2 = 0 WHERE Entry = 97881 AND Displayid1 = 18783 AND Displayid2 = 65485; -- Male Naga (scale 2.00)
UPDATE world.creature_template_wdb SET Displayid1 = 38795, Displayid2 = 0 WHERE Entry = 100717 AND Displayid1 = 1126 AND Displayid2 = 38795; -- Spider Egg
UPDATE world.creature_template_wdb SET Displayid1 = 16946, Displayid2 = 0 WHERE Entry = 33765 AND Displayid1 = 1126 AND Displayid2 = 16946;  -- ELM General Purpose Bunny (scale x2)

-- 2) Despair Ridge battle (quest 40077 The Invasion Begins). Every live demon there (Wrath Warrior 98486, Mo'arg Brute
--    98484, Foul Felstalker 98482, Hellish Imp 98483, Imp Mother 98497, plus the fighting Illidari and critters) has a
--    dead copy (Permanent Feign Death 159474: 97712, 98622, 97594, 98618, 98621) at the exact same spot. The live set is
--    meant for phase 5310 (on while quest 40378 is not taken) and the dead set for phase 5305 (on once 40378 is taken),
--    phase_definitions zone 7705 entries 18/19. But both spawn lists also carry 5114 5115 5116 5324 5837, which the
--    "Legion. Global" entry 1 gives every player in Mardum, so both sets were always visible: a corpse under every demon.
--    Keep only the phase that tells them apart (retail/TrinityCore have the battle spawns in 5310 only).
UPDATE world.creature SET PhaseId = '5310'
WHERE map = 1481 AND guid BETWEEN 367303 AND 367430 AND PhaseId = '5837 5324 5310 5116 5115 5114';      -- 128 live spawns
UPDATE world.creature SET PhaseId = '5305'
WHERE map = 1481 AND guid BETWEEN 367431 AND 367485 AND PhaseId = '5837 5324 5305 5116 5115 5114';      -- 54 after-battle spawns
--    24 more corpses lie exactly under a live demon but sit in other always-on phase lists: after the battle only too.
UPDATE world.creature SET PhaseId = '5305'
WHERE map = 1481 AND id IN (97594, 97712, 98618, 98621, 98622) AND guid IN (
  367285, 367286, 367287, 367290, 367294, 367488, 367490, 367499, 367500, 367502, 367503, 367515, 367519, 367524,
  367527, 367528, 367533, 367534, 367536, 367539, 367542, 367545, 367546, 367547);
