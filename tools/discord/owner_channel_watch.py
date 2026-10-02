#!/usr/bin/env python3
"""Watches the private #owner-amibari channel every 30 s for the owner's and amibari's commands.
"restart now" / "check bug reports": deletes the message, answers "restarting now" / "checking now" and appends the
command to owner_commands.pending, which Claude (dev-owner) polls (it touches owner_watch.alive on every poll).
Started by ~/start_all.sh (tmux session ownerwatch)."""
import json, os, time, urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
env = dict(l.strip().split("=", 1) for l in open(os.path.join(HERE, ".env")) if "=" in l and not l.startswith("#"))
HEADERS = {"Authorization": "Bot " + env["DISCORD_TOKEN"], "User-Agent": "DiscordBot (chronicles, 1)",
           "Content-Type": "application/json"}
CHANNEL = "1555370335820316714"
ALLOWED = {"1002310885349523517": "chronwastaken", "468733568726728704": "amibari"}
COMMANDS = [("restart now", "restarting now"), ("check bug reports", "checking now")]
PENDING = os.path.join(HERE, "owner_commands.pending")
ALIVE = os.path.join(HERE, "owner_watch.alive")


def api(method, path, body=None):
    req = urllib.request.Request("https://discord.com/api/v10/channels/" + CHANNEL + path, method=method, headers=HEADERS,
                                 data=json.dumps(body).encode() if body is not None else None)
    with urllib.request.urlopen(req, timeout=20) as r:
        data = r.read()
    return json.loads(data) if data else None


def log(*a):
    print(time.strftime("%F %T"), *a, flush=True)


last = str((int(time.time() * 1000) - 3600 * 1000 - 1420070400000) << 22)  # first run: the last hour
while True:
    try:
        for m in sorted(api("GET", "/messages?limit=50&after=" + last), key=lambda m: int(m["id"])):
            last = m["id"]
            who = ALLOWED.get(m["author"]["id"])
            hits = [c for c in COMMANDS if c[0] in m.get("content", "").lower()]
            if not who or not hits:
                continue
            api("DELETE", "/messages/" + m["id"])
            # ponytail: Claude only acts while its session runs; say so instead of promising a restart nobody does
            offline = not os.path.exists(ALIVE) or time.time() - os.path.getmtime(ALIVE) > 120
            for cmd, answer in hits:
                api("POST", "/messages", {"content": answer + (" (queued: Claude is offline right now)" if offline else "")})
                with open(PENDING, "a") as f:
                    f.write(json.dumps({"cmd": cmd, "by": who, "msg": m["id"], "at": time.strftime("%FT%TZ", time.gmtime())}) + "\n")
                log(who, cmd, "offline" if offline else "")
    except Exception as e:  # network / rate limit: try again next round
        log("error:", e)
    time.sleep(30)
