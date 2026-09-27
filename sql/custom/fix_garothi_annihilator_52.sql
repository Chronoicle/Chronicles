-- #52 (Claude): trash Garothi Annihilator (123398) Annihilation soak circles. Its stalker 123459 had no script and the
-- circle areatrigger 10793 (aura 245812) had no rows. Same setup as the boss version (122818 / areatrigger 10662).
-- Undo: undo_garothi_annihilator_52.sql
UPDATE world.creature_template SET ScriptName = 'npc_worldbreaker_annihilation_trigger' WHERE entry = 123459;
DELETE FROM world.spell_script_names WHERE spell_id = 245810 AND ScriptName = 'spell_worldbreaker_annihilation_dmg';
INSERT INTO world.spell_script_names (spell_id, ScriptName) VALUES (245810, 'spell_worldbreaker_annihilation_dmg');
DELETE FROM world.areatrigger_template WHERE entry = 10793;
INSERT INTO world.areatrigger_template SELECT 10793, 245812, 15600, 245812, DecalPropertiesId, Radius, RadiusTarget, Height, HeightTarget,
  `Float4`, `Float5`, isMoving, Distance, Speed, RePatch, RePatchSpeed, MoveCurveID, ElapsedTime, MorphCurveID, FacingCurveID, ScaleCurveID,
  HasFollowsTerrain, HasAttached, HasAbsoluteOrientation, HasDynamicShape, HasFaceMovementDir, hasAreaTriggerBox, RollPitchYaw1X,
  RollPitchYaw1Y, RollPitchYaw1Z, TargetRollPitchYawX, TargetRollPitchYawY, TargetRollPitchYawZ, windX, windY, windZ, windSpeed,
  windType, polygon, 'Annihilation (trash Garothi Annihilator, #52)' FROM world.areatrigger_template WHERE entry = 10662;
DELETE FROM world.areatrigger_data WHERE entry = 10793;
INSERT INTO world.areatrigger_data SELECT 10793, 245812, customEntry, moveType, waitTime, speed, activationDelay, updateDelay, maxCount,
  hitType, AngleToCaster, AnglePointA, AnglePointB, maxActiveTargets, Param, RandomRadiusOfSpawn, MoveEndDespawn, WithObjectSize,
  AliveOnly, AllowBoxCheck FROM world.areatrigger_data WHERE entry = 10662;
DELETE FROM world.areatrigger_actions WHERE entry = 10793;
INSERT INTO world.areatrigger_actions SELECT 10793, customEntry, id, moment, actionType, targetFlags, 245813, maxCharges, hasAura, hasAura2,
  hasAura3, hasspell, chargeRecoveryTime, scaleStep, scaleMin, scaleMax, scaleVisualUpdate, hitMaxCount, amount, onDespawn, auraCaster,
  minDistance, 'Annihilation (trash, #52)' FROM world.areatrigger_actions WHERE entry = 10662;
