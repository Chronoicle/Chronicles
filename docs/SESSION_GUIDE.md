# Server session guide (how the desktop Claude session works)

For a new Claude account or session that takes over the **server session** on the owner's Windows desktop.
Read `AGENTS.md` (rules), `HANDOFF.md` (what is open right now), `CHANGES.md` (what went live) first; this file is
the practical know-how that is not written down there. Written 2026-09-27 by Claude (desktop session).

## 1. Standing permissions from the owner (Christian)

These were given in chat and saved as private memory, so a new account does not have them. They still hold:

- **Run server work yourself** (SSH as `wow`, builds, SQL with fix/undo files, deploy lock, changelog, Discord replies).
  Don't hand the owner commands to paste. The server (184.174.37.33, since 2026-09-28) is the owner's own Contabo VPS (8 cores, 23 GB). The old Kamatera VPS 194.146.39.126 only hands out launcher updates, forwards port 1119 and redirects the website until the owner cancels it.
- **Never restart without an explicit OK in chat** ("restart now"). Build, stage and keep working, then ask.
  "restart now" means: the whole restart routine in section 4, including the changelog and reporter updates.
- **Discord:** Grok (the intake bot) is out of usage. You relay every new `For the reporter:` line yourself and comment
  `Told the reporter (Claude)` on the issue. **Check new reports only when the owner says so** ("check bug reports").
- The owner writes short messages ("restart now", "fix #58"). Answer short, report what changed and what is waiting.
- Owner's account is 2 (characters Chron guid 1, Chronl 5, Chrondh 20, Chronp 25 = Shadow priest, Chronm 36). Rxven (guid 37, account 9) was also edited on the owner's request.

## 2. Environment

- Repo: `C:\Users\Chr\Documents\GitHub\Chronicles`. Locally `origin` = Chronoicle/Chronicles (push here: `git push origin main`).
  On the server the same repo is `~/LegionCore` with remote `chronicles` (`git pull --ff-only chronicles main`).
  Workflow: edit + commit + push locally, then pull on the server and build there.
- SSH: `ssh -o BatchMode=yes wow@184.174.37.33 '<cmd>'` (key is set up, also for root; `grok_chronicles` is Grok's key, never use it). Services: `~/start_all.sh` (also @reboot) starts the tmux sessions bnet, world, cdn, status, discord.
- The Bash tool is Git Bash on Windows: **no `jq`, no `python`** locally. Parse JSON with `--jq` of `gh`, PowerShell
  `ConvertFrom-Json`, or run Python on the server (`python3` there).
- Many repo files are **CRLF**. `perl -0pi -e` patterns must use `\r?\n`, or use the Edit tool (safest for multi-line edits).
- `gh` is logged in with board access (project 1 of Chronoicle). Board move to "Needs testing":
  ```
  P=$(gh project view 1 --owner Chronoicle --format json --jq .id)
  F=$(gh project field-list 1 --owner Chronoicle --format json --jq '.fields[]|select(.name=="Status")|.id')
  O=$(gh project field-list 1 --owner Chronoicle --format json --jq '.fields[]|select(.name=="Status")|.options[]|select(.name=="Needs testing")|.id')
  gh project item-list 1 --owner Chronoicle --limit 200 --format json --jq '.items[]|select(.content.number==41)|.id' | while read id; do gh project item-edit --id $id --project-id $P --field-id $F --single-select-option-id $O; done
  ```
- The Claude Code auto-mode classifier sometimes returns "no verdict (error)". That is transient: retry once, do read-only
  work meanwhile.

## 3. Fix workflow (one bug)

1. `gh issue view N --comments`, read the report, find the code (`Grep`), check spell/item data (section 6).
2. Fix the root cause in the shared function (every caller), comment `// ... (#N)` like the surrounding code.
3. Commit `Claude: <what and why> (Refs #N)` with the attribution line, `git push origin main`.
4. Build on the server:
   ```
   test -e ~/DEPLOY.lock && cat ~/DEPLOY.lock   # someone else deploying? then wait / ask
   echo "Claude (desktop session) $(date -u +%H:%M) UTC: build #N, no restart" > ~/DEPLOY.lock
   cd ~/LegionCore && git pull -q --ff-only chronicles main && cd build && nohup bash -c "make -j2 > ~/build.log 2>&1; echo MAKE_EXIT=\$? >> ~/build.log; make install >> ~/build.log 2>&1; echo INSTALL_EXIT=\$? >> ~/build.log" > /dev/null 2>&1 &
   # wait: for i in $(seq 1 55); do grep -q INSTALL_EXIT ~/build.log && break; sleep 10; done; grep -a "_EXIT\| error:" ~/build.log
   rm ~/DEPLOY.lock
   ```
   ccache makes most builds 2-5 minutes. A **new .cpp file** needs `cmake .` in `~/LegionCore/build` first, and that
   recompiles all scripts (~30 min). Quick single-file check: `eval "$(cat ~/syntax_check.sh) <file.cpp>"`.
5. DB changes: `sql/custom/fix_<name>.sql` + `undo_<name>.sql` in the repo, copy to `~/` on the server, apply with
   `mysql world < ~/fix_<name>.sql`. DB changes to creatures/templates go live at the next restart (never `.reload`).
6. Issue comment:
   ```
   Staged: <commit>, built and installed (needs a restart). <technical cause and fix>
   For the reporter: <1-3 plain sentences, no code>. Live after the next restart. (Claude)
   ```
7. Reply in Discord to the report (section 5), then comment `Told the reporter (Claude)`.
8. Update `HANDOFF.md` (top of "Current state": what is staged / live / waiting), commit, push, `git pull` on the server.

Temporary diagnostic logs: `TC_LOG_INFO("server.<topic>", "...%u %s", ...)` (printf style; cast enums to `uint32`,
the fmt backend refuses enum types). They land in `~/legion/logs/Server.log` (appends, with timestamps).

## 4. Restart routine (only after "restart now")

```
test -e ~/DEPLOY.lock && cat ~/DEPLOY.lock
echo "Claude (desktop session) $(date -u +%H:%M) UTC: restart (owner OK) <what>" > ~/DEPLOY.lock
tmux send-keys -t world "server restart 60" Enter
# ~75 s later: wait until the pane shows "(worldserver-daemon) ready", then check ps -o lstart= -C worldserver
rm ~/DEPLOY.lock
```
Before the restart apply any SQL that must only go live with the new binary (see HANDOFF "NOT applied yet").
After the restart:
- Changelog embed (players see it; also feeds launcher + website news):
  write `~/changelog_restart_HHMM.json` like `[[{"title": "🛠️ Server update — ...", "color": 5814783, "fields": [{"name": "...", "value": "... Reported by <discord name>."}], "footer": {"text": "Legion 7.3.5 · build 26972"}, "timestamp": "..."}]]`
  then `cd ~/discord-bot && venv/bin/python bugs.py embed 1552351331392421908 ~/changelog_restart_HHMM.json`.
  Credit reporters by name, no pings, no file names.
- Issue comments `Live: <commit> after the HH:MM UTC restart (owner OK). Changelog <id>.` + `For the reporter: Live now, please test ...`,
  labels `gh issue edit N --add-label live,needs-test`, board card to "Needs testing", tell the reporter in Discord.
- CHANGES.md entry (newest first, `date — who — what — status — undo`) and HANDOFF.md.

Crash: the loop restarts the worldserver by itself; backtrace in `~/crashes/crash_<date>.log`. The binary has no line
numbers: find the faulting instruction with `gdb -batch -ex "info symbol 0x<addr-0x555555554000>" -ex "disassemble ..." ~/legion/bin/worldserver`.

## 5. Discord (bot = `~/discord-bot/bugs.py`, run with `venv/bin/python`)

- `bugs.py new`: unread reports + suggestions (marks them read for everyone). `bugs.py list 20`: recent, for context.
- `bugs.py reply <message id> "<text>"`: reply as the bot. If the original message was deleted (404 Unknown Message),
  reply to the reporter's latest message and say what it is about.
- Approved reporters (by Discord ID): James 947341290801078302 (patriarch8809), xinkeg 267053277823107072,
  eru.01 514798411648729118, gabrielf03d 468733568726728704 → issue labels `bug,<area>,approved`.
  Everyone else and all suggestions → `needs-owner`.
- Intake round: `bugs.py new`, then find which report IDs are already on the board (the Discord link is in the issue
  body or a comment):
  ```powershell
  $d = gh issue list -R Chronoicle/Chronicles --state all --limit 100 --json number,body,comments | ConvertFrom-Json
  foreach ($i in $ids) { $m = $d | ? { ($_.body + ($_.comments.body -join ' ')) -like "*$i*" } | % number; "$i : $($m -join ',')" }
  ```
  New real report → issue (template in AGENTS.md); follow-up → comment on the existing issue. Then reply to every
  reporter with the issue number ("Added to our board as issue #N ...").
- A message that is a Discord reply ("this works now, no need to fix"): find what it answers without printing the token:
  ```
  cd ~/discord-bot && venv/bin/python - <<'EOF'
  import os, json, urllib.request
  from dotenv import load_dotenv; load_dotenv(".env")
  req = urllib.request.Request("https://discord.com/api/v10/channels/<channel>/messages/<id>", headers={"Authorization": "Bot " + os.environ["DISCORD_TOKEN"], "User-Agent": "bugs"})
  m = json.load(urllib.request.urlopen(req)); print((m.get("referenced_message") or {}).get("content"))
  EOF
  ```

## 6. Game data tools (on the server, `~/client_parts`, run with `PYTHONPATH=~/client_parts python3`)

- `wdc1.py file.db2 [id ...]`: records of a DB2 as lists (ID first for most files). DB2s are in `~/data/dbc/enUS/`,
  game tables in `~/data/gt/`. Field order = `src/server/game/DataStores/DB2Structure.h`.
  - SpellEffect record: `[ID, Effect, BasePoints, EffectIndex, Aura, DifficultyID, Amplitude, AuraPeriod, BonusCoef,
    ChainAmp, ChainTargets, DieSides, ItemType, Mechanic, PointsPerResource, RealPointsPerLevel, TriggerSpell, PosFacing,
    Attributes, BonusCoefFromAP, PvpMultiplier, Coefficient, Variance, ResourceCoef, GroupSizeCoef, ClassMask[4],
    MiscValue[2], RadiusIndex[2], ImplicitTarget[2], SpellID]` (floats come back as int bits: `struct.unpack("f", struct.pack("I", x))`).
  - SpellMisc: `[CastingTimeIndex, DurationIndex, RangeIndex, ..., Speed(bits), ..., Attributes[14], SpellID]`.
  - SpellXSpellVisual: `[SpellVisualID, ID, Probability, CasterPlayerConditionID, ...]`: a non-zero caster condition
    means **players only**, so a creature casting that spell shows no visual (use an NPC version of the spell).
- `spellnames.py` → `/tmp/spellnames.pkl` {spellId: name}. `itemsparse.py` → `/tmp/itemsparse.pkl` {itemId: fields}:
  index 1 name, 22 AllowableClass, 23 ItemLevel, 27 stat allocation[10], 40 GemProperties, 45 quality, 46 InventoryType,
  52 stat types[10] (5 int, 7 sta, 32 crit, 36 haste, 49 mastery, 40 vers), 59 socket types[3].
  `Item.db2`: `[?, ClassID, SubclassID, ?, Material, InventoryType, ...]`.
  `questlines.py [words]` → `/tmp/questlines.pkl` (questline names + their quests).
- World DB `quest_template` has no titles and almost no class data; use questlines instead. `item_template` only has
  old custom items (7866 rows); Legion items are only in the DB2s.

## 7. Facts learned the hard way

- **Item levels via bonus IDs:** raid `567 651` (930 → 985), dungeon `567 641 698`, Legion legendaries `3630` (→ 1000),
  level deltas `1497` +25, `1502` +30, `1517` +45, `1527` +55, `1547` +75. `DB2Manager::GetItemBonusListForItemLevelDelta`
  maps a delta to a bonus. The Donate Vendor accepts `ilvl:N` in `donate_products.bonus` (after the next restart).
- **Editing characters:** only while the character is **offline** (online data is overwritten on save). Give items with
  the console mail command (creates proper durability/artifact data): `tmux send-keys -t world "send items <name> \"subject\" \"text\" id id ..." Enter`
  (max 12 per mail, no bonus support), then set `item_instance.bonusListIDs` / `itemLevel` for those guids. Mailed items
  have `owner_guid = 0`: filter by `mail_items.receiver`. Always make `bak_*` tables + an undo file.
- **Quests done:** insert into `character_queststatus_rewarded (guid, account, quest)` and delete from
  `character_queststatus`. That does not grant the quests' one-time rewards.
- **Class hall:** garrison site level 560 = Alliance class hall, 584 = Horde. Second Legion legendary = class hall talent
  (`Garrison::hasLegendLimitUp`, priest 456 "Armed by Faith"): row in `character_garrison_talents (guid, 0, talent, UNIX_TIMESTAMP()-864000, 0)`.
- **Spells:** player spells cast by creatures deal ~nothing (no spell/attack power) → pass custom base points; many
  player spells have player-only visuals → NPC versions. `spell_trigger` (LegionCore table) casts proc spells too;
  a script that also casts them doubles the effect (Call to the Void tendrils). Guardian pets (Mindbender) never get
  `spell_pet_auras`, only real `Pet` objects do; use `creature_template_addon.auras`.
- **Temporary logs still in the code:** `server.acrid` (Acrid Catalyst Injector; values verified 235/2682 at ilvl 985 →
  can be removed), `server.angel` (Avenging Angel boss casts), `server.eonar` (Mythic reset paths, waiting for xinkeg's
  test), `server.antoran` / `server.antorus` (Antorus), `server.paladin` (#46), `server.possession` (Codex, #47).

### Filling a character (gear, quests, artifacts, relics, Crucible): `tools/fill_character`

One script does everything that was done by hand for Chronp, for any class/spec (owner request 2026-09-27):
```
cd ~/LegionCore/tools/fill_character
python3 fill_character.py plan  <name> [--spec shadow]    # show what it would do (no changes)
python3 fill_character.py all   <name> [--spec shadow]    # character OFFLINE: gear mail + quests + artifacts
python3 fill_character.py artifacts|quests|gear <name>    # one part only (e.g. artifacts for a character that has gear)
python3 fill_character.py all <name> --rollback           # test: SQL in a transaction, prints the result, rolls back
python3 fill_character.py undo ~/fill_character/<name>_<time>
python3 fill_character.py check                           # validate presets.json for all 36 specs
```
- **gear:** 14 slots by mail (`send items` console) at ilvl 985 (legendaries 1000): preset legendaries + trinkets,
  T21 in the free tier slots, best Antorus piece for the rest by the spec's stat priority. `--all-legendaries` adds
  every class legendary. Missing artifacts (+ off-hands) are mailed too and moved straight into free bag slots.
- **quests:** level 110, class campaign + artifact questlines + Legionfall/Argus/Crucible (`CLASS_QUESTLINES`),
  third relic slot quest, class hall row if missing, class hall talent for the second legendary.
- **artifacts:** every artifact the character holds: rank 101 (all traits, 4th ranks, Concordance 50), tier 2,
  3 Antorus relics at 985, Crucible tier 1 + tier 2 (`crucible`) + tier 3 (`crucible_trait`) on each relic.
- Choices per spec live in `presets.json` (Shadow = Chronp's setup: Light Speed + Fiending Dark). Override the Crucible
  for one run with `--crucible "Light Speed" --crucible-trait "Fiending Dark"`.
- Every real run writes `~/fill_character/<name>_<time>/log.txt` + `undo.sql`. Artifacts still in the mailbox:
  take them out, log out, run `artifacts` again.

## 8. Custom content made in this session

- **Avenging Angel** world boss 500002 (`src/server/scripts/Custom/world_boss_avenging_angel.cpp`), spawned in the
  Gurubashi arena (guid 146929294, respawn 300 s). 2.147 billion health + 150 million per extra attacker, Frenzy
  111730 at +100% = all its damage x2, Crusader Strike tank stacks, Judgment, Shield of the Righteous, Consecration,
  Sacred Ground (Maiden), Witness the Void (Nighthold), two **Monke** adds 500003 (Hyrja look) every 60 s with Expel
  Light + Shield of Light. Tuning knobs are constants at the top of the file. SQL `sql/custom/fix_world_boss_avenging_angel.sql`.
- **Shop → Donate Vendor** (built, **not applied yet**, see HANDOFF): catalogue SQL `sql/custom/fix_shop_to_donate_vendor.sql`
  and `Bpay.Enabled = 0` must be applied together with the next restart, never before.

## 9. Where things stand

Always trust `HANDOFF.md` over this file for the current state. At the time of writing: waiting for the owner on
suggestions #54 (Eonar crystals by raid size) and #57 (.challenge), and for restarts; open bug issues #13, #25, #26,
#28, #29, #39, #40, #43, #45, #48-#53, #55, #56, #59 (see the board).
