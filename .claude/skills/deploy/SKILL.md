---
name: deploy
description: Build the worldserver on the live Chronicles server, restart it when the owner says "restart now", and do the go-live checklist (changelog, issues, board, reporters, CHANGES/HANDOFF). Use for every core/script change that has to reach the live server.
---

# Build, restart, go live

Rules that always apply (details in AGENTS.md / docs/SESSION_GUIDE.md): never `.reload`; restart only when the owner
says "restart now" (then always `server restart 60`); hold `~/DEPLOY.lock` for builds AND restarts; every DB change has
a fix + undo file; commit + push every change; update HANDOFF.md after every task.

- Server: `ssh -o BatchMode=yes wow@184.174.37.33`. Run these commands with the **Bash tool** (Git Bash), not
  PowerShell: PowerShell 5.1 strips embedded double quotes when it calls ssh.exe.
- Server time is Europe/Berlin (UTC+2 until 2026-10-25, then UTC+1); `ls`, file names and Server.log use it. Use
  `date -u` / `TZ=UTC` for every time you write down.
- Long waits: Bash with `run_in_background: true` (a foreground `sleep` is blocked, Monitor expires after 5 min).

## 1. Build (no owner OK needed)

Commit and `git push origin main` locally first; commit only your own files (`git add <paths>`): other sessions or
workflow agents may have work in the tree. A new .cpp file needs `cmake .` in `~/LegionCore/build` first (recompiles
all scripts, ~30 min). Then:

```bash
ssh -o BatchMode=yes wow@184.174.37.33 'cat ~/DEPLOY.lock 2>/dev/null && exit 1; echo "Claude <who>: <what> build $(date -u +%H:%M)Z" > ~/DEPLOY.lock && cd ~/LegionCore && git pull -q --ff-only chronicles main && git log --oneline -1 && cd build && (nohup bash -c "make -j4 > ~/build.log 2>&1; e=\$?; echo MAKE_EXIT=\$e >> ~/build.log; [ \$e = 0 ] && make install >> ~/build.log 2>&1; echo INSTALL_EXIT=\$? >> ~/build.log" > /dev/null 2>&1 < /dev/null &); echo started'
```

- A lock that exists and is not yours means another session is deploying: stop and tell the owner.
- Detach exactly like that (`( ... &)` and `< /dev/null`), or the ssh call hangs until make ends.
- `-j4`: the Contabo server has 8 cores (older docs say -j2 from the old server).
- Wait in the background (script-only change ~3-5 min; a change to a common header such as Spell.h, SpellAuras.h or
  Unit.h rebuilds most of the core, ~15-20 min):

```bash
until ssh -o BatchMode=yes wow@184.174.37.33 'grep -q INSTALL_EXIT ~/build.log'; do sleep 45; done; ssh -o BatchMode=yes wow@184.174.37.33 'grep -E "MAKE_EXIT|INSTALL_EXIT|error:" ~/build.log | head -20; ls -l --time-style=+%F_%T ~/legion/bin/worldserver; grep -q "INSTALL_EXIT=0" ~/build.log && rm -f ~/DEPLOY.lock; ls ~/DEPLOY.lock 2>/dev/null || echo unlocked'
```

- Compile error (MAKE_EXIT not 0, the lock stays): fix, commit, push, and build again with the same command **without**
  the `cat ~/DEPLOY.lock ... && exit 1; echo ... > ~/DEPLOY.lock &&` part (your own lock would stop it).
- **The installed binary goes live at the next start, including a crash restart**: `worldserver_loop.sh` restarts the
  server with whatever is installed, so staged fixes can go live unannounced. The running commit is in the last
  `grep -a "daemon) ready" ~/legion/logs/Server.log | tail -1`; the installed one in
  `strings -n 12 ~/legion/bin/worldserver | grep -m1 -E "^[0-9a-f]{12} 20"`.
- HANDOFF: "Staged, <commit> built + installed HH:MM UTC, needs a restart", plus any SQL that must be applied right
  before the restart.

## 2. Restart (only after the owner's "restart now")

1. Check: no foreign lock, `tail -1 ~/build.log` shows INSTALL_EXIT=0, and `pgrep -x worldserver` finds the server.
   If it doesn't, the loop has stopped (after `server shutdown`, or more than 5 crashes in 10 min) and the tmux
   `world` pane is a plain bash: `send-keys` would type into bash. Tell the owner instead.
2. Take the lock: `echo "Claude <who> $(date -u +%H:%M) UTC: restart (owner OK) <what>" > ~/DEPLOY.lock`.
3. Apply the SQL that HANDOFF says goes with this restart: `mysql < ~/LegionCore/sql/custom/fix_<name>.sql` (no
   database argument: the files name their databases, `~/.my.cnf` has the login), then check with a SELECT.
4. Count the ready banners (Server.log is appended across restarts), then restart:
   `ssh ... 'grep -ac "daemon) ready" ~/legion/logs/Server.log; tmux send-keys -t world "server restart 60" Enter; date -u +%H:%M:%S'`
5. Wait (background) until one more banner appears (the ready line wraps in tmux, so read Server.log); N = the count
   from step 4:

```bash
sleep 90; for i in $(seq 40); do [ "$(ssh -o BatchMode=yes wow@184.174.37.33 'grep -ac "daemon) ready" ~/legion/logs/Server.log')" -gt N ] && break; sleep 15; done; ssh -o BatchMode=yes wow@184.174.37.33 'grep -a "daemon) ready" ~/legion/logs/Server.log | tail -1; p=$(pgrep -x worldserver) && TZ=UTC ps -o lstart= -p $p || echo WORLDSERVER DOWN; ls -lt --time-style=+%F_%T ~/crashes | head -4; rm -f ~/DEPLOY.lock'
```

6. A new `~/crashes/crash_<server time>.log` from the shutdown means it crashed on the way down (crash-triage skill).
   Party bots are logged out by a restart; the owner re-adds them with `.partybot add`. Online/offline status posts
   come from `server_status_watch.sh` by themselves: don't post them.

## 3. Go live (right after the restart)

Player-visible changes get a #changelog post; staff-only ones (GM commands, party bots, NPCs only staff spawn) don't.

- **Changelog**: write `~/changelog_restart_HHMM.json` (HHMM = UTC; reusing a name overwrites an older day's file)
  like the last one (`ls -t ~/changelog_*.json | head -1`):
  `[[{"title": "🛠️ Server update — <topic>", "color": 5814783, "fields": [{"name": "<area>", "value": "<plain sentence>. Reported by <name>."}], "footer": {"text": "Legion 7.3.5 · build 26972"}, "timestamp": "YYYY-MM-DDTHH:MM:00+00:00"}]]`
  (the timestamp must end in `+00:00`: the bot's Python rejects `Z`). Credit reporters by name, never ping. Post with
  the bot's venv (system python has no discord module):
  `ssh ... 'cd ~/discord-bot && venv/bin/python bugs.py embed 1552351331392421908 ~/changelog_restart_HHMM.json'`.
  It prints `posted: <url>`: the message id is the last number. Post once: it also feeds the launcher and website
  news. To correct it use `bugs.py edit <channel> <message id> <file.json>` (a single list of embeds; the news is not
  updated by edit).
- **Issues**, per fixed issue (`$'...'` so `\n` becomes a newline; write `'` inside as `\'`):
  `gh issue comment N --body $'Live: <commit> after the HH:MM UTC restart (owner OK). Changelog <id>.\n\nFor the reporter: Live now, please test: <what to check>. (Claude)'`,
  `gh issue edit N --add-label live,needs-test`, and the board card to "Needs testing" (the `gh project item-edit`
  snippet in docs/SESSION_GUIDE.md).
- **Reporter**: `ssh ... 'cd ~/discord-bot && venv/bin/python bugs.py reply <report message id> "Live now (issue #N): <one or two plain sentences>. Please test."'`
  The id is the last number of the Discord link in the issue body; it must be in `bug_reports.jsonl` (else "no logged
  report"). Inside the single quotes write `'` as `'\''`. The reply pings the reporter on purpose. Then comment
  `Told the reporter (Claude)` on the issue.
- **CHANGES.md**: `- Claude (<session>) — restart HH:MM UTC (owner OK, 60 s timer), worldserver <commit>: <what> — live, changelog <id> — <undo: git revert ..., undo SQL files>`.
- **HANDOFF.md**: move the items from "Staged" to "Live since HH:MM UTC" with what the owner should test (edit the
  entries in place; don't paste a new block above old ones, which duplicates them); commit, push, and
  `git pull -q --ff-only chronicles main` in `~/LegionCore` on the server.
