# Diagnosis: coolant_test

base_commit: `46cbaeeb77a63f2a8284b681b7fabf08e9f4744d`.

## How I ran it

From `/work`:

```
tools/run_tests.sh --headless coolant_test
```

Godot 4.7.2. Runner summary at base_commit:

```
FAIL    quarantine coolant_test
---
      1 FAIL quarantine
=== quarantine coolant_test: exit 1, last 30 lines of test.log
V47 FAIL actual sword input breaks canister once
V47 FAIL ranged charge interrupted and marker cleared
V47 FAIL committed brute attack interrupted
V47 PASS outside radius unchanged
V47 PASS pressure causes no HP or currency change
V47 PASS duplicate break cannot release twice
V47 PASS pressure visual expires
V47 PASS real cover blocks pressure within radius
V47 FAIL gate and encounter count unchanged
V47 PASS consumption saved without reward
V47 PASS real scene reload restores broken shell
V47 PASS reload emits no pressure or reward
V47 SUMMARY failures=4
```

A temporary local probe (not submitted) printed the runtime values below. In a second probe it called `p.equip_weapon("robot_arm")` before the attack at line 22.

## Failing checks

| check | test expects (file:line) | game does (evidence) | verdict |
|---|---|---|---|
| actual sword input breaks canister once | `game/tests/coolant_test.gd:22-24`: pressing `attack` at x=35.95 facing +x breaks the canister and increments `coolant_releases` once. | Rend starts unarmed: a fresh save leaves `equipment.equipped_weapon()` empty, which `_build_route()` passes to `player.equip_weapon()` (`game/lab_route.gd:150`); that sets `weapon_id=""` and slot free (`game/player.gd:803,808-810`), and `_start_attack()` returns before any swing (`game/player.gd:818`). Probe: `weapon="" slot=1 phase=0`, canister intact. The current replacement input is robot-arm melee on the `attack` action after `equip_weapon("robot_arm")` (slot 2); Rend has no sword. Rule: M1 places the robot arm as a pickup in Arrival (`docs/milestone-1.md:28`) and lists the robot arm as the first weapon (`docs/milestone-1.md:39`). | test-stale |
| ranged charge interrupted and marker cleared | `game/tests/coolant_test.gd:25`: guard `route.enemies[2]` is in `RECOVERY`, has `_stun>0`, and its attack cue is hidden after the burst. | Because row 1 never breaks the canister, `_on_coolant_broken()` never runs, so `interrupt_with_pressure()` is never called (`game/lab_route.gd:1082-1088`, `game/enemy.gd:1072-1080`). Probe without arming: `state=3 (WINDUP) stun=0 cue_visible=true`; after equipping the robot arm and breaking it: `state=5 (RECOVERY) stun=0.55 cue_visible=false`. Rule: a coolant burst must interrupt nearby robots (`docs/plan.md:41` lists the canister as an interactable); the interruption path works. | test-stale |
| committed brute attack interrupted | `game/tests/coolant_test.gd:26`: brute `route.enemies[3]` is in `RECOVERY` with `_stun>0`. | Same dependency: no release means no pressure call. Probe without arming: `state=3 (WINDUP) stun=0`; after arming and breaking: `state=5 (RECOVERY) stun=0.55`. The brute takes the same `interrupt_with_pressure()` path (`game/enemy.gd:1072-1080`). Rule: M1 keeps the brute/overseer role in the robot set without exempting it from hazards (`docs/milestone-1.md:38`). | test-stale |
| gate and encounter count unchanged | `game/tests/coolant_test.gd:42`: `cleared` is empty, the gate is closed, and `route.enemies.size()==4`. | Probe: `cleared=[]`, `gate=false`, but `enemies=8` with ids `first, duelist, guard, hound, freight_raider, freight_duelist, relay_guard, brute`. `_build_route()` appends one enemy per uncleared `MISSION.ENCOUNTERS` entry (`game/lab_route.gd:154-167`), and that table now has eight encounters (`game/modules/world/notstrom_layout.gd:9-18`). Rule: M1's route table names these eight encounters (`docs/milestone-1.md:28-32`). | test-stale |

## Root causes

**1. Stale sword-era arming (row 1; causes rows 2 and 3).** The test positions Rend and presses `attack` but never picks up or equips the robot arm. On a fresh save the player has no weapon, so `_start_attack()` returns immediately (`game/player.gd:818`) and the canister is never hit. The "sword input" label is itself stale: Rend has no sword; robot-arm melee on the `attack` action replaces it. The pickup sits at x=1.8 (`game/data/route_layout.gd:8`), so a test that teleports to x=35.95 must equip the arm itself.

**2. Rows 2 and 3 fail only because row 1 never breaks the canister.** With the arm equipped, the probe shows both robots enter `RECOVERY` with stun 0.55 and the ranged cue clears. No independent game bug exists in `interrupt_with_pressure()` (`game/enemy.gd:1072-1080`) or in the distance/ray loop (`game/lab_route.gd:1082-1088`). The passing "outside radius unchanged" check is therefore vacuous in the failing run: no pressure was released at all.

**3. Stale encounter count (row 4).** The test hard-codes four enemies from an older, shorter route. The M1 route authors eight encounters (`game/modules/world/notstrom_layout.gd:9-18`) and spawns every uncleared one (`game/lab_route.gd:154-167`). `cleared` and `gate_open` are correct; only `size()==4` is wrong.

No harness failure occurred (the test reaches all checks; no null node or file), and the coolant hazard itself showed no game bug once the canister actually broke.

## Proposed fixes

- `game/tests/coolant_test.gd`, `run()`: call `p.equip_weapon("robot_arm")` after placing Rend at x=35.95 and before pressing `attack`, so the input uses the current robot-arm melee instead of the removed sword.
- `game/tests/coolant_test.gd`, `run()`: keep the ranged assertions after the canister actually breaks, either through the corrected attack setup or an explicit break in a dedicated setup; the guard behaviour already matches.
- `game/tests/coolant_test.gd`, `run()`: keep the brute assertions after the same actual-break setup; no change is needed in `interrupt_with_pressure()`.
- `game/tests/coolant_test.gd`, `run()`: replace `route.enemies.size()==4` with `route.enemies.size()==MISSION.ENCOUNTERS.size()` (eight today) and keep the `cleared` and `gate_open` assertions.
