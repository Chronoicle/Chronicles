#!/usr/bin/env python3
"""Party bots phase 2 (#65): spell rotations per spec -> world.partybot_spells, talent builds -> world.partybot_talents.

Rotations are written below by spell NAME; this resolves each name to the spell ID that spec really gets
(SpecializationSpells of the spec, then the class skill line, then artifact abilities, then the spec's talents)
and writes sql/custom/partybot_spells.sql. Unresolved names are printed and left out.

Run on the server:  PYTHONPATH=~/client_parts python3 gen_partybot_spells.py [out.sql]

Types (the AI walks a spec's list top to bottom every tick and casts the first one whose condition holds and that
the server accepts; cooldowns, costs, range and cast times are checked by the normal spell code):
  damage      on the target
  dot         on the target when it lacks the aura (aura = the spell, or the name given as 4th field); param = combo points
              needed (0 = none: Rupture, Rip, Nightblade)
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
         ("Storm Bolt", "damage", 0), ("Slam", "damage", 0)],
    72: [("Avatar", "cooldown", 0), ("Battle Cry", "cooldown", 0), ("Bloodbath", "cooldown", 0), ("Odyn's Fury", "cooldown", 0), ("Rampage", "damage", 0), ("Execute", "execute", 20),
         ("Bloodthirst", "damage", 0), ("Whirlwind", "aoe", 3), ("Raging Blow", "damage", 0), ("Victory Rush", "selfheal", 80),
         ("Storm Bolt", "damage", 0), ("Furious Slash", "damage", 0)],
    73: [("Taunt", T, 0), ("Ignore Pain", "buff", 0), ("Shield Block", "buff", 0), ("Demoralizing Shout", "cooldown", 0),
         ("Neltharion's Fury", "cooldown", 0), ("Shield Slam", "damage", 0), ("Shockwave", "aoe", 3), ("Thunder Clap", "aoe", 1), ("Revenge", "damage", 0),
         ("Impending Victory", "damage", 0), ("Devastate", "damage", 0)],
    # ---------------- Paladin
    65: [("Avenging Wrath", "aoeheal", 70), ("Beacon of Virtue", "aoeheal", 90), ("Tyr's Deliverance", "aoeheal", 70), ("Light of Dawn", "aoeheal", 85), ("Holy Shock", H, 90), ("Bestow Faith", "heal", 90), ("Flash of Light", H, 55),
         ("Holy Light", H, 85), ("Judgment", "damage", 0), ("Crusader Strike", "damage", 0)],
    66: [("Hand of Reckoning", T, 0), ("Avenging Wrath", "cooldown", 0), ("Eye of Tyr", "cooldown", 0), ("Hand of the Protector", "selfheal", 60), ("Shield of the Righteous", "buff", 0), ("Avenger's Shield", "damage", 0), ("Consecration", "aoe", 1),
         ("Judgment", "damage", 0), ("Blessed Hammer", "damage", 0)],
    70: [("Crusade", "cooldown", 0), ("Word of Glory", "aoeheal", 50), ("Wake of Ashes", "cooldown", 0), ("Divine Storm", "aoe", 3),
         ("Templar's Verdict", "damage", 0), ("Judgment", "damage", 0), ("Blade of Justice", "damage", 0),
         ("Crusader Strike", "damage", 0)],
    # ---------------- Hunter (no pet: bots have none tamed)
    253: [("Aspect of the Wild", "cooldown", 0), ("Bestial Wrath", "cooldown", 0), ("Titan's Thunder", "cooldown", 0),
          ("Stampede", "cooldown", 0), ("A Murder of Crows", "cooldown", 0), ("Dire Beast", "damage", 0), ("Kill Command", "damage", 0), ("Chimaera Shot", "damage", 0), ("Multi-Shot", "aoe", 3), ("Cobra Shot", "damage", 0)],
    254: [("Trueshot", "cooldown", 0), ("Windburst", "cooldown", 0), ("A Murder of Crows", "cooldown", 0), ("Marked Shot", "damage", 0), ("Multi-Shot", "aoe", 3),
          ("Aimed Shot", "damage", 0), ("Arcane Shot", "damage", 0)],
    255: [("Aspect of the Eagle", "cooldown", 0), ("Fury of the Eagle", "cooldown", 0), ("Spitting Cobra", "cooldown", 0), ("Lacerate", "dot", 0),
          ("Mongoose Bite", "damage", 0), ("Snake Hunter", "cooldown", 0), ("Caltrops", "cooldown", 0), ("Flanking Strike", "damage", 0), ("Carve", "aoe", 3), ("Throwing Axes", "damage", 0), ("Raptor Strike", "damage", 0)],
    # ---------------- Rogue
    259: [("Deadly Poison", "buff", 0), ("Vendetta", "cooldown", 0), ("Kingsbane", "cooldown", 0), ("Garrote", "dot", 0), ("Toxic Blade", "damage", 0), ("Rupture", "dot", 4),
          ("Envenom", "finisher", 4), ("Fan of Knives", "aoe", 3), ("Mutilate", "damage", 0)],
    260: [("Adrenaline Rush", "cooldown", 0), ("Curse of the Dreadblades", "cooldown", 0), ("Slice and Dice", "buff", 0), ("Run Through", "finisher", 5), ("Ghostly Strike", "dot", 0), ("Saber Slash", "damage", 0)],
    261: [("Shadow Dance", "cooldown", 0), ("Symbols of Death", "buff", 0), ("Goremaw's Bite", "cooldown", 0),
          ("Nightblade", "dot", 5), ("Eviscerate", "finisher", 5), ("Shuriken Storm", "aoe", 3), ("Shadowstrike", "damage", 0),
          ("Backstab", "damage", 0)],
    # ---------------- Priest
    256: [("Power Word: Radiance", "aoeheal", 80), ("Penance", H, 70), ("Power Word: Shield", H, 90), ("Shadow Mend", H, 55),
          ("Plea", H, 85), ("Mindbender", "cooldown", 0), ("Light's Wrath", "cooldown", 0), ("Penance", "damage", 0),
          ("Purge the Wicked", "dot", 0, 204213), ("Smite", "damage", 0)],
    257: [("Divine Hymn", "aoeheal", 50), ("Holy Word: Sanctify", "aoeheal", 80), ("Circle of Healing", "aoeheal", 85), ("Prayer of Healing", "aoeheal", 80),
          ("Holy Word: Serenity", H, 50), ("Flash Heal", H, 60), ("Prayer of Mending", H, 95), ("Renew", "hot", 90),
          ("Heal", H, 85), ("Holy Fire", "damage", 0), ("Smite", "damage", 0)],
    258: [("Shadowform", "buff", 0), ("Void Eruption", "damage", 0), ("Void Torrent", "cooldown", 0),
          ("Shadow Word: Death", "execute", 20), ("Vampiric Touch", "dot", 0), ("Mind Blast", "damage", 0), ("Mind Sear", "aoe", 4), ("Mind Flay", "damage", 0)],
    # ---------------- Death Knight
    250: [("Dark Command", T, 0), ("Vampiric Blood", "selfheal", 45), ("Death Strike", "selfheal", 75),
          ("Rune Tap", "selfheal", 60), ("Marrowrend", "buff", 0, 195181), ("Blood Mirror", "cooldown", 0), ("Consumption", "cooldown", 0), ("Blood Boil", "aoe", 1),
          ("Death and Decay", "aoe", 2), ("Heart Strike", "damage", 0), ("Death Strike", "damage", 0)],
    251: [("Pillar of Frost", "cooldown", 0), ("Sindragosa's Fury", "cooldown", 0), ("Hungering Rune Weapon", "cooldown", 0), ("Howling Blast", "dot", 0, "Frost Fever"),
          ("Remorseless Winter", "aoe", 2), ("Obliterate", "damage", 0), ("Frost Strike", "damage", 0)],
    252: [("Raise Dead", "pet", 0), ("Dark Arbiter", "cooldown", 0), ("Dark Transformation", "cooldown", 0), ("Apocalypse", "cooldown", 0),
          ("Outbreak", "dot", 0, "Virulent Plague"), ("Festering Strike", "damage", 0), ("Scourge Strike", "damage", 0),
          ("Death Coil", "damage", 0)],
    # ---------------- Shaman
    262: [("Fire Elemental", "cooldown", 0), ("Stormkeeper", "cooldown", 0), ("Ascendance", "cooldown", 0), ("Flame Shock", "dot", 0),
          ("Elemental Blast", "damage", 0), ("Earth Shock", "damage", 0), ("Lava Burst", "damage", 0), ("Chain Lightning", "aoe", 3), ("Lightning Bolt", "damage", 0)],
    263: [("Rainfall", "aoeheal", 80), ("Feral Spirit", "cooldown", 0), ("Doom Winds", "cooldown", 0), ("Flametongue", "buff", 0),
          ("Earthen Spike", "cooldown", 0), ("Sundering", "cooldown", 0), ("Crash Lightning", "aoe", 2), ("Stormstrike", "damage", 0), ("Lava Lash", "damage", 0), ("Rockbiter", "damage", 0)],
    264: [("Ascendance", "aoeheal", 60), ("Healing Tide Totem", "aoeheal", 50), ("Gift of the Queen", "aoeheal", 80), ("Chain Heal", "aoeheal", 80),
          ("Cloudburst Totem", "aoeheal", 90), ("Riptide", "hot", 90), ("Healing Surge", H, 55), ("Healing Wave", H, 85),
          ("Flame Shock", "dot", 0), ("Lava Burst", "damage", 0), ("Lightning Bolt", "damage", 0)],
    # ---------------- Mage
    62: [("Rune of Power", "cooldown", 0), ("Arcane Power", "cooldown", 0), ("Mark of Aluneth", "cooldown", 0), ("Arcane Missiles", "damage", 0),
         ("Supernova", "damage", 0), ("Arcane Explosion", "aoe", 4), ("Arcane Blast", "damage", 0)],
    63: [("Rune of Power", "cooldown", 0), ("Combustion", "cooldown", 0), ("Phoenix's Flames", "cooldown", 0), ("Fire Blast", "damage", 0),
         ("Flamestrike", "aoe", 4), ("Pyroblast", "damage", 0), ("Fireball", "damage", 0)],
    64: [("Icy Veins", "cooldown", 0), ("Frozen Orb", "cooldown", 0),
         ("Ebonbolt", "cooldown", 0), ("Flurry", "damage", 0), ("Ice Lance", "damage", 0), ("Frostbolt", "damage", 0)],
    # ---------------- Warlock
    265: [("Summon Felhunter", "pet", 0), ("Reap Souls", "cooldown", 0), ("Agony", "dot", 0), ("Corruption", "dot", 0),
          ("Soul Harvest", "cooldown", 0), ("Seed of Corruption", "aoe", 4), ("Unstable Affliction", "damage", 0), ("Drain Soul", "damage", 0)],
    266: [("Summon Felguard", "pet", 0), ("Summon Doomguard", "cooldown", 0), ("Thal'kiel's Consumption", "cooldown", 0),
          ("Shadowfury", "aoe", 3), ("Doom", "dot", 0), ("Call Dreadstalkers", "damage", 0), ("Hand of Gul'dan", "damage", 0),
          ("Demonic Empowerment", "damage", 0), ("Shadow Bolt", "damage", 0)],
    267: [("Summon Imp", "pet", 0), ("Summon Doomguard", "cooldown", 0), ("Dimensional Rift", "cooldown", 0),
          ("Shadowfury", "aoe", 3), ("Immolate", "dot", 0), ("Soul Harvest", "cooldown", 0), ("Conflagrate", "damage", 0), ("Channel Demonfire", "damage", 0), ("Chaos Bolt", "damage", 0), ("Incinerate", "damage", 0)],
    # ---------------- Monk
    268: [("Provoke", T, 0), ("Healing Elixir", "selfheal", 70), ("Ironskin Brew", "buff", 0), ("Exploding Keg", "cooldown", 0), ("Leg Sweep", "aoe", 3), ("Keg Smash", "damage", 0),
          ("Blackout Strike", "damage", 0), ("Breath of Fire", "aoe", 1), ("Rushing Jade Wind", "aoe", 1), ("Tiger Palm", "damage", 0)],
    269: [("Healing Elixir", "selfheal", 50), ("Storm, Earth, and Fire", "cooldown", 0), ("Invoke Xuen, the White Tiger", "cooldown", 0), ("Touch of Death", "cooldown", 0), ("Energizing Elixir", "cooldown", 0), ("Strike of the Windlord", "cooldown", 0),
          ("Whirling Dragon Punch", "damage", 0), ("Fists of Fury", "damage", 0), ("Rising Sun Kick", "damage", 0), ("Spinning Crane Kick", "aoe", 3),
          ("Blackout Kick", "damage", 0), ("Tiger Palm", "damage", 0)],
    270: [("Healing Elixir", "selfheal", 60), ("Revival", "aoeheal", 40), ("Mana Tea", "cooldown", 0), ("Invoke Chi-Ji, the Red Crane", "aoeheal", 70), ("Essence Font", "aoeheal", 80), ("Sheilun's Gift", H, 60), ("Renewing Mist", "hot", 95),
          ("Chi Wave", "heal", 90), ("Enveloping Mist", H, 55), ("Vivify", H, 75), ("Effuse", H, 85), ("Rising Sun Kick", "damage", 0),
          ("Blackout Kick", "damage", 0), ("Tiger Palm", "damage", 0)],
    # ---------------- Druid
    102: [("Renewal", "selfheal", 40), ("Moonkin Form", "buff", 0), ("Incarnation: Chosen of Elune", "cooldown", 0), ("New Moon", "cooldown", 0),
          ("Moonfire", "dot", 0), ("Sunfire", "dot", 0), ("Starsurge", "damage", 0), ("Lunar Strike", "damage", 0),
          ("Solar Wrath", "damage", 0)],
    103: [("Cat Form", "buff", 0), ("Renewal", "selfheal", 40), ("Tiger's Fury", "cooldown", 0), ("Berserk", "cooldown", 0), ("Ashamane's Frenzy", "cooldown", 0),
          ("Rake", "dot", 0), ("Rip", "dot", 5), ("Ferocious Bite", "finisher", 5), ("Thrash", "aoe", 2),
          ("Brutal Slash", "aoe", 2), ("Shred", "damage", 0)],
    104: [("Bear Form", "buff", 0), ("Growl", T, 0), ("Frenzied Regeneration", "selfheal", 60), ("Barkskin", "selfheal", 50),
          ("Ironfur", "buff", 0), ("Rage of the Sleeper", "cooldown", 0), ("Mangle", "damage", 0), ("Thrash", "aoe", 1),
          ("Moonfire", "dot", 0), ("Swipe", "damage", 0)],
    105: [("Renewal", "selfheal", 40), ("Tranquility", "aoeheal", 40), ("Essence of G'Hanir", "aoeheal", 75), ("Wild Growth", "aoeheal", 85),
          ("Flourish", "aoeheal", 70), ("Swiftmend", H, 40), ("Regrowth", H, 60), ("Rejuvenation", "hot", 95), ("Lifebloom", "hot", 90),
          ("Healing Touch", H, 80), ("Moonfire", "dot", 0), ("Solar Wrath", "damage", 0)],
    # ---------------- Demon Hunter
    577: [("Nemesis", "cooldown", 0), ("Fury of the Illidari", "cooldown", 0), ("Chaos Blades", "cooldown", 0), ("Eye Beam", "aoe", 2), ("Blade Dance", "aoe", 2), ("Eye Beam", "damage", 0), ("Chaos Strike", "damage", 0),
          ("Throw Glaive", "damage", 0)],
    581: [("Torment", T, 0), ("Soul Barrier", "selfheal", 60), ("Demon Spikes", "buff", 0), ("Fiery Brand", "cooldown", 0), ("Soul Carver", "cooldown", 0),
          ("Immolation Aura", "aoe", 1), ("Spirit Bomb", "aoe", 1), ("Sigil of Flame", "aoe", 1), ("Soul Cleave", "damage", 0), ("Felblade", "damage", 0), ("Shear", "damage", 0), ("Throw Glaive", "damage", 0)],
}


# talent build per spec: (Talent ID, name) for rows 1-7. A bot learns them at its first login (partybot_characters.setup
# = 0). Each ID must be the talent the core accepts at its row/column for the spec (checked below).
TALENTS = {
    62: [(22461, "Amplification"), (22443, "Slipstream"), (22445, "Rune of Power"), (22453, "Supernova"), (22907, "Chrono Shift"), (22474, "Erosion"), (21630, "Overpowered")],  # Arcane Mage
    63: [(22456, "Pyromaniac"), (22905, "Blazing Soul"), (22445, "Rune of Power"), (22465, "Flame On"), (22471, "Ice Ward"), (22472, "Flame Patch"), (21631, "Kindling")],  # Fire Mage
    64: [(22460, "Lonely Winter"), (16025, "Glacial Insulation"), (22447, "Incanter's Flow"), (22469, "Splitting Ice"), (22446, "Frigid Winds"), (22449, "Unstable Magic"), (21632, "Thermal Void")],  # Frost Mage
    65: [(17565, "Bestow Faith"), (17575, "Unbreakable Spirit"), (22179, "Fist of Justice"), (17593, "Aura of Mercy"), (17597, "Divine Purpose"), (22190, "Sanctified Wrath"), (21203, "Beacon of Virtue")],  # Holy Paladin
    66: [(22558, "Blessed Hammer"), (22594, "Crusader's Judgment"), (22179, "Fist of Justice"), (22435, "Retribution Aura"), (22705, "Hand of the Protector"), (22484, "Judgment of Light"), (21201, "Righteous Protector")],  # Protection Paladin
    70: [(22590, "Final Verdict"), (22593, "Greater Judgment"), (22896, "Fist of Justice"), (22182, "Blade of Wrath"), (22186, "Word of Glory"), (22484, "Judgment of Light"), (22215, "Crusade")],  # Retribution Paladin
    71: [(22624, "Dauntless"), (22625, "Storm Bolt"), (22380, "Trauma"), (15757, "Second Wind"), (22393, "Mortal Combo"), (22397, "In For The Kill"), (22407, "Opportunity Strikes")],  # Arms Warrior
    72: [(22633, "Endless Rage"), (22372, "Storm Bolt"), (19138, "Avatar"), (22382, "Warpaint"), (22391, "Frothing Berserker"), (22395, "Bloodbath"), (22402, "Reckless Abandon")],  # Fury Warrior
    73: [(15760, "Shockwave"), (19676, "Impending Victory"), (22626, "Best Served Cold"), (22488, "Crackling Thunder"), (22362, "Indomitable"), (22396, "Vengeance"), (22406, "Heavy Repercussions")],  # Protection Warrior
    102: [(22387, "Starlord"), (19283, "Renewal"), (22159, "Restoration Affinity"), (18577, "Typhoon"), (18579, "Incarnation: Chosen of Elune"), (22389, "Shooting Stars"), (21655, "Nature's Balance")],  # Balance Druid
    103: [(22363, "Predator"), (19283, "Renewal"), (22163, "Balance Affinity"), (21778, "Mighty Bash"), (21702, "Jagged Wounds"), (21711, "Brutal Slash"), (21646, "Moment of Clarity")],  # Feral Druid
    104: [(22419, "Brambles"), (22424, "Guttural Roars"), (22159, "Restoration Affinity"), (18577, "Typhoon"), (22421, "Galactic Guardian"), (22423, "Earthwarden"), (22426, "Rend and Tear")],  # Guardian Druid
    105: [(18572, "Abundance"), (19283, "Renewal"), (22160, "Guardian Affinity"), (18577, "Typhoon"), (21704, "Cultivation"), (22165, "Germination"), (22404, "Flourish")],  # Restoration Druid
    250: [(19166, "Heartbreaker"), (19218, "Rapid Decomposition"), (19221, "Ossuary"), (22014, "Red Thirst"), (19227, "Tightening Grasp"), (19231, "Rune Tap"), (21208, "Blood Mirror")],  # Blood Death Knight
    251: [(22017, "Icy Talons"), (22020, "Murderous Efficiency"), (22515, "Icecap"), (22521, "Abomination's Might"), (22031, "Inexorable Assault"), (22533, "Frozen Pulse"), (22537, "Hungering Rune Weapon")],  # Frost Death Knight
    252: [(22025, "Bursting Sores"), (22028, "Pestilent Pustules"), (22518, "Castigator"), (22522, "Sludge Belcher"), (22528, "Spell Eater"), (22532, "Shadow Infusion"), (22030, "Dark Arbiter")],  # Unholy Death Knight
    253: [(22280, "Way of the Cobra"), (22290, "Chimaera Shot"), (22318, "Trailblazer"), (22441, "One with the Pack"), (22284, "Binding Shot"), (19357, "A Murder of Crows"), (22273, "Stampede")],  # Beast Mastery Hunter
    254: [(22279, "Lone Wolf"), (22498, "True Aim"), (22318, "Trailblazer"), (21998, "Patient Sniper"), (22284, "Binding Shot"), (19357, "A Murder of Crows"), (22288, "Trick Shot")],  # Marksmanship Hunter
    255: [(22283, "Throwing Axes"), (22297, "Snake Hunter"), (22318, "Trailblazer"), (22277, "Caltrops"), (22496, "Ranger's Net"), (22271, "Serpent Sting"), (22272, "Spitting Cobra")],  # Survival Hunter
    256: [(19753, "Castigation"), (22316, "Body and Soul"), (22094, "Psychic Voice"), (19761, "Mindbender"), (22330, "Sanctuary"), (22161, "Purge the Wicked"), (21184, "Grace")],  # Discipline Priest
    257: [(19754, "Enlightenment"), (21976, "Perseverance"), (22562, "Afterlife"), (21750, "Light of the Naaru"), (19764, "Surge of Light"), (19767, "Divinity"), (21638, "Circle of Healing")],  # Holy Priest
    258: [(22313, "Fortress of the Mind"), (22325, "Mania"), (22094, "Psychic Voice"), (21751, "Lingering Insanity"), (22311, "Auspicious Spirits"), (21719, "Misery"), (21637, "Legacy of the Void")],  # Shadow Priest
    259: [(22338, "Elaborate Planning"), (22331, "Nightstalker"), (19239, "Deeper Stratagem"), (22123, "Cheat Death"), (22341, "Thuggee"), (22343, "Toxic Blade"), (21186, "Venom Rush")],  # Assassination Rogue
    260: [(22118, "Ghostly Strike"), (19237, "Acrobatic Strikes"), (19239, "Deeper Stratagem"), (22123, "Cheat Death"), (22124, "Dirty Tricks"), (19249, "Alacrity"), (22125, "Slice and Dice")],  # Outlaw Rogue
    261: [(19233, "Master of Subtlety"), (22331, "Nightstalker"), (19239, "Deeper Stratagem"), (22123, "Cheat Death"), (22334, "Strike from the Shadows"), (22335, "Dark Shadow"), (22132, "Master of Shadows")],  # Subtlety Rogue
    262: [(22357, "Earthen Rage"), (19259, "Gust of Wind"), (19275, "Lightning Surge Totem"), (19272, "Ancestral Swiftness"), (19270, "Elemental Blast"), (21968, "Echo of the Elements"), (21198, "Ascendance")],  # Elemental Shaman
    263: [(22353, "Landslide"), (22636, "Rainfall"), (19275, "Lightning Surge Totem"), (19272, "Ancestral Swiftness"), (22137, "Tempest"), (22351, "Sundering"), (22359, "Earthen Spike")],  # Enhancement Shaman
    264: [(19264, "Torrent"), (22492, "Graceful Spirit"), (19275, "Lightning Surge Totem"), (22323, "Deluge"), (21966, "Ancestral Vigor"), (21971, "Cloudburst Totem"), (21970, "Ascendance")],  # Restoration Shaman
    265: [(22040, "Malefic Grasp"), (22044, "Contagion"), (19280, "Demonic Circle"), (22046, "Soul Harvest"), (22047, "Demon Skin"), (19294, "Grimoire of Service"), (19293, "Soul Conduit")],  # Affliction Warlock
    266: [(22038, "Shadowy Inspiration"), (21694, "Improved Dreadstalkers"), (19286, "Shadowfury"), (22042, "Power Trip"), (22047, "Demon Skin"), (21717, "Grimoire of Synergy"), (19293, "Soul Conduit")],  # Demonology Warlock
    267: [(22039, "Backdraft"), (21695, "Eradication"), (19286, "Shadowfury"), (22046, "Soul Harvest"), (22047, "Demon Skin"), (19294, "Grimoire of Service"), (22482, "Channel Demonfire")],  # Destruction Warlock
    268: [(22091, "Eye of the Tiger"), (19302, "Celerity"), (22098, "Light Brewing"), (19995, "Leg Sweep"), (20174, "Healing Elixir"), (19819, "Rushing Jade Wind"), (22104, "Blackout Combo")],  # Brewmaster Monk
    269: [(22091, "Eye of the Tiger"), (19302, "Celerity"), (22099, "Energizing Elixir"), (19995, "Leg Sweep"), (20174, "Healing Elixir"), (20184, "Invoke Xuen, the White Tiger"), (22105, "Whirling Dragon Punch")],  # Windwalker Monk
    270: [(20185, "Chi Wave"), (19302, "Celerity"), (22168, "Lifecycles"), (19995, "Leg Sweep"), (20174, "Healing Elixir"), (22217, "Invoke Chi-Ji, the Red Crane"), (22218, "Mana Tea")],  # Mistweaver Monk
    577: [(22416, "Blind Fury"), (22765, "Demon Blades"), (22909, "Chaos Cleave"), (21864, "Desperate Instincts"), (21868, "Nemesis"), (21869, "Master of the Glaive"), (21900, "Chaos Blades")],  # Havoc Demon Hunter
    581: [(22503, "Agonizing Flames"), (22505, "Feast of Souls"), (22324, "Felblade"), (22508, "Feed the Demon"), (22546, "Concentrated Sigils"), (22768, "Spirit Bomb"), (21902, "Soul Barrier")],  # Vengeance Demon Hunter
}


def talent_rows(talent_db):
    """(spec, id) rows for TALENTS; exits on an ID the core would refuse (Player::LearnTalent bestSlotMatch)."""
    spec_class = {k: v[4] for k, v in wdc1.read(DBC + "ChrSpecialization.db2").items()}
    rows, bad = [], []
    for spec, picks in sorted(TALENTS.items()):
        cls = spec_class[spec]
        tiers = set()
        for tid, _name in picks:
            v = talent_db.get(tid)
            if not v or v[8] != cls or v[3] not in (0, spec):
                bad.append((spec, tid, "not a talent of this spec"))
                continue
            best = None
            for k in sorted(talent_db):
                w = talent_db[k]
                if w[8] != cls or w[4] != v[4] or w[5] != v[5]:
                    continue
                if w[3] == 0:
                    best = k
                elif w[3] == spec:
                    best = k
                    break
            if best != tid:
                bad.append((spec, tid, "the core takes talent %s at this position" % best))
            tiers.add(v[4])
            rows.append((spec, tid))
        if tiers != set(range(7)) or len(picks) != 7:
            bad.append((spec, 0, "needs one talent per row, has rows %s" % sorted(t + 1 for t in tiers)))
    for b in bad:
        print("BAD TALENT", *b)
    if bad:
        sys.exit(1)
    return rows


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
    talent_db = wdc1.read(DBC + "Talent.db2")
    talent_picks = talent_rows(talent_db)
    talents = {}   # (class, spec) -> spells; spec 0 = every spec of the class
    for v in talent_db.values():
        talents.setdefault((v[8], v[3]), set()).add(v[1])

    rows, missing = [], []
    for spec, entries in sorted(ROT.items()):
        cls = spec_class[spec]
        pools = [("picked talent", {talent_db[t][1] for t, _ in TALENTS.get(spec, [])}),
                 ("spec", spec_spells.get(spec, set())),
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
        f.write("-- talent builds (undo: DROP TABLE world.partybot_talents)\n")
        f.write("CREATE TABLE IF NOT EXISTS world.partybot_talents (spec SMALLINT UNSIGNED NOT NULL, talent INT UNSIGNED NOT NULL,\n"
                "  PRIMARY KEY (spec, talent)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;\n")
        f.write("DELETE FROM world.partybot_talents;\nINSERT INTO world.partybot_talents (spec, talent) VALUES\n")
        f.write(",\n".join("(%d, %d)" % r for r in talent_picks) + ";\n")
    print("rows", len(rows), "talents", len(talent_picks), "->", out)
    for spec, name in missing:
        print("MISSING", spec, name)


if __name__ == "__main__":
    main()
