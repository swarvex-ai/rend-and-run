# Diagnosis: projectile_lifetime_test

## How I ran it

base_commit: `64487271911e6ac81cd4ae608059b89e562fbac0`. From `/work`:

```
tools/run_tests.sh --headless projectile_lifetime_test
```

Summary at base_commit (6 PASS, 3 FAIL):

```
FAIL    quarantine projectile_lifetime_test
V49 FAIL live shooter projectile still deals one damage
V49 FAIL actual fired bolt owns impact handler
V49 PASS handler does not retain shooter
V49 FAIL flight still damages after shooter is freed
V49 PASS resolved bolt and handler are freed
V49 PASS single hit retains damage and direction
V49 PASS live attacker attribution preserved for parry
V49 PASS checkpoint territory remains protected
V49 PASS boundary impact also cleans up
V49 SUMMARY failures=3
```

A temporary local probe (prints only, restored byte-for-byte afterwards) showed `guard gun=smg`, `lane=false`, and no bolt after the first or second `_fire_energy`; with the territory gate opened locally, the gun fired, but the bolt still had only the visual child and stopped damaging once the shooter was freed.

## Failing checks

| check | test expects (file:line) | game does (evidence) | verdict |
|---|---|---|---|
| live shooter projectile still deals one damage | `game/tests/projectile_lifetime_test.gd:21`: after `guard._fire_energy(p)` and 0.7 s, `p.hp` drops from 5 to 4. | The guard is `route.enemies[2]` (`guard`, role 3, `territory_min_x=37`, `notstrom_layout.gd:12`), but the test moves it to x=32 and leaves that territory at 37 (`projectile_lifetime_test.gd:18`) while placing Rend at x=35 (`:17`). `_has_fire_lane()` rejects `player.x < _west_edge()` (`game/enemy.gd:1013-1014`), and `_fire_energy()` returns before `_fire_gun_burst()` (`game/enemy.gd:1023-1033`), so `gun.gd:188-204` never creates a bolt and the flight code at `energy_bolt.gd:73-94` is never reached. Probe: `lane=false`, `bolts after first=[]`. Lowering `guard.territory_min_x` locally made the same shot deal exactly 1 damage. Rule judged: a live shot at a valid target deals its damage; the gate is correct, the fixture is outside the current territory. | harness |
| actual fired bolt owns impact handler | `game/tests/projectile_lifetime_test.gd:27`: the bolt from the second shot exists and has two children, i.e. visual plus an impact handler. | At base no bolt exists because the same territory gate returns first. With territory lowered so the gun fires, the bolt has one child, `BoltVisual`; `energy_bolt.gd:35-50` builds only that visual. The handler is instead `gun._on_impact`, connected at `gun.gd:201`; `energy_impact.gd` is only attached as a bolt child by the old pulse-emitter branch (`game/enemy.gd:1038-1041`). Rule judged: `energy_impact.gd:1-4` states the handler is owned by the projectile, not the shooter. The `child_count()==2` shape is pulse-specific, but the ownership contract is not met by the current gun. | game-bug |
| flight still damages after shooter is freed | `game/tests/projectile_lifetime_test.gd:31`: after `guard.queue_free()`, the in-flight bolt still takes `p.hp` from 5 to 4. | Base also has no bolt from the lane gate. With territory lowered the bolt is fired, but `gun.gd:201` binds `bolt.impacted` to the gun's `_on_impact`; the gun is a child of the shooter's weapon pivot, so freeing the guard frees the gun and drops the connection. `energy_bolt.gd:86-90` still emits `impacted`, but no projectile-owned `energy_impact.gd:16-21` resolver is attached, so nothing damages or frees the bolt. Probe after the free: `p.hp=5`, `bolt_valid=true`; the bolt only disappears later from the timer at `gun.gd:204`. Rule judged: a shot already in flight survives its shooter's destruction. | game-bug |

## Root causes

1. **Fixture drift explains row 1 and also blocks rows 2–3 at base.** The test teleports the current `guard` encounter to x=32 without moving its authored `territory_min_x=37` (`notstrom_layout.gd:12`). Rend at x=35 is west of that edge, so `enemy.gd:1013-1024` correctly refuses to fire. The comparable ranged test already sets `foe.territory_min_x=30.0` for exactly this reason (`game/tests/ranged_integration_test.gd:24`).

2. **The ranged guards now use Meshy guns, not the pulse emitter.** `_attach_weapon()` gives every role-3 enemy with `gun_kind` a `gun.gd` node (`game/enemy.gd:265-272`), and `_fire_energy()` delegates to `_fire_gun_burst()` (`game/enemy.gd:1031-1033`). `gun.fire()` spawns an `energy_bolt.gd` but attaches no `energy_impact.gd`; it stores hit resolution in `_on_impact` on the gun itself (`game/gun.gd:197-204,225-231`). That breaks both the projectile-owns-handler contract (row 2) and survivability after the shooter dies (row 3).

3. **Current robots only fire guns from `gun.gd` SPECS.** The route's three role-3 encounters use `smg`, `pistol` and `energy_rifle` (`notstrom_layout.gd:12,14,16`); `power_sector.gd:61` spawns a role-3 `scattergun`. No current encounter omits `gun`, so the pulse-emitter branch at `enemy.gd:270-272` is not used in play. The rule still matters, and the gun code does not fulfil it.

## Proposed fixes

- `game/tests/projectile_lifetime_test.gd`, `run()`: set `guard.territory_min_x` below x=35 (or move Rend east of the guard's edge) before firing, so `_has_fire_lane()` tests the projectile rather than the territory gate.
- `game/modules/combat/gun.gd`, `fire()`: attach a projectile-owned impact handler/`energy_impact`-style node to each bolt (with damage, direction, shooter weak reference and piercing) instead of connecting `bolt.impacted` to `gun._on_impact`.
- `game/modules/combat/gun.gd`, `_on_impact()`/`fire()`: move hit resolution and bolt freeing onto that projectile-owned handler so the signal connection survives the shooter's death.

## Flaky after #81

### Reproduction count and commands

Checked out commit `87871ef06fa9dc664aa19e759babaa6758d5cf93`. At this commit the manifest already lists the test as `quarantine projectile_lifetime_test V49_TEST` (`game/tests/manifest.txt:90`), so plain `--headless` skips it. I used the quarantine form:

```
tools/run_tests.sh --headless --quarantine projectile_lifetime_test
```

- 12 runs without probes: 1 red, 11 green (red on run 1).
- 32 runs with the temporary prints below: 2 red (runs 16 and 30), 30 green.
- Total: **3 red in 44 single-test runs (~7 %)**. Every red failed exactly the same two checks together (`flight still damages after shooter is freed`, `resolved bolt and handler are freed`); the other seven passed.
- One full pipeline run `JOBS=3 tools/run_tests.sh --headless --quarantine`: this test green; the two failures were the other quarantined tests (`machinery_chamber_integration`, `overseer_integration`).

The probes were removed afterwards; all four touched game/test files match their original SHA-256 again.

### Evidence: red vs green

The first four SMG spreads are identical in both runs; only the second burst's spread differs. The red run's second bolt goes up over Rend and never resolves:

| | red (run 16) | green (run 1) |
|---|---|---|
| first burst spreads | `-0.01334 -0.01129 -0.02984 -0.01428` | `-0.01334 -0.01129 -0.02984 -0.01428` |
| second shot spread | `+0.06666` rad (+3.82°) | `-0.02725` rad (-1.56°) |
| second bolt direction | `(0.973795, 0.188922, -0.126615)` | `(0.987219, 0.096781, -0.126615)` |
| flight near Rend | `x=34.59 y=1.34 z=0.05`, next `x=35.11 y=1.44 z=-0.02` | `x=34.62 y=1.09 z=0.05`, next `x=35.15 y=1.14 z=-0.02` |
| result | passes over the player, no `impacted`, no `_resolve_impact` | `hit=Player`, `RESOLVE ... point=(34.68, 1.10, 0.04)`, `hp=4`, bolt freed |
| at the check | `bolt_valid=true pos=(56.40, 5.57, -2.79) resolved=false` | `bolt_valid=false` |

Red print (second burst onward):

```
PROBE FIRE kind=smg cone=4.00000 spread=0.06666 dir=(0.973795, 0.188922, -0.126615) origin=(31.99053, 0.831937, 0.387153)
PROBE TEST bolt=239628983317 pos=(31.99053, 0.831937, 0.387153) resolved=false handler=Impact:<Node#239729641854>
PROBE FLY ... from=(34.58731, 1.335729, 0.049514) to=(35.10667, 1.436488, -0.018014) hit=<null>
PROBE FLY ... from=(35.10667, 1.436488, -0.018014) to=(35.62603, 1.537246, -0.085542) hit=<null>
PROBE TEST after free player=(35.0, 0.01, 0.0) hp=5 bolt_valid=true bolt_pos=(56.40026, 5.567588, -2.786653) resolved=false
V49 FAIL flight still damages after shooter is freed
V49 FAIL resolved bolt and handler are freed
```

Green print (same point in the test):

```
PROBE FIRE kind=smg cone=4.00000 spread=-0.02725 dir=(0.987219, 0.096781, -0.126615) origin=(31.99053, 0.831937, 0.387153)
PROBE TEST bolt=239628983317 pos=(31.99053, 0.831937, 0.387153) resolved=false handler=Impact:<Node#239729641854>
PROBE FLY ... from=(34.62312, 1.090019, 0.049514) to=(35.14963, 1.141635, -0.018014) hit=Player:<CharacterBody3D#122893108866>
PROBE RESOLVE id=239628983317 collider=Player:<CharacterBody3D#122893108866> point=(34.68011, 1.095606, 0.042204)
PROBE TEST after free player=(35.0, 0.01, 0.0) hp=4 bolt_valid=false bolt_pos=(0.0, 0.0, 0.0) resolved=false
```

Two temporary forced experiments isolate the geometric cause (5th shot spread pinned to the red value `0.06666`):

- fixture unchanged (short capsule): 3 red in 3 runs, bolt passes over the head as above;
- fixture with `Collision.shape.height=1.65` and `position.y=0.825` (the standing size the game itself sets): 6 green in 6 runs; the same direction hits Rend at `hp=4`.

### Root cause

1. **The test gives Rend a 1.3 m collision capsule, 0.35 m shorter than the one the game uses.** `game/tests/projectile_lifetime_test.gd:18` disables the player's physics process and teleports him to y=0.01. `player.gd:_update_defense()` (`game/player.gd:231-239`) is the only place that sets `$Collision.shape.height = hurt_height()` (1.65 standing, `game/player.gd:210-211`) and `position.y = hurt_height()*0.5`. With physics disabled it never runs, so the scene default from `game/main.tscn:61-63,156-158` stays: height 1.3, centre y=0.65, top at ~1.31 above the floor. The gun aims at the chest (`enemy.gd:_chest()`, `game/enemy.gd:1019-1022`: `hurt_height()*0.7` ≈ 1.16), and the SMG's ±4° spread (`gun.gd:SPECS["smg"]` at `game/modules/combat/gun.gd:24-26`, applied at `gun.gd:194-196`) can add ~0.2 m at the 3 m distance. A near-max up-spread puts the sweep at y=1.34–1.44 at Rend's x: above the fixture's 1.31 m top, but inside the real 1.65 m standing capsule. In a real game the shot hits; only the fixture loses it.

2. **The spread is not seed-locked over the hit window.** The test calls `seed(1337)` once (`game/tests/projectile_lifetime_test.gd:15`), but the later shots read the same global RNG (`gun.gd:195`) that cosmetic per-frame code also consumes: camera shake after a hit (`game/main.gd:100-102`), welding arcs (`game/modules/world/welding_arm.gd:67`) and flickering lights (`game/modules/visuals/light_flicker.gd:16-27`). In addition `FX.hitstop()` restores time from a **real-time** timer (`game/fx.gd:114-125`, `ignore_time_scale=true`); under `--fixed-fps` the number of frames that pass during a 0.045–0.06 s wall-clock hitstop depends on CPU load. That changes how many `randf` calls happen before the second burst, which is exactly what the logs show: identical first four spreads, different second spread. This is why it is rarer alone and more likely in the parallel pipeline.

3. **The test's timing turns a miss into two failures.** When the second bolt misses, it is still alive at the check. Its life is 0.9 s (`gun.gd:25`); the test waits 0.08 + 0.7 s = 0.78 s after the shot (`game/tests/projectile_lifetime_test.gd:31-35`), before expiry (`game/modules/combat/energy_bolt.gd:73-94`) and before the gun's 1.0 s `queue_free` timer (`gun.gd:211`). So the same missed shot fails both "still damages" and "is freed", matching the lead's observation.

### Verdict

**Test/fixture, not a game bug.** The projectile handler and resolver are fine: every bolt that touches the capsule emits `impacted` and resolves even after the shooter is freed. The red runs are an intentionally random SMG pellet passing over a *test-shortened* collision capsule. No evidence that robots' bullets can do no damage in play; the one-shot expectation in the test is simply not guaranteed by a spread weapon.

(Fragility remains: even with the correct capsule, asserting that one random pellet must hit is a weak fixture. Fixing the capsule makes ±4° at this 3 m distance hit, but the test should not depend on cosmetic RNG at all.)

### Proposed fixes

- `game/tests/projectile_lifetime_test.gd`, `run()`: after the teleport, give Rend his standing capsule: `p.get_node("Collision").shape.height = p.hurt_height()` and `p.get_node("Collision").position.y = p.hurt_height() * 0.5` (or leave the player's physics process enabled and call `_update_defense()`), so the fixture matches `player.gd:_update_defense()`.
- `game/tests/projectile_lifetime_test.gd`, `run()`: make the second shot independent of the global RNG, e.g. call `seed(...)` immediately before `guard._fire_energy(p)` (with a value whose spread hits) or fire from closer range; do not rely on the single seeded stream surviving the hit VFX.
- `game/tests/projectile_lifetime_test.gd`, `run()`: if a shot may miss, wait beyond `life + 0.1` (≥1.0 s) before `resolved bolt and handler are freed`, so a miss fails only the damage check rather than both.
- Optional hardening in `game/modules/combat/gun.gd`, `fire()`: use a gun-owned `RandomNumberGenerator` instead of the global `randf_range`, so cosmetic RNG consumers and real-time hitstop cannot change weapon spread between runs.
