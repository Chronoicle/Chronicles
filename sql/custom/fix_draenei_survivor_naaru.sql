-- tyrvana: quest 9283 "Rescue the Survivors!" (Azuremyst): Gift of the Naaru cannot be cast on Draenei Survivor 16483.
-- The SmartAI already gives the credit on a spell hit from every Gift of the Naaru id (28880, 59542-59548, 121093,
-- 177650); the cast itself is refused. Unit::_IsValidAssistTarget (PvC case): a player may only assist a creature
-- that has UNIT_FLAG_PVP_ATTACKABLE, the PvP byte flag (faction template 1638 has no PvP flag) or type flag
-- CAN_ASSIST / TREAT_AS_RAID_UNIT (TypeFlags 0). The old C++ script npc_draenei_survivor set UNIT_FLAG_PVP_ATTACKABLE
-- (0x8) in Reset for exactly this; the SmartAI that replaced it does not. Set it on the template (4608 -> 4616).
-- Undo: undo_draenei_survivor_naaru.sql
UPDATE world.creature_template SET unit_flags = unit_flags | 8 WHERE entry = 16483;
