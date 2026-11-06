# Diagnosis: pressure_step_test

## How I ran it

base_commit: `46cbaeeb77a63f2a8284b681b7fabf08e9f4744d`. The snapshot has no `.git`, so the commit could not be re-resolved locally. From `/work`:

```
tools/run_tests.sh --headless pressure_step_test
```

Summary of a representative run at base_commit (temporary prints were added to confirm the values below, then all touched files were restored byte-for-byte):

```
V40 FAIL role 1 physically closes distance
V40 FAIL role 1 punishes standing in announced path
V40 FAIL role 2 physically closes distance
V40 FAIL role 2 punishes standing in announced path
V40 PASS low attack teaches jump
V40 PASS cooldown prevents hint spam
V40 FAIL same cue does not repeat
V40 SUMMARY failures=5
```

The run is deterministic: the same 2 checks pass and the same 5 fail on every run.

## Failing checks

| check | test expects (file:line) | game does (evidence) | verdict |
|---|---|---|---|
| role 1 physically closes distance | `game/tests/pressure_step_test.gd:26`: starting at x=34.3, the foe ends 0.5–1.5 m further west after 0.58 s. The test keeps the last role-1 enemy (`:16-17`). | The selected role-1 enemy is `freight_duelist` with `territory_min_x=55.3` (`notstrom_layout.gd:9-18`). Teleported to x=34.30, it enters WINDUP (state 3), sets vx=-0.5 from t=0.117, but the west-edge rule (`game/enemy.gd:24-25,437`) sees x=34.30 <= west=51.30 and zeroes vx before movement. Prints: `t=0.117 posx=34.300 vx=-0.500 west=51.30`; position stays 34.300 through 0.58 s, so distance closed = 0.0. | harness — the lunge exists (`enemy.gd:398-401`, `_lunge_start()` `:1157-1158`), but the test places the foe outside its authored territory, violating the rule that melee movement stops at `_west_edge()` (`enemy.gd:24-25,437`). |
| role 1 punishes standing in announced path | `game/tests/pressure_step_test.gd:27`: Rend at x≈32 loses exactly 1 HP from the announced strike. | Same clamped foe: distance stays 2.55 m, never inside `WEAPON_REACH` 1.45 (`game/enemy.gd:57,615-621`), so `_try_swing_hit` cannot connect and `p.hp` remains 5 (observed throughout WINDUP/SWING). | harness — hit geometry is correct (`enemy.gd:615-621`), but the foe never reaches reach because of the territory clamp (`enemy.gd:24-25,437`); the test setup is invalid, not the strike. |
| role 2 physically closes distance | `game/tests/pressure_step_test.gd:26`: starting at x=34.2, the foe ends 0.5–1.5 m further west after 0.82 s. The test keeps the last role-2 enemy (`:16-17`). | The selected role-2 enemy is the `overseer` (`notstrom_layout.gd:17`). Its `_physics_process` returns before `super` while the player is west of `ADMISSION_X=70` (`game/modules/combat/lab_overseer.gd:24-34`); observed player x=31.7, `adm=70.0`, x stays 34.200 through 0.82 s and vx stays 0. | harness — the base brute lunge exists (`enemy.gd:398-401,1157-1158`), but the test drives the gated overseer subclass at x≈34 instead of a plain brute inside its arena (`lab_overseer.gd:24-34`). |
| role 2 punishes standing in announced path | `game/tests/pressure_step_test.gd:27`: Rend loses exactly 1 HP after 0.82 s. | The overseer never calls `super._physics_process`, so WINDUP time does not advance and no SWING/contact occurs. Additionally, its high windup is 0.80 s (`lab_overseer.gd:48-49`) and contact starts 0.075 s into SWING (`enemy.gd:406-408`), i.e. ≈0.875 s, after the 0.82 s wait; the wait matches the base brute's 0.64 s windup (`enemy.gd:1146`). | harness — the strike code exists (`enemy.gd:406-408,615-621`), but the test selected a subclass with a different gate and timing and then waited too short (`lab_overseer.gd:24-34,48-49` vs `enemy.gd:1146`). |
| same cue does not repeat | `game/tests/pressure_step_test.gd:37-38`: after the `1:low` hint and with cooldown reset, `toast` must remain `"sentinel"`. | The same cue is correctly suppressed (`shown=true`, `lab_route.gd:351-352`). The loop then finds the leftover role-2 overseer still in WINDUP within 5 m (from the failed role-2 setup) and delivers a different cue `2:high` (not yet shown) at `game/lab_route.gd:343-358`; observed `role=1 kind=low shown=true`, then `role=2 kind=high shown=false`, and `toast` changes. | harness — the rule is "once per role/kind key" (`lab_route.gd:351-358`), not "no new hint ever"; the check is polluted by the prior role-2 state and asserts a stronger condition than the game contract. |

## Root causes

1. **Wrong enemy instances and invalid placement (4 checks).** `run()` assigns `foe` on every role match, so it keeps the *last* enemy of each role: `freight_duelist` (territory 55.3) for role 1 and the gated `overseer` (admission 70) for role 2, then teleports both to x≈34 (`game/tests/pressure_step_test.gd:16-23`; route order `notstrom_layout.gd:9-18`). For role 1 the west-edge rule (`enemy.gd:24-25,437`) cancels the otherwise working lunge; for role 2 the overseer's admission guard (`lab_overseer.gd:24-34`) stops all movement and state time. The test also waits 0.82 s, which is too short for the overseer's 0.80 s high windup but fits the base brute's 0.64 s (`lab_overseer.gd:48-49` vs `enemy.gd:1146`).

2. **Pressure-step code still exists.** The search finds the WINDUP lunge at `game/enemy.gd:398-401` with `_lunge_start()` at `:1157-1158` and the overseer override at `lab_overseer.gd:60-62`; `recovery_step.gd` is the post-miss retreat, and the other `step` hits are sidestep/sentinel movement. Nothing was removed; these checks are setup failures, not a missing feature.

3. **Hint check is polluted (1 check).** The failed role-2 setup leaves the overseer in WINDUP near the player. The `1:low` dedup works (`lab_route.gd:351-352`); a different `2:high` cue then legitimately replaces the toast, so the assertion `toast=="sentinel"` is too strong.

## Proposed fixes

- `game/tests/pressure_step_test.gd`, `run()`: select the local `encounter_id == "duelist"` (or spawn a fresh role-1 enemy) and set its `territory_min_x` west of x=32 before `_enter(WINDUP)` so the west-edge clamp cannot cancel the lunge.
- `game/tests/pressure_step_test.gd`, `run()`: after fixing the duelist's territory, keep the player at the measured x and assert the hit after the role-1 WINDUP plus SWING contact window rather than relying on the drifted position.
- `game/tests/pressure_step_test.gd`, `run()`: replace the last-role-2 overseer with a plain role-2 enemy from `main._make_enemy(34.2, 2, ...)` (or reset `active`, territory and put the player past `ADMISSION_X`) before `_enter(WINDUP)`.
- `game/tests/pressure_step_test.gd`, `run()`: for a plain brute keep the 0.82 s wait; if the overseer is intended, extend the wait past its 0.80 s high windup + 0.075 s contact offset and move the player past `ADMISSION_X`.
- `game/tests/pressure_step_test.gd`, `run()`: clear or reset all other WINDUP foes before the hint block and assert that the specific `1:low` key is not offered again, instead of requiring that `toast` never changes.
