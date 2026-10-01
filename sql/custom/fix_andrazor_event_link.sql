-- Owner OK 2026-10-01: Andrazor (creature 53267, guid 14568173, Mount Hyjal) was tied to the Mythic+ "Teeming" affix
-- weeks 127/131/134: their 170 game_event_creature rows (guids 14568062-14568231) are dungeon spawns that no longer
-- exist, and this one guid was reused for Andrazor, so he only spawned during those weeks (never since 2020). Unlinked: he
-- takes his turn in pool 15030 like the other 3 rares. The other 169 dangling rows are left (they match no creature). Needs a restart (read at startup).
-- Checked: the upstream LegionCore world dump (2024-10-23) has the same 3 rows (the collision is upstream); retail:
-- Andrazor, Lord of Cinders, is one of the 4 rares of the achievement The Fiery Lords of Sethria's Roost (Searris,
-- Kelbnar, Fah Jarakk; here pool 15030, one at a time), tied to no event. With the link the achievement can't be done.
-- Undo: undo_andrazor_event_link.sql
DELETE FROM world.game_event_creature WHERE guid = 14568173 AND eventEntry IN (127, 131, 134);
