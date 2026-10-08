-- #186 follow-up (Claude, dev-owner): the perched Sea Gulls 44880 still flapped after bytes1 = 0 (fix_sea_gull_anim_186):
-- their creature_template_movement had Ground 0 + Flight 1 (gravity off = always the flying animation), same cause as #188.
-- TrinityCore TDB 735.00 has 44880 as InhabitType 3 (ground + water, no air) -> they sit on the ledges.
UPDATE world.creature_template_movement SET Ground = 1, Swim = 1, Flight = 0 WHERE CreatureId = 44880 AND Ground = 0 AND Flight = 1;
