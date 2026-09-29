-- #122 part A (gabrielf03d, approved reporter; Claude desktop team subagent, 2026-09-29): Azsuna, Faronaar.
-- After turning in From Within (36920) at Kor'vas Bloodthorn (90255, Vanquish Point) she should follow you and offer
-- Fel Machinations (37656) and Saving Stellagosa (37450). Nothing happened, so the Azsuna story stopped there.
-- Undo: sql/custom/undo_azsuna_from_within.sql. Live with a worldserver restart (no .reload).
--
-- How it works: 90255 is only visible while 36920 is complete and not yet turned in (phase 4354). The follower is a
-- separate NPC, 90474, summoned by "Faronaar: Summon Kor'vas Bloodthorn" 178860 (client data: summon 90474, ally
-- guardian that follows its owner, limited to area group 4243 = Faronaar 7349, Legion Camp: Ruin 7351, Legion Camp:
-- Chaos 7354, Vanquish Point 7356, Fiendish Vault 7488; it unsummons itself when it leaves Faronaar). 90474 is the
-- quest giver and ender of 37656 / 37450 and the giver of Dark Revelations 37449. It has no spawn.
--
-- Causes:
-- a) spell_area 178860 (area 0, from 36920 rewarded) had quest_end 37449 with quest_end_status 66 (COMPLETE|REWARDED).
--    This core applies the spell only while the quest_end status IS in the mask (same bug as #69/#92), so she could
--    only come after Dark Revelations was done: never. 9 = NONE|INCOMPLETE: from the turn-in until Dark Revelations is
--    complete (what 66 meant as "forbidden" states).
-- b) Kor'vas's reward script cast 150096 (update zone auras) to trigger that row, but an area-0 row with an area group
--    is skipped when the player's previous area is in the same group (SpellArea::IsFitToRequirements, meant to stop
--    re-summons while walking inside Faronaar). Vanquish Point is surrounded by Faronaar 7349, so walking in from
--    Faronaar blocked the summon even with a). The script now casts 178860 itself (triggered). The spell_area row
--    still summons her when you enter Faronaar from outside or log in there (this also fixes characters that already
--    turned in From Within); one live summon per player (HasSpellAreaSpell, Player.cpp).
-- c) 90474 showed as a generic "Demon Hunter" (display 61909/61911/61906/61908) on a Felsaber with the swim anim tier.
--    The client names its summon spell "Summon Kor'vas Bloodthorn", its lines are Kor'vas's and it carries her
--    warglaives (same creature_equip_template as 90255), so it gets Kor'vas's name and model (66159, as 90255) and no
--    mount. Players who already saw the old name need to delete the client's Cache folder.
-- d) Fel Machinations: the map/minimap area (quest_poi 37656) is the same as the 7.3.5 client's QuestPOIBlob
--    322044 / 322063 / 325921 (turn-in, the 7-point prisoner area, quest giver): no change needed. The prisoners 90487
--    already carry the quest highlight (StateWorldEffectID 2100 -> QuestFeedbackEffect 105); the Soul Harvesters that
--    hold them (11 spawns, one on each prisoner) have it on entries 240075/240121/240122 but not on 240123 (guids
--    109134, 109139, 109140): added.

-- a) spell_area: follower from the From Within turn-in until Dark Revelations is complete.
UPDATE world.spell_area SET quest_end_status = 9
WHERE spell = 178860 AND area = 0 AND quest_start = 36920 AND quest_end = 37449 AND quest_end_status = 66;

-- b) Kor'vas's From Within reward script summons the follower directly (triggered).
UPDATE world.smart_scripts SET action_param1 = 178860, action_param2 = 2,
    comment = 'Kor''vas Bloodthorn - On Quest From Within Rewarded - Invoker Cast Faronaar: Summon Kor''vas Bloodthorn (#122)'
WHERE entryorguid = 90255 AND source_type = 0 AND id = 0 AND event_type = 20 AND event_param1 = 36920
  AND action_type = 85 AND action_param1 = 150096;

-- c) The follower looks like Kor'vas.
UPDATE world.creature_template_wdb SET Name1 = 'Kor''vas Bloodthorn', Displayid1 = 66159, Displayid2 = 0, Displayid3 = 0, Displayid4 = 0
WHERE Entry = 90474;
UPDATE world.creature_template_wdb_locale SET Name1 = 'Kor''vas Bloodthorn' WHERE ID = 90474 AND Locale = 'enUS';
UPDATE world.creature_template_addon SET mount = 0, bytes1 = 0 WHERE entry = 90474;

-- d) Quest highlight on the fourth Soul Harvester entry, like the other three.
UPDATE world.gameobject_template SET StateWorldEffectID = 2100 WHERE entry = 240123 AND StateWorldEffectID = 0;
