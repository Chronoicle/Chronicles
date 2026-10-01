#!/usr/bin/env python3
"""Static, read-only audit of the quests a level 1-10 character can get in the starting zones.

Run on the server (SELECTs only via `mysql -N`, client DB2 files via ~/client_parts/wdc1.py):
    python3 ~/LegionCore/tools/quest_audit.py > /tmp/quest_audit_1_10.md
    python3 ~/LegionCore/tools/quest_audit.py --selftest
Every check is one exact rule; the rules are printed at the top of the report.
"""
import collections, math, os, pickle, re, struct, subprocess, sys, time

HOME = os.path.expanduser("~")
sys.path.insert(0, HOME + "/client_parts")
import wdc1  # noqa: E402

DBC = "/home/wow/data/dbc/enUS/"
SRC = HOME + "/LegionCore/src/server"

# (report group, zone ids as creature.zoneId stores them: the start area is its own zone id in 7.x)
ZONES = [
    ("Northshire / Elwynn Forest", (6170, 12)),
    ("Coldridge Valley / New Tinkertown / Dun Morogh", (6176, 6457, 1)),
    ("Shadowglen / Teldrassil", (6450, 141)),
    ("Ammen Vale / Azuremyst Isle / Bloodmyst Isle", (6456, 3524, 3525)),
    ("Gilneas", (4755, 4714)),
    ("Kezan / The Lost Isles", (4737, 4720)),
    ("Deathknell / Tirisfal Glades", (6454, 85)),
    ("Valley of Trials / Durotar", (6451, 14)),
    ("Echo Isles", (6453,)),
    ("Camp Narache / Mulgore", (6452, 215)),
    ("Sunstrider Isle / Eversong Woods", (6455, 3430)),
    ("The Wandering Isle", (5736,)),
    ("Mardum / Vault of the Wardens (Demon Hunter start)", (7705, 7814)),
    ("Acherus / The Scarlet Enclave (Death Knight start)", (4298, 4342)),
]
CLASS_START = {7705: 12, 7814: 12, 4298: 6, 4342: 6}   # class start zones (zone -> class): every quest, no level filter
START_RACES = {6170: [1], 12: [1], 6176: [3], 6457: [7], 1: [3, 7], 6450: [4], 141: [4], 6456: [11], 3524: [11], 3525: [11],
               4755: [22], 4714: [22], 4737: [9], 4720: [9], 6454: [5], 85: [5], 6451: [2], 14: [2, 8], 6453: [8], 6452: [6],
               215: [6], 6455: [10], 3430: [10], 5736: [24], 7705: [4, 10], 7814: [4, 10]}   # zone -> races starting there
CLASS_SORT = {-81: 1, -141: 2, -261: 3, -162: 4, -262: 5, -372: 6, -82: 7, -161: 8, -61: 9, -395: 10, -263: 11, -407: 12}
CLASSES = {1: "Warrior", 2: "Paladin", 3: "Hunter", 4: "Rogue", 5: "Priest", 6: "Death Knight", 7: "Shaman", 8: "Mage",
           9: "Warlock", 10: "Monk", 11: "Druid", 12: "Demon Hunter"}
HOLIDAY_SORTS = {-21, -22, -41, -364, -366, -369, -370, -374, -375, -376, -378, -409, -430, -433}
NONE, COMPLETE, INCOMPLETE, REWARDED = 0, 1, 3, 6
COND_STATE = {8: {REWARDED}, 9: {INCOMPLETE}, 14: {NONE}, 28: {COMPLETE}}  # ConditionMgr.cpp, this core
SEV = ("BLOCKER", "MAJOR", "MINOR")
QUEST_TEXT = ("LogTitle LogDescription QuestDescription AreaDescription QuestCompletionLog PortraitGiverText PortraitGiverName "
              "PortraitTurnInText PortraitTurnInName")
CYR = re.compile("[\u0400-\u04FF]")
UPSTREAM = "its own previous quests are unobtainable"
TURNIN_YD = 15        # the owner's ~10 yd plus the rounding of sniffed points


def q(sql, db="world"):
    out = subprocess.run(["mysql", "-N", "-B", "--default-character-set=utf8mb4", db, "-e", sql],
                         capture_output=True, check=True).stdout.decode("utf8", "replace")   # bytes: texts contain a raw \r
    return [line.split("\t") for line in out.split("\n") if line]


def n(x):
    if x in ("NULL", ""):
        return 0
    try:
        return int(x)
    except ValueError:
        return int(float(x))


def ids(rows, col=0):
    return {n(r[col]) for r in rows}


def inlist(s):
    return ",".join(str(x) for x in s) or "NULL"


def db2(name, strings=()):
    """{id: fields}; the field positions listed in `strings` are turned from string-table offsets into text."""
    rows = {k: list(v) for k, v in wdc1.read(DBC + name + ".db2").items()}   # copied records share one list
    if strings:
        d = open(DBC + name + ".db2", "rb").read()
        h = struct.unpack_from(wdc1.HEADER, d, 0)
        so = struct.calcsize(wdc1.HEADER) + 4 * h[2] + h[1] * h[3]
        for v in rows.values():
            for i in strings:
                v[i] = d[so + v[i]:d.index(b"\0", so + v[i])].decode("utf8", "replace")
    return rows


def bits(mask):
    return [b for b in range(64) if mask >> b & 1]


# ---------------------------------------------------------------- client data
class Client:
    def __init__(self):
        self.spell = {k: v[0] for k, v in db2("Spell", (0,)).items()}
        self.spell.update({n(r[0]): "(hotfix spell)" for r in q("SELECT ID FROM spell", "hotfixes") if n(r[0]) not in self.spell})
        effects = {k: v for k, v in wdc1.read(DBC + "SpellEffect.db2").items()}
        for r in q("SELECT ID, Effect, EffectAura, EffectItemType, EffectTriggerSpell, EffectMiscValue1, EffectMiscValue2, SpellID "
                   "FROM spell_effect", "hotfixes"):
            v = [0] * 30
            v[1], v[4], v[12], v[16], v[26], v[29] = n(r[1]), n(r[2]), n(r[3]), n(r[4]), [n(r[5]), n(r[6])], n(r[7])
            effects[n(r[0])] = v
        self.eff = collections.defaultdict(set)      # effect type -> {(spell, misc0, item, trigger)}
        self.phase_aura = []                          # (spell, phasemask, phaseId) of SPELL_AURA_PHASE 261
        for v in effects.values():
            misc = v[26] if isinstance(v[26], list) else [v[26], 0]
            self.eff[v[1]].add((v[29], misc[0], v[12], v[16]))
            if v[4] == 261:
                self.phase_aura.append((v[29], misc[0] & 0xFFFFFFFF, misc[1]))
        self.area_parent = {k: v[5] for k, v in wdc1.read(DBC + "AreaTable.db2").items()}
        self.blobs = collections.defaultdict(list)   # quest -> [(objIndex, sorted points)]
        pts = collections.defaultdict(list)
        for k, v in sorted(wdc1.read(DBC + "QuestPOIPoint.db2").items()):
            pts[v[3]].append((v[1] - 65536 if v[1] > 32767 else v[1], v[2] - 65536 if v[2] > 32767 else v[2]))
        for k, v in wdc1.read(DBC + "QuestPOIBlob.db2").items():
            self.blobs[v[6]].append((-1 if v[7] == 127 else v[7], v[1], tuple(sorted(pts[k]))))
        self.areatrigger = set(wdc1.read(DBC + "AreaTrigger.db2"))
        self.criteria_tree = set(wdc1.read(DBC + "CriteriaTree.db2"))
        self.questline = {v[1] for v in wdc1.read(DBC + "QuestLineXQuest.db2").values()}
        self.combos = {(v[0], v[1]) for v in wdc1.read(DBC + "CharBaseInfo.db2").values()}
        self.spell_level = {v[5]: v[0] for v in wdc1.read(DBC + "SpellLevels.db2").values() if v[4] == 0}
        # spells a class can learn: specialization spells, class skill-line abilities, talents
        spec_class = {k: v[4] for k, v in wdc1.read(DBC + "ChrSpecialization.db2").items()}
        self.learn = collections.defaultdict(set)    # spell -> {classId}
        for v in wdc1.read(DBC + "SpecializationSpells.db2").values():
            if v[3] in spec_class:
                self.learn[v[1]].add(spec_class[v[3]])
        class_skill = {k for k, v in wdc1.read(DBC + "SkillLine.db2").items() if v[4] == 7}
        skill_classes = collections.defaultdict(int)
        for v in wdc1.read(DBC + "SkillRaceClassInfo.db2").values():
            skill_classes[v[1]] |= v[6] & 0xFFFFFFFF
        for v in wdc1.read(DBC + "SkillLineAbility.db2").values():
            mask = v[10] or skill_classes[v[4]]          # ClassMask 0: the classes of the skill line (Moonfire 8921)
            if v[4] in class_skill:
                self.learn[v[2]].update(c for c in CLASSES if mask >> (c - 1) & 1)
        for v in wdc1.read(DBC + "Talent.db2").values():
            self.learn[v[1]].add(v[8])
        if not os.path.exists("/tmp/itemsparse.pkl"):
            subprocess.run(["python3", HOME + "/client_parts/itemsparse.py"], env=dict(os.environ, PYTHONPATH=HOME + "/client_parts"),
                           check=True, capture_output=True)
        items = pickle.load(open("/tmp/itemsparse.pkl", "rb"))
        self.item = {k: v[1] for k, v in items.items()}
        self.item_quest = {k: v[31] & 0xFFFF for k, v in items.items() if v[31]}
        for r in q("SELECT ID, Display, StartQuestID FROM item_sparse", "hotfixes"):
            self.item[n(r[0])] = r[1]
            self.item_quest[n(r[0])] = n(r[2])

    def zone_of_area(self, area):
        return self.area_parent.get(area) or area


def learnable(client, spell, cls):
    """True if class `cls` can learn `spell` in 7.3.5 (spec spell, class skill-line ability, talent)."""
    return cls in client.learn.get(spell, ())


# ---------------------------------------------------------------- world data
class World:
    def __init__(self, client):
        c = client
        self.cpp = {int(x) for x in subprocess.run(
            ["grep", "-rhoE", r"\b[0-9]{3,7}\b", "--include=*.cpp", "--include=*.h", SRC],
            capture_output=True, text=True).stdout.split()}
        cols = ("ID QuestType QuestLevel MinLevel QuestSortID Flags AllowableRaces StartItem RewardNextQuest RewardSpell "
                "RewardDisplaySpell1 RewardDisplaySpell2 RewardDisplaySpell3").split()
        acols = "MaxLevel AllowableClasses SourceSpellID PrevQuestID NextQuestID ExclusiveGroup SpecialFlags".split()
        self.quest = {}
        for r in q("SELECT %s, t.LogTitle, %s FROM quest_template t LEFT JOIN quest_template_addon a ON a.ID = t.ID"
                   % (",".join("t." + x for x in cols), ",".join("IFNULL(a.%s,0)" % x for x in acols))):
            d = dict(zip(cols, map(n, r[:len(cols)])))
            d.update(zip(acols, map(n, r[len(cols) + 1:])))
            d["title"] = r[len(cols)] if r[len(cols)] != "NULL" else ""
            races = d["AllowableRaces"] & 0xFFFFFFFFFFFFFFFF
            d["races"] = races if races != 0xFFFFFFFFFFFFFFFF and races & 0x7F0007FF else -1   # loader: no playable race -> all
            self.quest[d["ID"]] = d
        for qid, title in q("SELECT ID, LogTitle FROM quest_template_locale WHERE locale = 'enUS' AND LogTitle <> ''"):
            if n(qid) in self.quest:
                self.quest[n(qid)]["title"] = title
        rel = lambda t: [(n(a), n(b)) for a, b in q("SELECT id, quest FROM " + t)]
        self.cstart, self.cend = rel("creature_queststarter"), rel("creature_questender")
        self.gstart, self.gend = rel("gameobject_queststarter"), rel("gameobject_questender")
        self.starters = collections.defaultdict(set)   # quest -> {(entry, quest)}
        for e, x in self.cstart + self.gstart:
            self.starters[x].add((e, x))
        self.event_start = {(n(a), n(b)) for a, b in q("SELECT id, quest FROM game_event_creature_quest UNION "
                                                       "SELECT id, quest FROM game_event_gameobject_quest")}
        self.seasonal = ids(q("SELECT questId FROM game_event_seasonal_questrelation"))
        self.disables = {n(r[0]): r[1:] for r in q("SELECT entry, flags, params_0, params_1, comment FROM disables WHERE sourceType = 1")}
        self.areaquest = ids(q("SELECT quest FROM area_queststart"))
        self.areaquest_end = ids(q("SELECT quest FROM areatrigger_questender"))
        self.createquest = ids(q("SELECT questid FROM playercreateinfo_quest"))
        self.spawned_c = ids(q("SELECT DISTINCT id FROM creature"))
        self.spawned_g = ids(q("SELECT DISTINCT id FROM gameobject"))
        self.ct = {n(r[0]): (n(r[1]), n(r[2]), n(r[3]), n(r[4]), r[5]) for r in
                   q("SELECT entry, npcflag, lootid, pickpocketloot, skinloot, ScriptName FROM creature_template")}
        self.cname, self.ctitle, credit = {}, {}, collections.defaultdict(set)
        self.wdb_drop = collections.defaultdict(set)     # item -> creatures whose sniffed QuestItem list has it
        for r in q("SELECT Entry, Name1, Title, KillCredit1, KillCredit2, %s FROM creature_template_wdb"
                   % ",".join("QuestItem%d" % i for i in range(1, 11))):
            self.cname[n(r[0])], self.ctitle[n(r[0])] = r[1], r[2]
            for k in (n(r[3]), n(r[4])):
                if k:
                    credit[k].add(n(r[0]))
            for i in r[5:]:
                if n(i):
                    self.wdb_drop[n(i)].add(n(r[0]))
        self.loot_owner = collections.defaultdict(set)   # (loot table, entry) -> creature entries
        for k, v in self.ct.items():
            for t, e in zip(("creature", "pickpocketing", "skinning"), v[1:4]):
                if e:
                    self.loot_owner[(t, e)].add(k)
        self.gt = {n(r[0]): dict(type=n(r[1]), name=r[2], flags=n(r[3]), loot=n(r[4]), qitems={n(x) for x in r[5:11]} - {0})
                   for r in q("SELECT entry, type, name, flags, Data1, questItem1, questItem2, questItem3, questItem4, questItem5, "
                              "questItem6 FROM gameobject_template")}
        for k, v in self.gt.items():
            if v["type"] in (3, 25, 50) and v["loot"]:
                self.loot_owner[("gameobject", v["loot"])].add(k)
        smart = collections.defaultdict(set)
        self.smart_npcflag, self.smart_cast = set(), []   # smart_cast: (source_type, entryorguid, spell)
        for e, st, a, p1 in q("SELECT entryorguid, source_type, action_type, action_param1 FROM smart_scripts "
                              "WHERE action_type IN (6,7,11,12,15,26,33,50,56,75,81,82,85,86,210,220,223)"):
            smart[n(a)].add(n(p1))
            if n(a) in (81, 82) and n(p1) & 2 and n(st) == 0 and n(e) > 0:
                self.smart_npcflag.add(n(e))
            if n(a) in (11, 75, 85, 86, 210):
                self.smart_cast.append((n(st), n(e), n(p1)))
        eff = lambda *types: {x[1] for t in types for x in c.eff[t]}
        scripts = lambda cmd: ids(q(" UNION ".join("SELECT datalong FROM %s WHERE command = %d" % (t, cmd) for t in (
            "event_scripts", "quest_start_scripts", "quest_end_scripts", "spell_scripts", "gameobject_scripts", "waypoint_scripts"))))
        self.summoned_c = (eff(28, 56) | smart[12] | smart[220] | scripts(10)   # by data; C++ is checked separately (self.cpp)
                           | ids(q("SELECT entry FROM creature_summon_groups")) | ids(q("SELECT accessory_entry FROM vehicle_template_accessory")))
        self.summoned_g = eff(76, 104, 105) | smart[50]
        live = self.spawned_c | self.summoned_c
        self.credit_src = {k for k, v in credit.items() if v & live} | smart[33] | eff(90, 134)
        self.any_entity = live | self.spawned_g | self.summoned_g | self.cpp   # creature/GO ids that can exist in game
        self.quest_event = eff(16) | smart[15] | smart[26] | smart[223] | self.areaquest_end | scripts(7)
        self.quest_start_other = (eff(150) | smart[7] | self.areaquest | self.createquest | set(c.item_quest.values())
                                  | {d["RewardNextQuest"] for d in self.quest.values() if d["Flags"] & 0x10000})
        self.item_created = {x[2] for t in (24, 157, 206) for x in c.eff[t]} | smart[56]
        self.trainer = ids(q("SELECT spell FROM npc_trainer")) | ids(q("SELECT Spell FROM playercreateinfo_spell")) | ids(
            q("SELECT Spell FROM playercreateinfo_spell_custom"))
        self.triggers = collections.defaultdict(set)      # spell -> spells it casts (EffectTriggerSpell, spell_linked_spell)
        for v in c.eff.values():
            for spell, _, _, trig in v:
                if trig:
                    self.triggers[spell].add(trig)
        for a, b in q("SELECT spell_trigger, spell_effect FROM spell_linked_spell"):
            self.triggers[abs(n(a))].add(abs(n(b)))
        self.phase_defs = collections.defaultdict(list)   # zone -> [(entry, phasemask, [phaseIds], flags)]
        for z, e, m, p, f in q("SELECT zoneId, entry, phasemask, phaseId, flags FROM phase_definitions"):
            self.phase_defs[n(z)].append((n(e), n(m), [int(x) for x in p.split()], n(f)))
        self.conds = collections.defaultdict(list)        # (sourceType, group, entry) -> [(else, type, v1, neg)]
        for st, g, e, eg, t, v1, neg in q("SELECT SourceTypeOrReferenceId, SourceGroup, SourceEntry, ElseGroup, "
                                         "ConditionTypeOrReference, ConditionValue1, NegativeCondition FROM conditions "
                                         "WHERE SourceTypeOrReferenceId IN (19, 23)"):
            self.conds[(n(st), n(g), n(e))].append((n(eg), n(t), n(v1), n(neg)))
        self.spell_area = [dict(zip(("spell", "area", "qs", "qss", "qes", "qe", "autocast"), map(n, r))) for r in
                           q("SELECT spell, area, quest_start, quest_start_status, quest_end_status, quest_end, autocast FROM spell_area")]
        self.spell_phase = [(n(a), n(b), n(c_)) for a, b, c_ in q("SELECT id, phasemask, phaseId FROM spell_phase")]


def cond_ok(rows, quest, status):
    """Conditions (ElseGroup = OR of AND groups) that can be true while `quest` has `status`.
    Only conditions on `quest` itself are evaluated; every other condition is assumed satisfiable."""
    if not rows:
        return True
    groups = collections.defaultdict(list)
    for eg, t, v1, neg in rows:
        groups[eg].append((t, v1, neg))
    return any(all(v1 != quest or t not in COND_STATE or (status in COND_STATE[t]) != bool(neg) for t, v1, neg in g)
               for g in groups.values())


def status_ok(mask, status):
    return bool(mask >> status & 1)


# ---------------------------------------------------------------- the audit
class Audit:
    def __init__(self, c, w):
        self.c, self.w = c, w
        self.findings = []   # (group, sev, quest, check, evidence)
        self.excluded = collections.Counter()
        self.scope = {}      # quest -> group label
        self.zone = {}       # quest -> zone id of most of its giver spawns
        self.zone_group = {z: g for g, zs in ZONES for z in zs}
        self.next_of = collections.defaultdict(list)
        for d in w.quest.values():
            if d["NextQuestID"] and abs(d["NextQuestID"]) in w.quest:
                self.next_of[abs(d["NextQuestID"])].append(d["ID"] if d["NextQuestID"] > 0 else -d["ID"])

    def add(self, group, sev, quest, check, evidence):
        self.findings.append((group, sev, quest, check, evidence))

    def cname(self, e):
        return "%s %d" % (self.w.cname.get(e, "?"), e)

    def gname(self, e):
        return "%s %d" % (self.w.gt.get(e, {}).get("name", "?"), e)

    def ename(self, k, e):
        return self.cname(e) if k == "c" else self.gname(e)

    def qname(self, qid):
        return "%d %s" % (qid, self.w.quest[qid]["title"]) if qid in self.w.quest else "%d (missing)" % qid

    # ---- scope
    def select(self):
        w, zg = self.w, self.zone_group
        spawns = collections.defaultdict(collections.Counter)
        self.zone_entities = collections.defaultdict(set)   # (smart source_type, entryorguid) -> groups
        for st, (kind, table) in enumerate((("c", "creature"), ("g", "gameobject"))):
            for e, guid, z in q("SELECT id, guid, zoneId FROM %s WHERE zoneId IN (%s)" % (table, inlist(zg))):
                spawns[(kind, n(e))][n(z)] += 1
                self.zone_entities[(st, n(e))].add(zg[n(z)])
                self.zone_entities[(st, -n(guid))].add(zg[n(z)])
        per_quest = collections.defaultdict(collections.Counter)
        for kind, rel in (("c", w.cstart), ("g", w.gstart)):
            for e, qid in rel:
                per_quest[qid].update(spawns.get((kind, e), {}))
        for qid, d in w.quest.items():
            zone = per_quest[qid].most_common(1)[0][0] if per_quest[qid] else d["QuestSortID"]
            group = zg.get(zone)
            if not group or zone not in CLASS_START and (d["MinLevel"] > 10 or d["QuestLevel"] > 10):
                continue
            if d["Flags"] & 0x400:
                self.excluded["tracking quests (QUEST_FLAGS_TRACKING, never in the quest log)"] += 1
            elif d["QuestType"] == 3:
                self.excluded["task / bonus objective quests (QuestType 3)"] += 1
            elif qid in w.seasonal or d["QuestSortID"] in HOLIDAY_SORTS or w.starters[qid] and w.starters[qid] <= w.event_start:
                self.excluded["holiday / game event quests"] += 1
            else:
                self.scope[qid], self.zone[qid] = group, zone

    def obtainable(self, qid):
        """Not disabled, and started by something that exists: a spawned/summoned (or C++-named) giver or another start."""
        w = self.w
        return qid in w.quest and qid not in w.disables and (qid in w.quest_start_other or any(
            e in w.any_entity for e, _ in w.starters[qid]))

    def prev_quests(self, qid):
        """Quest::prevQuests as the loader builds it: PrevQuestID (if it exists) + every quest whose NextQuestID is this one."""
        p = self.w.quest[qid]["PrevQuestID"]
        return list(dict.fromkeys(([p] if p and abs(p) in self.w.quest else []) + self.next_of[qid]))

    def load(self):
        w = self.w
        self.live = {qid for qid in self.scope if self.obtainable(qid)}
        self.needed = collections.defaultdict(set)   # quest -> live audited quests that list it as a previous quest
        for qid in self.live:
            for p in self.prev_quests(qid):
                self.needed[abs(p)].add(qid)
        self.starters, self.enders = collections.defaultdict(list), collections.defaultdict(list)
        for kind, rel, dest in (("c", w.cstart, self.starters), ("g", w.gstart, self.starters),
                                ("c", w.cend, self.enders), ("g", w.gend, self.enders)):
            for e, qid in rel:
                if qid in self.scope:
                    dest[qid].append((kind, e))
        self.spawns = collections.defaultdict(list)  # (kind, entry) -> [(map, zone, area, phaseMask, [PhaseId], x, y, npcflag)]
        for kind, table, flag in (("c", "creature", "npcflag"), ("g", "gameobject", "0")):
            ents = {e for v in list(self.starters.values()) + list(self.enders.values()) for k, e in v if k == kind}
            for r in q("SELECT id, map, zoneId, areaId, phaseMask, PhaseId, position_x, position_y, %s FROM %s WHERE id IN (%s)"
                       % (flag, table, inlist(ents))):
                self.spawns[(kind, n(r[0]))].append((n(r[1]), n(r[2]), n(r[3]), n(r[4]), [int(x) for x in r[5].split()],
                                                     float(r[6]), float(r[7]), n(r[8])))
        self.build_phase_sources()

    # ---- phases
    def build_phase_sources(self):
        c, w = self.c, self.w
        self.phase_src = src = collections.defaultdict(list)   # ('m', bit) / ('p', PhaseId) -> sources
        self.token_spells = collections.defaultdict(set)
        tokens = collections.defaultdict(set)
        for spell, mask, pid in c.phase_aura + w.spell_phase:
            tokens[spell].update(("m", b) for b in bits(mask))
            if pid:
                tokens[spell].add(("p", pid))
        src[("m", 0)].append(("default",))
        for z, defs in w.phase_defs.items():
            for e, mask, pids, flags in defs:
                for t in [("m", b) for b in (bits(mask) if not flags & 4 else [])] + [("p", p) for p in pids]:
                    src[t].append(("def", z, e))
        for row in w.spell_area:
            for t in tokens.get(row["spell"], ()):
                src[t].append(("sa", row))
        for spell, ts in tokens.items():
            for t in ts:
                src[t].append(("cast", spell))
                self.token_spells[t].add(spell)
        # spells cast in a zone group by its own data: quest spells, SmartAI casts of its spawns, spell_area, + 2 trigger levels
        self.local = local = collections.defaultdict(set)
        for qid, g in self.scope.items():
            local[g] |= {w.quest[qid][k] for k in ("SourceSpellID", "RewardSpell", "RewardDisplaySpell1", "RewardDisplaySpell2",
                                                   "RewardDisplaySpell3")}
        for st, e, spell in w.smart_cast:
            for g in self.zone_entities.get((st, e), ()):
                local[g].add(spell)
        for row in w.spell_area:
            g = self.zone_group.get(row["area"]) or self.zone_group.get(c.zone_of_area(row["area"]))
            if g:
                local[g].add(row["spell"])
        for s in local.values():
            for _ in range(2):
                s |= {t for x in list(s) for t in w.triggers.get(x, ())}

    def src_ok(self, s, sp, quest, status):
        """Can source s give its phase at spawn sp = (map, zone, area, ...) while `quest` has `status`?"""
        if s[0] == "default":
            return True
        if s[0] == "cast":
            g = self.zone_group.get(sp[1])
            return g is None or s[1] in self.local[g]
        if s[0] == "def":
            return s[1] == sp[1] and cond_ok(self.w.conds.get((23, s[1], s[2])), quest, status)
        r = s[1]
        return ((r["area"] in (sp[1], sp[2], 0) or r["area"] == -sp[0])
                and (r["qs"] != quest or status_ok(r["qss"], status)) and (r["qe"] != quest or status_ok(r["qes"], status)))

    def tokens(self, sp):
        return [("m", b) for b in bits(sp[3] or 1)], [("p", p) for p in sp[4]]

    def visible(self, sp, quest, status):
        masks, pids = self.tokens(sp)
        ok = lambda ts: any(self.src_ok(s, sp, quest, status) for t in ts for s in self.phase_src.get(t, ()))
        return ok(masks) and (not pids or ok(pids))

    def why_hidden(self, sp, quest, status):
        """(reason, phase spells of the missing phases that C++ names)"""
        out, cpp = [], set()
        for ts in self.tokens(sp):
            if ts and not any(self.src_ok(s, sp, quest, status) for t in ts for s in self.phase_src.get(t, ())):
                for t in ts:
                    label = ("phaseMask bit %d" % t[1]) if t[0] == "m" else ("PhaseId %d" % t[1])
                    blocked = [s for s in self.phase_src.get(t, ()) if s[0] == "def" and s[1] == sp[1] or s[0] == "sa" and
                               (s[1]["area"] in (sp[1], sp[2], 0) or s[1]["area"] == -sp[0])]
                    out.append("%s: %s" % (label, ("only via %s, whose condition on this quest fails" % ", ".join(
                        ("phase_definitions %d/%d" % s[1:]) if s[0] == "def" else ("spell_area %d" % s[1]["spell"]) for s in blocked[:3]))
                        if blocked else "no phase_definitions/spell_area of zone %d and no zone-cast spell gives it" % sp[1]))
                    cpp |= self.token_spells[t] & self.w.cpp
        return "; ".join(out[:4]), cpp

    # ---- 1 givers / enders, 2 disables
    def check_givers(self):
        w = self.w
        for qid, group in self.scope.items():
            d = w.quest[qid]
            if qid not in self.live:
                self.report_dead(qid, group)
                continue
            self.check_npcs(group, qid, self.starters[qid], NONE, "giver", qid in w.quest_start_other)
            if not self.enders[qid] and d["QuestType"] != 0 and not d["Flags"] & 0x10000:
                sev = 1 if qid in w.cpp else 0
                self.add(group, SEV[sev], qid, "1 ender: none", "no creature/gameobject_questender and not auto-complete "
                         "(QuestType 0 / QUEST_FLAGS_AUTOCOMPLETE)" + ("; the id appears in C++" if sev else ""))
            self.check_npcs(group, qid, self.enders[qid], COMPLETE, "ender", False)

    def report_dead(self, qid, group):
        """One finding for an audited quest nobody can get (disabled / no giver / giver not spawned)."""
        w, needed = self.w, sorted(self.needed.get(qid, ()))
        sev = "MAJOR" if (needed or qid in self.c.questline) and qid not in w.cpp else "MINOR"
        why = ("; previous quest of %s" % ", ".join(map(str, needed)) if needed else
               "; in a 7.3.5 QuestLine" if qid in self.c.questline else "; no audited quest needs it") + (
               "; the id appears in C++ (a script may offer it)" if qid in w.cpp else "")
        if qid in w.disables:
            flags, p0, p1, comment = w.disables[qid]
            self.add(group, sev, qid, "2 disabled", "disables sourceType 1 flags %s params '%s' '%s': %s%s" % (
                flags, p0, p1, comment or "(no comment)", why))
        elif not self.starters[qid]:
            self.add(group, sev, qid, "1 giver: none", "no creature/gameobject_queststarter, item StartQuestID, area_queststart, "
                     "spell effect 150, SmartAI 7 or playercreateinfo_quest" + why)
        else:
            self.add(group, sev, qid, "1 giver: not spawned", "%s not spawned, not summoned, not named in C++%s" % (
                ", ".join(self.ename(k, e) + ("" if k == "g" or e in w.ct else " (no creature_template)")
                          for k, e in self.starters[qid]), why))

    def check_npcs(self, group, qid, npcs, status, role, other_source):
        w = self.w
        spawned = [(k, e) for k, e in npcs if self.spawns.get((k, e))]
        if not npcs or other_source:
            return
        if not spawned:
            if not any(e in (w.summoned_c if k == "c" else w.summoned_g) for k, e in npcs):
                cpp = any(e in w.cpp for k, e in npcs)
                self.add(group, "MAJOR" if cpp else "BLOCKER", qid, "1 %s: not spawned" % role, "%s not in creature/gameobject "
                         "and not summoned by data (spell 28/56/76/104/105, SmartAI 12/50/220, script 10, summon groups, vehicle accessory)%s" % (
                             ", ".join(self.ename(k, e) for k, e in npcs), "; the id appears in C++" if cpp else ""))
            return
        vis = [(k, e, s) for k, e in spawned for s in self.spawns[(k, e)] if self.visible(s, qid, status)]
        if not vis:
            k, e = spawned[0]
            s = next(x for x in self.spawns[(k, e)] if self.zone_group.get(x[1])) if any(
                self.zone_group.get(x[1]) for x in self.spawns[(k, e)]) else self.spawns[(k, e)][0]
            why, cpp = self.why_hidden(s, qid, status)
            groups = collections.Counter((x[1], x[3], " ".join(map(str, x[4])) or "-") for x in self.spawns[(k, e)])
            self.add(group, "MAJOR" if cpp else "BLOCKER", qid, "1 %s: phase" % role, "%s: no spawn visible %s. Spawns "
                     "(zone/phaseMask/PhaseId): %s. %s%s" % (
                         self.ename(k, e), "before taking the quest" if status == NONE else "with the quest complete",
                         ", ".join("%d/%d/%s x%d" % (z, m, p, cnt) for (z, m, p), cnt in groups.most_common(3)), why,
                         "; phase spell %s named in C++" % ", ".join(map(str, sorted(cpp)[:3])) if cpp else ""))
            return
        # questgiver npcflag (creature.npcflag overrides creature_template.npcflag when non-zero)
        cre = [(e, s) for k, e, s in vis if k == "c"]
        if cre and len(cre) == len(vis) and not any((s[7] or w.ct.get(e, (0,))[0]) & 2 or e in w.smart_npcflag
                                                    or w.ct.get(e, ("",) * 5)[4] for e, s in cre):
            e = cre[0][0]
            self.add(group, "BLOCKER", qid, "7 %s: no questgiver flag" % role, "%s: npcflag %d without UNIT_NPC_FLAG_QUESTGIVER "
                     "(2) on every visible spawn, no SmartAI 81/82 adding it, no ScriptName" % (self.cname(e), w.ct.get(e, (0,))[0]))

    # ---- 4 chain and class
    @staticmethod
    def allowed(d, race, cls):
        ac, cbit = d["AllowableClasses"], 1 << (cls - 1)
        if ac > 0 and not ac & cbit or ac < 0 and -ac & cbit:
            return False
        return d["races"] == -1 or bool(d["races"] >> (race - 1) & 1)

    def classes(self, qid, seen=()):
        """Classes that can take the quest: AllowableClasses, narrowed by its previous quests' classes."""
        own = {cl for cl in CLASSES if self.allowed(dict(self.w.quest[qid], races=-1), 1, cl)}
        if self.zone.get(qid) in CLASS_START:
            own &= {CLASS_START[self.zone[qid]]}
        prevs = [abs(p) for p in self.prev_quests(qid) if self.obtainable(abs(p)) and abs(p) not in seen]
        return own & set().union(*(self.classes(p, seen + (qid,)) for p in prevs)) if prevs else own

    def dead_prevs(self, qid, seen=()):
        """({previous quest: why a player can never have it done}, [the others]) per Player::SatisfyQuestPreviousQuest,
        SatisfyQuestExclusiveGroup and SatisfyQuestNextChain; a reason is "deliberate" when it goes back to `disables` only."""
        w, d = self.w, self.w.quest[qid]
        dead, alive = {}, []
        for pq in self.prev_quests(qid):
            p, pd = abs(pq), w.quest[abs(pq)]
            if not self.obtainable(p):
                dead[pq] = "disabled" if p in w.disables else "no spawned/summoned quest giver"
            elif pq > 0 and d["ExclusiveGroup"] > 0 and pd["ExclusiveGroup"] == d["ExclusiveGroup"]:
                dead[pq] = "same positive ExclusiveGroup %d (rewarding it locks this quest)" % d["ExclusiveGroup"]
            elif p == d["RewardNextQuest"]:
                dead[pq] = "it is also this quest's RewardNextQuest"
            elif not any(self.allowed(d, *x) and self.allowed(pd, *x) for x in self.c.combos):
                dead[pq] = "no race/class may take both"
            elif p not in seen and not self.reachable(p, seen + (qid,)):
                dead[pq] = UPSTREAM + (" (cut by disables)" if self.deliberate[p] else "")
            else:
                alive.append(p)
        return dead, alive

    def reachable(self, qid, seen=()):
        if qid not in self.reach:
            dead, alive = self.dead_prevs(qid, seen)
            self.reach[qid] = self.obtainable(qid) and (bool(alive) or not dead)
            self.deliberate[qid] = all(why == "disabled" or why.endswith("(cut by disables)") for why in dead.values())
        return self.reach[qid]

    def check_chain(self):
        w, c = self.w, self.c
        self.reach, self.deliberate = {}, {}
        for qid in sorted(self.live):
            group, d = self.scope[qid], w.quest[qid]
            p = d["PrevQuestID"]
            prevs = self.prev_quests(qid)
            if p and abs(p) not in w.quest:
                self.add(group, "MINOR" if prevs else "BLOCKER", qid, "4 chain: PrevQuestID missing", "PrevQuestID %d does not exist "
                         "(the loader drops it%s)" % (p, "" if prevs else ", and with no previous quest left it is never available"))
            for col in ("NextQuestID", "RewardNextQuest"):
                if d[col] and abs(d[col]) not in w.quest:
                    self.add(group, "MINOR", qid, "4 chain: %s missing" % col, "%s %d does not exist" % (col, d[col]))
            if not prevs:
                continue
            dead, alive = self.dead_prevs(qid)
            if not alive:   # MAJOR when the chain was cut on purpose (disables) and the quest is in no 7.3.5 QuestLine
                self.reachable(qid)
                deliberate = self.deliberate[qid] and qid not in c.questline
                upstream = all(why.startswith(UPSTREAM) for why in dead.values())
                self.add(group, "MAJOR" if deliberate else "BLOCKER", qid, "4 chain: blocked upstream" if upstream else
                         "4 chain: previous quest unobtainable", "; ".join("%s: %s" % (self.qname(abs(pq)), why)
                                                                          for pq, why in dead.items()) + ("; never offered" if deliberate else ""))
                continue
            # start races of the giver's zone that the masks allow but no previous quest does: a race left out of a
            # chain, or a merge of several class chains that misses a class (a single class chain gating it is intended)
            zone = self.zone[qid]
            classes = {CLASS_START[zone]} if zone in CLASS_START else set(CLASSES) - set(CLASS_START.values())
            combos = {(r, cl) for r, cl in c.combos if r in START_RACES.get(zone, ()) and cl in classes}
            own = {x for x in combos if self.allowed(d, *x)}
            via = {x for x in own if any(self.allowed(w.quest[p], *x) for p in alive)}
            union = {cl for _, cl in via}
            twins = [x for x in self.live if self.scope[x] == group and w.quest[x]["title"] == d["title"]]
            viable = lambda x, r, cl: self.allowed(w.quest[x], r, cl) and (not self.prev_quests(x) or any(
                self.obtainable(abs(pq)) and self.allowed(w.quest[abs(pq)], r, cl) for pq in self.prev_quests(x)))
            blocked = {(r, cl) for r, cl in own - via if (len(union) > 1 or cl in union) and not any(viable(x, r, cl) for x in twins)}
            if blocked:
                self.add(group, "BLOCKER", qid, "4 chain: previous quest race/class", "%s (race %s) may take it, but no previous "
                         "quest (%s) or same-title variant is open to them" % (
                             ", ".join(sorted({CLASSES[cl] for r, cl in blocked})),
                             ",".join(sorted({str(r) for r, _ in blocked})), ", ".join(self.qname(x) for x in alive[:3])))

    def check_class(self):
        w = self.w
        for qid in sorted(self.live):
            group, d = self.scope[qid], w.quest[qid]
            cls = CLASS_SORT.get(d["QuestSortID"]) if self.zone[qid] not in CLASS_START else None
            others = self.classes(qid) - {cls}
            if cls and cls not in self.classes(qid):
                self.add(group, "MAJOR", qid, "4 class quest for the wrong class", "QuestSortID %d (%s) but the quest is open to %s" % (
                    d["QuestSortID"], CLASSES[cls], "/".join(CLASSES[x] for x in sorted(others)) or "nobody"))
            elif cls and others:
                self.add(group, "MAJOR", qid, "4 class quest for other classes", "QuestSortID %d (%s), AllowableClasses %d: also "
                         "open to %s" % (d["QuestSortID"], CLASSES[cls], d["AllowableClasses"], "/".join(CLASSES[x] for x in sorted(others))))
            if d["MaxLevel"] and d["MaxLevel"] < d["MinLevel"]:
                self.add(group, "BLOCKER", qid, "7 level range", "MaxLevel %d < MinLevel %d" % (d["MaxLevel"], d["MinLevel"]))
            accept = w.conds.get((19, 0, qid))
            if accept and not cond_ok(accept, qid, NONE):
                self.add(group, "BLOCKER", qid, "7 accept condition", "conditions SourceType 19 need a state of this quest itself "
                         "that is impossible before accepting it: %s" % accept)

    def check_objectives(self):
        w, c = self.w, self.c
        objs = collections.defaultdict(list)
        for r in q("SELECT QuestID, ID, Type, StorageIndex, ObjectID, Amount, Flags FROM quest_objectives "
                   "WHERE QuestID IN (%s)" % inlist(self.live)):
            objs[n(r[0])].append(dict(id=n(r[1]), type=n(r[2]), idx=n(r[3]), obj=n(r[4]), amount=n(r[5]), flags=n(r[6])))
        self.objs = objs
        items = {o["obj"] for v in objs.values() for o in v if o["type"] == 1}
        loot = self.loot_sources(items)
        vendor = ids(q("SELECT item FROM npc_vendor WHERE item IN (%s)" % inlist(items)))
        provided = {d["StartItem"] for d in w.quest.values()}
        for qid in sorted(self.live):
            group, d = self.scope[qid], w.quest[qid]
            event = d["SpecialFlags"] & 2 or any(o["type"] == 10 for o in objs[qid])
            if event and qid not in w.quest_event and not any(o["type"] == 10 and o["obj"] in c.areatrigger for o in objs[qid]):
                self.add(group, "MAJOR" if qid in w.cpp else "BLOCKER", qid, "3 event credit missing",
                         "needs an exploration/event credit (SpecialFlags 2 or an AREATRIGGER objective) but no areatrigger_questender, "
                         "AreaTrigger.db2 objective, spell effect 16, SmartAI 15/26/223 or script command 7 gives it" +
                         ("; the id appears in C++" if qid in w.cpp else ""))
            seen = collections.Counter(o["idx"] for o in objs[qid])
            for idx, cnt in seen.items():
                if cnt > 1 and idx >= 0:
                    self.add(group, "MAJOR", qid, "3 objective StorageIndex doubled", "%d objectives share StorageIndex %d" % (cnt, idx))
            for o in objs[qid]:
                t, x = o["type"], o["obj"]
                tag = "objective %d (type %d, %d)" % (o["id"], t, x)
                if o["flags"] & 0x54:   # OPTIONAL / HIDE_ITEM_GAINS / PART_OF_PROGRESS_BAR: CanCompleteQuest skips them
                    continue
                if o["amount"] <= 0 and t in (0, 1, 2, 3, 4, 9, 14, 15, 16, 17):
                    self.add(group, "MAJOR", qid, "3 objective Amount %d" % o["amount"], tag)
                if t in (0, 3):
                    if x not in w.ct:
                        self.add(group, "BLOCKER", qid, "3 kill/talk target missing", tag + ": no creature_template row")
                    elif x not in w.spawned_c | w.credit_src | w.summoned_c:
                        self.add(group, "MAJOR" if x in w.cpp else "BLOCKER", qid, "3 kill/talk target not spawned", "%s %s: not "
                                 "spawned, not summoned by data, no KillCredit/SmartAI 33/spell 90-134 credit%s" % (
                                     tag, self.cname(x), "; the id appears in C++" if x in w.cpp else ""))
                elif t == 1:
                    self.check_item(group, qid, tag, x, loot, vendor, provided)
                elif t == 2:
                    if x not in w.gt:
                        self.add(group, "BLOCKER", qid, "3 object missing", tag + ": no gameobject_template row")
                    elif x not in w.spawned_g | w.summoned_g:
                        self.add(group, "MAJOR" if x in w.cpp else "BLOCKER", qid, "3 object not spawned", "%s %s: not spawned or "
                                 "summoned by data%s" % (tag, self.gname(x), "; the id appears in C++" if x in w.cpp else ""))
                elif t == 5:
                    self.check_spell(group, qid, tag, x, d)
                elif t == 10 and x not in (-1, 0) and x not in c.areatrigger:
                    self.add(group, "BLOCKER", qid, "3 areatrigger missing", tag + ": not in AreaTrigger.db2")
                elif t == 14 and x not in c.criteria_tree:
                    self.add(group, "BLOCKER", qid, "3 criteria tree missing", tag + ": not in CriteriaTree.db2")

    def loot_sources(self, items):
        """{item: [(table, entry, questRequired)]}, reference_loot_template expanded."""
        holder = collections.defaultdict(set)    # reference entry -> (item, QuestRequired) it can give
        for e, i, ref, qr in q("SELECT Entry, Item, Reference, QuestRequired FROM reference_loot_template WHERE Item IN (%s)" % inlist(items)):
            holder[n(e)].add((n(i), n(qr)))
        frontier = set(holder)
        while frontier:
            nxt = set()
            for e, ref in q("SELECT Entry, Reference FROM reference_loot_template WHERE Reference IN (%s)" % inlist(frontier)):
                if not holder[n(e)] >= holder[n(ref)]:
                    holder[n(e)] |= holder[n(ref)]
                    nxt.add(n(e))
            frontier = nxt
        out = collections.defaultdict(list)
        for t in ("creature", "gameobject", "item", "pickpocketing", "skinning", "spell", "fishing", "mail", "world", "zone"):
            for e, i, ref, qr in q("SELECT Entry, Item, Reference, QuestRequired FROM %s_loot_template WHERE Item IN (%s) OR Reference IN (%s)"
                                   % (t, inlist(items), inlist(holder))):
                got = {(n(i), n(qr))} if n(ref) == 0 else holder.get(n(ref), set())
                for item, req in got:
                    if item in items:
                        out[item].append((t, n(e), req))
        return out

    def check_item(self, group, qid, tag, x, loot, vendor, provided):
        w, c = self.w, self.c
        if x not in c.item:
            self.add(group, "BLOCKER", qid, "3 item missing", tag + ": not in ItemSparse.db2 / hotfixes.item_sparse")
            return
        name = "%s %d" % (c.item[x], x)
        if x in vendor or x in provided or x in w.item_created:
            return
        src = loot.get(x, [])
        if any(t not in ("creature", "gameobject", "pickpocketing", "skinning") for t, e, r in src):
            return
        live = w.spawned_c | w.summoned_c
        if any(t != "gameobject" and w.loot_owner[(t, e)] & live for t, e, r in src):
            return
        notes = []
        for t, e, req in src:
            if t != "gameobject":
                continue
            gos = w.loot_owner[("gameobject", e)]
            if not gos and e in w.gt:
                notes.append("gameobject_loot_template %d is keyed by the object entry but %s has Data1 %d (#94 pattern)" % (
                    e, self.gname(e), w.gt[e]["loot"]))
            for g in gos:
                v = w.gt[g]
                if g not in w.spawned_g | w.summoned_g:
                    notes.append("%s not spawned" % self.gname(g))
                elif v["flags"] & 4 and x not in v["qitems"] and not (v["type"] == 3 and any(
                        t2 == "gameobject" and e2 == g and r2 for t2, e2, r2 in src)):
                    notes.append("%s (type %d) has GO_FLAG_INTERACT_COND but the item is not in its questItem1-6%s: not clickable (#118)" % (
                        self.gname(g), v["type"], "" if v["type"] == 50 else " nor QuestRequired loot under its entry"))
                else:
                    return
        creatures = [t + " " + str(e) for t, e, r in src if t != "gameobject"]
        drop = sorted(w.wdb_drop.get(x, ()))
        notes += ["only in %s loot of unspawned creatures" % ", ".join(creatures[:4])] if creatures else []
        notes += ["creature_template_wdb QuestItem lists it for %s (the retail drop) but their loot has no row" % ", ".join(
            self.cname(e) for e in drop[:3])] if drop else []
        self.add(group, "MAJOR" if x in w.cpp else "BLOCKER", qid, "3 item has no source", "%s %s: %s%s" % (
            tag, name, "; ".join(notes) or "no loot/vendor/create-item spell/provided item/SmartAI 56 source",
            "; the id appears in C++" if x in w.cpp else ""))

    def check_spell(self, group, qid, tag, x, d):
        c = self.c
        if x not in c.spell:
            self.add(group, "BLOCKER", qid, "3 spell missing", tag + ": not in Spell.db2")
            return
        name = "%s %d" % (c.spell[x], x)
        classes = sorted(self.classes(qid))
        if x in self.w.trainer:
            return
        can = [cl for cl in classes if learnable(c, x, cl)]
        if not can:
            self.add(group, "BLOCKER", qid, "3 spell not in the 7.3.5 kit", "%s %s: none of the classes that can take the quest (%s) "
                     "has it in SpecializationSpells/class SkillLineAbility/Talent/trainer" % (
                         tag, name, "/".join(CLASSES[cl] for cl in classes)))
        elif len(can) < len(classes):
            self.add(group, "MAJOR", qid, "3 spell quest open to other classes", "%s %s: only %s can learn it; also open to %s" % (
                tag, name, "/".join(CLASSES[cl] for cl in can), "/".join(CLASSES[cl] for cl in classes if cl not in can)))
        lvl = c.spell_level.get(x, 0)
        if lvl > 10 and self.zone[qid] not in CLASS_START:
            self.add(group, "MAJOR", qid, "3 spell learnt above level 10", "%s %s: SpellLevels BaseLevel %d" % (tag, name, lvl))

    def check_poi(self):
        c = self.c
        pois, pts = collections.defaultdict(list), collections.defaultdict(list)
        for r in q("SELECT QuestID, Idx1, ObjectiveIndex, MapID, VerifiedBuild FROM quest_poi WHERE QuestID IN (%s)" % inlist(self.live)):
            pois[n(r[0])].append((n(r[1]), n(r[2]), n(r[3]), n(r[4])))
        for r in q("SELECT QuestID, Idx1, X, Y FROM quest_poi_points WHERE QuestID IN (%s) ORDER BY QuestID, Idx1, Idx2" % inlist(self.live)):
            pts[(n(r[0]), n(r[1]))].append((n(r[2]), n(r[3])))
        for qid in sorted(self.live):
            group, client = self.scope[qid], c.blobs.get(qid, [])
            rows = pois.get(qid, [])
            if not rows:
                if client:
                    self.add(group, "MINOR", qid, "5 POI: none", "no quest_poi rows; the 7.3.5 client has %d blobs" % len(client))
                continue
            blobs = [(o, m, tuple(sorted(pts[(qid, i)])), b) for i, o, m, b in rows]
            notes, info = [], ""
            per_obj = collections.defaultdict(list)
            for o, m, p, b in blobs:
                per_obj[o].append(p)
            for o, plist in per_obj.items():
                if 0 <= o < 32 and len(plist) != len(set(plist)):
                    info = "objective %d blob doubled" % o
            objpts = {p: o for o, plist in per_obj.items() if 0 <= o < 32 for p in plist}
            for o, plist in per_obj.items():
                for p in plist:
                    if 0 <= o < 32 and objpts.get(p, o) != o and len(p) > 1:
                        notes.append("objective %d shows the objective %d area" % (o, objpts[p]))
            anchors = [pt for oo in (-1, 32) for p in per_obj.get(oo, []) for pt in p]
            for o, plist in per_obj.items():
                if 0 <= o < 32 and len(plist) > 1:
                    near = [p for p in plist if len(p) == 1 and any(dist(p[0], b) <= TURNIN_YD for b in anchors)]
                    if near and len(near) < len(plist):
                        notes.append("objective %d has a 2nd blob on the giver/turn-in point (marker snaps)" % o)
            ends = [s for k, e in self.enders.get(qid, []) for s in self.spawns.get((k, e), [])]
            # distance of every turn-in point to the nearest ender spawn on the same map
            d_end = [min((round(dist(pt, s[5:7])) for s in ends if s[0] == m), default=None) for o, m, p, b in blobs if o == -1 for pt in p]
            if ends and not d_end:
                notes.append("no turn-in blob (ObjectiveIndex -1)")
            elif ends and None in d_end:
                notes.append("turn-in blob on another map than the ender spawns")
            elif ends and min(d_end) > TURNIN_YD:
                notes.append("turn-in marker %d yd from the nearest ender spawn" % min(d_end))
            elif ends and max(d_end) > TURNIN_YD:
                notes.append("turn-in blob reaches %d yd from the ender (an objective area merged into it)" % max(d_end))
            if notes:
                builds = sorted({b for _, _, _, b in blobs})
                self.add(group, "MINOR", qid, "5 POI", "; ".join(list(dict.fromkeys(notes)) + [info] * bool(info)) + " (VerifiedBuild %s%s)" % (
                    "/".join(map(str, builds)), "; client has %d blobs" % len(client) if client else "; no client blobs"))

    def check_text(self):
        w, live, fields = self.w, inlist(self.live), QUEST_TEXT.split()
        rows = [("quest_template." + f, r[0], r[i + 1]) for r in q(
            "SELECT t.ID, %s FROM quest_template t LEFT JOIN quest_template_locale l ON l.ID = t.ID AND l.locale = 'enUS' "
            "WHERE t.ID IN (%s)" % (", ".join("IFNULL(NULLIF(l.%s, ''), t.%s)" % (f, f) for f in fields), live))
            for i, f in enumerate(fields)]
        rows += [("quest_objectives", r[0], r[1]) for r in q(
            "SELECT o.QuestID, IFNULL(NULLIF(l.Description, ''), o.Description) FROM quest_objectives o LEFT JOIN "
            "quest_objectives_locale l ON l.ID = o.ID AND l.locale = 'enUS' WHERE o.QuestID IN (%s)" % live)]
        rows += [("quest_offer_reward", r[0], r[1]) for r in q(
            "SELECT o.ID, IFNULL(NULLIF(l.OfferRewardText, ''), o.RewardText) FROM quest_offer_reward o LEFT JOIN "
            "quest_offer_reward_locale l ON l.ID = o.ID AND l.Locale = 'enUS' WHERE o.ID IN (%s)" % live)]
        rows += [("quest_request_items", r[0], r[1]) for r in q(
            "SELECT o.ID, IFNULL(NULLIF(l.CompletionText, ''), o.CompletionText) FROM quest_request_items o LEFT JOIN "
            "quest_request_items_locale l ON l.ID = o.ID AND l.Locale = 'enUS' WHERE o.ID IN (%s)" % live)]
        seen = set()
        for table, qid, text in rows:
            m = CYR.search(text)
            if m and (table, qid) not in seen:
                seen.add((table, qid))
                self.add(self.scope[n(qid)], "MINOR", n(qid), "6 Russian text", "%s: \"%s\"" % (table, snippet(text, m.start())))
        npcs = collections.defaultdict(set)
        for e, qid in w.cstart + w.cend:
            if qid in self.live:
                npcs[e].add(qid)
        for qid, ol in self.objs.items():
            for o in ol:
                if o["type"] in (0, 3):
                    npcs[o["obj"]].add(qid)
        for e, qs in npcs.items():
            text = "%s | %s" % (w.cname.get(e, ""), w.ctitle.get(e, ""))
            m = CYR.search(text)
            if m:
                qid = min(qs)
                self.add(self.scope[qid], "MINOR", qid, "6 Russian text", "creature_template_wdb %d name/title: \"%s\"%s" % (
                    e, snippet(text, m.start()), " (also quests %s)" % ", ".join(map(str, sorted(qs - {qid}))) if len(qs) > 1 else ""))

    def check_spell_area(self):
        c, w, zg = self.c, self.w, self.zone_group
        for r in w.spell_area:
            group = zg.get(r["area"]) or zg.get(c.zone_of_area(r["area"])) or self.scope.get(r["qs"]) or self.scope.get(r["qe"])
            if not group:
                continue
            qid = r["qs"] or r["qe"]
            tag = "spell_area spell %d %s area %d quest_start %d/%d quest_end %d/%d autocast %d" % (
                r["spell"], c.spell.get(r["spell"], "(missing)"), r["area"], r["qs"], r["qss"], r["qe"], r["qes"], r["autocast"])
            why = None
            if r["spell"] not in c.spell:
                why = "spell does not exist: the loader skips the row"
            elif r["qs"] and r["qs"] not in w.quest or r["qe"] and r["qe"] not in w.quest:
                why = "quest_start/quest_end does not exist: the loader skips the row"
            elif r["qs"] and not r["qss"] or r["qe"] and not r["qes"]:
                why = "status mask 0: never applies"
            elif r["qs"] and r["qs"] == r["qe"] and not r["qss"] & r["qes"]:
                why = "quest_start = quest_end with disjoint status masks: never applies"
            elif r["autocast"] and r["qe"] and not r["qes"] & 1 and r["qes"] & 64:
                why = ("quest_end_status %d has REWARDED but not NONE: this core applies the spell only WHILE quest_end is in the "
                       "mask, so it appears after quest_end is done instead of ending there (the #69/#92/#122 inverted mask)" % r["qes"])
            if why:
                self.add(group, "MAJOR", qid, "7 spell_area", tag + ": " + why)

    def run(self):
        self.select()
        self.load()
        for step in (self.check_givers, self.check_chain, self.check_class, self.check_objectives,
                     self.check_poi, self.check_text, self.check_spell_area):
            step()
        return self


def dist(a, b):
    return math.hypot(a[0] - b[0], a[1] - b[1])


def snippet(text, i):
    return text[max(0, i - 20):i + 60].replace("|", "/").replace("\\n", " ").strip()


# ---------------------------------------------------------------- report
RULES = """\
Severity: **BLOCKER** = cannot be taken, done or turned in; **MAJOR** = wrong but doable, or a break that a script we
cannot see may cover; **MINOR** = cosmetic (map markers, Russian text) or a quest nobody can get and nothing needs.
"The id appears in C++" lowers a finding one step: any 3-7 digit number in `src/server` counts, so it can hide a real
bug but never invents one.

**Scope.** A quest belongs to the zone group where most spawns of its quest giver are (else its `QuestSortID`), with
`MinLevel` <= 10 and `QuestLevel` <= 10 (-1 = scaling); Demon Hunter and Death Knight start zones take every quest. Not
audited: tracking quests (`Flags & 0x400`), task quests (`QuestType 3`), holiday/event quests (seasonal relation, holiday
`QuestSortID`, event-only givers). A quest nobody can get (disabled, no giver, giver not spawned) gets one finding and
no further checks; all other checks run on the obtainable ("live") quests.

1. **Giver/ender.** *giver: none / not spawned*: no starter row and no other start (item `StartQuestID`,
   `area_queststart`, spell effect 150, SmartAI 7, `playercreateinfo_quest`, `RewardNextQuest` of an auto-complete
   quest), or the starters are neither spawned, summoned by data nor named in C++: MAJOR if a live audited quest lists
   it as a previous quest or it is in a 7.3.5 `QuestLineXQuest`, else MINOR. *ender: none*: no ender and not
   auto-complete (`QuestType 0` / `Flags & 0x10000`). *not spawned*: no `creature`/`gameobject` row and not summoned by
   data (spell effects 28/56/76/104/105, SmartAI 12/50/220, script command 10, `creature_summon_groups`,
   `vehicle_template_accessory`).
   *phase*: no spawn is visible in the needed state (giver: quest NONE, ender: quest COMPLETE). A spawn needs one of its
   `phaseMask` bits (bit 0 is the default) and, if it has `PhaseId`s, one of them, from `phase_definitions` of its zone
   (conditions SourceType 23), `spell_area` of its zone/area, or a phase spell (aura 261 or `spell_phase`) cast in its
   zone group by quest data (`SourceSpellID`/`RewardSpell`/`RewardDisplaySpell`), SmartAI of its spawns or `spell_area`,
   plus two levels of `EffectTriggerSpell`/`spell_linked_spell`. Conditions count only where they test this quest
   (QUESTREWARDED, QUESTTAKEN = INCOMPLETE only in this core, QUEST_NONE, QUEST_COMPLETE, the spell_area masks); every
   other condition counts as met. MAJOR instead of BLOCKER when C++ names a spell that gives the missing phase.
2. **disables** sourceType 1: every row, with its comment (graded like *giver: none*).
3. **Objectives** (not OPTIONAL / HIDE_ITEM_GAINS / PART_OF_PROGRESS_BAR, which `CanCompleteQuest` skips). MONSTER/TALKTO:
   template exists; spawned, summoned by data, KillCredit1/2 of such a creature, SmartAI 33 or spell effect 90/134.
   ITEM: item exists (ItemSparse.db2 / hotfixes); a vendor, quest `StartItem`, create-item spell (24/157/206), SmartAI 56,
   a non-creature loot table, loot of a live creature (`lootid`/`pickpocketloot`/`skinloot`), or loot of a spawned
   chest/node (type 3/25/50, loot id = `Data1`) a quester can click: with `GO_FLAG_INTERACT_COND` the item must be in
   `questItem1-6` or (chests) be `QuestRequired` loot under the object entry (`GameObject::ActivateToQuest`, #118); the
   evidence names the `creature_template_wdb` QuestItem owners (the retail drop). GAMEOBJECT: template exists, spawned
   or summoned by data. LEARNSPELL: the spell is in `SpecializationSpells`/class `SkillLineAbility`/`Talent`/trainer for
   a class that can take the quest (AllowableClasses narrowed by the previous quests); MAJOR if some of those classes
   cannot learn it or `SpellLevels.BaseLevel` > 10. AREATRIGGER/CRITERIA_TREE ids exist in the DB2. `Amount` <= 0 and
   two objectives on one `StorageIndex`: MAJOR. Event credit: `SpecialFlags & 2` or an AREATRIGGER objective needs
   `areatrigger_questender`, a valid AREATRIGGER objective, spell effect 16, SmartAI 15/26/223 or script command 7. A quest
   without objectives completes on accept, so it is fine unless it needs such an event credit (the 26945 question).
4. **Chain.** `PrevQuestID`/`NextQuestID`/`RewardNextQuest` exist. The previous quests (the loader's `prevQuests`:
   `PrevQuestID` + every quest whose `NextQuestID` is this one; any one suffices) must include one that is obtainable,
   not in the same positive `ExclusiveGroup`, not this quest's `RewardNextQuest`, allowed together with the quest for
   some race/class (`CharBaseInfo`), and itself reachable through its own previous quests (recursively; "blocked
   upstream" when only that fails). MAJOR "never offered" instead of BLOCKER when the chain was cut by `disables` only and
   the quest is in no 7.3.5 QuestLine. Then, for the start races of the giver's zone (no Death Knight/Demon Hunter outside
   their zones) that the quest's masks allow and no same-title live variant serves: when some of them can do a previous
   quest, the others are reported if they share a class with them (a race left out) or if the previous quests span
   several classes (a merge of class chains missing a class); a single class chain gating a generic quest is how class
   quests work and is not reported. `ExclusiveGroup` is a group key in this core, not a quest id, so its value is not
   checked. Class quests (`QuestSortID` of a class) must not be open to other classes.
5. **Quest POI** (MINOR): the visible symptoms of the 23877/26124 merge fixed in `fix_teldrassil_quest_pois.sql` and
   `fix_azuremyst_quests_124.sql`: an objective showing another objective's area, an objective with a second single-point
   blob on the giver/turn-in point (the marker snaps), no turn-in blob, the turn-in marker more than 15 yd from every
   ender spawn (the owner's ~10 yd plus sniff rounding), a turn-in blob reaching beyond 15 yd (an objective area merged
   into it); no rows while the 7.3.5 client has blobs. An identical doubled blob draws nothing and is only mentioned.
6. **Russian text** (Cyrillic) in what an English client gets: the `*_locale` enUS row when it is not empty, else the base
   row (`quest_template` texts, `quest_objectives`, `quest_offer_reward`, `quest_request_items`), and the
   `creature_template_wdb` name/title of givers, enders and kill/talk targets.
7. **Other.** A giver/ender creature without `UNIT_NPC_FLAG_QUESTGIVER` on every visible spawn (spawn `npcflag` overrides
   the template when non-zero), no SmartAI 81/82 adding it and no ScriptName. `MaxLevel` < `MinLevel`. Accept conditions
   (SourceType 19) that need an impossible state of the quest itself. `spell_area` rows of the zones or of audited
   quests (MAJOR) that the loader skips, can never apply, or have the inverted `quest_end_status` (REWARDED without
   NONE: #69/#92/#122).
"""


def report(a, seconds):
    out = ["# Quest audit, levels 1-10 (static)", "",
           "Generated by `tools/quest_audit.py` on the live server (read-only) in %d s: %d quests in scope, %d of them obtainable, "
           "%d findings. Rules at the end." % (seconds, len(a.scope), len(a.live), len(a.findings)), ""]
    order = {s: i for i, s in enumerate(SEV)}
    count = collections.defaultdict(collections.Counter)
    for g, sev, *_ in a.findings:
        count[g][sev] += 1
    out += ["| Zone group | Quests | Obtainable | BLOCKER | MAJOR | MINOR |", "|---|---|---|---|---|---|"]
    per_group, live = collections.Counter(a.scope.values()), collections.Counter(a.scope[x] for x in a.live)
    for g, _ in ZONES:
        out.append("| %s | %d | %d | %d | %d | %d |" % (g, per_group[g], live[g], count[g]["BLOCKER"], count[g]["MAJOR"],
                                                       count[g]["MINOR"]))
    out += ["", "Not audited: " + ", ".join("%d %s" % (v, k) for k, v in a.excluded.items()) + ".", ""]
    for g, _ in ZONES:
        rows = sorted((f for f in a.findings if f[0] == g), key=lambda f: (order[f[1]], f[3], f[2]))
        out += ["## %s" % g, ""]
        if not rows:
            out += ["No findings.", ""]
            continue
        out += ["| Sev | Quest | Check | Evidence |", "|---|---|---|---|"]
        for _, sev, qid, check, ev in rows:
            out.append("| %s | %s | %s | %s |" % (sev, a.qname(qid).replace("|", "/"), check, ev.replace("|", "/")))
        out.append("")
    return "\n".join(out + ["## Rules", "", RULES])


def selftest(c):
    assert not learnable(c, 56641, 3), "Steady Shot is not a 7.3.5 hunter spell (#104)"
    assert not learnable(c, 73899, 7), "Primal Strike is not a 7.3.5 shaman spell (#118)"
    assert learnable(c, 193455, 3) and learnable(c, 188389, 7) and learnable(c, 100, 1)
    assert not learnable(c, 188389, 3)
    assert cond_ok([(0, 9, 5, 0)], 5, COMPLETE) is False and cond_ok([(0, 9, 5, 0), (1, 14, 5, 0)], 5, NONE) is True
    assert cond_ok([(0, 8, 7, 1)], 5, NONE) and not cond_ok([(0, 8, 5, 0)], 5, COMPLETE)
    assert CYR.search("Привет") and not CYR.search("Hello")
    print("selftest ok")


def main():
    t0 = time.time()
    c = Client()
    if "--selftest" in sys.argv:
        return selftest(c)
    a = Audit(c, World(c)).run()
    print(report(a, time.time() - t0))
    print("%d quests, %d findings, %.0f s" % (len(a.scope), len(a.findings), time.time() - t0), file=sys.stderr)


if __name__ == "__main__":
    main()
