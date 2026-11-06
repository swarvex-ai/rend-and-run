# Diagnosis: brute_commitment_test

## How I ran it

base_commit: `95fd312d2338b9b1d68aa7fe2691a7ce5a2d51f6` (the task snapshot; there is no `.git` folder to re-resolve it locally).

```
tools/run_tests.sh --headless brute_commitment_test
```

Runner and test summary at base_commit:

```
FAIL    quarantine brute_commitment_test
---
      1 FAIL quarantine
=== quarantine brute_commitment_test: exit 1, last 30 lines of test.log

V39-BRUTE FAIL early anticipation can be interrupted
V39-BRUTE FAIL committed cleaver keeps timing but takes full damage
V39-BRUTE PASS parry still interrupts committed cleaver
V39-BRUTE FAIL lethal strike overrides commitment
V39-BRUTE SUMMARY failures=3
```

I added temporary prints to the test locally (state, `_state_t`, HP, `_stun`, `_hit_recovering`, `active`, `_has_attack_momentum()`, script path) and reverted them. Two control runs: a temporary variant spawning a plain base brute with `main._make_enemy(0, 2)` passed 4/4; a variant setting the overseer `active=true` passed checks 2–4 but check 1 still failed because the overseer has 12 HP, not 2.

## Failing checks

| check | test expects (file:line) | game does (evidence) | verdict |
|---|---|---|---|
| early anticipation can be interrupted | `game/tests/brute_commitment_test.gd:14-16`: after `_enter(WINDUP)` at `_state_t=0.2`, a 1-damage hit leaves RECOVERY, `_hit_recovering=true`, hp 2. Base rule: before `_commit_time()` the hit is not committed (`game/enemy.gd:1154-1161`), so `take_melee_hit()` applies damage and enters recovery (`game/enemy.gd:709-726`). | The test's `if e.role==2` (`brute_commitment_test.gd:11-13`) selects the route's only role-2 node, the overseer (`game/modules/world/notstrom_layout.gd:17` → `lab_overseer.gd`), with `active=false` and `hp=12` (`lab_overseer.gd:4,6,20`). Debug before the hit: state WINDUP, momentum=false, hp 12. After it: state WINDUP, `_state_t=0.2`, `_hit_recovering=false`, hp 12, `_stun=0`. `lab_overseer.gd:64-65` returns before `super.take_melee_hit()` while inactive; even activated, hp would be 11, not 2. | test-stale. Judged against the base-brute rule in `enemy.gd:709-726,1154-1161`; the test assumes a plain 3-HP brute (`enemy.gd:162`) that is hittable while dormant, but the current route's role-2 node is the 12-HP, `active`-gated overseer. |
| committed cleaver keeps timing but takes full damage | `brute_commitment_test.gd:17-19`: with hp reset to 3 and WINDUP at `_state_t=0.45`, a 1-damage hit leaves WINDUP, `_state_t=0.45`, hp 2, `_stun=0`, `_hit_recovering=false`. Base rule: a committed attack takes full damage but keeps its reaction-free timing (`enemy.gd:709-716,1160-1161`). | Debug: momentum=true at 0.45 (the overseer's low windup is 0.70 with commit 0.40, `lab_overseer.gd:48-58`), but after the hit state is still WINDUP, `_state_t=0.45`, hp is still 3, `_stun=0`, `_hit_recovering=false`: the hit was dropped. `lab_overseer.gd:64-65` is the only gate; with `active=true` this check passes. | harness. Judged against the same committed full-damage rule (`enemy.gd:709-716,1160-1161`); the base behaviour is correct, but the test's setup uses a dormant encounter and never reaches it. |
| lethal strike overrides commitment | `brute_commitment_test.gd:22-23`: after the parry, `_enter(SWING)` plus a 2-damage hit kills (expected hp 0 from 2). Base rule: committed or not, `hp <= 0` calls `_die()` (`enemy.gd:711,714,750-751`). | Debug after `_enter(SWING)` and the 2-damage hit: state SWING, hp 3, `_dead=false`, `active=false`. The hit is dropped by `lab_overseer.gd:64-65`; additionally, because the previous check did not apply its damage, hp is 3, so even an applied 2-damage hit would leave hp 1 rather than kill. With a plain base brute all four checks pass. | harness. Judged against the lethal-overrides-commitment rule (`enemy.gd:711,714,750-751`); the failure cascades from the inactive-overseer setup, not from the rule. |

## Root causes

The test identifies its subject by taking the last/only `role==2` entry from `main.route.enemies` (`brute_commitment_test.gd:11-13`). In the current route that entry is the overseer (`notstrom_layout.gd:17`), whose `take_melee_hit()` returns immediately while `active` is false (`lab_overseer.gd:64-65`) and whose `MAX_HP` is 12 (`lab_overseer.gd:4,20`), so checks 1, 2 and 4 never see damage or the base interruption path; check 1 would still fail on HP even if activated.

There is no evidence of a game bug in the base role-2 commitment rules: a plain `main._make_enemy(0, 2)` passes all four checks. The same rules do apply to the overseer through `super.take_melee_hit()` and `super._has_attack_momentum()`, except that a braced attack is treated as committed from WINDUP onward (`lab_overseer.gd:98-99`), so early anticipation cannot interrupt a braced overseer attack; non-braced committed attacks still take full damage and keep timing, and a lethal hit still kills. Its timings differ from the base brute (high 0.80/commit 0.50, low 0.70/commit 0.40; `lab_overseer.gd:48-58`), which is why 0.45 is committed for the low attack used in check 2.

## Proposed fixes

- `game/tests/brute_commitment_test.gd`, `run()`: replace the route role-2 lookup with a fresh base brute (`main._make_enemy(0, 2)`) so the check exercises `enemy.gd`'s 3-HP brute instead of the overseer.
- `game/tests/brute_commitment_test.gd`, `run()`: if the overseer is the intended subject, set `active=true` and `hp=3` before the hit (and reset `_brace_hits`) so the dormant gate and 12-HP pool do not mask the rule.
- `game/tests/brute_commitment_test.gd`, `run()`: set `brute.hp=2` immediately before the 2-damage SWING hit so the lethal check does not depend on the previous check's damage landing.
