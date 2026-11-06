# Diagnosis: arena_gate_integration

base_commit: `f93880d28afbf3f3d1966c627463cbfca351a444`.

## How I ran it

From `/work`:

```
tools/run_tests.sh --headless arena_gate_integration
```

Godot 4.7.2. Runner summary at base_commit:

```
FAIL    quarantine arena_gate_integration
---
      1 FAIL quarantine
=== quarantine arena_gate_integration: exit 1, last 30 lines of test.log

ARENA PASS entry stays clear until whole player crossed
ARENA FAIL active encounter locks entry
ARENA FAIL gate physically blocks return
ARENA PASS death opens entry and resets living boss
ARENA FAIL death preserves reachable cache
ARENA FAIL cache reclaim still works
ARENA FAIL new attempt locks again
ARENA PASS boss defeat releases entry
ARENA PASS no invisible postfight barrier
ARENA SUMMARY failures=5
```

A temporary local probe (not submitted) printed the runtime values quoted below.

## Failing checks

| check | test expects (file:line) | game does (evidence) | verdict |
|---|---|---|---|
| active encounter locks entry | `game/tests/arena_gate_integration.gd:16-21`: with the boss active, moving to x=46.6 makes the gate locked and visible. | The route places the gate at `entry_x=BOSS_ENTRY_X-0.35`, i.e. 69.65 (`game/lab_route.gd:120`; `game/modules/world/notstrom_layout.gd:5` has `BOSS_ENTRY_X=70.0`). `close_x` is `entry_x+0.85`=70.5 (`game/modules/combat/arena_gate.gd:5-6`), and locking requires `player_x>=close_x` (`arena_gate.gd:23-24`). Probe at x=46.6: `locked=false layer=0 visible=false`. Rule: test intent uses the legacy 46.5 boundary (`arena_gate.gd:3`); `docs/milestone-1.md:32` puts the arena gate at x=70. | test-stale |
| gate physically blocks return | `game/tests/arena_gate_integration.gd:27-28`: a layer-1 ray from (46.2,1,0) to (45,1,0) hits the gate. | The gate body is at entry_x 69.65 (`game/modules/combat/arena_gate.gd:11`) and only gets collision layer 1 while locked (`arena_gate.gd:12,24`). Probe: `ray x46.2->45 empty=true`. After moving the player to x=70.6 the gate locks and the equivalent ray (70.2,1,0)->(69,1,0) hits (`empty=false`). Rule: the test ray still probes the legacy room; `docs/milestone-1.md:32` puts the gate at x=70. | test-stale |
| death preserves reachable cache | `game/tests/arena_gate_integration.gd:29-32`: after shards=7, `_last_grounded` at x=47 and `route.on_player_death()`, the cache holds 7 at x=47. | `on_player_death()` releases the gate, resets the overseer and saves, but never calls `death_cache.replace()` (`game/lab_route.gd:1101-1114`). `game/modules/loot/death_cache.gd:2` says the cache is legacy compatibility only and new farming deaths retain the wallet. Probe: `amount=0 active=false pos=(0,0,0)`, `shards=7`. Rule: test intent assumes the old death-drop; current design `docs/design/farming-design-v02.txt:168-173` keeps collected resources, and `docs/milestone-1.md:40` only requires a death cache to be recoverable once when one exists. | test-stale |
| cache reclaim still works | `game/tests/arena_gate_integration.gd:33-34`: at x=47, `route.reclaim_shards()` returns true and shards become 7. | `reclaim_shards()` refuses when the cache is inactive (`game/lab_route.gd:1121-1122`). Because death created no cache, the probe gives `reclaim=false`, `shards=7` unchanged. The reclaim path itself works for a legacy active cache (`game/tests/death_cache_integration.gd:42-51`). Rule: test intent assumes death created a cache; current policy creates none (`game/lab_route.gd:1110-1111`, `game/modules/loot/death_cache.gd:2`). | test-stale |
| new attempt locks again | `game/tests/arena_gate_integration.gd:33-37`: after death the player stays at x=47, then `boss.active=true` must lock the gate. | The player is still at x=47, below `close_x`=70.5, and locking requires `player_x>=close_x` (`game/modules/combat/arena_gate.gd:23`). Probe with the player at x=70.6 after death: `second attempt locked=true`, so the gate logic works in the real arena. Rule: test intent uses the legacy arena position; `docs/milestone-1.md:32` puts the gate at x=70. | test-stale |

## Root causes

**1. Stale arena coordinates (rows 1, 2 and 6).** The test hard-codes the legacy room: player x=46.1/46.6/47 and a return ray at x=46.2->45 (`arena_gate_integration.gd:16,19,27,29,33`). The arena moved to the airlock: `BOSS_ENTRY_X=70` (`game/modules/world/notstrom_layout.gd:5`), gate at 69.65 (`game/lab_route.gd:120`) closing at 70.5 (`game/modules/combat/arena_gate.gd:5-6`), overseer at 73 (`notstrom_layout.gd:4`). Probe values confirm the gate stays open at 46.6 and locks and collides at 70.6. This one stale assumption produces all three gate failures. It also makes the gate side of all four passes vacuous: "entry stays clear until whole player crossed", "death opens entry", "boss defeat releases entry" and "no invisible postfight barrier" all observe an already-open gate, so none exercises the closed state.

**2. Stale death-cache policy (rows 4 and 5).** The test assumes every death creates a shard cache at the last grounded position. Since farming v0.2 the game deliberately retains the wallet on death; only caches from the old policy remain reclaimable. `on_player_death()` contains no `death_cache.replace()` call (`game/lab_route.gd:1101-1114`), and `game/modules/loot/death_cache.gd:2` states that new farming deaths retain the wallet. The accepted headless `death_cache_integration` asserts exactly this (`game/tests/death_cache_integration.gd:35,42-51`). The probe's `amount=0`, `active=false` and failed reclaim are therefore expected current behaviour, not a reclaim bug.

No check failed from a crash or missing node, so none is a harness problem. No gate or reclaim logic failed when driven with current coordinates and a seeded cache, so I found no game bug in the arena boundary itself. Note a documentation conflict: `docs/glossary.md:22` and `docs/gdd.md:30-31` still describe shards dropped at death, while `docs/design/farming-design-v02.txt:168-173` and the current code keep them. If neVs wants the old drop rule back, that is a design change, not a repair of this test.

## Proposed fixes

- `game/tests/arena_gate_integration.gd`, `run()`: move the player to positions around the real entry (below 70.5, then above it) instead of 46.1/46.6 so the lock check runs against the airlock gate.
- `game/tests/arena_gate_integration.gd`, `run()`: move the return-block ray to the real gate at about x=70 instead of 46, ideally derived from the gate's `close_x`.
- `game/tests/arena_gate_integration.gd`, `run()`: rewrite the cache assertion to the current farming policy (shards stay 7, cache inactive) or, only after an explicit neVs decision to restore death-drop, assert the cache that `on_player_death()` would then create.
- `game/tests/arena_gate_integration.gd`, `run()`: seed an active legacy cache through the death cache's replace method before testing `reclaim_shards()`, as `death_cache_integration` does.
- `game/tests/arena_gate_integration.gd`, `run()`: set the boss active only after placing the player at or beyond the real closing position so the new-attempt check exercises `update_encounter()` in the real arena.
