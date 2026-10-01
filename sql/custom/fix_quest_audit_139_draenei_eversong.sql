-- #139 (quest audit 1-10, docs/quest_audit_1_10.md; Claude desktop team subagent 2026-10-01): the BLOCKERs in Ammen Vale /
-- Azuremyst, Sunstrider Isle / Eversong, Camp Narache / Mulgore and Mardum. Undo: sql/custom/undo_quest_audit_139_draenei_eversong.sql.
-- Live with a worldserver restart (no .reload). No client Cache change needed.

-- 1) Ammen Vale main chain. 9280 and 9369 are the same quest "Replenishing the Healing Crystals" (one QuestV2 unique bit,
--    3527): 9280 for draenei (after You Survived! 9279), 9369 for the other Alliance races (its race mask is Alliance
--    without draenei). 9369 had PrevQuestID 9280 and Urgent Delivery! (9409) needed 9369, so nobody could ever take 9369
--    and every draenei stopped after 9280 (9409, 9371, 10302, 9293, 9294, 10304, 9303, 9309, 10303, 9311, 9312, 9313,
--    9305, 9799 cut off). Now 9409 follows either variant (Player::SatisfyQuestPreviousQuest: any rewarded previous quest
--    is enough; 9280's NextQuestID makes it one), 9369 needs nothing, and Proenitus offers 9409 when 9280 is handed in
--    (RewardNextQuest, as 9369 already does). Draenei who already did 9280 can take 9409 from Proenitus.
UPDATE world.quest_template_addon SET PrevQuestID = 0 WHERE ID = 9369 AND PrevQuestID = 9280;
UPDATE world.quest_template_addon SET NextQuestID = 9409 WHERE ID = 9280 AND NextQuestID = 9369;
UPDATE world.quest_template SET RewardNextQuest = 9409 WHERE ID = 9280 AND RewardNextQuest = 0;

-- 2) Draenei class quests (same model as Shaman Training 9421 -> Primal Strike 26969, #118): the class trainer starts and
--    ends the auto-accept/auto-complete "<Class> Training" quest, which leads to the class quest (RewardNextQuest).
--    Warrior, Hunter and Paladin Training and Monk Training (31172) had an ender but no starter, so Your First Lesson
--    (26958), Steadying Your Shot (26963), The Light's Power (26966) and The Tiger Palm (31173) were never offered.
INSERT IGNORE INTO world.creature_queststarter (id, quest) VALUES
(16503, 9289),    -- Kore, Warrior Trainer
(16499, 9288),    -- Keilnei, Hunter Trainer
(16501, 9287),    -- Aurelon, Paladin Trainer
(63335, 31172);   -- Mojo Stormstout, Monk Trainer

-- 3) Ways of the Light (10069, blood elf paladin) had PrevQuestID 8328 (Mage Training), which no paladin can take. Its
--    real letter, Paladin Training (9676, Magistrix Erona -> Jesthenis Sunstriker, RewardNextQuest 10069; in the Legion
--    sniffs, locale VerifiedBuild 23877), was in `disables` as "Deprecated quest" and had no addon row (any class could
--    have taken it). Same setup as Mage Training 8328 now.
DELETE FROM world.disables WHERE sourceType = 1 AND entry = 9676;
DELETE FROM world.quest_template_addon WHERE ID = 9676;
INSERT INTO world.quest_template_addon (ID, AllowableClasses, PrevQuestID, NextQuestID, SpecialFlags) VALUES (9676, 2, 8325, 10069, 4);
UPDATE world.quest_template_addon SET PrevQuestID = 9676 WHERE ID = 10069 AND PrevQuestID = 8328;

-- 4) Warrior Training (8329, blood elf warrior) ends at Delios Silverblade (43010, Warrior Trainer, also the giver of
--    Charge! 27091), who had a template, equipment and addon but no spawn: no warrior trainer on Sunstrider Isle at all.
--    Spawned in the Sunspire's lower ring between Ranger Sallina and Matron Arena: Wowhead's retail points (Sunstrider
--    Isle map 64.4/43, 64.8/42.4, 64.8/42.6) and its Cataclysm point (Eversong 39.2/20.2), converted with WorldMapArea 893
--    (the same conversion puts the spawned trainers there within 3 yd of their rows), ~2 yd into the room so he does not
--    stand inside the "[DND] TAR Pedestal" 41805 and its collision object at (10380.7, -6419.4).
DELETE FROM world.creature WHERE guid = 146913901;
INSERT INTO world.creature (guid, id, map, zoneId, areaId, spawnMask, phaseMask, PhaseId, modelid, equipment_id, position_x, position_y, position_z, orientation, spawntimesecs, spawndist, currentwaypoint, curhealth, curmana, MovementType, npcflag, npcflag2, unit_flags, dynamicflags, AiID, MovementID, MeleeID, isActive, skipClone, personal_size, isTeemingSpawn, unit_flags3) VALUES
(146913901, 43010, 530, 6455, 3431, 1, 1, '', 0, 0, 10377.8, -6419.5, 38.6156, 3.3, 300, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

-- 5) Rite of Wisdom (773, Mulgore) needed Rite of Vision 772, which is in `disables` (the pre-Cataclysm version). Its
--    7.3.5 replacement is Rite of Vision 20441 (Zarlman Two-Moons, in the client's Mulgore QuestLine 564 like 773).
UPDATE world.quest_template_addon SET PrevQuestID = 20441 WHERE ID = 773 AND PrevQuestID = 772;

-- 6) Enter the Illidari: Ashtongue (40378, Mardum): go_q40378 gives the "Ashtongue forces" credit 88872, which had a
--    creature_template_wdb row but no creature_template ("non existing creature entry, quest can't be done" at load).
--    Player::KilledMonsterCredit matches the objective by entry, so the credit already counted; this only adds the
--    missing template, copied from its twin 94406 ("Enter the Illidari: Coilskar" Legion Gateway Kill Credit).
INSERT IGNORE INTO world.creature_template (entry,gossip_menu_id,minlevel,maxlevel,HealthScalingExpansion,SandboxScalingID,exp,faction,npcflag,npcflag2,speed_walk,speed_run,speed_fly,scale,mindmg,maxdmg,dmgschool,attackpower,dmg_multiplier,baseattacktime,rangeattacktime,unit_class,unit_flags,unit_flags2,unit_flags3,dynamicflags,trainer_type,trainer_spell,trainer_class,trainer_race,minrangedmg,maxrangedmg,rangedattackpower,lootid,pickpocketloot,skinloot,resistance1,resistance2,resistance3,resistance4,resistance5,resistance6,spell1,spell2,spell3,spell4,spell5,spell6,spell7,spell8,PetSpellDataId,VehicleId,mingold,maxgold,AIName,MovementType,HoverHeight,Mana_mod_extra,Armor_mod,RegenHealth,mechanic_immune_mask,flags_extra,ControllerID,WorldEffects,PassiveSpells,StateWorldEffectID,SpellStateVisualID,SpellStateAnimID,SpellStateAnimKitID,IgnoreLos,AffixState,MaxVisible,ScriptName)
SELECT 88872,gossip_menu_id,minlevel,maxlevel,HealthScalingExpansion,SandboxScalingID,exp,faction,npcflag,npcflag2,speed_walk,speed_run,speed_fly,scale,mindmg,maxdmg,dmgschool,attackpower,dmg_multiplier,baseattacktime,rangeattacktime,unit_class,unit_flags,unit_flags2,unit_flags3,dynamicflags,trainer_type,trainer_spell,trainer_class,trainer_race,minrangedmg,maxrangedmg,rangedattackpower,lootid,pickpocketloot,skinloot,resistance1,resistance2,resistance3,resistance4,resistance5,resistance6,spell1,spell2,spell3,spell4,spell5,spell6,spell7,spell8,PetSpellDataId,VehicleId,mingold,maxgold,AIName,MovementType,HoverHeight,Mana_mod_extra,Armor_mod,RegenHealth,mechanic_immune_mask,flags_extra,ControllerID,WorldEffects,PassiveSpells,StateWorldEffectID,SpellStateVisualID,SpellStateAnimID,SpellStateAnimKitID,IgnoreLos,AffixState,MaxVisible,ScriptName
FROM world.creature_template WHERE entry = 94406;
