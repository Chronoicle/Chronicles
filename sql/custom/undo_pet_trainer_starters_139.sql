-- Undo fix_pet_trainer_starters_139.sql (none of these four rows existed before)
DELETE FROM world.creature_queststarter WHERE (id, quest) IN ((63083, 31582), (63083, 31583), (63086, 31586), (63086, 31587));
