-- #146 Paladin class hall (gabrielf03d): the Libram of Ancient Kings you inscribe your name into (quest 38566
-- "A United Force") was sometimes a small golem; the inscribed book had a Russian name and Italian text.
-- Undo: undo_paladin_libram_146.sql. Apply with --default-character-set=utf8mb4. Live with a worldserver restart.
SET NAMES utf8mb4;

-- 1) Creature 92403 (the book before you sign it) has two displays: 1126 (a small golem model the DB uses as a
--    placeholder) and 63025 (the libram: same model file 983865 as the inscribed book object 240351).
--    CreatureTemplate::GetRandomValidModelId picks one at random, so half the time a golem stood there. Pin the book.
UPDATE world.creature SET modelid = 63025 WHERE guid = 11317975 AND id = 92403;

-- 2) The inscribed book 240351 had its Russian name. Its ruRU name is the same as the newer Libram of Ancient Kings
--    252396, which is English here.
UPDATE world.gameobject_template SET name = 'Libram of Ancient Kings' WHERE entry = 240351;

-- 3) Page 5121 is the first page of six class hall artifact tomes (this libram, Tome of the Ancients, Tome of Fel
--    Secrets, Tales of the Hunt, The Chronicle of Ages, Blood Ledger) and was Italian ("n questo tomo verrà
--    trascritta..."). No English row exists (no locale row, not in the repack dumps or TrinityCore), so this is the
--    Italian line in English.
UPDATE world.page_text SET Text = 'In this tome, the history and power of your Artifact will be recorded as your Artifact Knowledge increases.'
WHERE ID = 5121;

-- 4) Two of those tomes still had Russian names (Сказания об охоте, Хроника веков); English names of the class
--    hall artifact books.
UPDATE world.gameobject_template SET name = 'Tales of the Hunt' WHERE entry = 245039;
UPDATE world.gameobject_template SET name = 'The Chronicle of Ages' WHERE entry = 248501;
