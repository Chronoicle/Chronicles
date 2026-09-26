# Handoff: current state (update at the end of every task)

Last updated: 2026-09-26 ~20:30 UTC by Claude (desktop session). Previously: ~20:00 UTC by Claude (Project thread).

## Who does what right now

- **Server session:** a Claude session on the owner's Windows desktop (Remote Control, started from a Project thread). SSH as `wow` with its own key, `gh` logged in with board access. Cloud threads cannot reach the server; they start this session when server work is needed.
- The old server session on the owner's Mac is retired (its notes are in `docs/NOTES.md`).

## Current state

- **Codex, Refs #18:** entrance Wrangler yell now triggers once for the first nearby non-GM player, with retries on the existing 2-second instance tick; no full-group/leader requirement. Pathless Crusher 14507329 uses stationary fallback (SQL applied; backup/fix/undo `~/backup_eoa_18.sql`, `~/fix_eoa_18.sql`, `~/undo_eoa_18.sql`). Build and install passed (`~/build_eoa_18.log`, `~/install_eoa_18.log`); staged, not live, waiting for owner-approved restart. Arcanist path 9717100 is absent and unreferenced in creature_addon and creature_template_addon; no creature 97171 spawn exists. That report needs a current spawn/location or reliable route data; no guessed route added. Test solo/partial-group entry, delayed grid loading, no repeated yell, and Crusher behavior.


- Previously deployed changes are live. Last restart 18:34 UTC (owner OK): crash fix 0e21884, #33 7aef6a1, #29 Hasabel trash 3697fce. Changelog 1553476662119637004, Live comments posted.
- The 17:07 UTC crash restart made #24, #32, #15, #16, #31 and #30 (Paraxis reset + temporary `server.eonar` logs for Surge of Life) live.
- **Live since the restart at 19:39 UTC (owner OK), worldserver 936195d:** #34 Tirathon holds still while casting; #35 legendary limit 1 (2 with the tier 6 class hall talent), live conf `Player.UnlimitedLegionLegendaries = 0` (backup `~/legion/etc/worldserver.conf.bak_legendaries_20260926`); Codex BRH #21 (SQL applied, undo `~/undo_brh_21.sql`) and #23 (Amalgam exit fallback). Changelog 1553491289952231566, Live comments + labels posted. All four need an in-game test (see the issues).
- **Live since the restart at 20:26 UTC (owner OK), worldserver b1600a1 (PR #42) + 73f1b53:** #41 Call to the Void tendrils cast Mind Flay and cap at 3; Acrid Catalyst Injector works (253259 had no spell_script_names row; added with `~/fix_acrid_catalyst_injector.sql`, undo `~/undo_acrid_catalyst_injector.sql`; effect 0 checked in SpellEffect.db2: dummy aura). #39 the five VotW bosses have mechanic_immune_mask 617299839 (backup table `world.bak_votw_boss_immunities`, undo `~/undo_votw_boss_immunities.sql`). Deploy lock removed.
  Changelog 1553504519290355794 posted (`~/changelog_restart_2026.json`). **Still to do:** `Live:` comments + `live`/`needs-test` labels on #41 and #39. Blocked by the Claude Code auto-mode classifier (GitHub writes), not by the owner.

## Open work

1. **#39 rest (not started):** the rest of #39 (Glayvianna Swoop/Metamorphosis/Unleash Fury, Mendacius Meteor + grimguard rate, Illianna facing, Grimhorn Torment + position, misplaced Defiler/Scorcher pack, Vault of the Betrayer light/statues/webs) is DB/SmartAI and spell-data work that needs the server's DB and `wdc1.py`; not started. **#40** Arcway Mythic list is untaken.
2. **Antorus (xinkeg, approved):** #29 still open for the 60%/30% adds (activation spells 257941/257942 need their gateway NPCs 122543/122558; test with logging) and the other Hasabel points. #25 Felhounds, #26 platform, #28 High Command, #30 Eonar Surge of Life (after a test: `grep server.eonar ~/legion/logs/Server.log`, then remove the temporary logs).
3. **#27** trinkets out of combat: waiting for a retail source (needs-info).
4. **Neltharion's Lair #13:** one-shot/death-state behavior on Vileshard Crawler 96247, Blightshard Shaper 90998 and Tarspitter Lurker 91001, and trash placement after Naraxas. James's DK screenshots are in report 1553289525655109654. Avoid a broad core death-state guard without stronger evidence.
5. **Audit findings (no reporter):** #21 Black Rook Hold small script bugs, #22 BRH mobs without AI, #23 door fallback behind Amalgam, #17 dead spell_script_names rows, #18 EoA patrols/yell.
6. **Task board:** https://github.com/users/Chronoicle/projects/1. Use Refs #N for work that is not complete/live; never force-push.

## Needs an in-game check (issues labelled needs-test)

#1 Naraxas intro, #2 Neltharion's Lair retest, #3 Glazer on Mythic, #5 Court of Stars boat + lantern, #15 EoA weather, #24 Vault of the Wardens (console positions are estimates), #29 Hasabel trash, #33 Marking Targets and other procs.

## Waiting for the owner

- Grok: create its Discord bot + GitHub token, and turn on the board's auto-add workflow (server side is set up, see GROK.md). Until Grok runs, check Discord with `cd ~/discord-bot && venv/bin/python bugs.py new`.
- #4 Vileshard Crawler damage tuning; website #6 https, #7 shop items (SOAP), #8 Discord widget, #9 e-mail (SMTP).
- Optional: add launcher / website / Discord bot code to the repo (#12).
