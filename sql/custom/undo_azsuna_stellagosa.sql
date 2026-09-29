-- Undo of sql/custom/fix_azsuna_stellagosa.sql (Saving Stellagosa / Overseer Lykill / Dark Revelations).
-- Restores the rows as they were on live on 2026-09-30. Live with a worldserver restart (no .reload).
SET NAMES utf8mb4;

-- 1) chain bunnies and fel locks without PhaseId, bunny respawn 10 s
UPDATE world.creature SET PhaseId = '', spawntimesecs = 10 WHERE guid IN (269444, 269445, 269470) AND id = 90578;
UPDATE world.gameobject SET PhaseId = '' WHERE guid IN (109169, 109175, 109181) AND id = 239455;

-- 2) Fel Lock SmartAI back on Gossip Hello, no key condition
UPDATE world.smart_scripts SET event_type = 64, event_param1 = 0, comment = 'state data'
WHERE entryorguid = 239455 AND source_type = 1 AND id = 0 AND event_type = 70;
DELETE FROM world.conditions WHERE SourceTypeOrReferenceId = 22 AND SourceGroup = 1 AND SourceEntry = 239455 AND SourceId = 1;

-- 3) Stellagosa's Russian line
UPDATE world.creature_text SET Text = 'Спасибо тебе! А теперь я прикончу Стражницу, которая это подстроила.', BroadcastTextID = 0, Sound = 0, comment = 'Охотник на демонов to Player'
WHERE CreatureID = 90546 AND GroupID = 1 AND ID = 0 AND BroadcastTextID = 106120;

-- 4) old objective order (Chains 0, Find 1, Key 2)
UPDATE world.quest_objectives SET StorageIndex = CASE ID WHEN 277273 THEN 0 WHEN 277290 THEN 1 WHEN 277456 THEN 2 END
WHERE QuestID = 37450 AND ID IN (277273, 277290, 277456);
UPDATE world.quest_objectives_locale SET StorageIndex = CASE ID WHEN 277273 THEN 0 WHEN 277290 THEN 1 END
WHERE QuestId = 37450 AND ID IN (277273, 277290);

-- 5) Lykill casts Subduing Chains 185972 directly again, cage area trigger without actions
DELETE FROM world.creature_template_spell WHERE entry = 86535 AND spell = 185972;
INSERT INTO world.creature_template_spell (entry, spell, difficultyMask, Difficulties, comment) VALUES
(86535, 185972, 0, '', '@Subduing Chains');
DELETE FROM world.areatrigger_actions WHERE entry = 4293 AND customEntry = 9038;

-- 6) no server-side VehicleSeat override
DELETE FROM hotfixes.vehicle_seat WHERE ID IN (15333, 15334);
