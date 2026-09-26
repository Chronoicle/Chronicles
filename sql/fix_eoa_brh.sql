-- Issue #14 (Eye of Azshara): the DB named scripts the core does not have, so these NPCs had no AI
UPDATE world.creature_template SET ScriptName = 'npc_wrath_of_azshara_nagas' WHERE entry IN (98173, 100248, 100249, 100250);
UPDATE world.creature_template SET ScriptName = 'npc_deepbeard_quake' WHERE entry = 97916;
UPDATE world.creature_template SET ScriptName = 'npc_serpentrix_hydras' WHERE entry IN (97259, 97260);
UPDATE world.creature_template SET ScriptName = 'npc_hatecoil_monsoon' WHERE entry = 99852;
-- Issue #20 (Black Rook Hold): rolling boulders were trigger creatures with the invisible model for players
UPDATE world.creature_template SET flags_extra = flags_extra & ~128 WHERE entry = 111706;
UPDATE world.creature_template_wdb SET Displayid2 = 0 WHERE Entry = 111706;
