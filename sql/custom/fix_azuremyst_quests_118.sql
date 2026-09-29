-- #118 (tyrvana, owner OK 2026-09-29; Claude desktop team subagent): Azuremyst Isle (draenei start).
-- Undo: sql/custom/undo_azuremyst_quests_118.sql. Live with a worldserver restart (no .reload) plus the C++ in the same
-- commit (npcs_special.cpp: Flame Shock gives the dummy practice credit; GameObject.cpp: quest gathering nodes sparkle).
-- Players may need to delete the client's Cache folder to see the new quest texts and map markers.

-- 1) Inoculation (9303): the Inoculating Crystal (22962, spell 29528, a 3 s aura on Nestlewood Owlkin 16518) gave the
--    credit on hit. The old SmartAI was a broken merge (ids 1 and 2 twice): credit at once, then despawn in 5 s or a
--    summoned 16534. Now: on hit the owlkin runs around (Self Fear 31365) for the crystal's 3 s, then emotes, turns into
--    Inoculated Nestlewood Owlkin 16534 (UpdateEntry), the player who used the crystal gets the credit, and it despawns
--    15 s later (visible 10 s + 5 s) and respawns as a normal owlkin (spawntimesecs). Phase 1 keeps a pending 3 s timer
--    from firing after the owlkin died and respawned (OnReset sets phase 0).
DELETE FROM world.smart_scripts WHERE entryorguid = 16518 AND source_type = 0;
INSERT INTO world.smart_scripts (entryorguid, source_type, id, link, Difficulties, event_type, event_phase_mask, event_chance, event_flags, event_param1, event_param2, event_param3, event_param4, event_param5, action_type, action_param1, action_param2, action_param3, action_param4, action_param5, action_param6, target_type, target_param1, target_param2, target_param3, target_param4, target_x, target_y, target_z, target_o, comment) VALUES
(16518,0,0,1,'',8,0,100,1,29528,0,0,0,0,22,1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Nestlewood Owlkin - On Spellhit Inoculate Nestlewood Owlkin - Set Event Phase 1'),
(16518,0,1,2,'',61,0,100,0,0,0,0,0,0,64,1,0,0,0,0,0,7,0,0,0,0,0,0,0,0,'Nestlewood Owlkin - Link - Store Invoker'),
(16518,0,2,3,'',61,0,100,0,0,0,0,0,0,11,31365,2,0,0,0,0,1,0,0,0,0,0,0,0,0,'Nestlewood Owlkin - Link - Cast Self Fear (runs around)'),
(16518,0,3,0,'',61,0,100,0,0,0,0,0,0,67,1,3000,3000,0,0,100,1,0,0,0,0,0,0,0,0,'Nestlewood Owlkin - Link - Timed Event 1 in 3 s (crystal aura duration)'),
(16518,0,4,5,'',59,1,100,0,1,0,0,0,0,28,31365,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Nestlewood Owlkin - On Timed Event 1 (Phase 1) - Remove Self Fear'),
(16518,0,5,6,'',61,0,100,0,0,0,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Nestlewood Owlkin - Link - Say Line 0 (emote)'),
(16518,0,6,7,'',61,0,100,0,0,0,0,0,0,36,16534,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Nestlewood Owlkin - Link - Update Entry Inoculated Nestlewood Owlkin'),
(16518,0,7,8,'',61,0,100,0,0,0,0,0,0,33,16534,0,0,0,0,0,12,1,0,0,0,0,0,0,0,'Nestlewood Owlkin - Link - Quest Credit Inoculated Nestlewood Owlkin (stored player)'),
(16518,0,8,0,'',61,0,100,0,0,0,0,0,0,41,10000,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Nestlewood Owlkin - Link - Despawn in 10 s');

-- 2) Primal Strike (26969): Primal Strike 73899 was removed in 7.0.3 (no SkillLineAbility / SpecializationSpells row),
--    so "Reach Level 3 to Learn Primal Strike" could never complete; retail dropped the quest in 7.0.3 and it was in
--    `disables` here. Same model as the night elf class quests / #104: the quest comes back with the spell a shaman
--    really learns at level 3 in 7.3.5 (pre-10 shamans are Elemental: Flame Shock 188389). All six "learn Primal Strike"
--    objectives are the same fault (the orc, tauren, goblin and troll ones are still offered and can't be completed).
DELETE FROM world.disables WHERE sourceType = 1 AND entry = 26969;
-- no addon row: every draenei class could take the shaman quest. Class + chain like the other draenei class quests.
INSERT INTO world.quest_template_addon (ID, AllowableClasses, PrevQuestID) VALUES (26969, 64, 9421);
UPDATE world.quest_objectives SET ObjectID = 188389 WHERE Type = 5 AND ObjectID = 73899;
-- quest log / objective texts (enUS locale rows are what enUS clients get); titles stay, like #104
UPDATE world.quest_template SET LogDescription = REPLACE(LogDescription, 'Primal Strike', 'Flame Shock'),
  QuestDescription = REPLACE(QuestDescription, 'Primal Strike', 'Flame Shock')
WHERE ID IN (14011, 24527, 24760, 25143, 26969, 27027);
UPDATE world.quest_template_locale SET LogDescription = REPLACE(LogDescription, 'Primal Strike', 'Flame Shock'),
  QuestDescription = REPLACE(QuestDescription, 'Primal Strike', 'Flame Shock')
WHERE ID IN (14011, 24527, 24760, 25143, 26969, 27027) AND locale = 'enUS';
UPDATE world.quest_objectives SET Description = REPLACE(Description, 'Primal Strike', 'Flame Shock')
WHERE QuestID IN (14011, 24527, 24760, 25143, 26969, 27027);
UPDATE world.quest_objectives_locale SET Description = REPLACE(Description, 'Primal Strike', 'Flame Shock')
WHERE QuestId IN (14011, 24527, 24760, 25143, 26969, 27027) AND locale = 'enUS';
-- troll shaman (24760) practises on Tiki Target 38038 (SmartAI, not npc_training_dummy)
INSERT INTO world.smart_scripts (entryorguid, source_type, id, link, Difficulties, event_type, event_phase_mask, event_chance, event_flags, event_param1, event_param2, event_param3, event_param4, event_param5, action_type, action_param1, action_param2, action_param3, action_param4, action_param5, action_param6, target_type, target_param1, target_param2, target_param3, target_param4, target_x, target_y, target_z, target_o, comment) VALUES
(38038,0,3,0,'',8,0,100,0,188389,0,0,0,0,33,44175,0,0,0,0,0,7,0,0,0,0,0,0,0,0,'SpellHit (Flame Shock) - Kill Credit');

-- 3) An Alternative Alternative (9473).
-- 3a) Map markers: same broken merge of builds 23877/26124 as #84/#88/#105 (objective areas shifted by one Idx1, the
--     turn-in "area" = Daedal + 4 points of an objective area, one objective polygon with a tail of another). Rebuilt
--     from the 7.3.5 client's QuestPOIBlob 29961 (turn-in) + 29962-29966 (5 bulb areas) + 399989 (quest giver) and
--     QuestPOIPoint; the turn-in point (-4191, -12469) is Daedal's spawn (17215 at -4191.2, -12470.0).
DELETE FROM world.quest_poi WHERE QuestID = 9473;
DELETE FROM world.quest_poi_points WHERE QuestID = 9473;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9473,0,0,-1,0,0,530,464,0,0,1,0,0,0,0,26972),
(9473,0,1,0,258430,23692,530,464,0,0,0,0,0,0,0,26972),
(9473,1,2,0,258430,23692,530,464,0,0,0,0,0,0,0,26972),
(9473,2,3,0,258430,23692,530,464,0,0,0,0,0,0,0,26972),
(9473,3,4,0,258430,23692,530,464,0,0,0,0,0,0,0,26972),
(9473,4,5,0,258430,23692,530,464,0,0,0,0,0,0,0,26972),
(9473,0,6,32,0,0,530,464,0,0,0,0,0,141069,0,26972);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9473,0,0,-4191,-12469,26972),
(9473,1,0,-3850,-12811,26972),(9473,1,1,-3708,-12688,26972),(9473,1,2,-3672,-12610,26972),(9473,1,3,-3653,-12557,26972),
(9473,1,4,-3741,-12416,26972),(9473,1,5,-3802,-12507,26972),
(9473,2,0,-4224,-12974,26972),(9473,2,1,-4019,-12889,26972),(9473,2,2,-4010,-12870,26972),(9473,2,3,-4009,-12858,26972),
(9473,2,4,-4118,-12770,26972),(9473,2,5,-4160,-12792,26972),(9473,2,6,-4174,-12817,26972),(9473,2,7,-4195,-12857,26972),
(9473,2,8,-4206,-12886,26972),
(9473,3,0,-4372,-12782,26972),(9473,3,1,-4266,-12698,26972),(9473,3,2,-4242,-12614,26972),(9473,3,3,-4231,-12392,26972),
(9473,3,4,-4252,-12312,26972),(9473,3,5,-4289,-12278,26972),(9473,3,6,-4384,-12276,26972),(9473,3,7,-4455,-12585,26972),
(9473,4,0,-4332,-12186,26972),(9473,4,1,-4224,-12106,26972),(9473,4,2,-4236,-12052,26972),(9473,4,3,-4303,-12110,26972),
(9473,5,0,-3997,-12378,26972),(9473,5,1,-3944,-12336,26972),(9473,5,2,-3982,-12238,26972),(9473,5,3,-4051,-12247,26972),
(9473,5,4,-4025,-12321,26972),
(9473,6,0,-4191,-12469,26972);
-- 3b) Azure Snapdragon 181644 (the bulbs' only real source; 84 spawns, phase 1, fine) is a type 50 gathering node with
--     GO_FLAG_INTERACT_COND: the core never sent it the "activate + sparkle" flag (fixed in GameObject.cpp), so nobody
--     could click it. Its Data14 (= gathering spell for type 50) was 19676 "Tame Snow Leopard", the old chest
--     openTextID carried over by the type conversion, cast on the player at every loot.
UPDATE world.gameobject_template SET Data14 = 0 WHERE entry = 181644 AND Data14 = 19676;
