-- Undo for fix_azuremyst_quests_118.sql (#118): restores the rows exactly as they were on 2026-09-29.

-- 1) Nestlewood Owlkin SmartAI (the old rows, duplicate ids included)
DELETE FROM world.smart_scripts WHERE entryorguid = 16518 AND source_type = 0;
INSERT INTO world.smart_scripts (entryorguid, source_type, id, link, Difficulties, event_type, event_phase_mask, event_chance, event_flags, event_param1, event_param2, event_param3, event_param4, event_param5, action_type, action_param1, action_param2, action_param3, action_param4, action_param5, action_param6, target_type, target_param1, target_param2, target_param3, target_param4, target_x, target_y, target_z, target_o, comment) VALUES
(16518,0,0,1,'',8,0,100,1,29528,0,0,0,0,33,16534,0,0,0,0,0,7,0,0,0,0,0,0,0,0,'on spellhit - give credit'),
(16518,0,1,0,'',61,0,100,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,'say'),
(16518,0,1,2,'',61,0,100,0,0,0,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'say'),
(16518,0,2,0,'',61,0,100,0,0,0,0,0,0,41,5000,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'link - despawn'),
(16518,0,2,3,'',61,0,100,0,0,0,0,0,0,12,16534,3,30000,0,0,0,1,0,0,0,0,0,0,0,0,'say'),
(16518,0,3,0,'',61,0,100,0,0,0,0,0,0,41,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'link - despawn');

-- 2) Primal Strike quests
INSERT INTO world.disables (sourceType, entry, flags, params_0, params_1, comment) VALUES (1, 26969, 0, '', '', 'Deprecated quest: Primal Strike');
DELETE FROM world.quest_template_addon WHERE ID = 26969;
UPDATE world.quest_objectives SET ObjectID = 73899
WHERE ID IN (252512, 255939, 256534, 264911, 265028, 265483) AND Type = 5 AND ObjectID = 188389;
-- none of these texts contained 'Flame Shock' before the fix, so the reverse REPLACE is exact
UPDATE world.quest_template SET LogDescription = REPLACE(LogDescription, 'Flame Shock', 'Primal Strike'),
  QuestDescription = REPLACE(QuestDescription, 'Flame Shock', 'Primal Strike')
WHERE ID IN (14011, 24527, 24760, 25143, 26969, 27027);
UPDATE world.quest_template_locale SET LogDescription = REPLACE(LogDescription, 'Flame Shock', 'Primal Strike'),
  QuestDescription = REPLACE(QuestDescription, 'Flame Shock', 'Primal Strike')
WHERE ID IN (14011, 24527, 24760, 25143, 26969, 27027) AND locale = 'enUS';
UPDATE world.quest_objectives SET Description = REPLACE(Description, 'Flame Shock', 'Primal Strike')
WHERE QuestID IN (14011, 24527, 24760, 25143, 26969, 27027);
UPDATE world.quest_objectives_locale SET Description = REPLACE(Description, 'Flame Shock', 'Primal Strike')
WHERE QuestId IN (14011, 24527, 24760, 25143, 26969, 27027) AND locale = 'enUS';
DELETE FROM world.smart_scripts WHERE entryorguid = 38038 AND source_type = 0 AND id = 3 AND event_param1 = 188389;

-- 3) An Alternative Alternative map markers (the old merged rows) and Azure Snapdragon Data14
DELETE FROM world.quest_poi WHERE QuestID = 9473;
DELETE FROM world.quest_poi_points WHERE QuestID = 9473;
INSERT INTO world.quest_poi (QuestID, BlobIndex, Idx1, ObjectiveIndex, QuestObjectiveID, QuestObjectID, MapID, WorldMapAreaId, Floor, Priority, Flags, WorldEffectID, PlayerConditionID, WoDUnk1, AlwaysAllowMergingBlobs, VerifiedBuild) VALUES
(9473,0,0,0,258430,23692,530,464,0,0,1,0,0,0,0,23877),(9473,0,1,0,258430,23692,530,464,0,0,0,0,0,0,0,26124),
(9473,0,6,32,0,0,530,464,0,0,0,0,0,141069,0,26124),(9473,1,1,0,258430,23692,530,464,0,0,1,0,0,0,0,23877),
(9473,1,2,0,258430,23692,530,464,0,0,0,0,0,0,0,26124),(9473,2,2,0,258430,23692,530,464,0,0,1,0,0,0,0,23877),
(9473,2,3,0,258430,23692,530,464,0,0,0,0,0,0,0,26124),(9473,3,3,0,258430,23692,530,464,0,0,1,0,0,0,0,23877),
(9473,3,4,0,258430,23692,530,464,0,0,0,0,0,0,0,26124),(9473,4,4,0,258430,23692,530,464,0,0,1,0,0,0,0,23877),
(9473,4,5,0,258430,23692,530,464,0,0,0,0,0,0,0,26124),(9473,5,5,-1,0,0,530,464,0,0,1,0,0,0,0,23877);
INSERT INTO world.quest_poi_points (QuestID, Idx1, Idx2, X, Y, VerifiedBuild) VALUES
(9473,0,0,-3850,-12811,23877),(9473,0,1,-3708,-12688,23877),(9473,0,2,-3672,-12610,23877),(9473,0,3,-3653,-12557,23877),
(9473,0,4,-3741,-12416,23877),(9473,0,5,-3802,-12507,23877),(9473,1,0,-4224,-12974,23877),(9473,1,1,-4019,-12889,23877),
(9473,1,2,-4010,-12870,23877),(9473,1,3,-4009,-12858,23877),(9473,1,4,-4118,-12770,23877),(9473,1,5,-4160,-12792,23877),
(9473,1,6,-4174,-12817,23877),(9473,1,7,-4195,-12857,23877),(9473,1,8,-4206,-12886,23877),(9473,2,0,-4372,-12782,23877),
(9473,2,1,-4266,-12698,23877),(9473,2,2,-4242,-12614,23877),(9473,2,3,-4231,-12392,23877),(9473,2,4,-4252,-12312,23877),
(9473,2,5,-4289,-12278,23877),(9473,2,6,-4384,-12276,23877),(9473,2,7,-4455,-12585,23877),(9473,2,8,-4206,-12886,26124),
(9473,3,0,-4332,-12186,23877),(9473,3,1,-4224,-12106,23877),(9473,3,2,-4236,-12052,23877),(9473,3,3,-4303,-12110,23877),
(9473,3,4,-4252,-12312,26124),(9473,3,5,-4289,-12278,26124),(9473,3,6,-4384,-12276,26124),(9473,3,7,-4455,-12585,26124),
(9473,4,0,-3997,-12378,23877),(9473,4,1,-3944,-12336,23877),(9473,4,2,-3982,-12238,23877),(9473,4,3,-4051,-12247,23877),
(9473,4,4,-4025,-12321,23877),(9473,5,0,-4191,-12469,23877),(9473,5,1,-3944,-12336,26124),(9473,5,2,-3982,-12238,26124),
(9473,5,3,-4051,-12247,26124),(9473,5,4,-4025,-12321,26124),(9473,6,0,-4191,-12469,26124);
UPDATE world.gameobject_template SET Data14 = 19676 WHERE entry = 181644 AND Data14 = 0;
