-- Undo #90: before 2026-09-29 only guid 2 (James) had achievement 11063; these 34 level-110 characters did not.
DELETE FROM characters.character_achievement WHERE achievement = 11063 AND guid IN (1,5,9,13,17,20,23,25,26,27,28,34,35,36,37,38,40,46,47,48,49,50,51,52,58,59,61,67,84,85,86,87,88,96);
