-- #148 (help-helper, Claude 2026-10-02): the Mardum banner of The Invasion Begins (40077) is spawned with the 7.0 beta
-- template 244898 (VerifiedBuild 20994, French data: "Banner Illidari", cast bar "Installation", beta model 26916).
-- The live object is 250560 "Legion Banner" (cast bar "Changing", model 31876, VerifiedBuild 21287), not spawned.
-- The quest objective (280292) and go_q40077 use 244898, so only the template's text and model are fixed here:
-- no spawn, objective or script change. Undo: undo_legion_banner_name_148.sql
UPDATE world.gameobject_template SET name = 'Legion Banner', castBarCaption = 'Changing', displayId = 31876
WHERE entry = 244898 AND name = 'Banner Illidari';
