# Project knowledge (decisions and lessons)

Background that is not obvious from the code. Rules are in `AGENTS.md`, current work in `HANDOFF.md`, history in `CHANGES.md`.

## Decisions by the owner

- **Playerbots are parked** (2026-09-25). DestinyCore's bots are ~50k lines plus ~1,600 edits in 115 core files, and the server (8 GB RAM) was already short on memory. If they come back: start with solo "follow and fight" bots only (BotAI + class AIs + PlayerBotSession), not the battleground/arena bots, and only once crashes have settled. Solocraft and the built-in AuctionHouseBot are on instead.
- **Don't port boss/dungeon scripts from DestinyCore** (2026-09-25). The DestinyCore versions of Eye of Azshara, Court of Stars and Neltharion's Lair faked mechanics (Rokmora on mana instead of energy, no Brittle, etc.) and were reverted. LegionCore's own scripts (UWOW-derived) are better: compare them against LittleWigs/BigWigs timers and fix them. DestinyCore is still useful for class/artifact spells LegionCore has no handler for (`scripts/Custom/destiny_*.cpp`).
- **No domain for now** (2026-09-26): the website runs on the IP (http://194.146.39.126), no https yet.
- **Approved reporters** (game bugs fixed without asking): see `AGENTS.md`.

## Creature health and damage

- Base values come from the gt tables in `~/data/gt` (same as the client). At level 98-113 all NpcTotalHp tables are equal, but NpcDamageByClass (classic, 1,231 at 110) vs NpcDamageByClassExp6 (32,836) differ 27x, so creatures with HealthScalingExpansion 0 hit like Classic mobs. Fixed 2026-09-26: 4,922 Legion creatures set to 6 (undo `~/undo_hse_legion.sql`).
- Core difficulty multipliers (StatSystem.cpp, Mythic x10/x15 etc.) assume the Legion table. Karazhan matched UWOW damage.
- The 10 launch dungeons had 7.0 health; UWOW is exactly x2.068, applied to 354 entries only spawned there (undo `~/undo_hp_launch_dungeons.sql`). 7.1+ content (Cathedral, Karazhan) already matched.
- The owner compares against UWOW (a LegionCore server with retail-like numbers). When "mobs too weak/strong" comes up, compare against these tables before touching rates.
- Missing waypoint paths are common (`MovementType=2` without `creature_addon.path_id`): mobs stand still.

## Core pitfalls found so far

- AuraScript `DoCheckProc` runs **before** the core checks proc flags: never cast or change state in a CheckProc (Focused Will / Soul Leech bug, #32).
- `ProcEventInfo::GetSpellInfo()` was a stub returning nullptr until #33; scripts that check the triggering spell never fired before that.
- Creature proc cooldowns and RPPM use `getPreciseTime()` (steady clock); don't mix with GameTime.
- `EventMap::RescheduleEvent(id, time, group)`: the third argument is a group, not a flag.
- Changing a core header (Unit.h etc.) means a full rebuild (~1-2 h with -j2); the syntax check gives false "redefinition" errors from the old precompiled header.

## Built-in client UI (CASC patch)

The premium menu Lua is appended to `Interface\FrameXML\QuestChoiceFrameMixin.lua` inside the client's CASC storage. Tools in `~/client_parts` (build_patch.py, casc_write.py, casc_local.py, root.py, encoding.py, getfile.py, fetch_blob.py). Every one of these was a separate failure:
- A changed file needs a new build: new root + encoding + build config + .build.info (same key → "Error loading ..." in Logs/FrameXML.log).
- Build config without patch / patch-size / patch-config lines (else "encoding table mismatch in patch manifest").
- Encoding table stored like Blizzard's: BLTE blocks per section (22=n, especs=z, indexes/pages=n, *=z) with a matching trailer ESpec; root as ESpec 'z'.
- shmem (Data/data/shmem, offset 272 + 4*bucket) must name the new .idx versions.
- `Wow-64_Custom.exe` = Wow-64_Patched.exe with the versions URL and the `%s.patch.battle.net` CDN URL pointed at our patch server (`~/cdn/cdn_server.py`, tmux `cdn`, port 8099; nginx serves it as 194-146-39-126.nip.io on port 80).
- Always test on backups: a failed client start can create `CASCRepair.mrk` and wipe an index (restore kit `~/downloads/ClientRestore_full.zip`).

## Launcher

Source `~/launcher` (Go; `gui_windows.go` = WebView2 window via github.com/jchv/go-webview2, `console.go` for Linux tests, `ui.html` + logo embedded; design from Amibari's C# "Chronicles" launcher). Build: `GOOS=windows GOARCH=amd64 go build -ldflags "-H windowsgui -s -w"`; icon/manifest via `go-winres simply --icon icon.png --manifest gui`. Feeds: `~/cdn/launcher/news.json` (written when posting to #changelog) and `status.json` (Discord bot presence cog). Publish: copy to `~/cdn/launcher/Launcher.exe` and set `launcher_md5` in `manifest.json` (all launchers self-update). Test builds: `-X main.selfUpdates=no`.

## Website

SahtoutCMS V2 (made for AzerothCore 3.3.5) ported to LegionCore. Source `~/website_src/SahtoutCMS`, deploy `bash ~/website_src/deploy.sh` → `/var/www/chronicles` (nginx + php8.1-fpm, group www-data). PHP errors: `/var/www/chronicles/logs/php_errors.log`. DB `website` (user `website`, password in `~/.website_db`). The game login is the e-mail (`includes/srp6.php`, class `GameAccount`); signing up on the site creates the game account. Shop: services only; item delivery would need SOAP (off; needs a restart and a GM account → ask the owner). Changelog posts also go to the website news (`discord-bot/site_news.py`).
