-- Raid bosses outside Antorus could be stunned (and feared, rooted, polymorphed ...) too: all had mechanic_immune_mask 0
-- (Refs #81, Claude 2026-09-29). Same standard boss mask as fix_imonar_81.sql (#39): charm, disorient, disarm, distract,
-- fear, grip, root, silence, sleep, snare, stun, freeze, knockout, polymorph, banish, shackle, turn, horror, daze, sapped
-- (not interrupt). One entry per boss serves every difficulty on this core.
-- Every boss script was checked (each spell id in it, its Spell/SpellEffect/SpellCategories mechanics with hotfixes,
-- triggered spells, spell_linked_spell/spell_trigger/aura hooks, areatrigger actions): no boss needs one of these mechanics.
-- The CC spells with them all hit players; the scripted self-stuns (Skorpyron's Exoskeletal Vulnerability, Trilliax's
-- modes, Gul'dan's Wounded, Helya, Xavius, the dragons' Slumbering Nightmare, Moontalon) have no mechanic, and
-- SetControlled is not affected by the mask. Nothing is left out.
-- Dragon Soul: Warlord Zon'ozz 55308, Yor'sahj 55312. Throne of Thunder: Iron Qon 68078, Suen 68904, Lu'lin 68905.
-- Hellfire Citadel: Gurtogg Bloodboil 92146 and the council he summons, Blademaster Jubei'thos 92142, Dia Darkwhisper 92144.
-- Emerald Nightmare: Ursoc 100497, Ysondre 102679, Taerar 102681, Lethon 102682, Emeriss 102683, Xavius 103769,
-- Cenarius 104636, Il'gynoth 105393, Elerethe Renferal 106087.
-- Nighthold: Krosus 101002, Skorpyron 102263, Tichondrius 103685, Star Augur Etraeus 103758, Gul'dan 104154,
-- Trilliax 104288, Chronomatic Anomaly 104415, High Botanist Tel'arn 104528, Spellblade Aluriel 104881, Elisande 106643,
-- Solarist/Arcanist/Naturalist Tel'arn 109038/109040/109041, The Demon Within 111022.
-- Trial of Valor: Odyn 114263, Guarm 114323, Helya 114537 (elite, not rank 3, in the client data, but they are the bosses).
-- Tomb of Sargeras: Mistress Sassz'ine 115767, Harjatan 116407, Atrigan 116689, Belac 116691, Fallen Avatar 116939,
-- Kil'jaeden 117269, Maiden of Vigilance 118289, Captain Yathae 118374, Priestess Lunaspyre 118518,
-- Huntress Kasparian 118523, Engine of Souls 118460, Soul Queen Dejahna 118462, The Desolate Host 119072.
-- Nythendra 102672 and Goroth 115844 already have 2147483647 and stay as they are.
-- Undo: undo_raid_boss_cc_immunity_81.sql (all 47 were 0 before).
UPDATE world.creature_template SET mechanic_immune_mask = mechanic_immune_mask | 617299839
 WHERE entry IN (55308,55312,68078,68904,68905,92142,92144,92146,100497,101002,102263,102679,102681,102682,102683,103685,
 103758,103769,104154,104288,104415,104528,104636,104881,105393,106087,106643,109038,109040,109041,111022,114263,114323,
 114537,115767,116407,116689,116691,116939,117269,118289,118374,118460,118462,118518,118523,119072);
