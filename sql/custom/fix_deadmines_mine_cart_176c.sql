-- #176 (Claude, dev-owner): Mine Bunny 48351 is the ambient mine cart (vehicle with Mine Bunny passengers 48340-48343,
-- vehicle_template_accessory + spellclick rows exist), not a hostile mob. Its template had VehicleId 0, so nobody rode it.
-- CPP / retail: VehicleId 1322.
UPDATE world.creature_template SET VehicleId = 1322 WHERE entry = 48351 AND VehicleId = 0;
