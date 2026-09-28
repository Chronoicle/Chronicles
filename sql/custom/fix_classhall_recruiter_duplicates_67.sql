-- #67 class hall troop recruiters (work orders): 14 menus had the same "recruit" option 2-3 times (OptionIDs 0,1,2,
-- same text + broadcast text, no conditions), so the NPC would list it 2-3 times. Keep the lowest OptionID.
-- Undo: undo_classhall_recruiter_duplicates_67.sql (the 21 deleted rows).
DELETE o FROM gossip_menu_option o
JOIN (SELECT MenuID, OptionNpc, OptionBroadcastTextID, MIN(OptionID) keep_id FROM gossip_menu_option
      WHERE OptionNpc = 28 GROUP BY MenuID, OptionNpc, OptionBroadcastTextID HAVING COUNT(*) > 1) d
  ON d.MenuID = o.MenuID AND d.OptionNpc = o.OptionNpc AND d.OptionBroadcastTextID = o.OptionBroadcastTextID AND o.OptionID <> d.keep_id;
