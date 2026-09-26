# Handoff: current state (update at the end of every task)

Last updated: 2026-09-26 ~15:30 UTC by Claude.

## Current state

**Staged, not live (restart needed, ask the owner):** crash fix 0e21884 (override-spell auras), #33 ProcEventInfo::GetSpellInfo 7aef6a1, Hasabel trash SQL (#29). All built and installed, deploy lock released.

**17:07 UTC crash** (SIGSEGV in HandleAuraOverrideSpells, old build) → the loop restarted on the new build, so everything staged up to 9b68fd0 is LIVE (#24, #32, #15, #16, #31, #30 Paraxis + server.eonar logs). Changelog posted, issues commented + labelled live. **Crash fix 0e21884 is built + installed but NOT live: needs a restart (ask the owner).**

0a. **Staged, not live:** commit after ea63b95 = #32 Discipline Focused Will (and warlock Soul Leech) no longer proc on jumps/own spells. Built + installed. Live with the same restart as #24.
0b. **Staged, not live:** 2817f3c Eye of Azshara #15 weather mechanics + #16 naga slots; 79eac34 Prestige cap 25 (#31). Eonar #30 partial (Paraxis reset fix + temporary server.eonar logs for Surge of Life; after a test: grep server.eonar ~/legion/logs/Server.log). #27 trinkets out of combat: findings posted, waiting for a retail source (needs-info).
0. **Staged, not live (restart needed, ask the owner):** commit ea63b95 = Vault of the Wardens #24 (Ash'golm countermeasure consoles spawned + per-cycle click, Cordana walls + intro flags, Tormentorum tpCount, trash SmartAI). Built and installed; DB `~/fix_votw.sql` already applied (undo `~/undo_votw.sql`). After the restart: #changelog post (found by audit, no reporter), comment on #24, test in game (the console positions are estimates).
1. **Live:** commit a1e44a2 (Dargrul Crystal Spikes summon 200338 after target spell 200551) is running since the restart at 14:29 UTC; binary hash verified, ports up. Changelog, James and #13 updated.
2. **Completed by Codex:** Neltharion's Lair commit 07c4946 is live after a 60-second restart at ~14:17 UTC. Naraxas starts Spiked Tongue directly at full energy, and Dargrul's Molten Charskins/Understone Demolishers pin threat to the fixated player. The running process reports revision 07c4946, matches the installed binary hash, and ports 3443, 8085 and 8086 are listening.
3. **Post-deploy complete:** James received staged and live replies. #changelog: https://discord.com/channels/1552349612726161459/1552351331392421908/1553410127409975378. GitHub #13 has a live-status comment and remains open.
4. **Neltharion's Lair #13 still open:** investigate one-shot/death-state behavior on Vileshard Crawler 96247, Blightshard Shaper 90998 and Tarspitter Lurker 91001, and trash placement after Naraxas. Crystal Spikes is live (a1e44a2). James's DK screenshots are in report 1553289525655109654; pally screenshots were expected. Avoid a broad core death-state guard without stronger evidence.
5. **Discord reports:** run cd ~/discord-bot && venv/bin/python bugs.py new regularly (automatic watcher is off). James (ID 947341290801078302) is pre-approved for game bug fixes; reply to every reporter with status updates. The latest run marked 14 reports shown: James's #13 follow-up was worked, while 13 Antorus reports from xinkeg remain unworked and require owner approval before building.
6. **Good next tasks** (issues have details and proposed fixes):
   - #16 Eye of Azshara: bounds check on NagasContainerGUID[NagasCount++] in instance_eye_of_azshara.cpp:95; possible crash.
   - #15 Eye of Azshara: weather mechanics disabled by a bare return in instance_eye_of_azshara.cpp:280.
   - #21 Black Rook Hold small script bugs; #23 fallback that opens the door behind Amalgam after 30 seconds.
   - #17 dead spell_script_names rows, #18 cosmetic patrols/yell, #22 mobs without abilities.
7. **Task board:** https://github.com/users/Chronoicle/projects/1. Use Refs #N for work that is not complete/live; never force-push.

## Live now (last restart ~14:29 UTC)

- Neltharion's Lair #13 commit a1e44a2: Dargrul Crystal Spikes summoned at the marker.

- Neltharion's Lair #13 commit 07c4946: Naraxas Spiked Tongue full-energy trigger and Dargrul fixate threat/chase. Deployed by Codex; changelog and reporter updates posted.
- Eye of Azshara #14 and Black Rook Hold #19/#20 commit f404d17: corrected encounter script bindings, boss-event scheduling and rolling-boulder visibility. Deployed by Codex; issues closed.
- Neltharion's Lair #13 commits 7f5919b and da1bd14: Charskin/Demolisher chase, Landslide knockback, hammer and Dargrul-arena NPCs after his death, Hulks immune to CC/slows and still during Piercing Shards, Drums of War not attackable, Naraxas loot only from the chest, smooth tunnel slide, Rokmora submerged before the roleplay, and four duplicate trash spawns removed.
- Naraxas intro #1 commit 35e5859, Rokmora/Ularogg/Naraxas fixes #2, Mythic health fix, creature proc cooldown fix, Glazer, Signal Lantern and Court of Stars boat: see ~/CHANGES.md.
- Ularogg and Naraxas diagnostic steps: grep server.nl ~/legion/logs/Server.log.

## Needs an in-game check (issues labelled needs-test)

#1 Naraxas intro, #2 Neltharion's Lair retest including live commit 07c4946 and a1e44a2, #3 Glazer on Mythic, #5 Court of Stars boat + lantern, and live fixes #14/#19/#20.

## Waiting for the owner

- Team setup (commit b15809d, see AGENTS.md "Team and roles", GROK.md): grok user, tools (grok-discord, grok-gh), /srv/chronicles-view and cron are set up (2026-09-26 16:04); the owner still has to create Grok's Discord bot + GitHub token, and turn on the board's auto-add workflow. Until Grok is running, check Discord with bugs.py as before.
- Restart for the crash fix 0e21884 (override-spell auras).
- Approval/verdict for the 13 Antorus reports from xinkeg before any build.
- #4 Vileshard Crawler damage tuning; website #6 https, #7 shop items (SOAP), #8 Discord widget, #9 e-mail (SMTP).
- Optional: add launcher / website / Discord bot code to the repo (#12).
