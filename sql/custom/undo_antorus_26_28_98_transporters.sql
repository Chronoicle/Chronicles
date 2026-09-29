-- Undo fix_antorus_26_28_98_transporters.sql (#28, #98)
DELETE FROM world.creature WHERE guid=146940137 AND id=130137;
UPDATE world.creature_template SET ScriptName='' WHERE entry=130137;
DELETE FROM world.waypoint_data_script WHERE id=13013700;
DELETE FROM world.spell_script_names WHERE spell_id=254219 AND ScriptName='spell_command_defensive_countermeasures';
