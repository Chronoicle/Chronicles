-- Undo fix_andrazor_event_link.sql
INSERT IGNORE INTO world.game_event_creature (eventEntry, guid) VALUES (127, 14568173), (131, 14568173), (134, 14568173);
