# Dungeon bots (#140)

Owner request 2026-10-01: bots level up by running dungeons and report the bugs they find there. Level 15 or higher,
with the spells and talents a character of that level and spec has. A group is 1 tank, 1 healer and 3 DPS; when a real
player signs up, one bot is replaced by the player.

Built on the party bots (#65, `src/server/game/PartyBot/`): `PartyBotSession` (a socketless WorldSession),
`PartyBotAI` (follow a leader, fight what the leader fights, tank taunts, healer heals, spec rotations from
`world.partybot_spells`, talents from `world.partybot_talents`), `LFGMgr::AnswerForBot` (bots answer the role check
and accept the proposal), and the quest-test bot (`QuestBot.cpp`: logging style, `MoveTo`, `StandStill`, stuck
detection).

## Phases

1. **GM test runs.** `.partybot dungeontest <dungeon id | name | random> [level] | stop`: five bots of that level
   (default 15, never below the dungeon's minimum or 15) form a group with the tank as leader, queue through the
   Dungeon Finder, get teleported in, and clear the dungeon on their own. Every boss and every problem goes to the log.
2. **Leveling loop.** The same five bots keep their characters: after a run they queue for the next dungeon of their
   level (random dungeon). They level from kills and the dungeon reward and learn their new spells and talent rows.
3. **Dungeon Finder fill for players.** A real player who queues gets bots for the missing roles. This is
   player-facing: it is built behind a switch that stays off until the owner turns it on after phase 1 works.

## Pieces and who builds them

| Piece | File(s) | Owner |
|---|---|---|
| A. Bot at any level: spec, spells, talent rows, gear | `PartyBot.cpp/.h` (setup functions only) | dev-owner subagent (needs server data) |
| B. Dungeon leader AI: route, pulls, wipes, bug log | `DungeonBotAI.cpp` (new) | help-helper (+ subagents) |
| C. Run manager: command, group, Dungeon Finder, loop, session mode | `DungeonRun.cpp` (new), `cs_partybot.cpp`, session bits in `PartyBot.cpp/.h` | dev-owner subagent |
| D. Phase 3 player fill | later, `DungeonRun.cpp` + `LFGMgr` | after phase 1 |
| Reviews / build / restart / integration | | dev-check / dev-owner |

New `.cpp` files need `cmake .` in `~/LegionCore/build` before the next build (dev-owner does it).

## Interfaces (add to `PartyBot.h`, each piece in its own marked block)

```cpp
// A (PartyBot.cpp): a bot character of this spec at this level (>= 10) on a free partybot account, faction by the
// race. Its first login sets the level, the spec, the spells of that level (class + spec), the talents of every
// unlocked row (world.partybot_talents, rows above the level skipped) and level-scaling gear (heirlooms) for the spec.
// Returns an error text, empty on success; guid = the new character.
std::string CreateLevelBot(uint32 specId, uint8 level, bool alliance, std::string& name, ObjectGuid& guid);
// A: after a level-up of a bot (dungeon or quest test): learn the talent row that just opened.
static void OnBotLevelUp(Player* bot);

// B (DungeonBotAI.cpp): the tank's AI in a dungeon run. The four others keep PartyBotAI with the tank as leader.
PlayerAI* NewDungeonLeaderAI(Player* tank, uint32 runId);

// C (DungeonRun.cpp): called by B when the run is over (all bosses dead, or given up); C logs out / requeues.
void DungeonRunEnded(uint32 runId, bool cleared, std::string const& reason);
```

C creates the sessions in a dungeon mode (`PartyBotSession` gets the run id and the role; the tank's AI comes from
`NewDungeonLeaderAI`, the others' from `PartyBotAI(bot, tankGuid, slot)`), so B never creates or removes sessions.

## B: the leader AI (what "clear the dungeon" means)

- Wait at the entrance until all five are in the map and alive (after the Dungeon Finder teleport).
- **Route:** the dungeon's bosses in encounter order. Runtime data: the map's creature spawns whose template is a
  dungeon boss (the encounter creatures of `DungeonEncounter` / the InstanceScript's boss data, or the boss rank /
  flags), with their spawn positions; skip bosses already dead (`InstanceScript::GetBossState == DONE`).
- **Walk** to the next boss with pathfinding (like `QuestBotAI::MoveTo`), slowly enough for the group to follow.
- **Pull:** hostile creatures within ~20 yd of the path ahead are attacked one pack at a time; wait until out of
  combat, then for the healer above 70% mana and everyone above 70% health before the next pull.
- **Wipes:** everyone dead -> resurrect all five at the dungeon entrance (`ResurrectPlayer` + teleport to the
  instance's entrance position), count the wipe for that boss; 3 wipes on the same boss -> log it and end the run.
  One dead bot while others live: it resurrects next to the tank after the fight (like party bots do now).
- **Stuck:** no progress toward the next boss for 60 s, or no path -> log it, try the next boss, end if none left.
- **End:** all bosses dead (or the Dungeon Finder reward came) -> `DungeonRunEnded(runId, true, ...)`.

### Log (logger `server.questbot`, same style as the quest bot)

```
DUNGEONBOT event=<start|pull|wipe|resurrect|stuck|...> run=<id> dungeon=<lfg id> map=<id> bot=<tank name> ...
DUNGEONBOT run=<id> dungeon=<id> "<name>" boss=<entry> "<name>" result=KILLED|WIPE|EVADE|STUCK|NO_PATH|NOT_FOUND time=<s> level=<n> wipes=<n> detail=<...>
DUNGEONBOT run=end run=<id> dungeon=<id> cleared=<0|1> bosses=<killed>/<total> wipes=<n> time=<s> reason=<...>
```

What counts as a likely dungeon bug (the detail should make it clear): a boss that evades or resets every pull, a boss
or trash that can't be damaged, a boss whose death doesn't set its encounter DONE, a door that stays closed after a
boss (the next boss unreachable), a boss that is never spawned, the Dungeon Finder reward missing after the last boss.
Wipes alone are not bugs (bots can be weak); the log says how the wipe happened (boss health %, who died first).

## A: the bot at a level

- Level: `GiveLevel(level)`; spec at 10+ (`ActivateTalentGroup`); check what the core learns by itself on a level
  change (class and spec spells from SkillLineAbility / SpecializationSpells) and add what is missing.
- Talents: `partybot_talents` rows for the spec, only rows whose tier is unlocked at the level (Legion: 15, 30, 45,
  60, 75, 90, 100).
- Gear: level-scaling heirlooms per armor type and primary stat (check that heirloom scaling works in this core), a
  weapon for the spec. Bots don't need loot.
- Rotation: the spec's `partybot_spells` already skips spells the bot doesn't know (`TryCast` checks `HasSpell`);
  below level 10 the quest bot's starter table. Check that each tank/healer spec has at least its core spells at 15.

## C: the run

- Specs: tank and healer of the faction (e.g. Protection Paladin / Holy Paladin for Alliance, Protection Warrior /
  Restoration Druid ...), 3 different DPS specs. New characters for each run, or reuse idle ones of that level.
- Group: tank leader; the group joins the Dungeon Finder for the dungeon (or random of the level) with each member's
  role; `AnswerForBot` answers the role check and the proposal; the Dungeon Finder teleports them in.
- Phase 2 loop: after `DungeonRunEnded`, leave the dungeon, queue again for the level's random dungeon.
- Cap: a few runs at a time (all instances share one map-update thread, `MapUpdate.Threads = 1`).
- `.partybot dungeontest stop` ends every run (sessions dismissed).
