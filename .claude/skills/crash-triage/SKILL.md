---
name: crash-triage
description: Find the cause of a worldserver crash on the live Chronicles server from its gdb crash log - the crashing thread, the exact instruction (addr2line/objdump on the running binary; symbols but no debug info), what happened just before it in Server.log - and fix it. Use when the owner says the server crashed or a new ~/crashes/ file appears.
---

# Crash triage

The server runs under gdb in `~/legion/bin/worldserver_loop.sh` (tmux session `world`, only on the server). On a crash
the loop copies the gdb output (`bt 40` of the crashing thread, `thread apply all bt 12`) to
`~/crashes/crash_<YYYY-MM-DD_HHMMSS>.log` and starts the newest **installed** binary again, so a crash restart can put
staged fixes live. More than 5 crashes in 10 minutes, or an exit that is neither a signal nor code 2, stops the loop
and leaves the `world` pane at a bash prompt: then the server is down and starting it needs the owner's OK.

Times: file names, `ls` and Server.log use server time (Europe/Berlin: UTC+2 until 2026-10-25, then UTC+1; entries
before 2026-09-27 21:37 UTC are in UTC). `date -u` and `TZ=UTC ps` print UTC.

## 1. What crashed, and is the server back

```bash
ssh -o BatchMode=yes wow@184.174.37.33 'date -u +%F_%T; ls -lt --time-style=+%F_%T ~/crashes | head -4; p=$(pgrep -x worldserver) && TZ=UTC ps -o lstart= -p $p || echo WORLDSERVER DOWN; grep -a "daemon) ready" ~/legion/logs/Server.log | tail -3'
ssh -o BatchMode=yes wow@184.174.37.33 'f=~/crashes/<file>; grep -n -m1 "received signal" $f; awk "/received signal/{p=1} p && /^Thread [0-9]+ \\(/{exit} p" $f | grep -E "^#[0-9]+ " | cut -c1-260'
```

- The ready lines tell which commit crashed (the last banner before the crash time) and which one is live now (the
  banner after it).
- Frame #0 `Trinity::Assert(...)`: an ASSERT failed in frame #1 (it shows as SIGSEGV). The condition text only went to
  the console: `tmux capture-pane -p -t world -S - | grep -A2 "ASSERTION FAILED"` before it scrolls out (2000 lines);
  else find the ASSERT in frame #1's source.
- `__run_exit_handlers`, `~World`, `~WorldSession`, `DatabaseWorkerPool::Execute`: the crash happened at shutdown
  (`status=2` = a `server restart`): something ran after the databases closed.
- `Map::Update` / `Map::UpdateLoop` / `ThreadPoolMap` frames: a map thread. LegionCore updates sessions on map threads
  (`World::UpdateSessions` skips sessions that have a map), so packet handlers, addon messages (`OnPlayerChat`),
  scripts and party bot AI run there. Shared statics touched from them need a mutex.

## 2. The exact instruction

The log has no registers. Map each frame address to an offset: gdb disables ASLR, so the base is `0x555555554000`
(`offset = address - 0x555555554000`; check it against the `main=0x5555...<main>` argument of a `__libc_start_call_main`
frame). Use the binary that **crashed**: the running process's file is still readable even after `make install`
replaced it, until the next restart:

```bash
ssh -o BatchMode=yes wow@184.174.37.33 'e=/proc/$(pgrep -x worldserver)/exe; addr2line -f -C -e $e 0x<off0> 0x<off1> 0x<off2>'
ssh -o BatchMode=yes wow@184.174.37.33 'e=/proc/$(pgrep -x worldserver)/exe; nm -C -S $e | grep -F "Creature::SelectVictim()"; objdump -d --no-show-raw-insn -C --start-address=0x<start> --stop-address=0x<off0 + 0x30> $e | tail -45'
```

- If the server restarted after the crash, `/proc/.../exe` is the restarted binary, not the crashed one. `addr2line`
  tells: when it prints the same function names as the gdb frames, the layout matches (a rebuild that only changed
  unrelated files keeps it). If not, try `~/legion/bin/worldserver`, else reason from the source.
- Code in `[clone .cold]` parts is a separate symbol far from the main body (`nm -C -S $e | grep -F "<name> [clone .cold]"`).
- nm doesn't say which file: grep the source for the function (`Creature::SelectVictim` lives in `Unit.cpp`).
- Read the instructions up to the crash offset against the C++ source. Example (the 2026-09-28 taunt crash):
  `mov 0x0(%rbp),%rbp; mov 0x10(%rbp),%rax; mov (%rax),%rdi` in a loop = advance the std::list node, load its value,
  dereference it; on end() the "value" is the list size: a past-the-end iterator.

## 3. What happened just before

The loop restarts ~10 s after the crash and startup writes ~700 lines, so cut the window at the crash second:

```bash
ssh -o BatchMode=yes wow@184.174.37.33 'awk '\''$1>="2026-09-28_20:11:00" && $1<="2026-09-28_20:13:24"'\'' ~/legion/logs/Server.log | grep -v "Concordance roll\|Loaded\|>>" | tail -60 | cut -c1-230'
```

Look for boss script logs (who fought what), logins/logouts, party bots added (`Party bot X (account N) for Y`).

## 4. Fix and follow up

- Fix the root cause in the shared function, not only the caller in the backtrace; then look for the same bug class
  elsewhere (the saved workflow `.claude/workflows/review-core-change.js`, lens `crash`, or a sweep with one refuter
  per finding). Classes found on this core so far: `do { ++it; (*it)... } while (it != end)` loops,
  `Trinity::Containers::SelectRandomContainerElement` on an empty container (walks the list sentinel ~2^31 times =
  multi-second freeze, then reads end()), unguarded statics used from map threads, work after the DBs closed at
  shutdown.
- Build with the deploy skill; tell the owner the cause, whether the server is back, which commit is live now, and
  ask for "restart now" if the fix is not live yet.
- CHANGES.md: `crash HH:MM:SS UTC (<cause>); the loop restarted it at HH:MM:SS UTC on <commit>`; HANDOFF.md with the
  crash log file name.
