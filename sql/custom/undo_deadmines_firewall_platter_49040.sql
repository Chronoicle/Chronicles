-- Undo fix_deadmines_firewall_platter_49040.sql (faction 14, unit_flags 0 before)
UPDATE world.creature_template SET faction = 14, unit_flags = 0 WHERE entry = 49040;
