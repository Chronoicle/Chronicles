-- Claude (dev-owner) 2026-10-04, owner: fix all. The SmartAI loader drops "area explored / event happens" credit rows
-- (action 15) whose quest lacks QUEST_SPECIAL_FLAGS_EXPLORATION_OR_EVENT (2), so these 10 quests got no credit:
-- Easy is Boring, Hacking the Construct, Spirits Be Praised, Lou's Parting Thoughts, Bwemba's Spirit (x2),
-- Challenge Accepted, A Royal Summons, Crystals Not Included, The Path Forward. All had SpecialFlags 0.
UPDATE world.quest_template_addon SET SpecialFlags = SpecialFlags | 2 WHERE ID IN (14390,14430,25189,26232,29100,29219,30515,38035,46213,46941);
