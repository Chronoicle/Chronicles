-- Azsuna, Saving Stellagosa (37450) / Overseer Lykill (86535) / Dark Revelations (37449) (gabrielf03d, approved
-- reporter; Claude desktop team subagent, part B). Undo: sql/custom/undo_azsuna_stellagosa.sql.
-- Live with a worldserver restart (no .reload). Players may need to delete the client's Cache folder to see the new
-- objective order and the Lykill map marker (quest objectives are cached by the client).
SET NAMES utf8mb4;

-- 1) Stellagosa had no chains and flew off "as if saved" on her own. Her SmartAI (90546) frees her every 35 s when she
--    has no Cosmetic Chains 65612, which the 3 Stellagosa Chain Bunnies (90578) channel on her. The bunnies (and the 3 Fel
--    Locks 239455) had no PhaseId while Stellagosa has the phases of "Saving Stellagosa" (phase_definitions 7334 entry 9),
--    and this core's phase rule (WorldObject::InSamePhaseId) lets an object with no PhaseId and one with PhaseIds never
--    see each other: the bunnies never found her (no chains, so she freed herself every 35 s), and her reset could not
--    respawn them. Bunnies and locks get her phases, so she, the chains and the locks show and work together.
--    Bunny respawn 10 s -> 120 s: with 10 s (+5 s despawn delay) all 3 chains were never down at the same time for her
--    35 s check, so she could not be freed even with the key. Her own reset (actionlist 9145146) respawns them after her
--    flight, and the locks respawn after 180 s, so the next player is not blocked.
UPDATE world.creature SET PhaseId = '6838 6802 6759 6536 6327 5433 4483 4438 4270', spawntimesecs = 120
WHERE guid IN (269444, 269445, 269470) AND id = 90578;
UPDATE world.gameobject SET PhaseId = '6838 6802 6759 6536 6327 5433 4483 4438 4270'
WHERE guid IN (109169, 109175, 109181) AND id = 239455;

-- 2) A Fel Lock dropped its chain without Lykill's Key: its SmartAI used Gossip Hello (64), which the client's "report
--    use" packet fires on every click, key or not (HandleGameobjectReportUse -> GossipHello). The key check (lock 2358 =
--    item 120359, via the key's "Unlocking" spell 178964) only guards GameObject::Use, so the chain now drops on the
--    loot state change of a real use (event 70, state 2 = GO_ACTIVATED, invoker = the user), and only for a player who
--    has the key (condition, source 22 group id+1 = 1, source_type 1).
UPDATE world.smart_scripts SET event_type = 70, event_param1 = 2, comment = 'Fel Lock - On Use (GO_ACTIVATED, has Lykill''s Key) - Set Data 0 1 on closest Stellagosa Chain Bunny'
WHERE entryorguid = 239455 AND source_type = 1 AND id = 0 AND event_type = 64;
DELETE FROM world.conditions WHERE SourceTypeOrReferenceId = 22 AND SourceGroup = 1 AND SourceEntry = 239455 AND SourceId = 1;
INSERT INTO world.conditions (SourceTypeOrReferenceId, SourceGroup, SourceEntry, SourceId, ElseGroup, ConditionTypeOrReference, ConditionTarget, ConditionValue1, ConditionValue2, ConditionValue3, NegativeCondition, ErrorTextId, ScriptName, Comment) VALUES
(22, 1, 239455, 1, 0, 2, 0, 120359, 1, 0, 0, 0, '', 'Fel Lock: drop the chain only for a player with Lykill''s Key');

-- 3) Stellagosa spoke Russian when freed: her line (Talk 1 from actionlist 9054600) had BroadcastTextID 0, so the
--    Russian `Text` went out as is. The Russian is a translation of retail BroadcastText 106120 (female text, sound
--    57408): "My thanks, $pr. Now I am going to finish off the warden who did this to me." (display 64545 is female).
UPDATE world.creature_text SET Text = 'My thanks, $pr. Now I am going to finish off the warden who did this to me.', BroadcastTextID = 106120, Sound = 57408, comment = 'Stellagosa to Player'
WHERE CreatureID = 90546 AND GroupID = 1 AND ID = 0 AND BroadcastTextID = 0;

-- 4) No map marker for Overseer Lykill: the core sends quest objectives in StorageIndex order, and the 7.0 beta rows
--    (VerifiedBuild 21737) had Chains unlocked 0, Find Stellagosa 1, Lykill's Key 2. The key objective is "sequenced"
--    (flag 2: hidden until the objectives before it are done), so it and its marker at Lykill stayed hidden until the
--    chains were unlocked, which needs the key. The 7.3.5 client's QuestPOIBlob (323470/323471/323472, already in
--    quest_poi) has the retail order: 0 Find Stellagosa, 1 Lykill's Key, 2 Chains unlocked. Now the key objective and
--    the Lykill marker show once Stellagosa is found. Nobody has the quest in progress (checked 2026-09-30).
UPDATE world.quest_objectives SET StorageIndex = CASE ID WHEN 277290 THEN 0 WHEN 277456 THEN 1 WHEN 277273 THEN 2 END
WHERE QuestID = 37450 AND ID IN (277273, 277290, 277456);
UPDATE world.quest_objectives_locale SET StorageIndex = CASE ID WHEN 277290 THEN 0 WHEN 277273 THEN 2 END
WHERE QuestId = 37450 AND ID IN (277273, 277290);

-- 5) Overseer Lykill: the auto AI casts his creature_template_spell list. Subduing Chains 185970 (3 s cast) drops an
--    area trigger 4293 (radius 3, 10 s) that had no areatrigger_actions, so the cage on the ground did nothing; instead
--    he cast its debuff Subduing Chains 185972 (pacify + silence, 25 damage/s) straight on his target. That debuff has
--    SPELL_ATTR5_HIDE_DURATION in the client data (no timer by design): retail applies it while you stand in the cage.
--    Now the cage applies it on enter and removes it on leave / when the cage ends (moment 42 = leave|despawn|remove,
--    like Thalnos' Spirit Gale), and he no longer casts it directly. His loot is fine: Lykill's Key 120359 drops 100%
--    (QuestRequired) for a player who has "Saving Stellagosa".
DELETE FROM world.creature_template_spell WHERE entry = 86535 AND spell = 185972;
DELETE FROM world.areatrigger_actions WHERE entry = 4293 AND customEntry = 9038;
INSERT INTO world.areatrigger_actions (entry, customEntry, id, moment, actionType, targetFlags, spellId, maxCharges, hasAura, hasAura2, hasAura3, hasspell, chargeRecoveryTime, scaleStep, scaleMin, scaleMax, scaleVisualUpdate, hitMaxCount, amount, onDespawn, auraCaster, minDistance, comment) VALUES
(4293, 9038, 0, 1, 0, 2, 185972, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Overseer Lykill - Subduing Chains on enter cast'),
(4293, 9038, 1, 42, 1, 2, 185972, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'Overseer Lykill - Subduing Chains on exit remove');

-- 6) Dark Revelations: the camera sat far under Stellagosa (90982, vehicle 4103) on the flight back. When a passenger
--    boards, the core moves him to the seat's AttachmentOffset from VehicleSeat.db2 and only uses the sniffed
--    vehicle_attachment_offset (vehicle-space position) when that offset is 0,0,0 (VehicleJoinEvent::Execute). Seats
--    15333/15334 have small offsets relative to the model's seat bone ((0.2,0,-0.1) / (-0.2,0,-0.1)), so the player was
--    put at her feet, ~3.9 yd below her back; retail sends (0.99,0,3.84) / (0.47,0,3.84), exactly the sniffed rows
--    for 90982 seats 0 and 1 (seat bone at ~z 3.94 + the seat offset). These two seats belong only to vehicle 4103
--    (only creature 90982). Server-side override with the client's own values except AttachmentOffset = 0, so the core
--    uses the sniffed offsets. Not in hotfix_data, so nothing is sent to clients; the client keeps its own seat data.
DELETE FROM hotfixes.vehicle_seat WHERE ID IN (15333, 15334);
INSERT INTO hotfixes.vehicle_seat (ID, Flags, FlagsB, FlagsC, AttachmentOffsetX, AttachmentOffsetY, AttachmentOffsetZ, EnterPreDelay, EnterSpeed, EnterGravity, EnterMinDuration, EnterMaxDuration, EnterMinArcHeight, EnterMaxArcHeight, ExitPreDelay, ExitSpeed, ExitGravity, ExitMinDuration, ExitMaxDuration, ExitMinArcHeight, ExitMaxArcHeight, PassengerYaw, PassengerPitch, PassengerRoll, VehicleEnterAnimDelay, VehicleExitAnimDelay, CameraEnteringDelay, CameraEnteringDuration, CameraExitingDelay, CameraExitingDuration, CameraOffsetX, CameraOffsetY, CameraOffsetZ, CameraPosChaseRate, CameraFacingChaseRate, CameraEnteringZoom, CameraSeatZoomMin, CameraSeatZoomMax, UiSkinFileDataID, EnterAnimStart, EnterAnimLoop, RideAnimStart, RideAnimLoop, RideUpperAnimStart, RideUpperAnimLoop, ExitAnimStart, ExitAnimLoop, ExitAnimEnd, VehicleEnterAnim, VehicleExitAnim, VehicleRideAnimLoop, EnterAnimKitID, RideAnimKitID, ExitAnimKitID, VehicleEnterAnimKitID, VehicleRideAnimKitID, VehicleExitAnimKitID, CameraModeID, AttachmentID, PassengerAttachmentID, VehicleEnterAnimBone, VehicleExitAnimBone, VehicleRideAnimLoopBone, VehicleAbilityDisplay, EnterUISoundID, ExitUISoundID, VerifiedBuild) VALUES
(15333, 98, 33554432, 0, 0, 0, 0, 0, 14, 19.29, 0, 0, 1, 4, 0, 7, 19.29, 0, 0, 1, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 37, 38, 65535, 91, 65535, 65535, 37, 38, 39, 65535, 65535, 65535, 0, 0, 0, 0, 0, 0, 0, 21, 255, 255, 255, 255, 1, 0, 0, 26972),
(15334, 1108377611, 33554432, 0, 0, 0, 0, 0, 7, 19.29, 0, 0, 1, 4, 0, 7, 19.29, 0, 0, 1, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 37, 38, 65535, 91, 65535, 65535, 37, 38, 39, 65535, 65535, 65535, 0, 0, 0, 0, 0, 0, 0, 21, 255, 255, 255, 255, 1, 0, 0, 26972);
