# Diagnosis: security_pair_test

## How I ran it

base_commit: `54e212c2429496989ade064179cec1846f347770`. From `/work`:

```
tools/run_tests.sh --headless security_pair_test
```

Summary at base_commit (6 PASS, 3 FAIL):

```
FAIL    quarantine security_pair_test
V45 FAIL pair shares a nearby engagement area
V45 FAIL early charge acquires visible target
V45 PASS acquisition never swivels behind body
V45 PASS final charge commits aim
V45 PASS aim lock is visibly marked
V45 PASS lock marker clears with phase
V45 PASS real swept bolt stops at cover
V45 PASS space above cover stays clear
V45 FAIL actual jump clears barrier
V45 SUMMARY failures=3
```

Temporary print probes were restored byte-for-byte. Full suite afterwards: `JOBS=3 ../tools/run_tests.sh --headless` gave 84 PASS headless, 12 PASS hook.

## Failing checks

| check | test expects (file:line) | game does (evidence) | verdict |
|---|---|---|---|
| pair shares a nearby engagement area | `game/tests/security_pair_test.gd:14`: `route.enemies[2].x - route.enemies[1].x == 3.5`, i.e. guard minus duelist. | Probe: `duelist` x=32.500, `guard` x=40.000, difference +7.500. Enemies are appended in `ENCOUNTERS` order (`game/lab_route.gd:154-167`); today `duelist` is at 32.5 and `guard` at 40 (`game/modules/world/notstrom_layout.gd:11-12`, `docs/milestone-1.md:31`). The 3.5 m pair around the cover at x=40.8 (`game/data/route_layout.gd:29`) is now `guard` (40) and `hound` (43.5, `notstrom_layout.gd:12-13`); the duelist is no longer part of it. Rule judged: encounter positions are authored data in `ENCOUNTERS`, not the old index-based 3.5 m assumption. | test-stale — the authored table moved `duelist` to 32.5 and added `hound`; today's cover pair is `guard`+`hound`. |
| early charge acquires visible target | `game/tests/security_pair_test.gd:18`: `_aim_point` is within 0.001 of `p.global_position + Vector3(0,1.2,0)`; with Rend at (33,0.01,0) that expects (33,1.21,0). | Probe: actual `_aim_point`=(33,1.165,0), distance 0.0450. `_chest()` returns `player.global_position + Vector3(0, height*0.7, 0)` (`game/enemy.gd:1019-1021`); standing Rend is 1.65 m (`game/player.gd:210-211`), so 0.01+1.155=1.165. Early WINDUP acquisition calls `_chest()` (`game/enemy.gd:394-395`); the probe also showed `lane=true`, `front=-1`, so the target is acquired. Rule judged: a gunner aims at the middle of Rend's chest (70 % of hurt height), not at a fixed 1.2 m offset. | test-stale — the acquisition works; only the hard-coded 1.2 m height is stale. |
| actual jump clears barrier | `game/tests/security_pair_test.gd:46`: after jumping from x=39.4, final x>42.0 and the highest y>1.25. | Probe: top=1.5470 (above 1.25), final x=38.8501. The guard is `route.enemies[2]`, authored at x=40 (`game/modules/world/notstrom_layout.gd:12`), with an 0.8×1.5 collision (`game/enemy.gd:150-152`); its body overlaps the 40.0–41.6 cover (`game/lab_route.gd:1016-1020`) and the first manual physics tick moves it to x=39.59987, so the guard spans x=39.2–40.0 right on Rend's start. Rend settles at x=38.85007 before input (x=38.9203 with the guard moved), and with the guard present his `move_right` never advances him; robot collision and the 1.0 m push-box block the run-up (`game/enemy.gd:59-61,520-528`; `game/player.gd:764-771`). With the guard moved to x=30 the same jump reaches x=42.0584 and top=1.5473, and the check passes. Rule judged: robots block and keep `PUSH_GAP`; the barrier itself is jumpable (1.6×1.25 m, `game/lab_route.gd:1016-1020`). | test-stale — the fixture assumes a clear launch pad, but the living `guard` occupies it; the barrier jump itself works. |

## Root causes

1. **The pair check selects robots by spawn index, not by encounter id.** Revision 2 moved `duelist` from the old nearby position to 32.5 and inserted `hound` at 43.5 (`game/modules/world/notstrom_layout.gd:11-13`). `route.enemies[1]`/`[2]` still resolve to `duelist`+`guard`, now 7.5 m apart, while the 3.5 m pair at the cover is `guard`+`hound`. The check therefore fails on stale identities and distance, not on missing engagement.

2. **The aim check hard-codes a height the game no longer uses.** Acquisition refreshes `_aim_point` from `_chest()` (`game/enemy.gd:394-395,1019-1021`), which derives 70 % of `hurt_height()`; standing Rend's chest is 1.165 m above his feet, not the test's fixed 1.2 m. The 0.045 m difference is the whole failure.

3. **The jump fixture ignores the guard standing in its launch lane.** Rend is teleported 0.6 m from the guard's authored centre, and after one physics tick the guard's 0.8×1.5 body spans x=39.2–40.0, overlapping Rend's start at x=39.4. Robot collision plus the 1.0 m push-box shove him west and hold him there, so he never reaches the barrier. The barrier geometry is fine: the probe reaches y=1.547 and x=42.058 once the guard is moved away. A separate placement smell remains: the guard at authored x=40 overlaps the cover's 40.0–41.6 footprint by 0.4 m (`notstrom_layout.gd:12`; `route_layout.gd:29`; `lab_route.gd:1016-1020`), so physics pushes it to about x=39.6; this does not change the verdict because the test start is already inside the push-box even at x=40.

## Proposed fixes

- `game/tests/security_pair_test.gd`, `run()`: select robots by `encounter_id` and assert the spacing authored in `notstrom_layout.gd:9-18` (today 3.5 m for `guard`+`hound`, or 7.5 m for `duelist`+`guard`) instead of combining the old indices with 3.5 m.
- `game/tests/security_pair_test.gd`, `run()`: compare `_aim_point` with `guard._chest(p)` or assert x/z and the forward hemisphere, rather than the fixed `+Vector3(0,1.2,0)` height.
- `game/tests/security_pair_test.gd`, `run()`: move the `guard` out of the jump lane (probe used x=30) or clear its collision before placing Rend at x=39.4, then keep the barrier-jump assertion.
