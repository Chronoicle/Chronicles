-- #145 Warrior class hall (gabrielf03d): the Val'kyr of Odyn in Dalaran stood half in the floor and her option was
-- Russian; the Forge of Odyn (and the other Skyhold objects) had Russian names. Undo: undo_skyhold_valkyr_forge_145.sql.
-- Live with a worldserver restart (no .reload).
SET NAMES utf8mb4;

-- 1) Her model is made to hover 2.8 yards up (HoverHeight 2.8 = model hover 4.0 x display scale 0.7), but the
--    spawns sit right on the floor and her movement data (Ground 0, Flight 1 = no gravity) never adds the hover offset,
--    so the lower half of her body was under the floor. Lift the 8 ground spawns on the Broken Isles by 2.8; the
--    Skyhold one (map 1479) already flies in the air.
UPDATE world.creature SET position_z = CASE guid
    WHEN 12843688 THEN 748.633  -- Dalaran, Krasus' Landing (was 745.833)
    WHEN 12843690 THEN 142.179
    WHEN 12843691 THEN 66.334
    WHEN 12843692 THEN 144.745
    WHEN 12843693 THEN 771.173
    WHEN 12843694 THEN 134.874
    WHEN 12843695 THEN 183.682
    WHEN 12843696 THEN 4.4079
    END
WHERE id = 93819 AND guid IN (12843688, 12843690, 12843691, 12843692, 12843693, 12843694, 12843695, 12843696);

-- 2) Her option (warriors only, casts Jump to Skyhold) was Russian with no broadcast text. The client has no
--    "How do I get to Skyhold?" line; 128931 "Skyhold." is the client's own option for the warrior jump to Skyhold
--    (Danica on the Broken Shore uses it).
UPDATE world.gossip_menu_option SET OptionText = 'Skyhold.', OptionBroadcastTextID = 128931
WHERE MenuID = 93819 AND OptionID = 0;

-- 3) Skyhold objects with Russian names: the English names from retail (TrinityCore's sniffed gameobject_template,
--    same entries, types and displays; the ruRU locale rows mean the same).
UPDATE world.gameobject_template SET name = 'Forge of Odyn' WHERE entry = 245726;
UPDATE world.gameobject_template SET name = 'Valhallas Portal' WHERE entry = 244516;
UPDATE world.gameobject_template SET name = 'Saga of the Valarjar' WHERE entry = 248979;
UPDATE world.gameobject_template SET name = 'The Legend of Odyn' WHERE entry = 248980;
UPDATE world.gameobject_template SET name = 'The Favored of Odyn' WHERE entry = 248981;
UPDATE world.gameobject_template SET name = 'Artifact Research Notes' WHERE entry = 252801;
UPDATE world.gameobject_template SET name = 'Blessing of Mjolnir' WHERE entry = 252887;

-- 4) The last two Russian lines in Skyhold without a broadcast text. Durnolf's group 0 is the same line as his English
--    group 3 (122735). Crowley's group 0 (quest 45876 reward) was a copy of Eitrigg's "Hail to the Battlelord!";
--    128932 "To the Battlelord!" is Crowley's own voiced line (VO_72_Lord_Darius_Crowley_32).
UPDATE world.creature_text SET Text = '$n! I have goods for you! Come!', BroadcastTextID = 122735, comment = 'Quartermaster Durnolf to Player'
WHERE CreatureID = 112392 AND GroupID = 0 AND ID = 0;
UPDATE world.creature_text SET Text = 'To the Battlelord!', BroadcastTextID = 128932, comment = 'Lord Darius Crowley to Player'
WHERE CreatureID = 117480 AND GroupID = 0 AND ID = 0;
