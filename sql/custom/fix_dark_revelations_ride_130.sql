-- Dark Revelations (37449): the flight on Stellagosa (90982, vehicle 4103) from Faronaar to Kayn/Altruis
-- (gabrielf03d, approved reporter, #130 comment of 2026-10-01: "camera still way under her, she flies quite slow").
-- Claude desktop team subagent. Undo: sql/custom/undo_dark_revelations_ride_130.sql. Live with a worldserver restart.

-- 1) Speed. Her SmartAI path (waypoints 90982, ~1000 yd) has no speed of its own. This core moves a creature that
--    can fly at its flight speed (speed_fly 1.14286 x 7 = 8 yd/s, ~2 min ride); TrinityCore/retail take the run
--    speed (2.85714 x 7 = 20 yd/s). Same flight speed as run speed: ~50 s, like the Still Alive ride.
UPDATE world.creature_template SET speed_fly = 2.85714 WHERE entry = 90982;

-- 2) Seats. Retail (sniff): Kor'vas (90983) sits in front on seat 0 (VehicleSeat 15333, an NPC seat), the player
--    behind her on seat 1 (15334, the enter/exit seat). Here a second Kor'vas row also took seat 1, and the player's
--    ride spell 180768 asks for "any seat": the core ignores seats that are still being boarded in the same tick, so
--    the player was put on Kor'vas' seat 0 (her seat-0 copy despawned). Seat 0's client data is not meant for a
--    player (that is where the camera ends up far under Stellagosa; moving the player's offset up on 2026-09-30 did
--    not help). Drop the extra Kor'vas, and take seat 0 out of the "any seat" choice server-side (FlagsB 0 instead of
--    USABLE_FORCED_4 in our existing server-only override row, not in hotfix_data, so clients are not told), so the
--    player lands on seat 1 and Kor'vas keeps seat 0 (her accessory row boards it by seat number).
DELETE FROM world.vehicle_template_accessory WHERE EntryOrAura = 90982 AND seat_id = 1 AND accessory_entry = 90983;
UPDATE hotfixes.vehicle_seat SET FlagsB = 0 WHERE ID = 15333;
