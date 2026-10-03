-- #174 (Claude, dev-owner) Ragefire Chasm.
-- Horde quest NPCs (Kor'kron Elite, Invoker Xorenth, Commander Bagran: Horde factions 2238/2211) attacked Alliance groups
-- from the Dungeon Finder. IMMUNE_TO_PC: they neither attack nor can be attacked by players; Horde can still talk to them.
-- (The ones at the end now appear when Lava Guard Gordoth dies: instance_ragefire_chasm.cpp.)
UPDATE world.creature_template SET unit_flags = unit_flags | 256 WHERE entry IN (61404, 61716, 61724);
-- Flame Visual (61413, Dark Shaman Koranthal's channel target): model 169 is the Infernal/placeholder model (the flying
-- "fire golem"); its second model 11686 is the invisible trigger. Use only that.
UPDATE world.creature_template_wdb SET Displayid1 = 11686, Displayid2 = 0 WHERE Entry = 61413;
