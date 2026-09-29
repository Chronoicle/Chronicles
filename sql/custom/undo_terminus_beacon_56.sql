-- Undo fix_terminus_beacon_56.sql (#56): none of these rows existed before.
DELETE FROM world.areatrigger_template WHERE entry = 11885;
DELETE FROM world.areatrigger_data WHERE entry = 11885;
DELETE FROM world.areatrigger_actions WHERE entry = 11885;
DELETE FROM world.spell_script_names WHERE spell_id = 257376 AND ScriptName = 'spell_item_terminus_legion_bombardment';
DELETE FROM world.creature_template WHERE entry = 129063;
