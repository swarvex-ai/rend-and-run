# Diagnosis: service_return_integration

base_commit: `b40d28d410f1e1eadd3addb6e83a054b69fbb036`. This snapshot has no `.git`, so the commit could not be re-resolved locally.

## How I ran it

From `/work`:

```
tools/run_tests.sh --headless service_return_integration
```

Godot 4.7.2. Runner summary at base_commit:

```
FAIL    quarantine service_return_integration
---
      1 FAIL quarantine
=== quarantine service_return_integration: exit 1, last 30 lines of test.log
RETURN FAIL completion remains available before return
RETURN FAIL E input starts lift with rider
RETURN FAIL actual player reaches upper level
RETURN FAIL full physical return reaches first room alive
RETURN POSITION (54.67888, 0.000325, 0.0)
RETURN FAIL upper landing can call lift from safe catwalk
RETURN FAIL upper recall arrives without moving waiting player
RETURN FAIL legacy completion restores access without new unlock flag
RETURN SUMMARY failures=7
```

Temporary local probes (not submitted) printed the values quoted below.

## Failing checks

| check | test expects (file:line) | game does (evidence) | verdict |
|---|---|---|---|
| completion remains available before return | `game/tests/service_return_integration.gd:19-22`: clearing `first`, `duelist`, `guard` and killing the overseer, then standing at x=56, completes the route and pauses. | Probe: `gate=false cleared=["first","duelist","guard","brute"] completed=false paused=false p=(56,0,0) exit=79 lift_x=80`. `_enemy_defeated()` opens the gate only with all eight ids (`game/lab_route.gd:437-438`; `game/modules/world/notstrom_layout.gd:25-28`); completion also needs `x>EXIT_X=79` (`game/lab_route.gd:315-316`). The setup has 4/8 ids and stands at 56. | test-stale — judged against the V12 route's eight encounters (`notstrom_layout.gd:9-17`) and exit at 79 (`notstrom_layout.gd:6`; `docs/milestone-1.md:32`). |
| E input starts lift with rider | `game/tests/service_return_integration.gd:24-26`: E at x=56 sets `target_y=5` and lifts the player above y=1.2. | Probe: `target=0 lift=(80,0,0) p=(56,0,0) prompt="" completed=false`. The route overrides `lift_x` to `EXIT_X+1=80` (`game/lab_route.gd:123`), so `_station()` rejects 56 (`game/modules/world/service_return.gd:30`). E is routed to the lift only while `completed` (`game/lab_route.gd:253-255`), which row 1 never reaches. | test-stale — judged against `lab_route.gd:123` and `service_return.gd:30`; x=80 is already asserted by `expanded_world_integration.gd:16` and `mission_extent_integration.gd:18`. |
| actual player reaches upper level | `game/tests/service_return_integration.gd:30-31`: after the ride the player is on the floor near y=5. | Probe: `target=0 lift=(80,0,0) p=(56,0,0) floor=true`; the ride never began. A probe on the real platform called `interact()` at x=80 and saw `target=5`, `p=(80,1.57)` after 1 s, `p=(80,5.00)` on the floor after 3.2 s. | test-stale — downstream of rows 1-2 and stale x. Judged against the lift body and motion (`service_return.gd:18-19,27-28`) and station rules (`service_return.gd:30-32,46`); carrying works at the real endpoint. |
| full physical return reaches first room alive | `game/tests/service_return_integration.gd:37-39`: 7.9 s of move-left ends at x<1.5, y<0.1, alive. | Probe from x=56 on the ground: `(54.68,0,0)`, stopped near the freight crate because no ride happened. A probe from the real upper lift at x=80 reached x=19.38 after 12 s and x=-3.40 (alive, on floor) after 20 s. | test-stale — judged against `service_return.gd:4,20-21`: the catwalk is 78.5 m (1.5 to 78.8). At `move_speed=7.5` (`game/player.gd:27`), 7.9 s covers only about 59 m. |
| upper landing can call lift from safe catwalk | `game/tests/service_return_integration.gd:49-53`: at (54.5,5.08) E sets `target_y=5`. | Probe: x=54.5 gives `_station()=-1` because `lift_x=80`, so `target_y` stays 0. At the real catwalk edge (78.4,5.08): prompt `E / Y — Aufzug rufen`, `interact=true`, `target=5`. | test-stale — judged against the station radius `abs(x-lift_x)<=1.6` (`service_return.gd:30`) with lift at 80 (`lab_route.gd:123`); the safe edge is 78.8 (`service_return.gd:21`). |
| upper recall arrives without moving waiting player | `game/tests/service_return_integration.gd:54-55`: after 3.4 s lift is at y=5 and the waiting player is on the floor at y=5. | Because row 5 never called the lift: `lift=(80,0,0) target=0`; the player stands at (54.5,5.08) but no lift arrives. At (78.4,5.08) the corrected probe shows `lift=(80,5)` after 3.4 s, player `(78.4,5.001)` on the floor and unmoved. | test-stale — downstream of row 5. Judged against `service_return.gd:45`: an upper call sets `target_y=station`; only the lift moves (`service_return.gd:27-28`). |
| legacy completion restores access without new unlock flag | `game/tests/service_return_integration.gd:56-59`: save, reload, then `completed`, `service_return.unlocked` and shards match. | Probe after reload: `completed=false unlocked=true cleared=["first","duelist","guard","brute"] shards=3 expected=3`. Row 1 never set completion, so `_save_progress()` writes `completed=false` (`game/lab_route.gd:556`) and `_restore_progress()` reads it back (`game/lab_route.gd:532`); unlock comes from `"brute" in cleared` (`game/lab_route.gd:125`); shards match. | test-stale — judged against save rules `lab_route.gd:532,556` and unlock rule `lab_route.gd:125`; only the completion from row 1 is missing. |

## Root causes

**1. Stale lift endpoint and coordinates (rows 1-6).** The test still uses x=56/54.5 for the lift, its catwalk point and completion. Today `lift_x=MISSION.EXIT_X+1=80` (`game/lab_route.gd:123`; `notstrom_layout.gd:6`), and the catwalk runs from 1.5 to `lift_x-1.2=78.8` (`game/modules/world/service_return.gd:4,20-21`). At 56 `_station()` returns -1 (`service_return.gd:30`), so every later ride assertion collapses. x=56 is now the `freight_duelist` encounter (`notstrom_layout.gd:15`). Probes at the real platform showed the lift starting, carrying the rider to y=5, returning along the catwalk and answering an upper call at 78.4. `expanded_world_integration.gd:16` and `mission_extent_integration.gd:18-19` already assert the x=80 endpoint and upper call, so I found no game bug in lift motion, carrying or station logic.

**2. Stale completion setup (rows 1, 2, 7).** The test clears only `first`, `duelist`, `guard` and the overseer and expects completion at 56. The route needs all eight ids to open the gate (`lab_route.gd:437-438`; `notstrom_layout.gd:9-28`) and `x>79` to set `completed` (`lab_route.gd:315-316`). With four ids the gate stays shut, the summary never opens, and E never reaches the lift because that branch needs `completed` (`lab_route.gd:253`). The reload check then saves `completed=false`, so row 7 follows from row 1; the save path itself round-trips correctly.

**3. Stale return timing (row 4).** Even with the endpoint corrected, 7.9 s is too short for 78.5 m; the probe needed about 16-20 s. This is independent of the failed ride.

**Downstream effects.** Rows 3 and 6 fail only because the ride/call never starts. Row 4 is partly downstream but has its own timing error. Row 5 fails on its own wrong coordinate. Row 7 is downstream of row 1, not row 2.

**Reachability in the current route.** The lift exists at x=80 on the foundation under the airlock (x up to 83, `lab_route.gd:578,585`). Prerequisites: all eight encounters cleared to open the exit gate (`lab_route.gd:437-438`), `completed` from crossing x>79 (`lab_route.gd:315-316`), and `unlocked` from `"brute" in cleared` (`lab_route.gd:125,423`). The summary pauses once at that crossing; after resuming, the player can walk to 80. The prompt is exposed only after `completed` (`lab_route.gd:253`). So the lift is reachable only after a fully completed run, not from the old x=56 area. Caveat: `unlocked` is recomputed from `cleared`, and migration adds `NEW_IDS` but not `brute` (`game/modules/persistence/notstrom_save_migration.gd:15-27`), so a completed legacy save without `brute` would restore completion but not unlock the lift. The test does not construct that case because `_enemy_defeated(overseer)` adds `brute`.

## Proposed fixes

- `game/tests/service_return_integration.gd`, `run()`: derive all lift positions from `r.service_return.lift_x` (80) instead of 56/54.5, using `lift_x-1.2` for the safe catwalk edge.
- `game/tests/service_return_integration.gd`, `run()`: clear all eight ids and place the player beyond `MISSION.EXIT_X=79` before expecting completion and the summary.
- `game/tests/service_return_integration.gd`, `run()`: replace the fixed 7.9 s walk with a distance-derived timeout for the `lift_x-return_start_x` catwalk.
- `game/tests/service_return_integration.gd`, `run()`: after fixing completion, save and reload the real state; for legacy access, construct a genuine layout-revision-1 completed save instead of the current scene.
- `game/lab_route.gd`, `_ready()`/`_restore_progress()`: if completed legacy runs without `brute` should keep return access, derive `service_return.unlocked` from `completed or "brute" in cleared`; otherwise keep the current rule and document it.
