# Diagnosis: route_v12_test

## How I ran it

base_commit: `540c4d467817b1aebea80e4aab10910c8a7a78df`. From `/work`:

```
tools/run_tests.sh --headless route_v12_test
```

Runner summary at base_commit, identical on two runs:

```
FAIL    quarantine route_v12_test
---
      1 FAIL quarantine
```

The test log ends with `V12 SUMMARY checks=15 failures=6`. The six red checks are the ones in the table below. Temporary local probes (not submitted) copied the test, changed only the assumptions in the table, and restored the file byte-for-byte (md5 `005a9ec929e8836d3f9df875708fd11a`).

## Failing checks

| check | test expects (file:line) | game does (evidence) | verdict |
|---|---|---|---|
| four authored encounters, no wave spawner | `game/tests/route_v12_test.gd:20`: `route.enemies.size()==4`. | The spawn loop adds one enemy per non-cleared id in `MISSION.ENCOUNTERS` (`game/lab_route.gd:154-167`). `ENCOUNTERS` now has eight entries, including `brute` (`game/modules/world/notstrom_layout.gd:9-18`); the M1 route table also lists eight mission beats (`docs/milestone-1.md:28-32`). Probe: `PROBE enemy_count 8`. The count still affects the gate, because `all_cleared()` iterates all eight ids (`notstrom_layout.gd:25-28`) and only then opens it (`lab_route.gd:437-439`). | test-stale |
| attack actually changes arm pose | `game/tests/route_v12_test.gd:32`: the right-arm quaternion must change by more than 0.2 rad between windup and strike, sampled through `mixamorig_RightArm` (`:29-32`). | Every robot is mechanical (`game/enemy.gd:181`), and its rig uses the unprefixed bone `RightArm` (`enemy.gd:243`; strike tracks at `game/generated/robot_strike_motion.tres:99`). `find_bone("mixamorig_RightArm")` returns `-1` (log: `Index p_bone = -1 ... bone_size = 26`), so both samples fall back to identity and the angle is 0. Probe with `RightArm`: bone index 14 and angle `0.36` (> 0.2), while `_update_weapon_pose` seeks the strike clip (`enemy.gd:673-678`). | harness |
| upper detour reachable with actual jumps | `game/tests/route_v12_test.gd:48`: after jumps to x=11/14/18 the player must finish near x=18 and above y=2.3. | The old `Ground`/`Plat1`/`Plat2`/`Plat3` nodes are deleted at startup (`game/lab_route.gd:103-107`), and the route is a continuous foundation at y=-0.3..0 (`lab_route.gd:578-583`) with no platform in that span. Probe logs `TRAVERSE 18.0 (18.22543, 0.000797, ...)`, so the player is on the floor at y≈0. The M1 route table has no upper detour in zones 01-04 (`docs/milestone-1.md:28-32`); the upper deck belongs to the service return at the airlock. | test-stale |
| death preserves equipment and returns to checkpoint | `game/tests/route_v12_test.gd:60`: 1.5 s after lethal damage, `_dying` is false, `max_hp==7`, `hp==7` and x is near the checkpoint at 26 (`:59-60`). | `main._on_player_died()` waits 2.4 s before resetting HP and moving the player to `spawn_point` (`game/main.gd:117-120`), so at 1.5 s Rend is still dying with negative HP. Probe with a 3.0 s wait: `dying=false hp=7 max_hp=7 pos=(26.0,...) spawn=(26.0,...)`. `on_player_death()` preserves the equipment and saves (`lab_route.gd:1101-1114`); the checkpoint interaction sets `spawn_point` to `checkpoint_pos` (`lab_route.gd:308`), which `_ready` applies (`:170`). The death-to-checkpoint rule works within M1's < 10 s target; the test wait is too short. | harness |
| all guards defeated opens actual gate collision | `game/tests/route_v12_test.gd:65`: after setting every `route.enemies` member to hp=1 and one light hit (`:62-64`), `gate_open` is true and the `Collision` shape is disabled. | The test disabled physics for all enemies at `:24` and only re-enabled the first foe at `:35`. The overseer ignores damage unless active (`game/modules/combat/lab_overseer.gd:65`), and it activates only in `_physics_process` when the player is at or past `ADMISSION_X` 70 (`lab_overseer.gd:24-34`; `notstrom_layout.gd:5`). In addition, the two shield bearers block one light frontal hit (`game/enemy.gd:702-705,941-942`). The base run therefore clears only five ids and the gate stays closed. Probe after re-enabling the overseer's physics, moving to x=71 and removing the shields: all eight ids are cleared and `gate_open=true`, `disabled=true`. `_enemy_defeated` does call `_open_gate()` when `all_cleared()` is true (`lab_route.gd:437-439,466-469`). | test-stale |
| reaching exit completes route | `game/tests/route_v12_test.gd:67`: after placing the player at x=56 (`:66`), `route.completed` is true. | Completion requires `gate_open` and x strictly greater than `MISSION.EXIT_X` = 79 (`game/lab_route.gd:315-319`; `game/modules/world/notstrom_layout.gd:6`). x=56 is the `freight_duelist` encounter (`notstrom_layout.gd:15`), not the exit. Probe with the gate open: at x=80 `completed=true`; the base run at x=56 and a closed gate gives `completed=false`. | test-stale |

## Root causes

1. **Stale route geometry and coordinates (count, detour and exit rows).** The route grew from four to eight encounters (`notstrom_layout.gd:9-18`), the old platforms at x=11-18 were removed (`lab_route.gd:103-107,578-583`), and the exit moved from the old x=56 area to x=79 (`notstrom_layout.gd:6`). The count row is not the only gate dependency: even a test that expects eight enemies must still clear the overseer and both shield bearers before the gate can open.
2. **Stale bone namespace (attack row).** The current mechanical rig has `RightArm`, not `mixamorig_RightArm` (`enemy.gd:243`). The failing check never reads a real bone; it reads bone index -1 twice, which is a harness bug rather than an animation bug.
3. **Stale kill-all setup (gate row).** One light hit per enemy cannot defeat the shielded duelists (`enemy.gd:702-705,941-942`), and the remote loop bypasses the overseer's activation gate (`lab_overseer.gd:24-34,64-65`). The test also leaves every enemy's physics disabled except the first. The gate logic itself is correct when all eight encounters are defeated through the current combat rules.
4. **Harness timing (death row).** The test waits 1.5 s, but the authored respawn takes 2.4 s (`main.gd:117-120`). Equipment and checkpoint respawn both work once the real wait elapses.

No game bug was found in the three route rules the task names: death returns to the checkpoint with equipment, the gate opens when all eight encounters are cleared, and completion fires beyond x=79. All six failures are stale test assumptions or harness setup, not broken game logic.

## Proposed fixes

- `game/tests/route_v12_test.gd`, `run()`: replace the hard-coded count 4 with `MISSION.ENCOUNTERS.size()` or a "no wave spawner" assertion that does not pin the route size.
- `game/tests/route_v12_test.gd`, `run()`: sample the mechanical `RightArm` bone (or resolve the bone by suffix) for both windup and strike poses.
- `game/tests/route_v12_test.gd`, `run()`: remove or replace the x=18/y>2.3 upper-detour check with a traversal check on the current flat route, or move it to the real service-return upper deck.
- `game/tests/route_v12_test.gd`, `run()`: wait at least 2.6 s after lethal damage before asserting that Rend is alive at the checkpoint.
- `game/tests/route_v12_test.gd`, `run()`: re-enable all enemy physics, move the player past `ADMISSION_X` to activate the overseer, and break or remove both shields before asserting the open gate.
- `game/tests/route_v12_test.gd`, `run()`: place the player beyond `MISSION.EXIT_X` (79) after the gate opens instead of checking completion at x=56.
