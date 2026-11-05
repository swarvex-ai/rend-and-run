# Diagnosis: attack_cue_integration

## How I ran it

> Lead note, 05.11.2026: the task's actual base commit was `77db3e1`, not `2eba4f9`. Under `game/` the two differ only in `tests/manifest.txt`, so the runs and line references hold for `77db3e1`.

base_commit: `2eba4f9`, the baseline named in `docs/test-triage.md`. This snapshot has no `.git`, so the commit could not be re-resolved locally. In this snapshot `tools/run_tests.sh` has no execute bit, so I invoked the same script through bash:

```
bash tools/run_tests.sh --headless attack_cue_integration
```

Equivalent to the required `tools/run_tests.sh --headless attack_cue_integration`. Runner summary of a representative run:

```
FAIL    quarantine attack_cue_integration
---
      1 FAIL quarantine
logs: /tmp/rendrun-tests/<test>/test.log
```

Summary of the first three runs at base_commit (each log also contains the two `V41 FAIL` lines):

```
Run 1: FAIL quarantine attack_cue_integration -> V41 SUMMARY failures=2
Run 2: FAIL quarantine attack_cue_integration -> V41 SUMMARY failures=2
Run 3: FAIL quarantine attack_cue_integration -> V41 SUMMARY failures=2
```

I ran it 12 times headless. Per-run failures:

| Run | `high cue visible in committed direction` | `heavy commitment retains warning` | V41 failures |
|---|---|---|---|
| 1-4 | FAIL | FAIL | 2 |
| 5 | PASS | FAIL | 1 |
| 6-12 | FAIL | FAIL | 2 |

So the first check is non-deterministic (failed 11/12), while the second failed every run (12/12).

## Failing checks

| check | test expects (file:line) | game does (evidence) | verdict |
|---|---|---|---|
| high cue visible in committed direction | `game/tests/attack_cue_integration.gd:21`: cue visible, `pivot.position.x < 0`, `pivot.position.y == 1.25` after `route.enemies[1]` (duelist) enters WINDUP at `:18-20`. | The cue exists and points left, but its height depends on the randomly chosen strike. `_enter(WINDUP)` calls `_choose_strike()` (`game/enemy.gd:488`); for a duelist it returns one of side/overhead/uppercut/thrust (`game/enemy.gd:1109-1115`). Only `side` is `kind:"high"`; the other three are `kind:"heavy"` (`game/enemy.gd:72-76`). `_attack_kind()` therefore returns `"heavy"` (`game/enemy.gd:1105-1106`) and `begin()` places the cue at Y=0.95 instead of 1.25 (`game/modules/vfx/enemy_attack_cue.gd:25,77`). Temporary prints: `side` -> Y=1.25 PASS; `overhead`/`uppercut`/`thrust` -> Y=0.95 FAIL. | test-stale. Judged against the cue contract that height follows the committed strike band (`enemy_attack_cue.gd:24-25,77`), and `enemy.gd:1105-1106,1109-1115`; the game cue matches the strike, the test assumes a fixed high strike. Non-determinism source: `randi()` at `game/enemy.gd:1115` with no fixed seed. |
| heavy commitment retains warning | `game/tests/attack_cue_integration.gd:35-37`: `route.enemies[3]` is treated as the brute, enters WINDUP at `_state_t=0.4`, takes a nonlethal hit, and the cue must stay visible. | `route.enemies[3]` is the hound, not the brute. Encounters are appended in `MISSION.ENCOUNTERS` order (`game/lab_route.gd:152-165`); that order is first, duelist, guard, hound, ... (`game/modules/world/notstrom_layout.gd:9-17`), so the brute is index 7. Debug print: `role=0 id=hound state=5 momentum=false cue_visible=false` after the hit. Because role 0 has no attack momentum (`game/enemy.gd:1160-1161`), `take_melee_hit` falls into the interruption branch and calls `_enter(RECOVERY)` (`game/enemy.gd:709-725`), which cancels the cue (`game/enemy.gd:492`). Temporarily selecting the actual brute by `encounter_id == "brute"` made the check pass 3/3. | test-stale. Judged against the heavy-commitment rule that only role 2 in committed WINDUP keeps its warning (`game/enemy.gd:1160-1161,709-725`); the test selects the wrong enemy because the encounter list grew from the old route. Not a game bug. |

## Root causes

The first failure is random strike selection. A duelist's WINDUP chooses a fresh strike from four candidates; three of them are heavy and only one is high. The cue correctly follows that choice, so the assertion "always high" only passes when `side` happens to be rolled. This explains the lead's window/headless difference: the check is flaky by design, not timing-dependent.

The second failure is a stale encounter index. The test assumed the fourth spawned enemy is the brute, which was true before the route grew to eight encounters. Today index 3 is the hound, so the test exercises a role without attack momentum and sees the cue cancelled as the game intends. There is no evidence of a game bug in either check.

## Proposed fixes

- `game/tests/attack_cue_integration.gd`, `run()`: pin `e.forced_strike` to a high strike such as `"side"` before the first WINDUP, or assert the cue height against `e._attack_kind()` instead of a fixed 1.25.
- `game/tests/attack_cue_integration.gd`, `run()`: select the brute by `encounter_id == "brute"` instead of the fragile `route.enemies[3]`.
