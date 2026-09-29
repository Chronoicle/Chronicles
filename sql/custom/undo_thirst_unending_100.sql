-- Undo #100: remove the Paladin Arcane Torrent SpellHit row from Mana Wyrm 15274's SmartAI.
DELETE FROM world.smart_scripts WHERE entryorguid = 15274 AND source_type = 0 AND id = 8 AND event_param1 = 155145;
