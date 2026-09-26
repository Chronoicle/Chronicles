# Handoff: current state (update at the end of every task)

Last updated: 2026-09-26 ~19:30 UTC by Claude (Project thread).

## Who does what right now

- **Server session:** a Claude session on the owner's Windows desktop (Remote Control, started from a Project thread). SSH as `wow` with its own key, `gh` logged in with board access. Cloud threads cannot reach the server; they start this session when server work is needed.
- The old server session on the owner's Mac is retired (its notes are in `docs/NOTES.md`).

## Current state

- **Staged by Codex, Refs #23:** Amalgam exit gate opens after 30 seconds even if an outro ghost cannot finish its path; normal outro and saved-instance opening remain intact. Build and install passed; waiting for owner-approved restart. Not live. No DB changes. Logs: `~/build_brh_23.log`, `~/install_brh_23.log`. In-game test: kill Amalgam with a stuck outro ghost and verify the exit opens after 30 seconds; also verify normal outro, wipe, and saved-instance re-entry.

- **Staged by Codex, Refs #21:** Black Rook Hold Soul Echoes array bounds, Scavenger potion reset, Dantalionax death dialogue, and Felspite Dominator SmartAI link. Build and install passed; SQL applied, waiting for owner-approved restart. Not live. Backup `~/backup_brh_21.sql`, fix `~/fix_brh_21.sql`, undo `~/undo_brh_21.sql`. Logs: `~/build_brh_21.log`, `~/install_brh_21.log`. Test Soul Echoes animations, Scavenger wipe/re-pull below 66%, boss death line and Dominator casts in game.
- Previously deployed changes are live. Last restart 18:34 UTC (owner OK): crash fix 0e21884, #33 7aef6a1, #29 Hasabel trash 3697fce. Changelog 1553476662119637004, Live comments posted.
- The 17:07 UTC crash restart made #24, #32, #15, #16, #31 and #30 (Paraxis reset + temporary `server.eonar` logs for Surge of Life) live.
- **Open pull request (branch `claude/project-thread-3qur8k`) for #34 and #35**, not merged or built yet:
  - #34 Tirathon Saltheril now stands still while casting (script-only: `CastAndHold` focuses the current target so the chase stops until Spell::finish releases it).
  - #35 legendary limit: `Player.UnlimitedLegionLegendaries` default is now 0 (code + conf.dist). **The server session must also set `Player.UnlimitedLegionLegendaries = 0` in `~/legion/etc/worldserver.conf`** (make install only replaces the .dist; the live conf probably still says 1). Players already wearing 3+ legendaries keep them until they unequip.

## Open work

1. **#34, #35:** staged in the open PR above (agent:claude).
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
