UPDATE world.creature_template SET ScriptName = 'npc_wrath_of_azshara_naga' WHERE entry IN (98173, 100248, 100249, 100250);
UPDATE world.creature_template SET ScriptName = 'npc_king_deepbeard_quake' WHERE entry = 97916;
UPDATE world.creature_template SET ScriptName = 'npc_blazing_hydra_spawn' WHERE entry = 97259;
UPDATE world.creature_template SET ScriptName = 'npc_arcane_hydra_spawn' WHERE entry = 97260;
UPDATE world.creature_template SET ScriptName = 'npc_lady_hatecoil_monsoon' WHERE entry = 99852;
UPDATE world.creature_template SET flags_extra = flags_extra | 128 WHERE entry = 111706;
UPDATE world.creature_template_wdb SET Displayid2 = 11686 WHERE Entry = 111706;
