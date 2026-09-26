# Changes (newest first). Who / what / live? / undo

Format: `date — who — what — status — undo`. Core code changes are also git commits in `~/LegionCore`.

## 2026-09-26

- Claude — live since the 18:34 UTC restart (owner OK): crash fix HandleAuraOverrideSpells (0e21884); #33 ProcEventInfo::GetSpellInfo (7aef6a1: Marking Targets, Beacon of Light, Judgment of Light, Master of the Glaive and other procs); #29 Antorus Blazing Imp / Hungering Stalker SmartAI (3697fce) — changelog 1553476662119637004 — `git revert` the commit / `~/undo_hasabel_trash.sql`.
- (live since the 17:07 crash restart) #24 VotW, #32 Focused Will/Soul Leech, #15/#16 EoA, #31 Prestige 25, #30 Eonar Paraxis reset + temporary server.eonar logs — changelog 1553453656781627424.
- Claude — Eye of Azshara weather mechanics on + naga slot overflow (#15/#16, 2817f3c); Prestige cap 14→25 (#31, 79eac34) — built, **live after next restart** — git revert.
- Claude — #32 Focused Will (priest) and Soul Leech (warlock) cast from the proc check: fired on jumps and own spells (error spam, frame drops) — built, **live after next restart** — `git revert` the commit.
- Claude — Vault of the Wardens #24 (from ChatGPT's audit): Ash'golm countermeasure consoles, Cordana walls/intro, Tormentorum prisons, Belcher/Infester/Broodmother/Foul Mother abilities (commit ea63b95) — built + DB applied, **live after next restart** — `git revert ea63b95`, `~/undo_votw.sql`.
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
