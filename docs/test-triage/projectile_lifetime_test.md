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
