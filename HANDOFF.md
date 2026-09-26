# Handoff: current state (update at the end of every task)

Last updated: 2026-09-26 ~21:05 UTC by Claude (desktop session). Previously: ~20:45 UTC by Claude (desktop session).

## Who does what right now

- **Server session:** a Claude session on the owner's Windows desktop (Remote Control, started from a Project thread). SSH as `wow` with its own key, `gh` logged in with board access. Cloud threads cannot reach the server; they start this session when server work is needed.
- The old server session on the owner's Mac is retired (its notes are in `docs/NOTES.md`).

## Current state

- **Staged, NOT live (built + installed ~21:40 UTC), 82ca524, #25 Felhounds:** mark swap re-applies 200 ms after 251444 (its target-less trigger 244053 ran before its own mark removal, so the swap left nobody marked), swap at 50%; Enflamed 244471 / Siphon 244578 dummies now apply marks 248815 / 248819 (nothing did). Decay / Consuming Sphere / Desolate Path chains look complete: need an in-game look. xinkeg told (also about #30).
- **#29 notes (not changed):** Collapsing World: energize 247143 ticks 1 s, Hasabel is class 4 (energy), 243983 has no cost; no code reason found for "never cast". 60%/30% adds: activation spells 257939/41/42 use NEARBY_ENTRY (38) + conditions on gateways 122494/122543/122558 (summon group 0 of 122104, ~40 yd from her); the chain looks right, needs a test fight with logging (note: Server.log is overwritten on every restart, grab logs before restarting).
- **Staged, NOT live (built + installed ~21:20 UTC, waiting for the owner's restart OK), 60d790f, #30:** core fix so JUMP_DEST landing spells run (EffectMovementGenerator cast on a null target failed; fixes Surge of Life glide + Dive Down and 515 other jump spells, watch for doubled landing effects); Antorus event objects one-shot per instance instead of one global bool (statue trigger 805 was dead after the first trigger server-wide); statue visual always plays. Temporary `server.eonar` logs removed. Staged comment on #30 posted. xinkeg's original #30 reports were deleted in Discord, so nobody was told yet: tell xinkeg in a new message/reply when live. **Owner rule since ~21:10 UTC: ask before every restart.**
- **Live since the restart at 21:00 UTC (owner OK), worldserver fc5af4b, #13 Neltharion's Lair:** a34f340 core fix for creatures that fell over at 0 health but kept fighting (ModifyHealth in DealDamage used attacker-scaled health while the kill check used real health; also caused the one-shots), 4151cf7 Hulks cast Piercing Shards + move-allowed channels (Fixate 200154) no longer take the creature spell focus so Dargrul's adds chase, 81608bb Ularogg resets to his platform + idols shuffle over the floor circles, 5fdbdc9 Rokmora/Naraxas intros prepared on first AI update (Naraxas unselectable until he emerges), fc5af4b barrel ride as one smooth spline. Changelog 1553511610889404507, Live comment + labels, James told. **Watch** for side effects of the two core changes (damage/health on scaled creatures, channel facing).
- Previously deployed changes are live. Last restart 18:34 UTC (owner OK): crash fix 0e21884, #33 7aef6a1, #29 Hasabel trash 3697fce. Changelog 1553476662119637004, Live comments posted.
- The 17:07 UTC crash restart made #24, #32, #15, #16, #31 and #30 (Paraxis reset + temporary `server.eonar` logs for Surge of Life) live.
- **Live since the restart at 19:39 UTC (owner OK), worldserver 936195d:** #34 Tirathon holds still while casting; #35 legendary limit 1 (2 with the tier 6 class hall talent), live conf `Player.UnlimitedLegionLegendaries = 0` (backup `~/legion/etc/worldserver.conf.bak_legendaries_20260926`); Codex BRH #21 (SQL applied, undo `~/undo_brh_21.sql`) and #23 (Amalgam exit fallback). Changelog 1553491289952231566, Live comments + labels posted. All four need an in-game test (see the issues).
- **Live since the restart at 20:26 UTC (owner OK), worldserver b1600a1 (PR #42) + 73f1b53:** #41 Call to the Void tendrils cast Mind Flay and cap at 3; Acrid Catalyst Injector works (253259 had no spell_script_names row; added with `~/fix_acrid_catalyst_injector.sql`, undo `~/undo_acrid_catalyst_injector.sql`; effect 0 checked in SpellEffect.db2: dummy aura). #39 the five VotW bosses have mechanic_immune_mask 617299839 (backup table `world.bak_votw_boss_immunities`, undo `~/undo_votw_boss_immunities.sql`). Deploy lock removed.
- **Live since the restart at 20:41 UTC (owner OK), worldserver 7ca8ea4:** Codex #18 Eye of Azshara Wrangler yell for solo/partial groups + Crusher 14507329 stationary (undo `~/undo_eoa_18.sql`). Changelog 1553507051139768341, Live comment posted. Still open on #18: Arcanist path 9717100 (no waypoints, no spawn reference).
- **Discord:** Grok is out of usage; Claude relays `For the reporter:` lines (`bugs.py reply`) and checks new reports only when the owner says so.
  Changelog 1553504519290355794 posted (`~/changelog_restart_2026.json`). `Live:` comments + `live`/`needs-test` labels posted on #41 and #39; both need an in-game test.

## Open work

1. **#39 rest (not started):** the rest of #39 (Glayvianna Swoop/Metamorphosis/Unleash Fury, Mendacius Meteor + grimguard rate, Illianna facing, Grimhorn Torment + position, misplaced Defiler/Scorcher pack, Vault of the Betrayer light/statues/webs) is DB/SmartAI and spell-data work that needs the server's DB and `wdc1.py`; not started. **#40** Arcway Mythic list is untaken.
2. **Antorus (xinkeg, approved):** #29 still open for the 60%/30% adds (activation spells 257941/257942 need their gateway NPCs 122543/122558; test with logging) and the other Hasabel points. #25 Felhounds, #26 platform, #28 High Command, #30 Eonar: Surge of Life fix staged (above); Paraxis Inquisitor/crystals/Feedback still unverified in game.
3. **#27** trinkets out of combat: waiting for a retail source (needs-info).
4. **Neltharion's Lair #13 (Claude), still open:** tunnel slide clips at the third corner + bump at the end (Catmull-Rom overshoot in `spell_entrance_run_plr_move`; add points around the corner once someone sees which), Rokmora RP NPCs talk over each other (conversation 1885 timing is fine) and should run past instead of despawning (no route data), fall damage in the pool under Naraxas, trash after Naraxas / before Dargrul positions, drummer positions + drumming animation, Dargrul footsteps. Needs James's exact spots or retail data for the position items.
5. **Audit findings (no reporter):** #21 Black Rook Hold small script bugs, #22 BRH mobs without AI, #23 door fallback behind Amalgam, #17 dead spell_script_names rows, #18 EoA patrols/yell.
6. **Task board:** https://github.com/users/Chronoicle/projects/1. Use Refs #N for work that is not complete/live; never force-push.

## Needs an in-game check (issues labelled needs-test)

#1 Naraxas intro, #2 Neltharion's Lair retest, #3 Glazer on Mythic, #5 Court of Stars boat + lantern, #15 EoA weather, #24 Vault of the Wardens (console positions are estimates), #29 Hasabel trash, #33 Marking Targets and other procs.

## Waiting for the owner

- Grok: create its Discord bot + GitHub token, and turn on the board's auto-add workflow (server side is set up, see GROK.md). Until Grok runs, check Discord with `cd ~/discord-bot && venv/bin/python bugs.py new`.
- #4 Vileshard Crawler damage tuning; website #6 https, #7 shop items (SOAP), #8 Discord widget, #9 e-mail (SMTP).
- Optional: add launcher / website / Discord bot code to the repo (#12).
