-- Issue #129: restore creature_template.ScriptName that the repack world DB (~/dump/world.sql.gz, the source of live)
-- had blanked, back to the upstream LegionCore dump ~/LegionCore_world_735.26972_2024_10_23.sql.
-- Only entries whose script is registered by the running core (none of these names is in the last startup's
-- "does not exist in the core" list; every one is in "Script named ... does not have a script name assigned"
-- or already used on another entry), whose live AIName is not a SmartAI with rows, and that are not on the
-- leave list (wrong-entry assignments 90005/59220/77810/103352, custom gold shop 70436).
-- The repack blanked them with no reason in the repo; no sql/updates or sql/custom file blanks any of these.
-- Goes live with a worldserver restart (no .reload). Undo: undo_creature_scriptnames_129.sql
UPDATE world.creature_template SET ScriptName = 'auchindoun_mob_sargerei_cleric' WHERE entry IN (77134) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'auchindoun_mob_sargerei_hopilite' WHERE entry IN (77133) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'auchindoun_mob_sargerei_ritualist' WHERE entry IN (77130) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'auchindoun_mob_sargerei_soulbinder' WHERE entry IN (77812) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'auchindoun_mob_sargerei_spirit_tender' WHERE entry IN (77131) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'auchindoun_mob_sargerei_zealot' WHERE entry IN (77132) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'auchindoun_mob_soul_priest' WHERE entry IN (76595) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'auchindoun_mob_tuulani' WHERE entry IN (79248) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'auchindoun_teronogor_mob_gromkash' WHERE entry IN (77889) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'auchindoun_teronogor_mob_gulkosh' WHERE entry IN (78437) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'auchindoun_teronogor_mob_shaadum' WHERE entry IN (78728) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'boss_inquisitor_meto' WHERE entry IN (124592) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'boss_kaathar' WHERE entry IN (75839) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'boss_xeritac' WHERE entry IN (84550) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'guard_generic' WHERE entry IN (35190) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'mob_animated_protector' WHERE entry IN (62995) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'mob_cleansing_water' WHERE entry IN (60646) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'mob_coalesced_corruption' WHERE entry IN (60886) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'mob_corrupting_waters' WHERE entry IN (60621) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'mob_defiled_ground' WHERE entry IN (60906) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'mob_globue' WHERE entry IN (65691) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'mob_guardian' WHERE entry IN (61038,61042,61046) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'mob_lei_shi_hidden' WHERE entry IN (63099) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'mob_minion_of_fear' WHERE entry IN (60885) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'mob_minion_of_fear_controller' WHERE entry IN (60957) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'mob_night_terror_summon' WHERE entry IN (64393) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'mob_night_terrors' WHERE entry IN (64390) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'mob_pure_light_terrace' WHERE entry IN (60788) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'mob_return_to_the_terrace' WHERE entry IN (65736) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'mob_terror_spawn' WHERE entry IN (61034) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'mob_torloth_the_magnificent' WHERE entry IN (22076) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_109494' WHERE entry IN (109494) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_96666' WHERE entry IN (96666) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_akama' WHERE entry IN (68137) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_amber_pool_stalker' WHERE entry IN (62762) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_amberbeam_stalker' WHERE entry IN (62510) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_apparition_of_fear' WHERE entry IN (64368) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_apparition_of_terror' WHERE entry IN (66100) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_alliance_gateway_guardian' WHERE entry IN (84651,84652) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_alune_windmane' WHERE entry IN (80488) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_ancient_inferno' WHERE entry IN (84875) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_anenga' WHERE entry IN (81870) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_angry_zurge' WHERE entry IN (83869) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_anne_otther' WHERE entry IN (85140) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_ashmaul_destroyer' WHERE entry IN (84876) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_ashmaul_magma_caster' WHERE entry IN (84906) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_atomik' WHERE entry IN (82204) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_avenger_turley' WHERE entry IN (80499) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_belloc_brightblade' WHERE entry IN (88448) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_brock_the_crazed' WHERE entry IN (80498) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_captain_hoodrych' WHERE entry IN (79900) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_centurion_firescream' WHERE entry IN (88771) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_chani_malflame' WHERE entry IN (85129) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_chris_clarkie' WHERE entry IN (82909) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_commander_anne_dunworthy' WHERE entry IN (84173) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_ecilam' WHERE entry IN (82966) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_elder_darkweaver_kath' WHERE entry IN (85771) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_elementalist_novo' WHERE entry IN (80491) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_elliott_van_rook' WHERE entry IN (80493) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_ex_alliance_racer' WHERE entry IN (82884) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_examiner_rahm_flameheart' WHERE entry IN (88676) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_excavator_hardtooth' WHERE entry IN (88567) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_excavator_rustshiv' WHERE entry IN (88568) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_faction_champions' WHERE entry IN (81725,81726) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_fangraal' WHERE entry IN (81859) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_farseer_kylanda' WHERE entry IN (82901) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_fen_tao' WHERE entry IN (91483) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_flight_masters' WHERE entry IN (86049,87617) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_general_ushet_wolfbarger' WHERE entry IN (84473) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_goregore' WHERE entry IN (84893) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_grimnir_sternhammer' WHERE entry IN (88679) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_harrison_jones' WHERE entry IN (84223) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_herald' WHERE entry IN (84113) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_hildie_hackerguard' WHERE entry IN (80495) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_horde_gateway_guardian' WHERE entry IN (84645,84646) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_illandria_belore' WHERE entry IN (88675) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_jackson_bajheera' WHERE entry IN (80484) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_jared_v_hellstrike' WHERE entry IN (85131) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_john_swifty' WHERE entry IN (79902) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_kauper' WHERE entry IN (84466) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_kaz_endsky' WHERE entry IN (87690) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_kimilyn' WHERE entry IN (88109) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_korlok' WHERE entry IN (80858) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_kronus' WHERE entry IN (82201) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_legionnaire_hellaxe' WHERE entry IN (88772) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_lifeless_ancient' WHERE entry IN (81883) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_lord_mes' WHERE entry IN (80497) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_malda_brewbelly' WHERE entry IN (85122) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_mandragoraster' WHERE entry IN (83683) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_mare_wildrunner' WHERE entry IN (84660) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_marketa' WHERE entry IN (82660) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_mathias_zunn' WHERE entry IN (85137) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_mindbender_talbadar' WHERE entry IN (80490) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_misirin_stouttoe' WHERE entry IN (88682) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_morriz' WHERE entry IN (85133) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_necrolord_azael' WHERE entry IN (80486) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_officer_ironore' WHERE entry IN (88697) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_officer_rumsfeld' WHERE entry IN (88696) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_panthora' WHERE entry IN (83691) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_razor_guerra' WHERE entry IN (85138) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_rifthunter_yoske' WHERE entry IN (80496) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_shadow_figurine' WHERE entry IN (78620) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_shani_freezewind' WHERE entry IN (80485) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_soulbrewer_nadagast' WHERE entry IN (80489) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_speedy_horde_racer' WHERE entry IN (82903) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_spirit_healer' WHERE entry IN (80723,80724) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_stormshield_druid' WHERE entry IN (81887) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_stormshield_gladiator' WHERE entry IN (85812) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_stormshield_sentinel' WHERE entry IN (86767) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_stormshield_stormcrow' WHERE entry IN (82895) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_taylor_dewland' WHERE entry IN (80500) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_tosan_galaxyfist' WHERE entry IN (80494) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_underpowered_earth_fury' WHERE entry IN (82200) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_valant_brightsworn' WHERE entry IN (82893) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_vanguard_samuelle' WHERE entry IN (80492) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_volcanic_ground' WHERE entry IN (84952) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_volcano' WHERE entry IN (88226) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_voljins_spear_battle_standard' WHERE entry IN (85383) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_warspear_gladiator' WHERE entry IN (85811) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_warspear_headhunter' WHERE entry IN (88691) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_warspear_shaman' WHERE entry IN (82438) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_wrynns_vanguard_battle_standard' WHERE entry IN (85382) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_ashran_zaram_sunraiser' WHERE entry IN (84468) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_c100161' WHERE entry IN (100161) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_constellation' WHERE entry IN (70058) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_cross_eye' WHERE entry IN (67857) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_eerie_fog' WHERE entry IN (71453) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_embodied_terror' WHERE entry IN (62969) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_essence_of_storm' WHERE entry IN (69739) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_faction_boss' WHERE entry IN (82876,82877) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_frigten_spawn' WHERE entry IN (62977) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_garalon_crusher' WHERE entry IN (63191) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_garalons_leg' WHERE entry IN (63053) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_gilnean_mastiff' WHERE entry IN (36713) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_highmaul_arcane_remnant' WHERE entry IN (79388) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_highmaul_areatrigger_for_crowd' WHERE entry IN (79260) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_highmaul_bfc9000' WHERE entry IN (81403) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_highmaul_bladespire_sorcerer' WHERE entry IN (81224) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_highmaul_chain_hurl_vehicle' WHERE entry IN (79134) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_highmaul_destructive_resonance' WHERE entry IN (77681) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_highmaul_drunken_bileslinger' WHERE entry IN (78954) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_highmaul_earthen_pillar_stalker' WHERE entry IN (80476) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_highmaul_gorian_reaver' WHERE entry IN (78549) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_highmaul_gorian_warmage' WHERE entry IN (78121) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_highmaul_highmaul_sweeper' WHERE entry IN (88874) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_highmaul_iron_bomber' WHERE entry IN (78926) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_highmaul_kargath_bladefist_trigger' WHERE entry IN (78846) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_highmaul_koragh_volatile_anomaly' WHERE entry IN (79956) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_highmaul_living_mushroom' WHERE entry IN (78884) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_highmaul_maggot' WHERE entry IN (80728) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_highmaul_mind_fungus' WHERE entry IN (79082) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_highmaul_night_twisted_cadaver' WHERE entry IN (80679) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_highmaul_night_twisted_fanatic' WHERE entry IN (87768) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_highmaul_night_twisted_supplicant' WHERE entry IN (86185) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_highmaul_oro' WHERE entry IN (86072) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_highmaul_rejuvenating_mushroom' WHERE entry IN (78868) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_highmaul_rokka_and_lokk' WHERE entry IN (86071,86073) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_highmaul_rune_of_displacement' WHERE entry IN (77429) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_highmaul_somldering_stoneguard' WHERE entry IN (80051) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_highmaul_spore_shooter' WHERE entry IN (86612) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_highmaul_volatile_anomaly' WHERE entry IN (78077) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_jeron_emberfall' WHERE entry IN (88178) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_jubeka_shadowbreaker' WHERE entry IN (70166) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_laughing_skull' WHERE entry IN (33990) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_lighting_pilar_master_bunny' WHERE entry IN (70409) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_lighting_spear_float_stalker' WHERE entry IN (70500) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_mage_mirror_image' WHERE entry IN (31216) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_master_cheng_q31840' WHERE entry IN (66138) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_meljarak_amber_prison' WHERE entry IN (62531) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_meljarak_wind_bomb' WHERE entry IN (67053) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_phase3_room_center_stalker' WHERE entry IN (70481) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_pheromone_trail' WHERE entry IN (63021) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_rylai_crestfall' WHERE entry IN (88224) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_springtender_ashani' WHERE entry IN (64846) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_stone_sentiel' WHERE entry IN (70324) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_taoshi' WHERE entry IN (70320) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_tayak_storm_unleashed_plr_veh' WHERE entry IN (63567) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_tayak_storm_unleashed_veh' WHERE entry IN (63278,63299,63300,63301,63302,63303) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_tempest_slash' WHERE entry IN (62908) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_thunder_forge' WHERE entry IN (70061) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_unstable_sha' WHERE entry IN (62919) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'npc_zorlok_sonic_ring' WHERE entry IN (62689,62716,62717,62743,62744) AND ScriptName = '';
UPDATE world.creature_template SET ScriptName = 'trigger_PureLight_Visual' WHERE entry IN (61797) AND ScriptName = '';

-- Left blank on purpose (83 of the 284):
-- a) 74 entries run a SmartAI with smart_scripts rows (the dump had AIName SmartAI + the ScriptName, so the C++
--    script won there; left per the issue rule, owner decision): entry ScriptName
--   1740 npc_deathguard_saltain, 2530 mob_yenniku, 7784 npc_OOX17, 16364 npc_infused_crystal
--   16483 npc_draenei_survivor, 17243 npc_engineer_spark_overgrind, 17682 npc_princess_stillpine
--   17824 npc_captured_sunhawk_agent, 18209 npc_kurenai_captive, 21847 npc_fel_guard_hound, 25969 npc_jenny
--   28659 npc_artruis_Q12581, 43934 npc_soul_fragment, 46753 boss_alakir, 47175 npc_stormling
--   49337 npc_darnel_q26800, 49340 npc_scarlet_corpse_q26800, 55085 boss_perotharn, 69964 npc_kanrethad_ebonlocke
--   77404 boss_the_butcher, 77428 boss_imperator_margok, 77809 npc_highmaul_arcane_aberration
--   78237 boss_twin_ogron_phemos, 78238 boss_twin_ogron_pol, 78491 boss_brackenspore, 78714 boss_kargath_bladefist
--   78757 npc_highmaul_fire_pillar, 78948 boss_tectus, 79015 boss_koragh, 79068 npc_highmaul_iron_grunt_second
--   79092 npc_highmaul_fungal_flesh_eater, 79183 npc_highmaul_spore_shooter, 79296 npc_highmaul_ravenous_bloodmaw
--   80048 npc_highmaul_vulgor, 80599 npc_highmaul_night_twisted_earthwarper
--   80822 npc_highmaul_night_twisted_berserker, 81269 npc_highmaul_warden_thultok
--   81270 npc_highmaul_gorian_guardsman, 81272 npc_highmaul_gorian_runemaster
--   81780 npc_highmaul_guard_captain_thag, 81806 npc_highmaul_gorian_royal_guardsman
--   81807 npc_highmaul_councilor_nouk, 81808 npc_highmaul_councilor_magknor, 81809 npc_highmaul_councilor_gorluk
--   81810 npc_highmaul_councilor_daglat, 81811 npc_highmaul_high_councilor_malgris
--   82399 npc_highmaul_ogron_earthshaker, 82400 npc_highmaul_ogron_brute, 82519 npc_highmaul_highmaul_conscript
--   82528 npc_highmaul_gorian_arcanist, 82532 npc_highmaul_krush, 82698 npc_highmaul_night_twisted_devout
--   84946 npc_highmaul_iron_grunt, 84948 npc_highmaul_ogre_grunt_second, 84958 npc_highmaul_ogre_grunt
--   85225 npc_highmaul_gorian_sorcerer, 85240 npc_highmaul_night_twisted_soothsayer
--   85243 npc_highmaul_void_aberration, 85245 npc_highmaul_night_twisted_ritualist
--   85246 npc_highmaul_greater_void_aberration, 86256 npc_highmaul_gorian_high_sorcerer
--   86290 npc_highmaul_underbelly_vagrant, 86326 npc_highmaul_breaker_of_frost, 86329 npc_highmaul_breaker_of_fire
--   86330 npc_highmaul_breaker_of_fel, 86607 npc_highmaul_iron_flame_technician, 86609 npc_highmaul_iron_warmaster
--   86875 npc_highmaul_wild_flames, 87229 npc_highmaul_iron_blood_mage, 87293 npc_highmaul_phantasmal_weapon
--   87589 npc_highmaul_ogron_warbringer, 87619 npc_highmaul_gorian_warden, 87910 npc_highmaul_gorian_rune_mender
--   116849 npc_stormstout_brewer_q45404
-- b) script missing in code or wrong script for the entry:
--   1978 Deathstalker Erland (npc_deathstalker_erland): script missing in code; upstream 2024_12_08_01_remove_old_quest.sql removed the quest/script
--   18478 Avatar of the Martyred (mob_avatar_of_martyred): script missing in code; upstream 2024_12_11_01_auchenai_crypts_trash_ai.sql replaced it with SmartAI on purpose
--   35364 Slahtz (npc_experience): script missing in code; upstream 2024_11_30_fix_gossip_menu_option.sql dropped npc_experience on purpose
--   35365 Behsten (npc_experience): script missing in code; upstream 2024_11_30_fix_gossip_menu_option.sql dropped npc_experience on purpose
--   59220 Jandice Barov (npc_illusion): Ulduar Yogg-Saron npc_illusion script on the Scholomance Jandice Barov illusion: on damage it turns into an Influence Tentacle, JustDied dereferences ToTempSummon() unchecked
--   70436 Blacktalon Quartermaster (creature_blacktalon_quartermaster): custom repack gossip shop (sells Sha-touched gems, MoP legendary cloaks, Eye of the Black Prince for gold via AddItem, charges 15000g where it says 10k), replaces the NPC's normal gossip: economy change, owner decision
--   77810 Soulbinder Nyami (boss_nyami): hostile boss_nyami BossAI on the friendly Soulbinder Nyami of the Kaathar event (its own script auchindoun_kaathar_mob_nyami is commented out in the loader); the boss 76177 already has boss_nyami. No Auchindoun spawns live
--   90005 Nightfallen Construct (npc_mogu_font): dump assigns the Throne of Thunder Jin'rokh "mogu font" script (SetDisplayId 11686, unselectable, passive, cannot die) to the Legion Nightfallen Construct (spellclick NPC, 13 spawns in Azsuna, map 1220 zone 7334): would make them unselectable with another model
--   103352 Beast (boss_the_beast): boss_the_beast is written for UBRS The Beast 10430 (blackrock_spire.h NPC_THE_BEAST); 103352 is an unspawned other "Beast". Follow-up: 10430 itself has no ScriptName (dump too)
