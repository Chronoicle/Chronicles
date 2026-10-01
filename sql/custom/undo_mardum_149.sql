-- Undo for fix_mardum_149.sql (#149 Mardum): restores the values from before the fix, 2026-10-02.
UPDATE world.creature_template_wdb SET Displayid1 = 169, Displayid2 = 59610 WHERE Entry = 101704;
UPDATE world.creature_template_wdb SET Displayid1 = 1126, Displayid2 = 13069 WHERE Entry = 95049;
UPDATE world.creature_template_wdb SET Displayid1 = 169, Displayid2 = 65037 WHERE Entry = 96768;
UPDATE world.creature_template_wdb SET Displayid1 = 27904, Displayid2 = 65028 WHERE Entry = 93764;
UPDATE world.creature_template_wdb SET Displayid1 = 18783, Displayid2 = 65485 WHERE Entry = 97881;
UPDATE world.creature_template_wdb SET Displayid1 = 1126, Displayid2 = 38795 WHERE Entry = 100717;
UPDATE world.creature_template_wdb SET Displayid1 = 1126, Displayid2 = 16946 WHERE Entry = 33765;

UPDATE world.creature SET PhaseId = '5837 5324 5310 5116 5115 5114'
WHERE map = 1481 AND guid BETWEEN 367303 AND 367430 AND PhaseId = '5310';
UPDATE world.creature SET PhaseId = '5837 5324 5305 5116 5115 5114'
WHERE map = 1481 AND guid BETWEEN 367431 AND 367485 AND PhaseId = '5305';
UPDATE world.creature SET PhaseId = '5837 5324 5116 5115 5114' WHERE map = 1481 AND PhaseId = '5305' AND guid IN (367285, 367286, 367287);
UPDATE world.creature SET PhaseId = '5837 5324 5116 5115 5114 4899' WHERE map = 1481 AND PhaseId = '5305' AND guid IN (367290, 367294);
UPDATE world.creature SET PhaseId = '5837 5324 5116 5115 5114 5095 5094' WHERE map = 1481 AND PhaseId = '5305' AND guid IN (367502, 367503, 367515, 367519, 367524, 367527, 367528, 367533, 367534, 367536, 367539, 367542, 367545, 367546, 367547);
UPDATE world.creature SET PhaseId = '5837 5463 5324 5116 5115 5114 5095 5094' WHERE map = 1481 AND PhaseId = '5305' AND guid IN (367488, 367490, 367499, 367500);
