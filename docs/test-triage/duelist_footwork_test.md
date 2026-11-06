# Diagnosis: duelist_footwork_test

base_commit: `54e212c2429496989ade064179cec1846f347770` (the snapshot has no `.git`, so it could not be re-resolved locally). Godot 4.7.2 headless.

## How I ran it

From `/work`, six times in total (one baseline plus five repeats, identical results):

```
tools/run_tests.sh --headless duelist_footwork_test
```

Runner summary at base_commit:

```
FAIL    quarantine duelist_footwork_test
---
      1 FAIL quarantine
=== quarantine duelist_footwork_test: exit 1, last 30 lines of test.log
V44 PASS miss leaves an initial punish window 1.0
V44 PASS fixed bounded retreat 1.0
V44 FAIL still in vulnerable recovery
V44 PASS miss leaves an initial punish window -1.0
V44 PASS fixed bounded retreat -1.0
V44 FAIL still in vulnerable recovery
V44 PASS counterhit deals full damage and cancels step
V44 PASS successful swing does not retreat
V44 PASS parry cancels retreat
V44 PASS backstep cannot pass through wall
V44 PASS backward ground check prevents ledge exit
V44 PASS standing is punished by high attack
V44 FAIL crouch avoids announced high attack
V44 SUMMARY failures=3
```

The triage row says 11/2; this run shows 11 PASS and 3 FAIL lines because "still in vulnerable recovery" is asserted once per front and fails both times, so there are two distinct failing checks. Temporary prints (reverted; hashes restored) logged state, `_state_t`, step activity, strike, hit bands and hurt height. No display was available, so no window run was possible.

After restoring the files, `JOBS=3 tools/run_tests.sh --headless` reported `84 PASS headless` and `12 PASS hook`.

## Failing checks

| check | test expects (file:line) | game does (evidence) | verdict |
|---|---|---|---|
| still in vulnerable recovery | `game/tests/duelist_footwork_test.gd:27-35`: after 0.08 s stationary and 0.24 s retreat (0.32 s after `_enter(RECOVERY)`), the state is still RECOVERY while the retreat step is inactive. | Temp print at 0.32 s: `state=2 (CHASE) state_t=0.0 step=false x=31.496` for front +1 and `state=2 state_t=0.0 step=false x=32.504` for front -1. Role 1 leaves RECOVERY at `_state_t>=_recovery_duration()` = 0.32 s (`game/enemy.gd:422-423,1148-1149`). The 0.18 s step starts at 0.12 s (`game/enemy.gd:418-419,498-499`; `game/modules/combat/recovery_step.gd:24-25`), so it ends at 0.30 s and recovery at 0.32 s. | test-stale. Rule: role 1's actual recovery window is 0.32 s (`game/enemy.gd:1148-1149`; `docs/bestiary/sentinel.md:15,37`), not the unused `RECOVERY_S` 0.8 (`game/enemy.gd:54`); the assertion samples exactly at the window's end. |
| crouch avoids announced high attack | `game/tests/duelist_footwork_test.gd:58-66`: with crouch pressed, Rend keeps 5 HP against the duelist's announced high strike. | Standing control: `strike=side kind=high hurt_height=1.65 low=1.15 high=1.6 band_hit=true`, hp 4 (correct). Crouch temp prints over two runs: once the duelist rolled `side` (`hurt_height=1.05 band_hit=false`, correctly ducked) but the extra `awakened_blank` hit with `thrust` (`low=0.7 high=1.5`); once the duelist rolled `uppercut` (`kind=heavy low=0.3 high=1.7 band_hit=true`) and `awakened_blank` also hit (`x=35.54 front=-1 crouching=true band_hit=true`). The blank spawns at x=37.2 when `prepare(1.0)` puts Rend at x=36 (`game/lab_route.gd:390-408`; `game/data/route_layout.gd:37`) and is not in `route.enemies`, which the test disables. | harness. Rule: only a high band (low >= 1.10) clears the 1.05 m crouch (`game/enemy.gd:72-73,608-613`; `game/player.gd:210-211`); overhead/uppercut are meant to be un-duckable (`game/enemy.gd:69,74-75`). The test never pins `forced_strike`, so `_choose_strike()` can roll side/overhead/uppercut/thrust (`game/enemy.gd:1109-1118`), and the earlier teleport spawns a second attacker outside the disabled list. |

## Root causes

1. The recovery assertion is stale: role 1 leaves RECOVERY at 0.32 s (`game/enemy.gd:1148-1149,422-423`), while the test samples at 0.08 + 0.24 = 0.32 s and expects a post-retreat vulnerable window based on the unused `RECOVERY_S` 0.8 (`game/enemy.gd:54`); the retreat (`game/enemy.gd:418-419,498-499`; `recovery_step.gd:24-25`) ends at 0.30 s, leaving no window at the sampled time.

2. The crouch check is a harness problem: it never pins `forced_strike`, so `_choose_strike()` can pick a heavy overhead/uppercut/thrust (`game/enemy.gd:1109-1118`) that is designed to hit a 1.05 m crouch (`game/enemy.gd:74-76,608-613`; `game/player.gd:210-211`), and the earlier `prepare(1.0)` at x=36 spawns the route's `awakened_blank` at x=37.2 (`game/lab_route.gd:390-408`; `game/data/route_layout.gd:37`) outside `route.enemies`, which then attacks Rend during the check.

Both failures are role-1 behaviour, so they also affect the shield bearer in the route: the tested `route.enemies[1]` is already `duelist` with `shield:true` (`game/modules/world/notstrom_layout.gd:11`), and `freight_duelist` has the same role-1-plus-shield spec (`game/modules/world/notstrom_layout.gd:15`); the shield is lowered during WINDUP/SWING (`game/enemy.gd:937-938`) and changes neither recovery nor the strike bands.

## Proposed fixes

- `game/tests/duelist_footwork_test.gd`, `run()`: sample `e._state == e.RECOVERY` inside the real window (for example at 0.30 s, or derive the time from `e._recovery_duration()`) and stop requiring a post-retreat window after 0.32 s.
- `game/tests/duelist_footwork_test.gd`, `run()`: before the crouch comparison pin `e.forced_strike = "side"` and keep the `awakened_blank` spawned by `prepare(1.0)` out of the measurement (disable or free it, or prepare the +1 case away from `AWAKENING_X`) so only the pinned high strike tests the crouch hurtbox.
