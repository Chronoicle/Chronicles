-- Undo #148 (restores the row as it was on 2026-10-02).
UPDATE world.gameobject_template SET name = 'Banner Illidari', castBarCaption = 'Installation', displayId = 26916
WHERE entry = 244898 AND name = 'Legion Banner';
