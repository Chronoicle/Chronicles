-- #30 (Claude subagent, desktop team): Eonar area "imp in a corner" + floating / in-wall models.
-- The ambient FX stalkers (126937 Stalker x19, 126980 Stalker x2, 127694 Eonar Beam Stalker x4; auras Eonar Cosmetic
-- Fireflies 252021 / Wisp 252003) list two displays: 16480 (a full-size Imp: same model 8109 + texture as the warlock
-- imp 4449) and 39810 (invisible stalker model). Without CREATURE_FLAG_EXTRA_TRIGGER, ObjectMgr::ChooseDisplayId picks
-- one at random per spawn, so about half of them show up as imps standing in corners, floating in the air or in walls.
-- Trigger flag = always the invisible model (GMs still see the imp), not selectable, passive; like Focus 125930 (130).
-- Before: flags_extra = 0 for all three. Undo: undo_eonar_30_stalker_imps.sql
UPDATE world.creature_template SET flags_extra = flags_extra | 128 WHERE entry IN (126937, 126980, 127694);
