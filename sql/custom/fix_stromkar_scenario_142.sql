-- #142 (gabrielf03d), Arms Warrior artifact scenario "The Sword of Kings" (scenario 1037, map 1539), last step "The Warbreaker".
-- Desktop team (Claude subagent, 2026-10-01). Apply with mysql --default-character-set=utf8mb4. Undo: undo_stromkar_scenario_142.sql
SET NAMES utf8mb4;

-- 1) No artifact, "second click": Zakajz (104276) summons the pickup gameobject 247877 at 1% health. It is a chest, but its
-- loot id (Data1) was 0, so the first click opened an empty loot window; the next click released that empty loot, which
-- ran the pickup script (step credit, scene, Execute bar) without ever giving the sword. The loot row with Strom'kar
-- (gameobject_loot_template 247877) already exists, it just was not linked. Ungrouped chest loot has no loot spec check,
-- so any warrior spec gets it. Name was Russian ("Стромкар"; the sniffed ruRU name is "Стром'кар" = Strom'kar).
UPDATE world.gameobject_template SET Data1 = 247877, name = 'Strom''kar', castBarCaption = 'Retrieving' WHERE entry = 247877;

-- 2) The sword: 247877 uses display 9806 like every artifact pickup (a glow, not a weapon); the weapon is drawn by a
-- visual. Effects Bunny 103151, summoned on the same spot (always the invisible model: flags_extra 128), now shows
-- Strom'kar 1 s after it appears (spell visual kit 65550 = the Strom'kar model; no client spell or display uses that
-- kit, so the server plays it; the delay lets the client know the bunny first). Taking the sword despawns the bunny, so
-- the sword and its sparkles disappear. Only Zakajz summons 103151; its map spawns never get "just summoned".
UPDATE world.smart_scripts SET link = 5 WHERE entryorguid = 103151 AND source_type = 0 AND id = 4 AND link = 0;
UPDATE world.smart_scripts SET link = 3 WHERE entryorguid = 247877 AND source_type = 1 AND id = 2 AND link = 0;

-- 3) No way back: the Fury and Protection pickups send the player to Skyhold (C++ go_art_warswords / go_art_earthwarder:
-- credit 103739 "Returned to Valhallas" + Jump to Skyhold 192085, which leaps and then teleports with 216016). Arms had
-- nothing. Now, when Thoradin finishes his farewell (text 3, after the final Execute), the player gets the same credit
-- and casts Jump to Skyhold on itself (cast flags 2 triggered + 16 target casts on itself). Thoradin lived 3 minutes
-- from the sword pickup; 10 minutes now, so a slow Execute still gets the farewell and the jump.
UPDATE world.event_scripts SET datalong2 = 600000 WHERE id = 49110 AND command = 10 AND datalong = 104307;

DELETE FROM world.smart_scripts WHERE (entryorguid = 247877 AND source_type = 1 AND id = 3)
    OR (entryorguid = 103151 AND source_type = 0 AND id BETWEEN 5 AND 7)
    OR (entryorguid = 104307 AND source_type = 0 AND id BETWEEN 5 AND 6);
INSERT INTO world.smart_scripts (entryorguid, source_type, id, link, event_type, event_flags, event_param1, event_param2,
       action_type, action_param1, action_param2, action_param3, action_param4, action_param5, action_param6,
       target_type, target_param1, target_param2, comment) VALUES
(247877, 1, 3, 0, 61, 0, 0,      0, 45, 2,      2,    0,       0, 0, 0,   19, 103151, 10,  'Link - Set Data 2 2 on the sword bunny (despawn)'),
(103151, 0, 5, 0, 61, 1, 0,      0, 67, 1,      1000, 1000,    0, 0, 100, 1,  0,      0,   'Link - Timed event 1 in 1 s'),
(103151, 0, 6, 0, 59, 1, 1,      0, 27, 65550,  0,    3600000, 0, 0, 0,   1,  0,      0,   'Timed event 1 - Show Strom''kar (visual kit 65550)'),
(103151, 0, 7, 0, 38, 1, 2,      2, 41, 0,      0,    0,       0, 0, 0,   1,  0,      0,   'Data Set 2 2 - Despawn (sword taken)'),
(104307, 0, 5, 6, 52, 1, 3, 104307, 33, 103739, 0,    0,       0, 0, 0,   21, 100,    0,   'Text Over (farewell) - Kill credit Returned to Valhallas'),
(104307, 0, 6, 0, 61, 1, 0,      0, 11, 192085, 18,   0,       0, 0, 0,   21, 100,    0,   'Link - Player casts Jump to Skyhold on itself');

-- 4) Other artifact pickups with Russian names / cast bar text (names and captions only, English from the client's
-- item names and the sniffed ruRU names; 248832 is "Боевые мечи доблести" = Warswords of Valor, as creature 98678
-- "Corrupted Warswords of Valor" in the same scenario).
UPDATE world.gameobject_template SET name = 'Felo''melorn', castBarCaption = 'Retrieving' WHERE entry = 247494;
UPDATE world.gameobject_template SET name = 'Fists of the Heavens', castBarCaption = 'Retrieving' WHERE entry = 248086;
UPDATE world.gameobject_template SET name = 'Scale of the Earth-Warder' WHERE entry = 248831;
UPDATE world.gameobject_template SET name = 'Warswords of Valor', castBarCaption = 'Wielding' WHERE entry = 248832;
UPDATE world.gameobject_template SET name = 'Fangs of the Devourer' WHERE entry = 249347;
UPDATE world.gameobject_template SET name = 'Skull of the Man''ari', castBarCaption = 'Retrieving' WHERE entry = 249821;
UPDATE world.gameobject_template SET name = 'The Silver Hand', castBarCaption = 'Retrieving' WHERE entry = 249824;
UPDATE world.gameobject_template SET castBarCaption = 'Retrieving' WHERE entry IN (251049, 252054);
UPDATE world.gameobject_template SET name = 'Fu Zan, the Wanderer''s Companion', castBarCaption = 'Retrieving' WHERE entry = 251605;
UPDATE world.gameobject_template SET name = 'The Dreadblades' WHERE entry = 254087;
UPDATE world.gameobject_template SET name = 'Sheilun', castBarCaption = 'Retrieving' WHERE entry = 256913;
