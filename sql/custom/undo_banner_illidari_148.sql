-- Undo #148 (restores the row as it was on 2026-10-02).
UPDATE world.gameobject_template SET flags = 262145 WHERE entry = 244898 AND flags = 262144;
