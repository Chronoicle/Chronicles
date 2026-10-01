-- #148 (help-helper, Claude 2026-10-02): Banner Illidari 244898 (Mardum, quest 40077) had flags 262145 = 0x40000 |
-- GO_FLAG_IN_USE (0x1, "disables interaction while animated") in its template: the client does not let you click it.
-- The other Mardum quest goobers (241751, 241756, 244439) have 262176 (0x40000 | 0x20 NODESPAWN); only 0x1 is cleared.
-- The script side (go_q40077 GossipUse) is in mardum.cpp. Undo: undo_banner_illidari_148.sql
UPDATE world.gameobject_template SET flags = flags & ~1 WHERE entry = 244898 AND flags = 262145;
