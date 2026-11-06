# Diagnosis: guard_spacing_test

base_commit: `46cbaeeb77a63f2a8284b681b7fabf08e9f4744d` (the snapshot has no `.git`, so the commit could not be re-resolved locally).

## How I ran it

From `/work`, repeatedly:

```
tools/run_tests.sh --headless guard_spacing_test
```

Runner summary at base_commit (identical in 1 + 5 runs):

```
FAIL    quarantine guard_spacing_test
---
      1 FAIL quarantine
...
V48 retreat actual=0.0 desired=0.0
V48 SUMMARY failures=4
```

The triage row says 9/5; here it is 10/4. The named `retreat uses backward walk` check passes without a retreat (below). A window run was impossible (no X11/Wayland), so a display red could not be reproduced.

Temporary prints (reverted) logged state, front, distance, west edge and ground/`test_move` probes.

## Failing checks

| check | test expects (file:line) | game does (evidence) | verdict |
|---|---|---|---|
| approach triggers visible retreat | `game/tests/guard_spacing_test.gd:12-17`: guard at x=32.2, Rend at x=30; after `_enter(CHASE)` and 0.12 s the spacing step is active and guard.x > start+0.1. | No step starts. Temp print: `dx=-2.2 front=-1 state=2 armed=true active=false west=33.0 ahead_x=32.9 moveblock=false groundray=true eligible=false`; distance stays 0.0. `advance()` commits only when `eligible` is true (`game/modules/combat/guard_spacing.gd:70-74`); `enemy.gd` makes it false because the retreat target `ahead.x` is below `_west_edge()` (`game/enemy.gd:1092,1096-1098`). `_west_edge()` in CHASE is min(territory 37, pursuit 33)=33 (`game/enemy.gd:24`, `game/lab_route.gd:160-164`); the test is 0.8 m west of it. | test-stale. Rule: a step may only retreat onto free floor inside the guard's west edge (`game/enemy.gd:1098`; `game/modules/combat/guard_spacing.gd:70-74`). Refusing the step is correct; x=32.2 is stale for the grown route. |
| retreat uses backward walk | `game/tests/guard_spacing_test.gd:18`: after 0.12 s `guard._anim.assigned_animation == "walk"`. | This check passes here, but only vacuously: the same run has `distance=0.0`, `active=false`, `armed=true`, so no retreat exists. The true retreat clip is chosen only while `_guard_spacing.is_active()` and `absf(velocity.x)>0.1` (`game/enemy.gd:654-657`); without an active step the clip comes from ordinary CHASE locomotion (`game/enemy.gd:679-683`), not from a retreat. | unclear. I could not reproduce this red headless, and the assertion does not establish a retreat. Rule judged: a retreat must play walk while the spacing step is active (`game/enemy.gd:654-657`; `game/modules/combat/guard_spacing.gd:80-81`). A display/timing-dependent red is plausible but unproven here. |
| retreat is bounded near 0.7m | `game/tests/guard_spacing_test.gd:22-25`: x displacement is `>0.5` and `<=0.72`. | Actual `distance=0.0`, `desired=0.0`: the step never committed for the west-edge reason above. The module's own bound is sound: trigger 1.55 < d <= 2.8, speed 2.8, duration 0.25 s, max 0.7 m (`game/modules/combat/guard_spacing.gd:34-38,72-74`). The test cannot observe it because `advance()` never starts `_step`. | test-stale. Rule: one step travels at most 0.7 m (`game/modules/combat/guard_spacing.gd:37-38`), reached only after an eligible commit (`game/enemy.gd:1092,1098`; `guard_spacing.gd:72-74`). The 0.0 m is a consequence of the illegal test position, not a violated bound. |
| step does not repeat while close | `game/tests/guard_spacing_test.gd:26`: after the first retreat the module is disarmed and a second close call returns zero velocity. | Fails on `not is_armed()`: the first call never committed, so the module is still armed (`armed=true active=false` in the first temp print). The no-repeat rule is `_armed = false` on commit and rearm only at distance >= 4.0 (`game/modules/combat/guard_spacing.gd:36,70-74`); it is never exercised. The later `-4.1` call passes `separation rearms step` only because armed was already true. | test-stale. Rule: one committed step disarms until separation >= 4.0 m (`game/modules/combat/guard_spacing.gd:36,70-74`), driven from `game/enemy.gd:1099`. The failure is the same missing first commit, not a repeated-step bug. |
| no ground behind prevents retreat | `game/tests/guard_spacing_test.gd:47-48`: after teleporting to x=69 and waiting 0.1 s, a retreat call must return zero and stay inactive because there is no floor behind. | Temp print at x=69: `state=2 front=-1 dx=-2.2 armed=true active=false west=33.0 floor=true`; the call gives `moveblock=false`, `ahead=(69.7, 0.3, 0)`, `groundblock=false` (floor ray hit), so `eligible=true` and the step becomes active (`state` stays CHASE because guard physics was disabled at line 23, so the 0.1 s wait does not update the state). At base the arena floor now extends behind x=69, so the "no ground" premise is false. | test-stale. Rule: a retreat step requires a floor hit behind it (`game/enemy.gd:1096-1098`) and starts only when eligible (`game/modules/combat/guard_spacing.gd:70-74`). Floor is present, so starting the step is correct; the test's x=69 coordinate has aged out of the route geometry. |

## Root causes

Four reds share one stale setup. The guard encounter is authored at x=40 with `min_x=37`; `lab_route.gd:160-164` sets `pursuit_min_x=33` (min_x-4, clamped by checkpoint x=26+2), so in CHASE `_west_edge()=33` (`enemy.gd:24`). At x=32.2 the +0.7 m retreat target (32.9) fails `ahead.x >= _west_edge()` (`enemy.gd:1098`). No step starts, so the active, distance, bound and disarm checks fail. The guard correctly refuses to step outside its pursuit line.

The fifth red is stale geometry: x=69 is no longer a ledge. The floor ray finds ground at x=69.7, so the step correctly starts; the test disabled guard physics earlier, so its 0.1 s wait cannot change state.

`guard_spacing.gd` is still called from `enemy.gd`: instantiated at :98, advanced for `role == 3` in CHASE at :329, used for the walk animation at :654, cancelled at `:1085-1087`, reset at `:689-690`. `route.enemies[2]` is that role-3 guard (`notstrom_layout.gd:10-12`); no evidence of a retreat-module bug.

## Proposed fixes

- `game/tests/guard_spacing_test.gd`, `run()`: place the guard inside its chase territory (for example x=35-36 with Rend 2.2 m west) instead of x=32.2, or override `pursuit_min_x`/`territory_min_x` for this unit scenario so the 0.7 m retreat stays east of `_west_edge()`.
- `game/tests/guard_spacing_test.gd`, `run()`: after making the step start, assert `_guard_spacing.is_active()` together with the walk clip (or the backward velocity/displacement) so the line cannot pass on ordinary CHASE locomotion.
- `game/tests/guard_spacing_test.gd`, `run()`: keep the 0.5-0.72 m window but measure it only after the step has committed, or compare `_guard_spacing.distance_traveled()` with the module's 0.7 m cap to avoid unrelated chase drift.
- `game/tests/guard_spacing_test.gd`, `run()`: guarantee the first step commits and disarms before this check, then keep the `not is_armed()` plus zero-second-call assertion (or seed the step through `advance()` deterministically).
- `game/tests/guard_spacing_test.gd`, `run()`: use an actual no-floor ledge at base, or build a temporary gap for the test, instead of x=69 (which now has arena floor), and re-enable guard physics if the CHASE-to-IDLE transition is meant to be part of the setup.
