-- Undo for fix_broken_shore_paths_79.sql
DELETE FROM world.waypoint_data_script WHERE id IN
    (439136, 439137, 439141, 439144, 439145, 439146,
     439148, 439149, 439150, 439151, 439152, 439153, 439154, 439155);
