-- Owner OK 2026-10-01: Andrazor (creature 53267, guid 14568173, Mount Hyjal) was tied to the Mythic+ "Teeming" affix
-- weeks 127/131/134: their 170 game_event_creature rows (guids 14568062-14568231) are dungeon spawns that no longer
-- exist, and this one guid was reused for Andrazor, so he only spawned during those weeks (never since 2020). Unlinked:
-- he is always there. The other 169 dangling rows are left (they match no creature). Needs a restart (read at startup).
-- Undo: undo_andrazor_event_link.sql
DELETE FROM world.game_event_creature WHERE guid = 14568173 AND eventEntry IN (127, 131, 134);
