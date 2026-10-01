-- Undo of sql/custom/fix_dark_revelations_ride_130.sql (values as they were on live 2026-10-02). Live with a restart.
UPDATE world.creature_template SET speed_fly = 1.14286 WHERE entry = 90982;
DELETE FROM world.vehicle_template_accessory WHERE EntryOrAura = 90982 AND seat_id = 1;
INSERT INTO world.vehicle_template_accessory (EntryOrAura, accessory_entry, seat_id, offsetX, offsetY, offsetZ, offsetO, minion, description, summontype, summontimer) VALUES
(90982, 90983, 1, 0, 0, 0, 0, 0, 'Drake', 8, 300);
UPDATE hotfixes.vehicle_seat SET FlagsB = 33554432 WHERE ID = 15333;
