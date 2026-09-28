#!/usr/bin/env python3
"""Fill a Legion character in one go, the way Chronp was done by hand (owner request 2026-09-27, Claude):

  gear       best-in-slot gear for the spec by mail (Antorus + T21 + two legendaries + trinkets) at a fixed item level
  quests     level 110, class campaign + artifact questlines + Legionfall / Argus / Netherlight Crucible marked done,
             class hall (if missing) and the class hall talent for the second legendary (Garrison::hasLegendLimitUp)
  artifacts  every artifact of the class: rank 101 with every trait filled and the second tier, three Antorus relics
             socketed and the Netherlight Crucible picked on each relic (tier 1 + one Light/Shadow trait + one artifact trait)

Run on the server as wow with the character OFFLINE (online data is overwritten when the character saves):
  python3 ~/LegionCore/tools/fill_character/fill_character.py plan <name> [--spec shadow]   # show everything, change nothing
  python3 ~/LegionCore/tools/fill_character/fill_character.py all  <name> [--spec shadow]   # gear + quests + artifacts
  python3 ~/LegionCore/tools/fill_character/fill_character.py gear|quests|artifacts <name> ...
  python3 ~/LegionCore/tools/fill_character/fill_character.py undo ~/fill_character/<name>_<time>
  python3 ~/LegionCore/tools/fill_character/fill_character.py check                        # validate presets.json for all specs
Options: --spec NAME|ID|all (repeatable, default: the character's current spec) --ilvl 985 --all-legendaries
         --crucible "Light Speed" --crucible-trait "Fiending Dark" (override every artifact) --no-mail-artifacts
         --rollback (test: runs the SQL inside one transaction, prints the result and rolls it back; sends no mail)
Mails go out with the world console command `send items`. Artifacts that arrive by mail are moved straight into free bag
slots so their traits/relics can be written in the same run; gear stays in the mailbox. Every run writes
~/fill_character/<name>_<time>/ with log.txt and undo.sql (undo only while the character is offline). Gear/spec choices
live in presets.json next to this file.
"""
import argparse, json, os, pickle, random, re, struct, subprocess, sys, time

HOME = os.path.expanduser("~")
sys.path.insert(0, os.path.join(HOME, "client_parts"))
import wdc1  # noqa: E402  (~/client_parts, DB2 reader)

DBC = os.path.join(HOME, "data/dbc/enUS/")
HERE = os.path.dirname(os.path.abspath(__file__))
RUNS = os.path.join(HOME, "fill_character")

CLASSES = {1: "Warrior", 2: "Paladin", 3: "Hunter", 4: "Rogue", 5: "Priest", 6: "Death Knight", 7: "Shaman", 8: "Mage",
           9: "Warlock", 10: "Monk", 11: "Druid", 12: "Demon Hunter"}
ARMOR = {1: 4, 2: 4, 6: 4, 3: 3, 7: 3, 4: 2, 10: 2, 11: 2, 12: 2, 5: 1, 8: 1, 9: 1}  # class -> Item.db2 armor subclass
PRIMARY = {0: 5, 1: 5, 2: 3, 3: 3, 4: 4, 5: 4}  # ChrSpecialization.PrimaryStatPriority -> stat type (5 int, 3 agi, 4 str)
HYBRID = {3: (71, 72, 73), 4: (71, 72, 74), 5: (71, 73, 74)}
STATS = {"crit": 32, "haste": 36, "mastery": 49, "vers": 40}
SLOTS = [("head", (1,)), ("neck", (2,)), ("shoulders", (3,)), ("back", (16,)), ("chest", (5, 20)), ("wrist", (9,)),
         ("hands", (10,)), ("waist", (6,)), ("legs", (7,)), ("feet", (8,)), ("finger1", (11,)), ("finger2", (11,)),
         ("trinket1", (12,)), ("trinket2", (12,))]
TIER_SLOTS = ("head", "shoulders", "back", "chest", "hands", "legs")
ANTORUS = 946  # JournalInstance
LEGENDARY_LIMIT = 357  # ItemLimitCategory of Legion legendaries
# Garrison::hasLegendLimitUp: class hall talent that allows a second legendary
CLASS_HALL_TALENT = {1: 412, 2: 401, 3: 379, 4: 445, 5: 456, 6: 434, 7: 42, 8: 390, 9: 368, 10: 258, 11: 357, 12: 423}
# Player::GetQuestForUnLockThirdSocket
THIRD_RELIC_QUEST = {1: 43425, 2: 43424, 3: 43423, 4: 43422, 5: 43420, 6: 43407, 7: 43418, 8: 43415, 9: 43414,
                     10: 43359, 11: 43409, 12: 43412}
# QuestLine.db2: class campaign + artifact questlines (checked with quest_template.QuestSortID)
CLASS_QUESTLINES = {1: [238, 213, 214, 215, 216, 217], 2: [236, 86, 87, 221, 222], 3: [228, 174, 165, 173, 269, 270, 271, 220],
                    4: [212, 162, 163, 183], 5: [230, 218, 219, 239, 243], 6: [232, 170, 273, 168, 169, 209, 274],
                    7: [231, 264, 265, 266, 267, 268], 8: [237, 248, 166, 223, 244], 9: [229, 207, 208, 224, 245],
                    10: [234, 172, 196, 194, 195, 246], 11: [235, 171, 164, 167, 193, 210], 12: [197, 161, 159, 160]}
# Legionfall, Argus and the Netherlight Crucible
COMMON_QUESTLINES = [309, 344, 345, 346, 348, 350, 353, 367, 368, 371, 372]
ALLIANCE_RACES = {1, 3, 4, 7, 11, 22, 25, 29, 30, 34, 37}
CLASS_HALL_SITE = {True: 560, False: 584}  # character_garrison.SiteLevelId, Alliance / Horde
PF_GOLD, PF_FINAL, PF_HAS_RANK, PF_RELIC = 0x01, 0x04, 0x20, 0x40  # ArtifactPower flags (Item.h)
BACKPACK = range(23, 39)
MAIL_ITEMS_MAX = 12


def die(msg):
    sys.exit("ERROR: " + msg)


class Log:
    def __init__(self):
        self.path, self.lines = None, []

    def __call__(self, *a):
        line = " ".join(str(x) for x in a)
        print(line)
        self.lines.append(line)
        if self.path:
            with open(self.path, "a") as f:
                f.write(line + "\n")


log = Log()


# ---------------------------------------------------------------- database

def rows(query, db="characters"):
    p = subprocess.run(["mysql", "-N", "-B", db, "-e", query], capture_output=True, text=True)
    if p.returncode:
        die("MySQL: %s\n%s" % (p.stderr.strip(), query[:300]))
    return [line.split("\t") for line in p.stdout.splitlines()]


def execute(script, db="characters"):
    p = subprocess.run(["mysql", db], input=script, capture_output=True, text=True)
    if p.returncode:
        die("MySQL: %s" % p.stderr.strip())


def dump(table, where, db="characters"):
    p = subprocess.run(["mysqldump", "--no-create-info", "--skip-add-locks", "--compact", "--skip-extended-insert",
                        "--no-tablespaces", "--skip-triggers", db, table, "--where=" + where], capture_output=True, text=True)
    if p.returncode:
        die("mysqldump %s: %s" % (table, p.stderr.strip()))
    return "DELETE FROM %s.%s WHERE %s;\n%s" % (db, table, where, p.stdout.replace("INSERT INTO `", "INSERT INTO `%s`.`" % db))


def ids(values):
    return ",".join(str(int(v)) for v in values) or "0"


# ---------------------------------------------------------------- game data (client DB2s)

def gt_rows(name):
    """~/data/gt/<name> as {first column: {header: value}}."""
    with open(os.path.join(HOME, "data/gt", name)) as f:
        head = f.readline().rstrip("\n").split("\t")
        return {int(float(v[0])): dict(zip(head, map(float, v))) for v in (l.rstrip("\n").split("\t") for l in f) if v[0]}


def strings(path):
    d = open(path, "rb").read()
    h = struct.unpack_from(wdc1.HEADER, d, 0)
    so = struct.calcsize(wdc1.HEADER) + 4 * h[2] + h[1] * h[3]
    return lambda o: d[so + o:d.index(b"\0", so + o)].decode("utf8", "replace")


def cached_pickle(path, tool):
    if not os.path.exists(path):
        subprocess.run([sys.executable, os.path.join(HOME, "client_parts", tool)], check=True, capture_output=True,
                       env=dict(os.environ, PYTHONPATH=os.path.join(HOME, "client_parts")))
    return pickle.load(open(path, "rb"))


class Data:
    def __init__(self):
        self.sparse = cached_pickle("/tmp/itemsparse.pkl", "itemsparse.py")  # {item: fields}, see itemsparse.py
        self.spellnames = cached_pickle("/tmp/spellnames.pkl", "spellnames.py")
        self.ql_names, self.ql_quests = cached_pickle("/tmp/questlines.pkl", "questlines.py")
        self.item = wdc1.read(DBC + "Item.db2")  # [icon, class, subclass, ...]
        s = strings(DBC + "ChrSpecialization.db2")
        # spec -> (class, role 0 tank / 1 healer / 2 dps, primary stat type, name)
        self.specs = {k: (v[4], v[7], PRIMARY.get(v[8], 5), s(v[0])) for k, v in wdc1.read(DBC + "ChrSpecialization.db2").items()
                      if 1 <= v[4] <= 12}
        self.children = {v[-1]: v[0] for v in wdc1.read(DBC + "ItemChildEquipment.db2").values()}
        self.level_delta = {v[0]: k for k, v in wdc1.read(DBC + "ItemBonusListLevelDelta.db2").items()}
        self.gemprops = wdc1.read(DBC + "GemProperties.db2")  # [type mask, enchant, min ilvl]
        self.enchants = wdc1.read(DBC + "SpellItemEnchantment.db2")  # [name, EffectArg[3], ...]
        self.relic_talents = wdc1.read(DBC + "RelicTalent.db2")  # [power, label, type 1 shadow / 2 light / 3 trait, ...]
        rank_spell = {}
        for r in wdc1.read(DBC + "ArtifactPowerRank.db2").values():  # [spell, aura override, bonus list, rank index, power]
            if r[3] == 0:
                rank_spell[r[4]] = r[0]
        self.powers = {}  # artifact -> [(power, flags, max rank, tier, label, name)]
        self.relic_powers = []
        for r in wdc1.read(DBC + "ArtifactPower.db2").values():  # [pos, artifact, flags, max, tier, id, label]
            p = (r[5], r[2], r[3], r[4], r[6], self.spellnames.get(rank_spell.get(r[5]), "?"))
            if r[1]:
                self.powers.setdefault(r[1], []).append(p)
            elif r[2] & PF_RELIC:
                self.relic_powers.append(p)
        # artifact per spec: lowest class artifact ID with a real item; its item = lowest non-test, non-child item
        child_items = set(self.children.values())
        art_items = {}
        for iid, v in self.sparse.items():
            if v[62] and v[45] == 6 and not v[1].startswith("Test") and iid not in child_items:
                art_items.setdefault(v[62], []).append(iid)
        self.artifact_of_item = {iid: a for a, l in art_items.items() for iid in l}
        self.artifact_spec, self.spec_artifact = {}, {}
        for k, v in sorted(wdc1.read(DBC + "Artifact.db2").items()):  # [.., texture kit, spec, category, ...]
            if v[6] == 1 and v[5] in self.specs and k in art_items:
                self.artifact_spec[k] = v[5]
                self.spec_artifact.setdefault(v[5], (k, min(art_items[k])))
        # relic sockets per artifact: item sockets + the third socket from ArtifactUnlock's bonus list (ItemBonus type 6)
        bonus = {}
        for b in wdc1.read(DBC + "ItemBonus.db2").values():  # [values[3], bonus list, type, order]
            bonus.setdefault(b[1], []).append(b)
        self.unlock_sockets = {}
        for u in wdc1.read(DBC + "ArtifactUnlock.db2").values():  # [bonus list, power rank, power, condition, artifact]
            for b in bonus.get(u[0], []):
                if b[2] == 6:
                    self.unlock_sockets.setdefault(u[4], []).extend([b[0][1]] * b[0][0])
        # default appearance per artifact (only used when the artifact has no row yet)
        sets = {v[7]: (v[8], v[4]) for v in wdc1.read(DBC + "ArtifactAppearanceSet.db2").values()}
        self.default_appearance = {}
        for v in sorted(wdc1.read(DBC + "ArtifactAppearance.db2").values(), key=lambda v: (sets.get(v[5], (0, 99))[1], v[7])):
            art = sets.get(v[5], (0,))[0]
            self.default_appearance.setdefault(art, v[11])
        # Antorus loot
        je = wdc1.read(DBC + "JournalEncounter.db2")
        encounters = {k for k, v in je.items() if v[6] == ANTORUS}
        self.antorus = sorted({v[0] for v in wdc1.read(DBC + "JournalEncounterItem.db2").values() if v[1] in encounters})
        # tertiary stats: RandPropPoints (epic) per item level, rating multiplier per item level, rating per 1% at 110
        self.randprop = {k: v[2] for k, v in wdc1.read(DBC + "RandPropPoints.db2").items()}
        self.rating_mult = gt_rows("CombatRatingsMultByILvl.txt")
        self.rating_pct = gt_rows("CombatRatings.txt").get(110, {})

    # item helpers
    def name(self, iid):
        return self.sparse[iid][1] if iid in self.sparse else "item %d" % iid

    def usable(self, iid, cls):
        v = self.sparse.get(iid)
        return v is not None and (v[22] == -1 or v[22] & (1 << (cls - 1)) != 0)

    def is_legendary(self, iid):
        v = self.sparse.get(iid)
        return v is not None and v[45] == 5 and v[41] == LEGENDARY_LIMIT

    def is_relic(self, iid):
        i = self.item.get(iid)
        return i is not None and i[1] == 3 and i[2] == 11

    def relic_label(self, iid):
        g = self.gemprops.get(self.sparse[iid][40])
        e = self.enchants.get(g[1]) if g else None
        return max(e[1]) if e else 0

    def relic_fits(self, iid, socket_type):
        g = self.gemprops.get(self.sparse[iid][40])
        return bool(g) and socket_type >= 2 and bool(g[0] & (1 << (socket_type - 2)))

    def bonus_for(self, iid, ilvl, defaults):
        """Bonus list and item level so the item ends up at ilvl (legendaries: the 1000 upgrade)."""
        if self.is_legendary(iid):
            return defaults["legendary_bonus"], defaults["legendary_ilvl"]
        delta = ilvl - self.sparse[iid][23]
        if delta == 0:
            return "", ilvl
        if delta not in self.level_delta:
            die("no ItemBonusListLevelDelta for %+d (%s)" % (delta, self.name(iid)))
        return str(self.level_delta[delta]), ilvl

    def sockets(self, art, item):
        return [t for t in self.sparse[item][59] if t] + self.unlock_sockets.get(art, [])

    def label_of(self, art, trait_name):
        for p in self.powers[art]:
            if p[5].lower() == trait_name.lower() and p[4]:
                return p[4]
        die("artifact %d has no relic-rankable trait called %r" % (art, trait_name))

    def trait_by_label(self, art, label):
        for p in self.powers[art]:
            if p[4] == label:
                return p
        return None

    def crucible_talent(self, name):
        """Tier 2 Netherlight Crucible trait by name -> (RelicTalent ID, 1 shadow / 2 light)."""
        rank_names = {p[0]: p[5] for p in self.relic_powers}
        for k, v in self.relic_talents.items():
            if v[2] in (1, 2) and rank_names.get(v[0], "").lower() == name.lower():
                return k, v[2]
        die("unknown Netherlight Crucible trait %r" % name)

    def relic_talent_for_label(self, label):
        for k, v in self.relic_talents.items():
            if v[2] == 3 and v[1] == label:
                return k
        die("no RelicTalent for artifact trait label %d" % label)


# ---------------------------------------------------------------- presets and planning

def load_presets():
    return json.load(open(os.path.join(HERE, "presets.json")))


def spec_role(d, spec):
    cls, role, primary, _ = d.specs[spec]
    if role == 0:
        return "tank"
    if role == 1:
        return "healer"
    return {5: "int_dps", 3: "agi_dps", 4: "str_dps"}[primary]


def resolve_specs(d, cls, current, wanted):
    own = [s for s, v in d.specs.items() if v[0] == cls]
    if not wanted:
        return [current] if current in own else own[:1]
    out = []
    for w in wanted:
        if w == "all":
            out += sorted(own)
            continue
        m = [s for s in own if str(s) == w or d.specs[s][3].lower() == w.lower()]
        if not m:
            die("%s has no spec %r (specs: %s)" % (CLASSES[cls], w, ", ".join(d.specs[s][3] for s in own)))
        out += m
    return list(dict.fromkeys(out))


def pick_gear(d, cls, spec, presets, ilvl, all_legendaries=False):
    """Returns [(slot, item, bonus, ilvl)] for one spec."""
    defaults, preset = presets["defaults"], presets["specs"][str(spec)]
    _, role, primary, _ = d.specs[spec]
    order = [STATS[s.strip()] for s in preset["stats"].split(">")]
    weights = {st: 1.0 + 0.1 * (len(order) - i) for i, st in enumerate(order)}
    chosen = {}

    def free_slot(iid):
        inv = d.sparse[iid][46]
        for slot, invs in SLOTS:
            if inv in invs and slot not in chosen:
                return slot
        return None

    def place(iid, slot=None, why=""):
        if not d.usable(iid, cls):
            die("%s (%d) cannot be used by a %s (%s)" % (d.name(iid), iid, CLASSES[cls], why))
        slot = slot or free_slot(iid)
        if slot and slot not in chosen:
            chosen[slot] = iid

    def fits(iid):
        v, it = d.sparse.get(iid), d.item.get(iid)
        if not v or not it or it[1] != 4 or not d.usable(iid, cls):
            return False
        if v[46] not in (2, 11, 12, 16) and it[2] != ARMOR[cls]:
            return False
        types = [t for t in v[52] if t != -1]
        prim = [t for t in types if t in (3, 4, 5, 71, 72, 73, 74)]
        return not prim or primary in prim or any(t in HYBRID[primary] for t in prim)

    def score(iid):
        v = d.sparse[iid]
        return sum(weights.get(t, 0) * a for t, a in zip(v[52], v[15]))

    for iid in preset.get("legendaries", []):
        place(iid, why="legendary")
    for slot, iid in preset.get("items", {}).items():
        place(iid, slot, why="preset item")
    for iid in preset.get("trinkets") or defaults["trinkets"][spec_role(d, spec)]:
        place(iid, why="trinket")
    tier = [iid for iid, v in d.sparse.items() if v[35] and v[23] == 930 and v[45] == 4 and v[22] == 1 << (cls - 1)]
    for iid in sorted(tier):
        slot = free_slot(iid)
        if slot in TIER_SLOTS:
            chosen[slot] = iid
    for slot, invs in SLOTS:
        if slot in chosen:
            continue
        cands = [i for i in d.antorus if d.sparse.get(i) and d.sparse[i][46] in invs and fits(i) and i not in chosen.values()]
        if cands:
            chosen[slot] = max(cands, key=lambda i: (score(i), -i))
    gear = []
    for slot, _ in SLOTS:
        if slot in chosen:
            bonus, lvl = d.bonus_for(chosen[slot], ilvl, defaults)
            gear.append((slot, chosen[slot], bonus, lvl))
    gear = add_perks(d, gear, defaults.get("perks", {}))
    if all_legendaries:
        have = {g[1] for g in gear}
        for iid in sorted(i for i in d.sparse if d.is_legendary(i) and d.usable(i, cls) and i not in have):
            bonus, lvl = d.bonus_for(iid, ilvl, defaults)
            gear.append(("extra", iid, bonus, lvl))
    return gear


# ItemBonus lists: tertiary stat (type 2, allocation 3000) and prismatic socket; stat column in CombatRatings.txt
TERTIARY = {"leech": (41, "Lifesteal"), "avoidance": (40, "Avoidance"), "speed": (42, "Speed")}
PRISMATIC_SOCKET = 1808
PROP_INDEX = {1: 0, 5: 0, 20: 0, 7: 0, 3: 1, 6: 1, 8: 1, 10: 1, 12: 1, 2: 2, 9: 2, 11: 2, 16: 2}  # InventoryType -> RandPropPoints column


def tertiary_rating(d, iid, lvl):
    """Rating one tertiary bonus gives on this item (Item::GetItemStatValue x Player::_ApplyItemBonuses multiplier)."""
    inv = d.sparse[iid][46]
    points = d.randprop.get(lvl, [0] * 5)[PROP_INDEX.get(inv, 0)]
    mult = d.rating_mult.get(lvl, {}).get("Jewelry Multiplier" if inv in (2, 11) else "Armor Multiplier", 1.0)
    # -1: the core multiplies with the float32 game table value, so count one rating low to never land just under
    return int(int(points * 3000 * 0.0001 + 0.5) * mult) - 1


def add_perks(d, gear, perks):
    """presets defaults.perks: {"leech": 20, "avoidance": 20, "speed": 20, "socket": true} (owner request 2026-09-28).
    Tertiary stats go on the fewest armor/jewelry pieces that reach the % (the core caps each at 20%, so more is wasted);
    every armor/jewelry piece gets a prismatic socket. Not on trinkets or legendaries (retail never has them there)."""
    if not perks:
        return gear
    eligible = [n for n, (slot, iid, _, _) in enumerate(gear) if slot not in ("trinket1", "trinket2", "extra")
                and not d.is_legendary(iid) and d.sparse[iid][46] in PROP_INDEX]
    extra = {n: [] for n in range(len(gear))}
    for stat, (bonus_id, column) in TERTIARY.items():
        want = perks.get(stat, 0) * d.rating_pct.get(column, 0)
        if not want:
            continue
        rating = {n: tertiary_rating(d, gear[n][1], gear[n][3]) for n in eligible}
        best = None
        for mask in range(1, 1 << len(eligible)):
            pick = [eligible[i] for i in range(len(eligible)) if mask >> i & 1]
            total = sum(rating[n] for n in pick)
            if total >= want and (best is None or (total, len(pick)) < best[0]):
                best = ((total, len(pick)), pick)
        pick = best[1] if best else eligible
        total = sum(rating[n] for n in pick)
        log("  %-9s %4d rating on %d pieces = %.1f%% (target %d%%, capped at 20%%)" % (
            stat, total, len(pick), total / d.rating_pct[column], perks[stat]))
        for n in pick:
            extra[n].append(str(bonus_id))
    if perks.get("socket"):
        for n in eligible:
            extra[n].append(str(PRISMATIC_SOCKET))
    return [(slot, iid, " ".join([b for b in [bonus] if b] + extra[n]), lvl) for n, (slot, iid, bonus, lvl) in enumerate(gear)]


def full_rank(p, tier_unlocked=True):
    """Purchased rank of a fully filled artifact (7.3.5: 35 base points, 4th ranks, 7.2 traits, Concordance)."""
    _, flags, max_rank, tier, _, _ = p
    if flags & PF_RELIC or max_rank == 0:
        return 0
    if flags & PF_FINAL:
        return 1 if tier == 0 else max_rank  # old paragon trait stays at 1 after the tier unlock (Player.cpp)
    if tier == 0 and flags & PF_HAS_RANK and tier_unlocked:
        return max_rank + 1  # Item::LoadArtifactData: +1 max rank with the second tier
    return max_rank


def plan_relics(d, art, item, preset, defaults, overrides, seed):
    """Relics per socket and the Netherlight Crucible data (item_instance_relics) for one artifact."""
    rng = random.Random(seed)
    stat = preset["stats"].split(">")[0].strip()
    tank = d.specs[d.artifact_spec[art]][1] == 0
    tier2_name = overrides.get("crucible") or preset.get("crucible") or (
        defaults["crucible_tank"] if tank else defaults["crucible_by_stat"][stat])
    tier2, side = d.crucible_talent(tier2_name)
    trait_name = overrides.get("crucible_trait") or preset.get("crucible_trait")
    t3_label = d.label_of(art, trait_name) if trait_name else defaults["crucible_trait_label"]
    rankable = {v[1] for v in d.relic_talents.values() if v[2] == 3}  # labels relics and crucible tier 3 can rank up
    labels = sorted({p[4] for p in d.powers[art] if p[4] in rankable})
    if t3_label not in labels:
        die("artifact %d has no trait with label %d" % (art, t3_label))
    prefer = [d.label_of(art, n) for n in preset.get("relic_traits", [])]
    sockets = d.sockets(art, item)[:3]
    relic_pool = [i for i in d.antorus if d.is_relic(i) and d.relic_label(i) in labels]
    fixed = preset.get("relics") if art == d.spec_artifact.get(d.artifact_spec[art], (0,))[0] else None
    relics, used = [], set()
    for n, st in enumerate(sockets):
        pick = None
        if fixed and n < len(fixed) and d.relic_fits(fixed[n], st):
            pick = fixed[n]
        if not pick:
            cands = [i for i in relic_pool if d.relic_fits(i, st)]
            if not cands:
                die("no Antorus relic fits socket type %d of artifact %d" % (st, art))
            cands.sort(key=lambda i: (d.relic_label(i) not in prefer, prefer.index(d.relic_label(i)) if d.relic_label(i) in prefer else 0,
                                      d.relic_label(i) in used, d.relic_label(i) == t3_label, d.relic_label(i), i))
            pick = cands[0]
        used.add(d.relic_label(pick))
        relics.append(pick)
    shadow = [k for k, v in d.relic_talents.items() if v[2] == 1]
    light = [k for k, v in d.relic_talents.items() if v[2] == 2]
    data = []
    for n, relic in enumerate(relics):
        dark_id = tier2 if side == 1 else rng.choice(shadow)
        light_id = tier2 if side == 2 else rng.choice(light)
        others = [d.relic_talent_for_label(l) for l in labels if l not in (t3_label, d.relic_label(relic))]
        rng.shuffle(others)
        # talent bits: 0 tier 1 (Netherlight Fortification), 1 shadow, 2 light, 5 the extra tier 3 slot = our trait
        bits = 1 | (2 if side == 1 else 4) | 32
        data.append("1 %d %d %d %d %d" % (n + 2, 65536 | bits, dark_id | (light_id << 16), others[0] | (others[1] << 16),
                                          d.relic_talent_for_label(t3_label)))
    return relics, data, tier2_name, d.trait_by_label(art, t3_label)[5]


# ---------------------------------------------------------------- character access

class Char:
    def __init__(self, name):
        if not re.match(r"^[^\W\d_]{2,12}$", name):
            die("bad character name %r" % name)
        r = rows("SELECT guid, name, account, race, class, level, online, specialization FROM characters WHERE name = '%s'" % name)
        if not r:
            die("no character called %s" % name)
        self.guid, self.name, self.account, self.race, self.cls, self.level, self.online, self.spec = \
            int(r[0][0]), r[0][1], int(r[0][2]), int(r[0][3]), int(r[0][4]), int(r[0][5]), int(r[0][6]), int(r[0][7])

    def require_offline(self):
        if int(rows("SELECT online FROM characters WHERE guid = %d" % self.guid)[0][0]):
            die("%s is online. Log the character out first (online data overwrites every change on save)." % self.name)

    def owned_items(self, entries):
        """{entry: [(item guid, bag, slot)]} in bags/bank/equipped."""
        out = {}
        for g, e, bag, slot in rows("SELECT ii.guid, ii.itemEntry, ci.bag, ci.slot FROM character_inventory ci JOIN item_instance ii "
                                    "ON ii.guid = ci.item WHERE ci.guid = %d AND ii.itemEntry IN (%s)" % (self.guid, ids(entries))):
            out.setdefault(int(e), []).append((int(g), int(bag), int(slot)))
        return out

    def mailed_items(self, entries):
        out = {}
        for g, e, m in rows("SELECT ii.guid, ii.itemEntry, mi.mail_id FROM mail_items mi JOIN item_instance ii ON ii.guid = mi.item_guid "
                            "WHERE mi.receiver = %d AND ii.itemEntry IN (%s)" % (self.guid, ids(entries))):
            out.setdefault(int(e), []).append((int(g), int(m)))
        return out

    def free_bag_slots(self):
        used = {(int(b), int(s)) for b, s in rows("SELECT bag, slot FROM character_inventory WHERE guid = %d" % self.guid)}
        free = [(0, s) for s in BACKPACK if (0, s) not in used]
        for g, e, s in rows("SELECT ii.guid, ii.itemEntry, ci.slot FROM character_inventory ci JOIN item_instance ii ON ii.guid = ci.item "
                            "WHERE ci.guid = %d AND ci.bag = 0 AND ci.slot BETWEEN 19 AND 22 ORDER BY ci.slot" % self.guid):
            size = D.sparse.get(int(e), [0] * 64)[51]
            free += [(int(g), n) for n in range(size) if (int(g), n) not in used]
        return free


# ---------------------------------------------------------------- steps

class Run:
    def __init__(self, ch, dry, rollback=False):
        self.ch, self.dry, self.undo, self.rollback, self.pending = ch, dry, [], rollback, []
        if not dry and not rollback:
            self.dir = os.path.join(RUNS, "%s_%s" % (ch.name, time.strftime("%Y%m%d_%H%M%S")))
            os.makedirs(self.dir, exist_ok=True)
            log.path = os.path.join(self.dir, "log.txt")

    # undo.sql runs newest step first: every backup/undo statement goes to the front
    def backup(self, table, where):
        if not self.dry and not self.rollback:
            self.undo.insert(0, dump(table, where))
            self.save_undo()

    def undo_sql(self, sql):
        if not self.dry and not self.rollback:
            self.undo.insert(0, sql)
            self.save_undo()

    def save_undo(self):
        with open(os.path.join(self.dir, "undo.sql"), "w") as f:
            f.write("-- Undo of fill_character.py for %s (guid %d). Run only while the character is offline:\n"
                    "-- mysql characters < %s/undo.sql\n" % (self.ch.name, self.ch.guid, self.dir))
            f.write("\n".join(self.undo) + "\n")

    def sql(self, script):
        if self.rollback:
            self.pending.append(script)
        elif not self.dry:
            execute(script)

    def test_and_rollback(self):
        """--rollback: runs every statement in one transaction, shows the result, then rolls back."""
        g = self.ch.guid
        check = ("SELECT 'level', level FROM characters WHERE guid = {g};\n"
                 "SELECT 'rewarded quests', COUNT(*) FROM character_queststatus_rewarded WHERE guid = {g};\n"
                 "SELECT 'class hall talents', GROUP_CONCAT(talentID) FROM character_garrison_talents WHERE guid = {g};\n"
                 "SELECT 'artifact', a.itemEntry, a.itemGuid, a.tier, a.totalrank, SUM(p.purchasedRank) FROM item_instance_artifact a "
                 "JOIN item_instance_artifact_powers p ON p.char_guid = a.char_guid AND p.itemEntry = a.itemEntry WHERE a.char_guid = {g} "
                 "GROUP BY a.itemEntry, a.itemGuid, a.tier, a.totalrank;\n"
                 "SELECT 'relics', r.itemGuid, r.first_relic, r.second_relic, r.third_relic, g.gemItemId1, g.gemItemId2, g.gemItemId3 "
                 "FROM item_instance_relics r LEFT JOIN item_instance_gems g ON g.itemGuid = r.itemGuid WHERE r.char_guid = {g};\n").format(g=g)
        p = subprocess.run(["mysql", "-N", "-B", "characters"], capture_output=True, text=True,
                           input="START TRANSACTION;\n%s\n%sROLLBACK;\n" % ("\n".join(self.pending), check))
        if p.returncode:
            die("MySQL (rolled back): " + p.stderr.strip())
        log("\n== Inside the test transaction (rolled back, nothing kept) ==\n" + p.stdout.rstrip())


def step_gear(run, d, presets, specs, args):
    ch = run.ch
    items = []
    for spec in specs:
        gear = pick_gear(d, ch.cls, spec, presets, args.ilvl, args.all_legendaries)
        log("\n== Gear for %s (%d items) ==" % (presets["specs"][str(spec)]["spec"], len(gear)))
        for slot, iid, bonus, lvl in gear:
            log("  %-9s %6d  %-45s ilvl %d  bonus %s" % (slot, iid, d.name(iid), lvl, bonus or "-"))
        items += [(iid, bonus, lvl) for _, iid, bonus, lvl in gear]
    # every artifact of the class (+ off-hand child) the character does not have yet
    arts = [d.spec_artifact[s][1] for s in sorted(d.specs) if d.specs[s][0] == ch.cls and s in d.spec_artifact]
    owned, mailed = ch.owned_items(arts), ch.mailed_items(arts)
    missing = [a for a in arts if a not in owned and a not in mailed] if not args.no_mail_artifacts else []
    log("\n== Artifacts ==")
    for a in arts:
        log("  %6d %-45s %s" % (a, d.name(a), "owned" if a in owned else "in the mailbox" if a in mailed else
                                "will be mailed" if a in missing else "skipped (--no-mail-artifacts)"))
    art_items = [(a, "", 0) for a in missing] + [(d.children[a], "", 0) for a in missing if a in d.children]
    if run.dry or not (items or art_items):
        return
    if run.rollback:
        log("  (--rollback test: no mail sent)")
        return
    send_mail(run, d, items, "Your gear", "Gear filled by the staff. Enjoy!")
    if art_items:
        new = send_mail(run, d, art_items, "Your artifacts", "Artifact weapons filled by the staff.")
        move_to_bags(run, d, new)


def send_mail(run, d, items, subject, body):
    """Sends items with the world console, waits for the mail rows, applies bonus lists. Returns [(item guid, entry, mail)]."""
    ch = run.ch
    before = int(rows("SELECT COALESCE(MAX(id), 0) FROM mail")[0][0])
    chunks = [items[i:i + MAIL_ITEMS_MAX] for i in range(0, len(items), MAIL_ITEMS_MAX)]
    for n, chunk in enumerate(chunks, 1):
        title = subject if len(chunks) == 1 else "%s %d/%d" % (subject, n, len(chunks))
        cmd = 'send items %s "%s" "%s" %s' % (ch.name, title, body, " ".join(str(i[0]) for i in chunk))
        subprocess.run(["tmux", "send-keys", "-t", "world", cmd, "Enter"], check=True)
        log("console:", cmd)
        time.sleep(1)
    got = []
    for _ in range(60):
        got = rows("SELECT mi.item_guid, ii.itemEntry, m.id FROM mail m JOIN mail_items mi ON mi.mail_id = m.id JOIN item_instance ii "
                   "ON ii.guid = mi.item_guid WHERE m.receiver = %d AND m.id > %d" % (ch.guid, before))
        if len(got) >= len(items):
            break
        time.sleep(1)
    if len(got) < len(items):
        die("only %d of %d mailed items arrived in the DB (worldserver console busy?)" % (len(got), len(items)))
    got = [(int(g), int(e), int(m)) for g, e, m in got]
    mails = sorted({m for _, _, m in got})
    item_guids = [g for g, _, _ in got]
    run.undo_sql("-- mails %s: remove what is still in the mailbox\nDELETE ii FROM item_instance ii JOIN mail_items mi ON mi.item_guid = ii.guid "
                 "WHERE mi.mail_id IN (%s);\nDELETE FROM mail_items WHERE mail_id IN (%s);\nDELETE FROM mail WHERE id IN (%s);"
                 % (ids(mails), ids(mails), ids(mails), ids(mails)))
    want = {}
    for iid, bonus, lvl in items:
        want.setdefault(iid, []).append((bonus, lvl))
    sql = []
    for g, e, _ in got:
        bonus, lvl = want[e].pop(0) if want.get(e) else ("", 0)
        if bonus or lvl:
            sql.append("UPDATE item_instance SET bonusListIDs = '%s', itemLevel = %d WHERE guid = %d;" % (bonus + " " if bonus else "", lvl, g))
    run.sql("\n".join(sql))
    log("mailed %d items in mails %s (item guids %d..%d)" % (len(got), ",".join(map(str, mails)), min(item_guids), max(item_guids)))
    return got


def move_to_bags(run, d, got):
    """Moves freshly mailed artifacts into free bag slots so their artifact data can be written now."""
    ch = run.ch
    free = ch.free_bag_slots()
    moved, sql = [], []
    for g, e, m in got:
        if not free:
            log("  no free bag slot for %s: it stays in the mailbox (run 'artifacts' again after taking it out)" % d.name(e))
            continue
        bag, slot = free.pop(0)
        sql += ["UPDATE item_instance SET owner_guid = %d WHERE guid = %d;" % (ch.guid, g),
                "DELETE FROM mail_items WHERE item_guid = %d;" % g,
                "INSERT INTO character_inventory (guid, bag, slot, item) VALUES (%d, %d, %d, %d);" % (ch.guid, bag, slot, g)]
        moved.append(g)
        log("  %s -> %s slot %d" % (d.name(e), "backpack" if bag == 0 else "bag %d" % bag, slot))
    if not moved:
        return
    mails = sorted({m for _, _, m in got})
    sql.append("DELETE m FROM mail m LEFT JOIN mail_items mi ON mi.mail_id = m.id WHERE m.id IN (%s) AND mi.item_guid IS NULL;" % ids(mails))
    run.undo_sql("-- artifacts moved from the mail into the bags\nDELETE FROM character_inventory WHERE item IN (%s);\n"
                 "DELETE FROM item_instance WHERE guid IN (%s);" % (ids(moved), ids(moved)))
    run.sql("\n".join(sql))


def step_quests(run, d, args):
    ch = run.ch
    quests = set()
    for line in CLASS_QUESTLINES[ch.cls] + COMMON_QUESTLINES:
        quests |= {q for _, q in d.ql_quests.get(line, [])}
    quests.add(THIRD_RELIC_QUEST[ch.cls])
    talent = CLASS_HALL_TALENT[ch.cls]
    site = CLASS_HALL_SITE[ch.race in ALLIANCE_RACES]
    has_hall = rows("SELECT COUNT(*) FROM character_garrison WHERE CharacterGuid = %d AND SiteLevelId IN (560, 584)" % ch.guid)[0][0] != "0"
    log("\n== Quests and class hall ==")
    log("  level %d -> %s" % (ch.level, "110" if ch.level < 110 else "unchanged"))
    log("  %d quests marked done (questlines %s + third relic slot quest %d)" % (
        len(quests), " ".join(map(str, CLASS_QUESTLINES[ch.cls] + COMMON_QUESTLINES)), THIRD_RELIC_QUEST[ch.cls]))
    log("  class hall: %s" % ("present" if has_hall else "created (site level %d)" % site))
    log("  class hall talent %d (second legendary)" % talent)
    if run.dry:
        return
    g = ch.guid
    run.undo_sql("UPDATE characters SET level = %d WHERE guid = %d;" % (ch.level, g))
    run.backup("character_queststatus_rewarded", "guid = %d" % g)
    run.backup("character_queststatus", "guid = %d" % g)
    run.backup("character_garrison", "CharacterGuid = %d" % g)
    run.backup("character_garrison_talents", "guid = %d" % g)
    q = ids(sorted(quests))
    sql = ["UPDATE characters SET level = 110, xp = 0 WHERE guid = %d AND level < 110;" % g,
           "DELETE FROM character_queststatus WHERE guid = %d AND quest IN (%s);" % (g, q),
           "INSERT IGNORE INTO character_queststatus_rewarded (guid, account, quest) VALUES %s;"
           % ",".join("(%d, %d, %d)" % (g, ch.account, x) for x in sorted(quests))]
    if not has_hall:
        sql.append("INSERT INTO character_garrison (CharacterGuid, SiteLevelId, GarrTypeId, FollowerActivationsRemainingToday, "
                   "NumFollowerActivationRegenTimestamp, CacheLastUsage, _MissionGen) VALUES (%d, %d, 0, 1, 0, 0, UNIX_TIMESTAMP());" % (g, site))
    sql.append("REPLACE INTO character_garrison_talents (guid, GarrTypeId, talentID, orderTime, flags) VALUES (%d, 0, %d, UNIX_TIMESTAMP() - 864000, 0);" % (g, talent))
    run.sql("\n".join(sql))


def step_artifacts(run, d, presets, args):
    ch = run.ch
    defaults = presets["defaults"]
    overrides = {"crucible": args.crucible, "crucible_trait": args.crucible_trait}
    all_art_items = [i for i, a in d.artifact_of_item.items() if a in d.artifact_spec and d.specs[d.artifact_spec[a]][0] == ch.cls]
    owned = ch.owned_items(all_art_items)
    mailed = ch.mailed_items(all_art_items)
    log("\n== Artifacts: rank, traits, relics, Netherlight Crucible ==")
    for e in sorted(set(mailed) - set(owned)):
        log("  %s is still in the mailbox: take it out, log out and run 'artifacts' again" % d.name(e))
    work = []
    for e, places in sorted(owned.items()):
        g = sorted(places, key=lambda p: (not (p[1] == 0 and p[2] in (15, 16)), p[0]))[0][0]  # equipped copy first
        work.append((e, g))
    if run.dry:  # plan: also show the artifacts the gear step would mail
        mains = [d.spec_artifact[s][1] for s in sorted(d.specs) if d.specs[s][0] == ch.cls and s in d.spec_artifact]
        work += [(e, 0) for e in mains if e not in owned]
    if not work:
        log("  no artifact in the bags/bank")
        return
    guids = [g for _, g in work]
    if not run.dry:
        run.backup("item_instance_artifact", "char_guid = %d" % ch.guid)
        run.backup("item_instance_artifact_powers", "char_guid = %d" % ch.guid)
        run.backup("item_instance_relics", "char_guid = %d OR itemGuid IN (%s)" % (ch.guid, ids(guids)))
        run.backup("item_instance_gems", "itemGuid IN (%s)" % ids(guids))
        run.backup("item_instance", "guid IN (%s)" % ids(guids))
    existing = {int(r[0]): r for r in rows("SELECT itemEntry, xp, artifactAppearanceId FROM item_instance_artifact WHERE char_guid = %d" % ch.guid)}
    ench = {int(r[0]): r[1].split() for r in rows("SELECT guid, enchantments FROM item_instance WHERE guid IN (%s)" % ids(guids))}
    sql = []
    for e, g in work:
        art = d.artifact_of_item[e]
        spec = d.artifact_spec[art]
        preset = presets["specs"][str(spec)]
        powers = d.powers[art]
        ranks = {p[0]: full_rank(p) for p in powers}
        total = sum(ranks.values())
        relics, relic_data, t2, t3 = plan_relics(d, art, e, preset, defaults, overrides, g)
        appearance = int(existing[e][2]) if e in existing and int(existing[e][2]) else d.default_appearance.get(art, 0)
        log("  %s (%s, item %d): rank %d, tier 2%s" % (d.name(e), preset["spec"], g, total, "" if total == 101 else "  WARNING: expected 101"))
        for n, r in enumerate(relics):
            label = d.relic_label(r)
            log("    relic %d: %-32s +1 %-26s crucible: Netherlight Fortification, %s, %s" % (
                n + 1, d.name(r), d.trait_by_label(art, label)[5], t2, t3))
        xp = existing[e][1] if e in existing else "0"
        sql.append("REPLACE INTO item_instance_artifact (itemGuid, xp, artifactAppearanceId, itemEntry, tier, char_guid, totalrank) "
                   "VALUES (%d, %s, %d, %d, 1, %d, %d);" % (g, xp, appearance, e, ch.guid, total))
        values = ["(%d, %d, %d, %d, %d, 0)" % (g, p[0], ranks.get(p[0], 0), e, ch.guid) for p in powers + d.relic_powers]
        sql.append("REPLACE INTO item_instance_artifact_powers (itemGuid, artifactPowerId, purchasedRank, itemEntry, char_guid, totalrank) "
                   "VALUES %s;" % ",".join(values))
        bonus = [d.bonus_for(r, args.ilvl, defaults)[0] for r in relics]
        cols = ["itemGuid"]
        vals = [str(g)]
        for n in range(3):
            cols += ["gemItemId%d" % (n + 1), "gemBonuses%d" % (n + 1), "gemContext%d" % (n + 1), "gemScalingLevel%d" % (n + 1)]
            if n < len(relics):
                vals += [str(relics[n]), "'%s'" % (bonus[n] + " " if bonus[n] else ""), "0", "110"]
            else:
                vals += ["0", "NULL", "0", "0"]
        sql.append("REPLACE INTO item_instance_gems (%s) VALUES (%s);" % (", ".join(cols), ", ".join(vals)))
        tokens = (ench.get(g, []) + ["0"] * 39)[:39]
        for n, r in enumerate(relics):
            tokens[(2 + n) * 3:(2 + n) * 3 + 3] = [str(d.gemprops[d.sparse[r][40]][1]), "0", "0"]
        sql.append("UPDATE item_instance SET enchantments = '%s ' WHERE guid = %d;" % (" ".join(tokens), g))
        relic_cols = (relic_data + ["", "", ""])[:3]
        sql.append("REPLACE INTO item_instance_relics (itemGuid, char_guid, first_relic, second_relic, third_relic) "
                   "VALUES (%d, %d, '%s', '%s', '%s');" % (g, ch.guid, relic_cols[0], relic_cols[1], relic_cols[2]))
    run.sql("\n".join(sql))


def export_gear_npc(d, presets, path):
    """world.gear_npc_items for the staff gear NPC (scripts/Custom/gear_up_npc.cpp): the same gear as `gear`, every spec."""
    out = ["-- Generated by fill_character.py export: gear for npc_gear_up, one row per spec and slot.",
           "CREATE TABLE IF NOT EXISTS gear_npc_items (spec SMALLINT UNSIGNED NOT NULL, slot VARCHAR(16) NOT NULL,",
           "  item INT UNSIGNED NOT NULL, bonus VARCHAR(128) NOT NULL DEFAULT '', PRIMARY KEY (spec, slot));",
           "DELETE FROM gear_npc_items;"]
    rows = 0
    for spec in sorted(d.specs, key=lambda s: (d.specs[s][0], s)):
        if str(spec) not in presets["specs"]:
            continue
        for slot, iid, bonus, _ in pick_gear(d, d.specs[spec][0], spec, presets, presets["defaults"]["ilvl"]):
            out.append("INSERT INTO gear_npc_items VALUES (%d, '%s', %d, '%s');" % (spec, slot, iid, bonus))
            rows += 1
    with open(path, "w") as f:
        f.write("\n".join(out) + "\n")
    print("%d rows -> %s  (apply: mysql world < %s)" % (rows, path, path))


def check_presets(d, presets):
    """Plans gear and relics for every spec without touching the DB."""
    ok = True
    for spec in sorted(d.specs, key=lambda s: (d.specs[s][0], s)):
        p = presets["specs"].get(str(spec))
        if not p:
            print("MISSING preset for spec %d %s" % (spec, d.specs[spec][3]))
            ok = False
            continue
        cls = d.specs[spec][0]
        gear = pick_gear(d, cls, spec, presets, presets["defaults"]["ilvl"])
        missing = [s for s, _ in SLOTS if s not in {g[0] for g in gear}]
        art, item = d.spec_artifact[spec]
        total = sum(full_rank(x) for x in d.powers[art])
        relics, _, t2, t3 = plan_relics(d, art, item, p, presets["defaults"], {}, 1)
        print("%-24s %2d items%s | %s rank %d | relics %s | crucible %s + %s" % (
            p["spec"], len(gear), " MISSING " + ",".join(missing) if missing else "", d.name(item), total,
            ", ".join(d.name(r) for r in relics), t2, t3))
        print("    " + "; ".join("%s %s" % (s, d.name(i)) for s, i, _, _ in gear))
        ok &= not missing and total == 101
    print("OK" if ok else "problems above")


def undo(path):
    f = os.path.join(os.path.expanduser(path), "undo.sql")
    if not os.path.exists(f):
        die("no undo.sql in %s" % path)
    m = re.search(r"guid (\d+)\)", open(f).read())
    if m and int(rows("SELECT online FROM characters WHERE guid = %s" % m.group(1))[0][0]):
        die("the character is online, log it out first")
    execute(open(f).read())
    print("undone:", f)


D = None


def main():
    global D
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("command", choices=["plan", "all", "gear", "quests", "artifacts", "undo", "check", "export"])
    ap.add_argument("name", nargs="?")
    ap.add_argument("--spec", action="append")
    ap.add_argument("--ilvl", type=int)
    ap.add_argument("--all-legendaries", action="store_true")
    ap.add_argument("--crucible")
    ap.add_argument("--crucible-trait")
    ap.add_argument("--no-mail-artifacts", action="store_true")
    ap.add_argument("--rollback", action="store_true", help="test: run the SQL in a transaction, show the result, roll back (no mail)")
    args = ap.parse_args()
    if args.command == "undo":
        return undo(args.name or die("undo needs the run directory"))
    presets = load_presets()
    args.ilvl = args.ilvl or presets["defaults"]["ilvl"]
    D = Data()
    if args.command == "check":
        return check_presets(D, presets)
    if args.command == "export":
        return export_gear_npc(D, presets, args.name or os.path.join(HOME, "gear_npc_items.sql"))
    if not args.name:
        die("character name missing")
    ch = Char(args.name)
    dry = args.command == "plan"
    if not dry and not args.rollback:
        ch.require_offline()
        if os.path.exists(os.path.join(HOME, "DEPLOY.lock")):
            print("note: ~/DEPLOY.lock exists (%s)" % open(os.path.join(HOME, "DEPLOY.lock")).read().strip())
    run = Run(ch, dry, args.rollback)
    specs = resolve_specs(D, ch.cls, ch.spec, args.spec)
    log("%s %s (guid %d, %s level %d, spec %s)%s" % (args.command, ch.name, ch.guid, CLASSES[ch.cls], ch.level,
        ", ".join(presets["specs"][str(s)]["spec"] for s in specs),
        "  [dry run, nothing changed]" if dry else "  [--rollback test]" if args.rollback else ""))
    if args.command in ("plan", "all", "gear"):
        step_gear(run, D, presets, specs, args)
    if args.command in ("plan", "all", "quests"):
        step_quests(run, D, args)
    if args.command in ("plan", "all", "artifacts"):
        step_artifacts(run, D, presets, args)
    if args.rollback:
        run.test_and_rollback()
    elif not dry:
        log("\nDone. Undo (character offline): python3 %s undo %s" % (os.path.abspath(__file__), run.dir))


if __name__ == "__main__":
    main()
