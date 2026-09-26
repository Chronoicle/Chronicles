# Changes (newest first). Who / what / live? / undo

Format: `date — who — what — status — undo`. Core code changes are also git commits in `~/LegionCore`.

## 2026-09-26

- Claude (desktop session) — restart 22:31 UTC (owner OK), worldserver 45fa71a: #28 Legion Cruiser stays in the sky + officer rotation (2726233, temporary server.antoran logs); #29 temporary server.antorus logs; #39 Mendacius/Grimhorn SmartAI + Illianna facing (affe7ba, SQL) and Glayvianna (45fa71a); conf: Server.log appends with timestamps — live, changelog 1553534481116299355 — `git revert` the commits, `~/undo_votw_mythic_39.sql`, conf backup `~/legion/etc/worldserver.conf.bak_serverlog_20260926`.
- Claude (desktop session) — #10 website character pages show gear via Wowhead links — live (deploy.sh, no restart) — `cp ~/backup_character_php_20260926.php ~/website_src/SahtoutCMS/pages/character.php && bash ~/website_src/deploy.sh`.
- Claude (desktop session) — restart 21:34 UTC (owner OK), worldserver 363373c: core fix so jump-to-location landing spells run (60d790f, all JUMP_DEST spells); #30 Surge of Life glide, Antorus event triggers per instance + statue visual (60d790f), no reset after the Paraxis Inquisitor (363373c); #25 Felhounds mark swap + Enflamed/Siphon marks (82ca524) — live, changelog 1553520116816285859 — `git revert` the commits.
- Claude (desktop session) — restart 21:00 UTC (owner OK), worldserver fc5af4b: core fix for creatures at 0 health that kept fighting (a34f340, all dungeons); #13 Hulks Piercing Shards + Fixate chase (4151cf7, core Spell.cpp focus), Ularogg reset/idols (81608bb), Rokmora/Naraxas intros (5fdbdc9), barrel ride (fc5af4b) — live, changelog 1553511610889404507 — `git revert` the commits.
- Claude (desktop session) — restart 20:41 UTC (owner OK), worldserver 7ca8ea4 (Codex): #18 Eye of Azshara Wrangler yell for solo/partial groups, pathless Crusher 14507329 stationary — live, changelog 1553507051139768341 — `git revert 7ca8ea4`, `~/undo_eoa_18.sql`.
- Claude (desktop session) — restart 20:26 UTC (owner OK), worldserver b1600a1 (PR #42) + 73f1b53: #41 Call to the Void tendrils deal damage, max 3; Acrid Catalyst Injector procs (missing script binding added); #39 VotW bosses immune to CC — live, changelog 1553504519290355794 — `git revert` the commits, `~/undo_acrid_catalyst_injector.sql`, `~/undo_votw_boss_immunities.sql`.
- Claude (desktop session) — restart 19:39 UTC (owner OK), worldserver 936195d: #34 Tirathon stops to cast; #35 legendary limit back to retail (1, 2 with the class hall talent; live conf `Player.UnlimitedLegionLegendaries = 0`); Codex Black Rook Hold #21 (SQL) and #23 — live, changelog 1553491289952231566 — `git revert` the commits, conf backup `~/legion/etc/worldserver.conf.bak_legendaries_20260926`, `~/undo_brh_21.sql`.
- Claude — live since the 18:34 UTC restart (owner OK): crash fix HandleAuraOverrideSpells (0e21884); #33 ProcEventInfo::GetSpellInfo (7aef6a1: Marking Targets, Beacon of Light, Judgment of Light, Master of the Glaive and other procs); #29 Antorus Blazing Imp / Hungering Stalker SmartAI (3697fce) — changelog 1553476662119637004 — `git revert` the commit / `~/undo_hasabel_trash.sql`.
- (live since the 17:07 crash restart) #24 VotW, #32 Focused Will/Soul Leech, #15/#16 EoA, #31 Prestige 25, #30 Eonar Paraxis reset + temporary server.eonar logs — changelog 1553453656781627424.
- Claude — Eye of Azshara weather mechanics on + naga slot overflow (#15/#16, 2817f3c); Prestige cap 14→25 (#31, 79eac34) — built, live since the 17:07 UTC crash restart — git revert.
- Claude — #32 Focused Will (priest) and Soul Leech (warlock) cast from the proc check: fired on jumps and own spells (error spam, frame drops) — built, live since the 17:07 UTC crash restart — `git revert` the commit.
- Claude — Vault of the Wardens #24 (from ChatGPT's audit): Ash'golm countermeasure consoles, Cordana walls/intro, Tormentorum prisons, Belcher/Infester/Broodmother/Foul Mother abilities (commit ea63b95) — built + DB applied, live since the 17:07 UTC crash restart — `git revert ea63b95`, `~/undo_votw.sql`.
- Codex (deploy finished by Claude) — Neltharion's Lair #13: Dargrul Crystal Spikes summoned at the marker (commit a1e44a2) — live (60-second restart ~14:29 UTC); changelog + James reply posted — git revert a1e44a2.
- Codex — Neltharion's Lair #13: Naraxas Spiked Tongue full-energy trigger and Dargrul fixate threat/chase (commit 07c4946) — live (60-second restart ~14:17 UTC); changelog and reporter updates posted — git revert 07c4946.
- Claude + Codex deploy — Eye of Azshara script names (#14), Black Rook Hold Illysanna/Kurtalos events (#19) and boulders (#20) (commit f404d17) — live (60-second restart ~14:03 UTC); changelog posted — `git revert f404d17`, `~/undo_eoa_brh.sql`.
- Claude — Neltharion's Lair #13: Charskin/Demolisher chase, Landslide knockback, hammer + Dargrul NPCs after death, Hulks, Drums of War, Naraxas loot, smooth tunnel slide, Rokmora intro, duplicate trash (commits 7f5919b, da1bd14) — live (restart ~07:00) — `git revert`, `~/undo_nl_james.sql`, `~/undo_nl_duplicates.sql`.
- Claude — Naraxas intro: emerge animation, mystic scream, allies walk in after the kill (commit 35e5859) — live (restart ~05:45) — `git revert 35e5859`.
- Claude — Neltharion's Lair: creature proc cooldown core fix (Rokmora), Ularogg intermission timers, Naraxas emerge + Spiked Tongue check + logging — live (restart ~04:30) — `git revert` the commit / backups `~/backup_boss_ularogg_cragshaper.cpp`, `~/backup_boss_naraxas.cpp`.
- Claude — Signal Lantern: gossip creature model 11686, Nightborne lantern object at the pier edge, test spawn removed — live (restart ~04:30) — `~/undo_cos_lantern.sql`.
- Claude — Mythic health fix: `Creature::GetHealthMultiplierForTarget` uses the level ratio only (hits took up to ~6× the shown health) — live (restart 02:36).
- ChatGPT — Glazer (Vault of the Wardens): beam conditions for 194333 (all three effects target Glazer), Focus root/facing, lens cooldown, Mythic Overloaded Lens (NPC 113552) — live — `~/glazer-fix-20260926/undo.sql` + `worldserver.before-glazer`.
- Claude — Court of Stars boat: waypoint paths 9100402/9100403, 30 s ride, Ly'leth summoned and narrating, lantern moved to the pier edge — live — `~/undo_cos_boat.sql`.
- Claude — Duskwatch Sentry (Court of Stars) fights when it cannot reach a beacon — live.
- Claude — Legion creatures on the Legion damage table (HealthScalingExpansion 0 → 6, 4,922 entries) — live — `~/undo_hse_legion.sql`.
- Claude — launch-dungeon health ×2.068 (354 entries only spawned in the 10 launch dungeons) — live — `~/undo_hp_launch_dungeons.sql`.
- Claude — Cathedral of Eternal Night: flight loops for 29 Dreadwing bats — live — `~/undo_cathedral_bats.sql`.
- Claude — website (SahtoutCMS on the IP, e-mail = game login), nginx in front of the patch server — live — site files `/var/www/chronicles`, nginx config `/etc/nginx/sites-available/chronicles` (root).
- Claude — new launcher look (Go/WebView2 "Chronicles") with progress bar — live — previous launcher `~/launcher/Launcher_prev.exe`.

## 2026-09-25

- Claude — premium system, built-in client UI (CASC patch), launcher, Discord changelog/news, Title Master, GM Island decor, many boss/spell/crash fixes — live. See #changelog for the player-facing list.
