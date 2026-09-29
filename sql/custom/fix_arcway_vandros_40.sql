-- #40 The Arcway, Advisor Vandros: Timeless Wraith (103130) cast Time Lock (203957) only 20-22 s after being engaged,
-- after players had already run past. First cast now 3-5 s, repeat unchanged (20-22 s).
-- ponytail: 3-5 s is an assumption (no retail timer found), tune from a retail log.
UPDATE `world`.`smart_scripts` SET `event_param1` = 3000, `event_param2` = 5000
WHERE `entryorguid` = 103130 AND `source_type` = 0 AND `id` = 1 AND `action_param1` = 203957;
