-- Undo fix_deadmines_mine_cart_176c.sql
UPDATE world.creature_template SET VehicleId = 0 WHERE entry = 48351;
