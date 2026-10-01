#!/usr/bin/env python3
"""Read-only summary of the dungeon bots' DUNGEONBOT log lines (#140, src/server/game/PartyBot/DungeonBotAI.cpp).

    python3 ~/LegionCore/tools/dungeonbot_report.py ~/legion/logs/Server.log > /tmp/dungeonbot_report.md
    grep DUNGEONBOT Server.log | python3 tools/dungeonbot_report.py
    python3 tools/dungeonbot_report.py --selftest

Markdown: one row per run, the result counts per boss, and the likely dungeon bugs (a boss that resets, a boss dead
without its encounter DONE, a boss never found, no path / stuck on the way, targets that take no damage) grouped by
dungeon and boss with a count and the first detail. Wipes alone are not listed as bugs (bots can be weak).
Quests: DONE / INCOMPLETE counts per dungeon quest; a kill without credit or an item that never dropped is a likely bug.
"""
import collections, re, sys

RESULTS = ("KILLED", "WIPE", "EVADE", "STUCK", "NO_PATH", "NOT_FOUND")
# key=value, then an optional "quoted name" that belongs to that key (dungeon=12 "Deadmines", boss=639 "Glubtok")
FIELD = re.compile(r'(\w+)=(\S+)(?: "([^"]*)")?')


def parse(line):
    """The fields of one DUNGEONBOT line; detail= and reason= run to the end of the line. None if not one."""
    at = line.find("DUNGEONBOT ")
    if at < 0:
        return None
    text = line[at + len("DUNGEONBOT "):].rstrip("\n")
    rest = {}
    for key in ("detail", "reason"):
        cut = text.find(" %s=" % key)
        if cut >= 0:
            rest[key] = text[cut + len(key) + 2:]
            text = text[:cut]
    fields, names = {}, {}
    end = text.startswith("run=end ")
    for key, value, name in FIELD.findall(text[len("run=end "):] if end else text):
        fields[key] = value
        if name:
            names[key] = name
    fields.update(rest)
    fields["_end"], fields["_names"] = end, names
    return fields


def report(lines):
    runs, current = [], {}                      # current: run id -> its record (ids repeat after a restart)
    boss_counts = collections.OrderedDict()     # (dungeon, boss entry) -> Counter of results
    boss_names = {}
    quests = collections.OrderedDict()          # (dungeon, quest id) -> [title, DONE, INCOMPLETE, first INCOMPLETE detail]
    bugs = collections.OrderedDict()            # (dungeon, kind, entry) -> [count, name, first detail]

    def run_of(fields):
        rid = fields.get("run", "?")
        if rid not in current:                  # a run whose start is not in this log piece
            current[rid] = {"run": rid, "dungeon": fields.get("dungeon", "?"), "name": "", "level": "?", "members": "?",
                            "tank": fields.get("bot", "?"), "cleared": "?", "bosses": "?", "wipes": 0, "time": "?", "reason": "(no end line)"}
            runs.append(current[rid])
        return current[rid]

    def bug(dungeon, kind, entry, name, detail):
        key = (dungeon, kind, entry)
        if key not in bugs:
            bugs[key] = [0, name, detail]
        bugs[key][0] += 1

    for line in lines:
        f = parse(line)
        if not f:
            continue
        names = f["_names"]
        if f["_end"]:
            r = run_of(f)
            r.update(cleared=f.get("cleared", "?"), bosses=f.get("bosses", "?"), time=f.get("time", "?"), reason=f.get("reason", ""))
            r["wipes"] = int(f.get("wipes", r["wipes"]))
            current.pop(f.get("run", "?"), None)
            continue
        event = f.get("event")
        if event == "start":
            current.pop(f.get("run", "?"), None)
            r = run_of(f)
            r.update(name=names.get("bot", ""), level=f.get("level", "?"), members=f.get("members", "?"), tank=f.get("bot", "?"))
            continue
        r = run_of(f)
        dungeon = r["name"] or names.get("dungeon") or "dungeon %s" % r["dungeon"]
        if event is None and "quest" in f:    # quest results also carry result=: keep them out of the boss table
            qid, title, detail = f["quest"], names.get("quest", ""), f.get("detail", "")
            q = quests.setdefault((dungeon, qid), [title, 0, 0, ""])
            if f.get("result") == "DONE":
                q[1] += 1
            else:
                q[2] += 1
                q[3] = q[3] or detail
                if "credit 0" in detail:
                    bug(dungeon, "QUEST no kill credit", qid, title, detail)
                if "never dropped" in detail:
                    bug(dungeon, "QUEST item never dropped", qid, title, detail)
        elif event == "evade":
            bug(dungeon, "EVADE (reset)", f.get("boss", "?"), boss_names.get(f.get("boss")), f.get("detail", ""))
        elif event == "oddmob":
            bug(dungeon, "HOSTILE FAR ABOVE LEVEL", f.get("target", "?"), names.get("target"), f.get("detail", ""))
        elif event == "giveup":
            bug(dungeon, "NO DAMAGE (giveup)", f.get("target", "?"), names.get("target"), "health %s" % f.get("health", "?"))
        elif event is None and "result" in f:
            entry, result, detail = f.get("boss", "?"), f["result"], f.get("detail", "-")
            boss_names[entry] = names.get("boss", "")
            boss_counts.setdefault((dungeon, entry), collections.Counter())[result] += 1
            if not r["name"]:
                r["name"] = names.get("dungeon", "")
            if result in ("EVADE", "STUCK", "NO_PATH", "NOT_FOUND"):
                bug(dungeon, result, entry, boss_names[entry], detail)
            elif result == "KILLED" and "not DONE" in detail:
                bug(dungeon, "KILLED but encounter not DONE", entry, boss_names[entry], detail)

    out = ["# Dungeon bot report", "", "## Runs (%d)" % len(runs), "",
           "| run | dungeon | level | bots | tank | cleared | bosses | wipes | time | reason |",
           "|---|---|---|---|---|---|---|---|---|---|"]
    for r in runs:
        out.append("| %s | %s (%s) | %s | %s | %s | %s | %s | %s | %ss | %s |" % (r["run"], r["name"] or "?", r["dungeon"], r["level"],
                   r["members"], r["tank"], r["cleared"], r["bosses"], r["wipes"], r["time"], r["reason"]))
    out += ["", "## Bosses", "", "| dungeon | boss | " + " | ".join(RESULTS) + " |", "|---|---|" + "---|" * len(RESULTS)]
    for (dungeon, entry), counts in boss_counts.items():
        out.append("| %s | %s %s | %s |" % (dungeon, entry, boss_names.get(entry, ""), " | ".join(str(counts[x]) for x in RESULTS)))
    out += ["", "## Quests", ""]
    if quests:
        out += ["| dungeon | quest | DONE | INCOMPLETE | first INCOMPLETE detail |", "|---|---|---|---|---|"]
        for (dungeon, qid), (title, done, incomplete, detail) in quests.items():
            out.append("| %s | %s %s | %d | %d | %s |" % (dungeon, qid, title, done, incomplete, detail.replace("|", "/")))
    else:
        out.append("None.")
    out += ["", "## Likely bugs (%d)" % len(bugs), ""]
    if bugs:
        out += ["| dungeon | kind | entry | name | count | first detail |", "|---|---|---|---|---|---|"]
        for (dungeon, kind, entry), (count, name, detail) in bugs.items():
            out.append("| %s | %s | %s | %s | %d | %s |" % (dungeon, kind, entry, name or boss_names.get(entry, ""), count, detail.replace("|", "/")))
    else:
        out.append("None.")
    return "\n".join(out) + "\n"


SAMPLE = r'''2026-10-01 10:00:00 DUNGEONBOT event=start run=1 dungeon=18 map=389 bot=Tankbot "Ragefire Chasm" difficulty=1 level=15 members=5 bosses=2 route=61408,61412
2026-10-01 10:01:00 DUNGEONBOT event=pull run=1 dungeon=18 map=389 bot=Tankbot target=11318 "Ragefire Trogg" at=1.0,2.0,3.0 boss=61408
2026-10-01 10:02:00 DUNGEONBOT event=giveup run=1 dungeon=18 map=389 bot=Tankbot target=11319 "Ragefire Shaman" health=100% reason=no damage for 45 s
2026-10-01 10:03:00 DUNGEONBOT run=1 dungeon=18 "Ragefire Chasm" boss=61408 "Adarogg" result=KILLED time=120 level=15 wipes=0 detail=-
2026-10-01 10:04:00 DUNGEONBOT event=evade run=1 dungeon=18 map=389 bot=Tankbot boss=61412 detail=boss reset at 40% with 5/5 alive (evades every pull?)
2026-10-01 10:05:00 DUNGEONBOT run=1 dungeon=18 "Ragefire Chasm" boss=61412 "Dark Shaman Koranthal" result=NO_PATH time=60 level=15 wipes=1 detail=no path from 1,2,3 to 4,5,6 (a closed door or a missing bridge?)
2026-10-01 10:00:01 DUNGEONBOT event=quests run=1 dungeon=18 bot=Healbot added=5723,5728 skipped=4
2026-10-01 10:02:30 DUNGEONBOT event=useobject run=1 dungeon=18 bot=Healbot object=175085 "Chest" quest=5723
2026-10-01 10:05:00 DUNGEONBOT quest=5723 "Testing an Enemy's Strength" result=DONE run=1 dungeon=18 bot=Healbot level=16
2026-10-01 10:05:00 DUNGEONBOT quest=5728 "Hidden Enemies" result=INCOMPLETE run=1 dungeon=18 bot=Healbot level=16 targets=in_map detail=0:MONSTER:11518:2/6 (killed 3, credit 0),1:ITEM:14544:0/1 (never dropped)
2026-10-01 10:05:00 DUNGEONBOT quest=5761 "Slaying the Beast" result=INCOMPLETE run=1 dungeon=18 bot=Tankbot level=16 targets=not_in_map detail=0:MONSTER:11520:0/1
2026-10-01 10:05:01 DUNGEONBOT run=end run=1 dungeon=18 cleared=0 bosses=1/2 wipes=0 time=301 reason=no boss left on the route
'''


def selftest():
    text = report(SAMPLE.splitlines(True))
    assert "| 1 | Ragefire Chasm (18) | 15 | 5 | Tankbot | 0 | 1/2 | 0 | 301s | no boss left on the route |" in text, text
    assert "| Ragefire Chasm | 61408 Adarogg | 1 | 0 | 0 | 0 | 0 | 0 |" in text, text
    assert "| Ragefire Chasm | NO_PATH | 61412 | Dark Shaman Koranthal | 1 | no path from 1,2,3 to 4,5,6 (a closed door or a missing bridge?) |" in text, text
    assert "| Ragefire Chasm | NO DAMAGE (giveup) | 11319 | Ragefire Shaman | 1 | health 100% |" in text, text
    assert "EVADE (reset) | 61412 | Dark Shaman Koranthal | 1 |" in text and "## Likely bugs (5)" in text, text
    assert "| Ragefire Chasm | 5723 Testing an Enemy's Strength | 1 | 0 |  |" in text, text
    assert "| Ragefire Chasm | 5728 Hidden Enemies | 0 | 1 | 0:MONSTER:11518:2/6 (killed 3, credit 0),1:ITEM:14544:0/1 (never dropped) |" in text, text
    assert "| Ragefire Chasm | 5761 Slaying the Beast | 0 | 1 | 0:MONSTER:11520:0/1 |" in text, text
    assert "| Ragefire Chasm | QUEST no kill credit | 5728 | Hidden Enemies | 1 |" in text, text
    assert "| Ragefire Chasm | QUEST item never dropped | 5728 | Hidden Enemies | 1 |" in text, text
    assert "57" not in text.split("## Quests")[0], text   # no quest in the boss table
    print("selftest ok")


if __name__ == "__main__":
    if sys.argv[1:] == ["--selftest"]:
        selftest()
    else:
        with (open(sys.argv[1], encoding="utf8", errors="replace") if sys.argv[1:] else sys.stdin) as src:
            sys.stdout.write(report(src))
