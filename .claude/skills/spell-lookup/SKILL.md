---
name: spell-lookup
description: Look up WoW 7.3.5 game data (spells, spell effects, talents, artifact traits, summons, creatures) and the database hooks that change spell behaviour on the Chronicles server. Use when investigating a spell, talent, artifact or summon bug before touching code.
---

# Game data and spell hooks on the server

Server: `ssh -o BatchMode=yes wow@184.174.37.33`, read-only for lookups (SELECT only). SQL: `mysql world -e "..."`
(`~/.my.cnf` has the login). Longer Python: an ssh heredoc (`ssh ... python3 - <<'EOF' ... EOF`).

## The client data, and the server's overrides

DB2 files: `/home/wow/data/dbc/enUS/`, read with `~/client_parts/wdc1.py`:

```python
import sys; sys.path.insert(0, "/home/wow/client_parts")
import wdc1, pickle
rows = wdc1.read("/home/wow/data/dbc/enUS/SpellEffect.db2")   # {id: [fields...]}
names = pickle.load(open("/tmp/spellnames.pkl", "rb"))        # {spellId: name}
```

- **The `hotfixes` database overrides the DB2 files** at load (`DB2Stores.cpp` LoadFromDB): e.g.
  `mysql hotfixes -e "SELECT ID, Effect, EffectAura, EffectIndex, SpellID FROM spell_effect WHERE SpellID IN (...)"`
  (also `spell`, `spell_misc`, `spell_aura_options`, `talent`, `artifact_power`, `summon_properties`). Check it before
  trusting the file.
- `/tmp/spellnames.pkl` is lost when the server reboots: `PYTHONPATH=~/client_parts python3 ~/client_parts/spellnames.py`.
- Item data: `~/client_parts/itemsparse.py` (-> /tmp/itemsparse.pkl); wdc1 can't read offset-map files (ItemSparse,
  ConversationLine, SceneScriptText). Strings come back as string-table offsets (see spellnames.py).
- Floats come back as their raw 32-bit pattern (`1065353216` = 1.0). Arrays wider than 32 bits come back as lists;
  smaller ones as one packed int.
- Field positions follow the struct in `src/server/game/DataStores/DB2Structure.h`, **minus the ID** when the file keeps
  IDs in a separate list, **plus the parent/relation key appended last** when the file has one. Check one known row
  before trusting an index.

| File | List index |
|---|---|
| SpellEffect.db2 (ID inline, keyed by effect row) | 0 ID, 1 Effect, 2 BasePoints, 3 EffectIndex, 4 EffectAura, 5 DifficultyID, 7 EffectAuraPeriod, 16 EffectTriggerSpell, 26 MiscValue[2], 27 RadiusIndex[2], 28 ImplicitTarget[2], 29 SpellID (relation). Scan for `v[29] == spell`; one row per (EffectIndex, DifficultyID) |
| Talent.db2 (ID not in list) | 0 Description, 1 SpellID, 2 OverridesSpellID, 3 SpecID (0 = every spec of the class), 4 TierID (row - 1), 5 ColumnIndex, 8 ClassID |
| ArtifactPower.db2 | 1 ArtifactID, 2 Flags, 3 MaxPurchasableRank, 4 Tier (0 = first tier, 1 = second), 5 ID (see fill_character.py) |
| ArtifactPowerRank.db2 (ID not in list) | 0 SpellID, 1 AuraPointsOverride, 2 ItemBonusListID, 3 RankIndex, 4 ArtifactPowerID; RankIndex 0 = the trait's spell |
| SummonProperties.db2 (ID not in list) | 0 Flags, 1 Control, 2 Faction, 3 Title, 4 Slot |

Numbers: effects 2 SCHOOL_DAMAGE, 3 DUMMY, 6 APPLY_AURA, 28 SUMMON, 30 ENERGIZE, 64 TRIGGER_SPELL, 77 SCRIPT_EFFECT,
179 CREATE_AREATRIGGER; auras 4 DUMMY, 226 PERIODIC_DUMMY.

- **Talents**: per class/row/column the core takes the first talent (ID order) whose SpecID is the player's current
  spec, else the last SpecID-0 one; any other talent ID at that position is refused (`Player::LearnTalent`).
- **ArtifactPower flags** (Item.h): 0x01 GOLD, 0x02 NO_LINK_REQUIRED (the starter trait has a free rank), 0x04 FINAL
  (Tier 1 = Concordance of the Legionfall, max 50; Tier 0 = the first tier's final trait, max 20, stays at 1 after the
  unlock), 0x08 SCALES_WITH_NUM_POWERS, 0x10 DONT_COUNT_FIRST_BONUS_RANK, 0x20 HAS_RANK (Tier 0 only: a 4th rank once
  the second tier is unlocked), 0x40 RELIC_TALENT.

## Where spell behaviour hides in the world DB

Spells are often wired by tables, not code. Negative ids are real (fire on aura remove, or "every rank"), so match
both signs. `option` and `group` are reserved words: backtick them.

```sql
SELECT * FROM spell_script_names WHERE ABS(spell_id) IN (...);          -- C++ SpellScript/AuraScript name
SELECT * FROM spell_linked_spell WHERE ABS(spell_trigger) IN (...) OR ABS(spell_effect) IN (...);
SELECT spell_id, spell_trigger, `option`, effectmask FROM spell_dummy_trigger WHERE spell_id IN (...) OR ABS(spell_trigger) IN (...);
SELECT spell_id, spell_trigger, `option`, effectmask FROM spell_aura_trigger WHERE spell_id IN (...) OR ABS(spell_trigger) IN (...);
SELECT spell_id, spell_trigger, `option` FROM spell_trigger WHERE spell_id IN (...) OR ABS(spell_trigger) IN (...);
SELECT spellId, spellDummyId, type, `option` FROM spell_aura_dummy WHERE spellId IN (...) OR ABS(spellDummyId) IN (...);
SELECT * FROM spell_visual WHERE spellId IN (...);                     -- world.spell_visual, not hotfixes.spell_visual
```

- `effectmask` = a bit per effect index (1 = effect 0, 2 = effect 1, 4 = effect 2, 8 = effect 3).
- More tables with spell columns: `spell_proc`, `spell_proc_event`, `spell_proc_check`, `spell_pet_auras` (only real
  pets), `spell_concatenate_aura`, `spell_check_cast`, `spell_target_filter`, `spell_trigger_delay`,
  `spell_pending_cast`, `spell_talent_linked_spell`, `spell_scripts`, `spell_bonus_data`, `spell_target_position`,
  `spell_area`. Area triggers (effect 179): `areatrigger_template`, `areatrigger_data`, `areatrigger_actions`.
- Hardcoded: `ApplySpellFix` in `SpellMgr.cpp`, and switches in `SpellEffects.cpp`, `SpellAuraEffects.cpp`, `Unit.cpp`:
  `grep -rn "<spellId>" src/server`.
- Trap: at startup the loader deletes `spell_script_names` rows whose spell doesn't exist, so a row for an unknown
  spell disappears silently.

## Creatures (summons, adds)

`creature_template` has no model or name columns here: display and name are in `creature_template_wdb`
(`Displayid1..4`, `Name1`), equipment in `creature_equip_template`. `creature_template_addon` = entry, path_id, mount,
bytes1 (stand state), bytes2 (low byte = sheath state), emote, auras. Any addon row, even all zeros, skips the default
melee sheath in `Creature::UpdateEntry`. Summon rules: SummonProperties (table above) plus `TemporarySummon.cpp` slot
overrides and the per-entry hooks in `Spell::SummonGuardian` (`SpellEffects.cpp`).

## Example: Warrior Ravager (issue #51)

152277 (Arms) and 228920 (Prot) don't summon anything themselves: `spell_dummy_trigger` (effectmask 8 = effect 3)
casts 227876, which summons 76168 at the spot (SummonProperties 4089); `spell_aura_trigger` gives rage (152277 ->
248439); `spell_script_names` has `spell_warr_ravager` on 227876 (ticks the damage 156287 from each summon) and
`spell_warr_ravager_t20` on 156287; `spell_visual` has 227876; `ApplySpellFix({227876})` in SpellMgr.cpp; the visual
needed the owner's weapon in the summon's hand (display 56304 is an empty rig that only draws the right-hand item) in
`Spell::SummonGuardian`; the red trail/circle is only in display 55644 (Warrior_Ravager.m2, 56304 is
Warrior_Ravager_notrail.m2), set by aura 177466 (`spell_warr_ravager_visual`) from `creature_template_addon.auras`
(its `spell_pet_auras` rows never apply: the Ravager is a guardian, not a pet). Check every place.
