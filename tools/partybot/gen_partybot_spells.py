#!/usr/bin/env python3
"""Party bots phase 2 (#65): spell rotations per spec -> world.partybot_spells.

Rotations are written below by spell NAME; this resolves each name to the spell ID that spec really gets
(SpecializationSpells of the spec, then the class skill line, then artifact abilities, then the spec's talents)
and writes sql/custom/partybot_spells.sql. Unresolved names are printed and left out.

Run on the server:  PYTHONPATH=~/client_parts python3 gen_partybot_spells.py [out.sql]

Types (the AI walks a spec's list top to bottom every tick and casts the first one whose condition holds and that
the server accepts; cooldowns, costs, range and cast times are checked by the normal spell code):
  damage      on the target
  dot         on the target when it lacks the aura (aura = the spell, or the name given as 4th field)
  execute     on the target below param % health
  finisher    on the target with at least param combo points
  buff        on self when self lacks the aura
  cooldown    on the target (or self) in combat; the spell's own cooldown gates it
  aoe         on the target when at least param enemies are within 8 yd of it
  heal        on the lowest group member below param % health
  hot         on the lowest group member below param % without the aura
  aoeheal     on self when at least 3 group members are below param %
  selfheal    on self below param % health
  taunt       on an enemy that attacks a group member other than the bot (tanks)
  pet         when the bot has no pet
"""
import pickle, sys, os
import wdc1

DBC = "/home/wow/data/dbc/enUS/"
CLASS_SKILL = {1: 840, 2: 800, 3: 795, 4: 921, 5: 804, 6: 796, 7: 924, 8: 904, 9: 849, 10: 829, 11: 798, 12: 1848}

T, H = "taunt", "heal"
ROT = {
    # ---------------- Warrior
    71: [("Battle Cry", "cooldown", 0), ("Warbreaker", "cooldown", 0), ("Colossus Smash", "dot", 0), ("Execute", "execute", 20),
         ("Mortal Strike", "damage", 0), ("Bladestorm", "aoe", 3), ("Whirlwind", "aoe", 3), ("Victory Rush", "selfheal", 80),
         ("Slam", "damage", 0)],
    72: [("Battle Cry", "cooldown", 0), ("Odyn's Fury", "cooldown", 0), ("Rampage", "damage", 0), ("Execute", "execute", 20),
         ("Bloodthirst", "damage", 0), ("Whirlwind", "aoe", 3), ("Raging Blow", "damage", 0), ("Victory Rush", "selfheal", 80),
         ("Furious Slash", "damage", 0)],
    73: [("Taunt", T, 0), ("Ignore Pain", "buff", 0), ("Shield Block", "buff", 0), ("Demoralizing Shout", "cooldown", 0),
         ("Neltharion's Fury", "cooldown", 0), ("Shield Slam", "damage", 0), ("Thunder Clap", "aoe", 1), ("Revenge", "damage", 0),
         ("Victory Rush", "selfheal", 80), ("Devastate", "damage", 0)],
    # ---------------- Paladin
    65: [("Tyr's Deliverance", "aoeheal", 70), ("Light of Dawn", "aoeheal", 85), ("Holy Shock", H, 90), ("Flash of Light", H, 55),
         ("Holy Light", H, 85), ("Judgment", "damage", 0), ("Crusader Strike", "damage", 0)],
    66: [("Hand of Reckoning", T, 0), ("Eye of Tyr", "cooldown", 0), ("Light of the Protector", "selfheal", 60),
         ("Shield of the Righteous", "buff", 0), ("Avenger's Shield", "damage", 0), ("Consecration", "aoe", 1),
         ("Judgment", "damage", 0), ("Hammer of the Righteous", "damage", 0)],
    70: [("Avenging Wrath", "cooldown", 0), ("Wake of Ashes", "cooldown", 0), ("Divine Storm", "aoe", 3),
         ("Templar's Verdict", "damage", 0), ("Judgment", "damage", 0), ("Blade of Justice", "damage", 0),
         ("Crusader Strike", "damage", 0)],
    # ---------------- Hunter (no pet: bots have none tamed)
    253: [("Aspect of the Wild", "cooldown", 0), ("Bestial Wrath", "cooldown", 0), ("Titan's Thunder", "cooldown", 0),
          ("Dire Beast", "damage", 0), ("Kill Command", "damage", 0), ("Multi-Shot", "aoe", 3), ("Cobra Shot", "damage", 0)],
    254: [("Trueshot", "cooldown", 0), ("Windburst", "cooldown", 0), ("Marked Shot", "damage", 0), ("Multi-Shot", "aoe", 3),
          ("Aimed Shot", "damage", 0), ("Arcane Shot", "damage", 0)],
    255: [("Aspect of the Eagle", "cooldown", 0), ("Fury of the Eagle", "cooldown", 0), ("Lacerate", "dot", 0),
          ("Mongoose Bite", "damage", 0), ("Flanking Strike", "damage", 0), ("Carve", "aoe", 3), ("Raptor Strike", "damage", 0)],
    # ---------------- Rogue
    259: [("Vendetta", "cooldown", 0), ("Kingsbane", "cooldown", 0), ("Garrote", "dot", 0), ("Rupture", "finisher", 4),
          ("Envenom", "finisher", 4), ("Fan of Knives", "aoe", 3), ("Mutilate", "damage", 0)],
    260: [("Adrenaline Rush", "cooldown", 0), ("Curse of the Dreadblades", "cooldown", 0), ("Roll the Bones", "finisher", 5),
          ("Run Through", "finisher", 5), ("Pistol Shot", "damage", 0), ("Saber Slash", "damage", 0)],
    261: [("Shadow Dance", "cooldown", 0), ("Symbols of Death", "buff", 0), ("Goremaw's Bite", "cooldown", 0),
          ("Nightblade", "finisher", 5), ("Eviscerate", "finisher", 5), ("Shuriken Storm", "aoe", 3), ("Shadowstrike", "damage", 0),
          ("Backstab", "damage", 0)],
    # ---------------- Priest
    256: [("Power Word: Radiance", "aoeheal", 80), ("Penance", H, 70), ("Power Word: Shield", H, 90), ("Shadow Mend", H, 55),
          ("Plea", H, 85), ("Light's Wrath", "cooldown", 0), ("Shadow Word: Pain", "dot", 0), ("Penance", "damage", 0),
          ("Smite", "damage", 0)],
    257: [("Divine Hymn", "aoeheal", 50), ("Holy Word: Sanctify", "aoeheal", 80), ("Prayer of Healing", "aoeheal", 80),
          ("Holy Word: Serenity", H, 50), ("Flash Heal", H, 60), ("Prayer of Mending", H, 95), ("Renew", "hot", 90),
          ("Heal", H, 85), ("Holy Fire", "damage", 0), ("Smite", "damage", 0)],
    258: [("Shadowform", "buff", 0), ("Void Eruption", "damage", 0), ("Void Torrent", "cooldown", 0),
          ("Shadow Word: Death", "execute", 20), ("Vampiric Touch", "dot", 0), ("Shadow Word: Pain", "dot", 0),
          ("Mind Blast", "damage", 0), ("Mind Sear", "aoe", 4), ("Mind Flay", "damage", 0)],
    # ---------------- Death Knight
    250: [("Dark Command", T, 0), ("Vampiric Blood", "selfheal", 45), ("Death Strike", "selfheal", 75),
          ("Marrowrend", "buff", 0, 195181), ("Consumption", "cooldown", 0), ("Blood Boil", "aoe", 1),
          ("Death and Decay", "aoe", 2), ("Heart Strike", "damage", 0), ("Death Strike", "damage", 0)],
    251: [("Pillar of Frost", "cooldown", 0), ("Sindragosa's Fury", "cooldown", 0), ("Howling Blast", "dot", 0, "Frost Fever"),
          ("Remorseless Winter", "aoe", 2), ("Obliterate", "damage", 0), ("Frost Strike", "damage", 0)],
    252: [("Raise Dead", "pet", 0), ("Dark Transformation", "cooldown", 0), ("Apocalypse", "cooldown", 0),
          ("Outbreak", "dot", 0, "Virulent Plague"), ("Festering Strike", "damage", 0), ("Scourge Strike", "damage", 0),
          ("Death Coil", "damage", 0)],
    # ---------------- Shaman
    262: [("Fire Elemental", "cooldown", 0), ("Stormkeeper", "cooldown", 0), ("Flame Shock", "dot", 0),
          ("Earth Shock", "damage", 0), ("Lava Burst", "damage", 0), ("Chain Lightning", "aoe", 3), ("Lightning Bolt", "damage", 0)],
    263: [("Feral Spirit", "cooldown", 0), ("Doom Winds", "cooldown", 0), ("Flametongue", "buff", 0),
          ("Crash Lightning", "aoe", 2), ("Stormstrike", "damage", 0), ("Lava Lash", "damage", 0), ("Rockbiter", "damage", 0)],
    264: [("Healing Tide Totem", "aoeheal", 50), ("Gift of the Queen", "aoeheal", 80), ("Chain Heal", "aoeheal", 80),
          ("Healing Stream Totem", "aoeheal", 90), ("Riptide", "hot", 90), ("Healing Surge", H, 55), ("Healing Wave", H, 85),
          ("Flame Shock", "dot", 0), ("Lava Burst", "damage", 0), ("Lightning Bolt", "damage", 0)],
    # ---------------- Mage
    62: [("Arcane Power", "cooldown", 0), ("Mark of Aluneth", "cooldown", 0), ("Arcane Missiles", "damage", 0),
         ("Arcane Explosion", "aoe", 4), ("Arcane Blast", "damage", 0)],
    63: [("Combustion", "cooldown", 0), ("Phoenix's Flames", "cooldown", 0), ("Fire Blast", "damage", 0),
         ("Flamestrike", "aoe", 4), ("Pyroblast", "damage", 0), ("Fireball", "damage", 0)],
    64: [("Summon Water Elemental", "pet", 0), ("Icy Veins", "cooldown", 0), ("Frozen Orb", "cooldown", 0),
         ("Ebonbolt", "cooldown", 0), ("Flurry", "damage", 0), ("Ice Lance", "damage", 0), ("Frostbolt", "damage", 0)],
    # ---------------- Warlock
    265: [("Summon Felhunter", "pet", 0), ("Reap Souls", "cooldown", 0), ("Agony", "dot", 0), ("Corruption", "dot", 0),
          ("Seed of Corruption", "aoe", 4), ("Unstable Affliction", "damage", 0), ("Drain Soul", "damage", 0)],
    266: [("Summon Felguard", "pet", 0), ("Summon Doomguard", "cooldown", 0), ("Thal'kiel's Consumption", "cooldown", 0),
          ("Doom", "dot", 0), ("Call Dreadstalkers", "damage", 0), ("Hand of Gul'dan", "damage", 0),
          ("Demonic Empowerment", "damage", 0), ("Shadow Bolt", "damage", 0)],
    267: [("Summon Imp", "pet", 0), ("Summon Doomguard", "cooldown", 0), ("Dimensional Rift", "cooldown", 0),
          ("Immolate", "dot", 0), ("Conflagrate", "damage", 0), ("Chaos Bolt", "damage", 0), ("Incinerate", "damage", 0)],
    # ---------------- Monk
    268: [("Provoke", T, 0), ("Ironskin Brew", "buff", 0), ("Exploding Keg", "cooldown", 0), ("Keg Smash", "damage", 0),
          ("Blackout Strike", "damage", 0), ("Breath of Fire", "aoe", 1), ("Tiger Palm", "damage", 0)],
    269: [("Storm, Earth, and Fire", "cooldown", 0), ("Touch of Death", "cooldown", 0), ("Strike of the Windlord", "cooldown", 0),
          ("Fists of Fury", "damage", 0), ("Rising Sun Kick", "damage", 0), ("Spinning Crane Kick", "aoe", 3),
          ("Blackout Kick", "damage", 0), ("Tiger Palm", "damage", 0)],
    270: [("Revival", "aoeheal", 40), ("Essence Font", "aoeheal", 80), ("Sheilun's Gift", H, 60), ("Renewing Mist", "hot", 95),
          ("Enveloping Mist", H, 55), ("Vivify", H, 75), ("Effuse", H, 85), ("Rising Sun Kick", "damage", 0),
          ("Blackout Kick", "damage", 0), ("Tiger Palm", "damage", 0)],
    # ---------------- Druid
    102: [("Moonkin Form", "buff", 0), ("Celestial Alignment", "cooldown", 0), ("New Moon", "cooldown", 0),
          ("Moonfire", "dot", 0), ("Sunfire", "dot", 0), ("Starsurge", "damage", 0), ("Lunar Strike", "damage", 0),
          ("Solar Wrath", "damage", 0)],
    103: [("Cat Form", "buff", 0), ("Tiger's Fury", "cooldown", 0), ("Berserk", "cooldown", 0), ("Ashamane's Frenzy", "cooldown", 0),
          ("Rake", "dot", 0), ("Rip", "finisher", 5), ("Ferocious Bite", "finisher", 5), ("Thrash", "aoe", 2),
          ("Swipe", "aoe", 3), ("Shred", "damage", 0)],
    104: [("Bear Form", "buff", 0), ("Growl", T, 0), ("Frenzied Regeneration", "selfheal", 60), ("Barkskin", "selfheal", 50),
          ("Ironfur", "buff", 0), ("Rage of the Sleeper", "cooldown", 0), ("Mangle", "damage", 0), ("Thrash", "aoe", 1),
          ("Moonfire", "dot", 0), ("Swipe", "damage", 0)],
    105: [("Tranquility", "aoeheal", 40), ("Essence of G'Hanir", "aoeheal", 75), ("Wild Growth", "aoeheal", 85),
          ("Swiftmend", H, 40), ("Regrowth", H, 60), ("Rejuvenation", "hot", 95), ("Lifebloom", "hot", 90),
          ("Healing Touch", H, 80), ("Moonfire", "dot", 0), ("Solar Wrath", "damage", 0)],
    # ---------------- Demon Hunter
    577: [("Fury of the Illidari", "cooldown", 0), ("Eye Beam", "aoe", 2), ("Blade Dance", "aoe", 2), ("Chaos Strike", "damage", 0),
          ("Demon's Bite", "damage", 0), ("Throw Glaive", "damage", 0)],
    581: [("Torment", T, 0), ("Demon Spikes", "buff", 0), ("Fiery Brand", "cooldown", 0), ("Soul Carver", "cooldown", 0),
          ("Immolation Aura", "aoe", 1), ("Soul Cleave", "damage", 0), ("Shear", "damage", 0), ("Throw Glaive", "damage", 0)],
}


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else "partybot_spells.sql"
    names = pickle.load(open("/tmp/spellnames.pkl", "rb"))
    by_name = {}
    for sid, n in names.items():
        by_name.setdefault(n, []).append(sid)

    spec_class = {k: v[4] for k, v in wdc1.read(DBC + "ChrSpecialization.db2").items()}
    spec_spells = {}
    for v in wdc1.read(DBC + "SpecializationSpells.db2").values():
        spec_spells.setdefault(v[3], set()).add(v[1])
    skill_spells = {}
    for v in wdc1.read(DBC + "SkillLineAbility.db2").values():
        skill_spells.setdefault(v[4], set()).add(v[2])
    artifact = {v[0] for v in wdc1.read(DBC + "ArtifactPowerRank.db2").values()}
    talents = {}   # (class, spec) -> spells; spec 0 = every spec of the class
    for v in wdc1.read(DBC + "Talent.db2").values():
        talents.setdefault((v[8], v[3]), set()).add(v[1])

    rows, missing = [], []
    for spec, entries in sorted(ROT.items()):
        cls = spec_class[spec]
        pools = [("spec", spec_spells.get(spec, set())),
                 ("class", skill_spells.get(CLASS_SKILL[cls], set())),
                 ("artifact", artifact),
                 ("talent", talents.get((cls, spec), set()) | talents.get((cls, 0), set()))]

        def resolve(name):
            ids = by_name.get(name, [])
            for label, pool in pools:
                hit = sorted(i for i in ids if i in pool)
                if hit:
                    return hit[0], label
            return None, None

        for prio, e in enumerate(entries):
            name, typ, param = e[0], e[1], e[2]
            sid, src = resolve(name)
            if not sid:
                missing.append((spec, name))
                continue
            aura = 0
            if len(e) > 3 and isinstance(e[3], int):
                aura = e[3]
            elif len(e) > 3:
                cand = [i for i in by_name.get(e[3], []) if i < 300000]
                aura = min(cand) if cand else 0
            rows.append((spec, prio, sid, typ, param, aura, name.replace("'", "''"), src))

    with open(out, "w") as f:
        f.write("-- Party bots phase 2 (#65): spell rotations per spec, generated by tools/partybot/gen_partybot_spells.py.\n")
        f.write("-- Tune here or in the generator; read by the worldserver at start (restart to apply). Undo: DROP TABLE world.partybot_spells.\n")
        f.write("CREATE TABLE IF NOT EXISTS world.partybot_spells (spec SMALLINT UNSIGNED NOT NULL, prio TINYINT UNSIGNED NOT NULL,\n"
                "  spell INT UNSIGNED NOT NULL, type VARCHAR(16) NOT NULL, param INT NOT NULL DEFAULT 0, aura INT UNSIGNED NOT NULL DEFAULT 0,\n"
                "  comment VARCHAR(64) NOT NULL DEFAULT '', PRIMARY KEY (spec, prio)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;\n")
        f.write("DELETE FROM world.partybot_spells;\nINSERT INTO world.partybot_spells (spec, prio, spell, type, param, aura, comment) VALUES\n")
        f.write(",\n".join("(%d, %d, %d, '%s', %d, %d, '%s (%s)')" % r for r in rows) + ";\n")
    print("rows", len(rows), "->", out)
    for spec, name in missing:
        print("MISSING", spec, name)


if __name__ == "__main__":
    main()
