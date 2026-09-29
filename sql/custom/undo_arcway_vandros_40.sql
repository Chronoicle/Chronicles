-- Undo #40 (fix_arcway_vandros_40.sql): Time Lock first cast back to 20-22 s.
UPDATE `world`.`smart_scripts` SET `event_param1` = 20000, `event_param2` = 22000
WHERE `entryorguid` = 103130 AND `source_type` = 0 AND `id` = 1 AND `action_param1` = 203957;
