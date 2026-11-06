# Diagnosis: feedback_priority_integration

base_commit: `af4b9fb1e6ae2a81fd809cbcbee75e7c9a450c54`.

## How I ran it

From `/work`:

```
tools/run_tests.sh --headless feedback_priority_integration
```

Godot 4.7.2. Runner summary at base_commit (one check red):

```
FAIL    quarantine feedback_priority_integration
---
      1 FAIL quarantine
=== quarantine feedback_priority_integration: exit 1, last 30 lines of test.log
H54 INTEGRATION PASS save warning survives block
H54 INTEGRATION FAIL supply reward cannot hide save warning
H54 INTEGRATION PASS parry replaces routine hint
H54 INTEGRATION PASS hint cannot replace combat feedback
H54 INTEGRATION PASS latest combat outcome replaces old outcome
H54 INTEGRATION PASS discarded hints do not replay
H54 INTEGRATION PASS completion survives routine combat feedback
H54 INTEGRATION failures=1
```

A temporary local print (not submitted; the test file is back at base_commit) reported after `_on_supply_broken("entry_supply",3,Vector3.ZERO)`: `toast=Speichern fehlgeschlagen toast_time=5.0 shards=0 pending={ "entry_supply": 3 } pickups={ "entry_supply": ShardPickup_entry_supply } save_error=false`.

## Failing checks

| check | test expects (file:line) | game does (evidence) | verdict |
|---|---|---|---|
| supply reward cannot hide save warning | `game/tests/feedback_priority_integration.gd:15`: after `_on_supply_broken()` the toast is still `"Speichern fehlgeschlagen"` **and** `shards==3`. | The toast part passes: the save warning set at `:12` has priority 3, the block feedback offered at `game/lab_route.gd:802` has priority 2 and is discarded by `game/modules/ui/feedback_priority.gd:26-27` (lower priority while an equal/higher one is active); `_message()` (`game/lab_route.gd:366-370`) only copies accepted offers. `_on_supply_broken()` (`:759-765`) emits no reward message at all; it stores `pending_shards["entry_supply"]=3` (`:763`), saves, and spawns a pickup (`:765`). Shards are credited only when the pickup reaches Rend (`:781`), and the reward message is offered later with priority 1 (`:789`). Probe: `shards=0`, `pending={"entry_supply":3}`, pickup present. | test-stale (not a game bug): the rule "a supply reward must never replace an active save warning" holds in the priority model, but the test still assumes crate breaking credits shards immediately instead of creating a pickup. |

## Root causes

The priority model behaves as specified: `offer()` rejects a lower-priority message while a higher one is active (`game/modules/ui/feedback_priority.gd:26-27`), and `_message()` (`game/lab_route.gd:366-370`) only updates `toast` for accepted offers. The save warning (priority 3) therefore survives both the block feedback (priority 2) and any later supply-reward message (priority 1). A save-failure message on pickup collection is still offered at priority 3 (`:790`), so it would replace a reward, never the reverse.

The failing assertion combines that passing message check with a stale reward model. Supply crates became a two-stage reward: `_on_supply_broken()` records the amount in `pending_shards` and spawns a `shard_pickup` (`game/lab_route.gd:759-765`); `shards` is incremented only in `_collect_shard_pickup()` when the pickup is reached (`:776-781`). The test calls only the break handler, so `shards` stays 0 and the combined check fails, even though the warning text is unchanged at priority 3.

## Proposed fixes

`game/tests/feedback_priority_integration.gd`, `run()`: after `_on_supply_broken()`, assert the pending reward (`r.pending_shards["entry_supply"]==3`) and the unchanged priority-3 warning, or call `r._collect_shard_pickup("entry_supply")` before asserting `r.shards==3`.
