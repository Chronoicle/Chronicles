-- #139 follow-up (owner OK 2026-10-01; Claude desktop team dev-owner): two battle pet trainers end their first pet battle
-- quests but do not start them, so those quests were never offered (same gap the alliance-starts fix closed for Grady
-- Bannson 63075 and Valeena 63070): Will Larsons 63083 (Alliance: 31582 Learning the Ropes, 31583 On The Mend) and
-- Matty 63086 (Horde: 31586 On The Mend, 31587 Got one!). Undo: undo_pet_trainer_starters_139.sql
INSERT IGNORE INTO world.creature_queststarter (id, quest) VALUES (63083, 31582), (63083, 31583), (63086, 31586), (63086, 31587);
