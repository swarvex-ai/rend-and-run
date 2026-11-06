# Diagnosis: edge_warning_test

## How I ran it

From `/work`, at base_commit `46cbaeeb77a63f2a8284b681b7fabf08e9f4744d` (this snapshot has no `.git`, so the hash is the one named by the task):

```
tools/run_tests.sh --headless edge_warning_test
```

Godot 4.7.2. Runner summary at base_commit:

```
FAIL    quarantine edge_warning_test
---
      1 FAIL quarantine
=== quarantine edge_warning_test: exit 1, last 30 lines of test.log
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

V46 FAIL offscreen charging guard warns right
V46 FAIL committed guard turns edge white
V46 PASS interrupt removes threat
V46 PASS dead attacker never warns
V46 PASS finished charge clears warning
V46 PASS visible attacker uses world cue only
V46 FAIL left offscreen direction is correct
V46 PASS attacker facing away does not warn
V46 PASS player death clears warning
V46 PASS solid cover suppresses blocked charge
V46 FAIL clear lane restores warning
V46 PASS pause notification clears warning
V46 PASS completed sector clears warning
V46 SUMMARY failures=4
```

Temporary local prints (not submitted; both files restored) gave the values below. Headless viewport is **64 × 64** (`get_visible_rect().size`), while `project.godot:17-18` sets 1280 × 720 and the window runner uses 960 × 540. The indicator still works headless: the observed unprojected x was 156.0 for the right foe and −92.0 for the left foe, both outside `[0, 64]`, and the probe with the player moved east of the guard's engagement edge passed all 13 checks headless. So the failure is **not** headless vs. window.

## Failing checks

| check | test expects (file:line) | game does (evidence) | verdict |
|---|---|---|---|
| offscreen charging guard warns right | `game/tests/edge_warning_test.gd:13-18`: player and camera at x=32, guard at x=39, then `right.visible`, `not left.visible`, `not right.is_locked()`. | Player x=32 is west of the guard's `_west_edge()`: guard territory is 37 (`game/modules/world/notstrom_layout.gd:12`), so `pursuit_min_x = max(37-4, 26+2) = 33` (`game/lab_route.gd:161-164`) and `_west_edge()` returns 33 in WINDUP (`game/enemy.gd:24-25`). `_has_fire_lane()` therefore returns false at `game/enemy.gd:1014`; the ray itself was clear (`hit=none`). `_update_edge_warnings()` skips the foe at `game/lab_route.gd:1041`, states stay 0 and both warnings are cleared (`game/lab_route.gd:1044`). | test-stale. Rule judged against: an edge warning is only for a charging, unobstructed ranged attacker that can actually fire (`game/lab_route.gd:1026` comment; `_fire_energy()` reuses `_has_fire_lane()` at `game/enemy.gd:1024`). The test forces a rifleman into WINDUP at a player outside its engagement ground, a threat the game correctly does not produce. |
| committed guard turns edge white | `game/tests/edge_warning_test.gd:19-20`: after `_state_t=0.6`, `right.is_locked()`. | Same lane veto: with player x=32 the loop never reaches the committed branch (`_state_t >= 0.55` -> state 2) at `game/lab_route.gd:1043`; `right` was never set and `is_locked()` stays false (`game/modules/ui/edge_threat_indicator.gd:50-51`). | test-stale. Rule judged against: locked/white follows committed `_state_t >= 0.55` only for a warning that exists (`game/lab_route.gd:1043`); the test's precondition violates the firing rule at `game/enemy.gd:1014`. |
| left offscreen direction is correct | `game/tests/edge_warning_test.gd:33-34`: player and camera stay at x=32, foe at x=25 facing +1, then `left.visible` and `not right.visible`. | Same west-edge veto: `_west_edge()` is 33, player x=32 is outside it, so `_has_fire_lane()` fails at `game/enemy.gd:1014` (ray clear) and the left warning is cleared at `game/lab_route.gd:1044`; unprojected x was −92.0, so the side test itself would be sound. | test-stale. Rule judged against: side comes from the unprojected x sign (`game/lab_route.gd:1039-1045`), but only for a valid charging attacker (`game/enemy.gd:1014,1024`); the left position is outside the guard's ground like row 1. |
| clear lane restores warning | `game/tests/edge_warning_test.gd:45-46`: after returning player and camera to x=32 and foe to x=39, `right.visible`. | Same west-edge veto as row 1: `_west_edge()` = 33 (`game/enemy.gd:24-25`, from `game/lab_route.gd:161-164`), player x=32 fails `_has_fire_lane()` at `game/enemy.gd:1014`, warning cleared at `game/lab_route.gd:1044`. The preceding cover check passes (ray hits `SecurityCover` at x=41.6), so the lane is otherwise clear. | test-stale. Rule judged against: warning returns only when an unobstructed attacker can fire (`game/lab_route.gd:1026,1041`); the test's restore position is outside the guard's engagement edge. |

## Root causes

All four red checks share one cause: the test fixes Rend at x=32 while the guard it uses is the authored guard at x=40 with `min_x=37`. In WINDUP its western edge is `min(territory_min_x, pursuit_min_x) = min(37, 33) = 33` (`game/enemy.gd:24-25`, `game/lab_route.gd:161-164`), so `_has_fire_lane()` rejects player x=32 before any geometry check (`game/enemy.gd:1014`). `_update_edge_warnings()` then skips that foe (`game/lab_route.gd:1041`), and every check built on the right or left indicator fails while checks that only assert "not visible" pass trivially. A local probe moving player and camera to x=34 (east of 33) made all 13 checks pass, including both edge directions and the committed white state; no game code was changed. There is no evidence of a game bug or a harness crash. Headless is not the cause: the 64 × 64 viewport only changes pixel scale, and off-screen x values remain far outside it; the indicator draws and updates headless. The only headless difference in the test is that the PNG branch (`game/tests/edge_warning_test.gd:21-24`) is skipped.

## Proposed fixes

- `game/tests/edge_warning_test.gd`, `run()`: move the player and camera to x=34 (or lower the guard's `pursuit_min_x` below 32) so the right-edge guard has a valid firing lane and the warning is produced.
- `game/tests/edge_warning_test.gd`, `run()`: keep the same x=34 setup when setting `_state_t=0.6`, so the committed `>= 0.55` branch and the white/locked state are actually exercised.
- `game/tests/edge_warning_test.gd`, `run()`: use the same x=34 player/camera position for the left-direction case, leaving foe x=25 to test only the unprojected side.
- `game/tests/edge_warning_test.gd`, `run()`: restore player and camera to x=34 instead of 32 before the "clear lane" call, so the lane is valid after the cover step.
- Optional determinism in `game/tests/edge_warning_test.gd`, `run()`: set a fixed viewport size (for example `get_viewport().size = Vector2i(960, 540)`) before measuring, so headless (64 × 64) and windowed runs share the same projection scale.
