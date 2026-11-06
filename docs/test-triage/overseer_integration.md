# Diagnosis: overseer_integration

## How I ran it

base_commit: `562bba06ea91d6cb9cfe0cc4620131bd6b2ff4b8`. From `/work`:

```
tools/run_tests.sh --headless overseer_integration
```

Representative run at base_commit (temporary prints were added only to confirm the values below, then the test file was restored byte-for-byte):

```
FAIL    quarantine overseer_integration
---
      1 FAIL quarantine
P28 SUMMARY checks=32 failures=13
```

The run is deterministic: 19 checks pass and the same 13 fail on every run.

## Failing checks

| check | test expects (file:line) | game does (evidence) | verdict |
|---|---|---|---|
| interior activates with alert | `game/tests/overseer_integration.gd:35-37`: player at x=47.8, then boss physics step must set `active` and state `ALERT`. | Player x=47.8 is west of `ADMISSION_X`; `ADMISSION_X` is `BOSS_ENTRY_X` 70 (`game/modules/combat/lab_overseer.gd:5`, `game/modules/world/notstrom_layout.gd:4-5`) and `_physics_process` returns below it (`lab_overseer.gd:24-31`). Observed: `active=false bossx=73 playerx=47.8 admission=70`. Judged against the M1 route, which puts the overseer at 73 and the arena entry at 70 (`docs/milestone-1.md`, zone 05). | test-stale |
| owner activates boss HUD | `game/tests/overseer_integration.gd:39`: after `route._process(0)` the HUD is visible and its bar is 12. | The owner passes `boss_alive and overseer.active` to the HUD (`game/lab_route.gd:224-226`); because activation failed the value is false and `update_state` sets `visible = _active` (`game/modules/ui/overseer_status.gd:46-54`). Same stale activation coordinate as the row above. | test-stale |
| repeat hit still deals full damage | `game/tests/overseer_integration.gd:48-50`: a 1-damage hit during RECOVERY lowers HP from 12 to 11. | The overseer ignores all melee damage while inactive: `take_melee_hit` returns when `not active` (`game/modules/combat/lab_overseer.gd:64-67`). Observed: `active=false hp_before=12 hp_after=12`. Same stale activation coordinate. | test-stale |
| retreat resets without trapping | `game/tests/overseer_integration.gd:82-85`: player at x=45 makes the boss reset to HP 12, phase 1, unsevered, at x=49. | No reset happens because the boss was never active (`lab_overseer.gd:24-31`). Even with `active=true`, `reset_encounter` restores `_home`, which is `BOSS_X` 73, not 49 (`lab_overseer.gd:11,69-85`; `notstrom_layout.gd:4`). Observed after the step: `hp=3 severed=true x=49` (x=49 was set by the earlier hit-routing block, not by reset). | test-stale |
| legacy role timing 0 | `game/tests/overseer_integration.gd:90`: role 0 windup 0.44 and recovery 0.48. | Base enemy returns windup 0.44 but recovery 0.40 (`game/enemy.gd:1145-1149`). Observed: `windup=0.44 recovery=0.40 expect_r=0.48`. Judged against the test's own intent "Existing default role timings remain exactly unchanged" (`overseer_integration.gd:89`), which still holds only the old recovery table. | test-stale |
| legacy role timing 1 | `game/tests/overseer_integration.gd:90`: role 1 windup 0.40 and recovery 0.38. | Base enemy returns windup 0.40 but recovery 0.32 (`game/enemy.gd:1145-1149`). Observed: `windup=0.40 recovery=0.32 expect_r=0.38`. Same stale recovery table. | test-stale |
| legacy role timing 2 | `game/tests/overseer_integration.gd:90`: role 2 windup 0.64 and recovery 0.70. | Base enemy returns windup 0.64 but recovery 0.62 (`game/enemy.gd:1145-1149`). Observed: `windup=0.64 recovery=0.62 expect_r=0.70`. The overseer overrides both methods (`lab_overseer.gd:48-55`), so it did not change the base role-2 values. | test-stale |
| legacy role timing 3 | `game/tests/overseer_integration.gd:90`: role 3 windup 0.44 and recovery 0.48. | Base enemy returns windup 0.44 but recovery 0.40 (`game/enemy.gd:1145-1149`). Observed: `windup=0.44 recovery=0.40 expect_r=0.48`. Same stale recovery table. | test-stale |
| autonomous encounter uses both attacks | `game/tests/overseer_integration.gd:91-105`: after reset, player at x=47.7, 300 physics frames must show a high and a low contact. | Player x=47.7 is below `ADMISSION_X` 70, so the boss never activates and never attacks (`lab_overseer.gd:24-31`). Observed: `seen={} bossactive=false bossx=73 playerx=47.7`. With the player moved to x=71.7 the same loop sees both contacts, so the AI is not broken. | test-stale |
| death resets boss and preserves reachable shard cache | `game/tests/overseer_integration.gd:107-109`: after death, boss HP 12 and inactive, and the death cache holds 7 shards at x=47. | Boss reset passes, but `on_player_death` no longer writes the death cache (`game/lab_route.gd:1101-1116`); only legacy caches are imported/reclaimable (`lab_route.gd:489-492`, `game/modules/loot/death_cache.gd:1-4`). Observed: `bosshp=12 bossactive=false cacheactive=false cacheamt=0 shards=7`. Judged against M1's economy, which needs the existing cache to be recoverable once, not a new cache on every death. | test-stale |
| cache can be reclaimed on next attempt | `game/tests/overseer_integration.gd:111`: `reclaim_shards()` succeeds and shards become 7. | No cache was created by the death, so `reclaim_shards` returns false at the active-cache guard (`game/lab_route.gd:1121-1123`). Observed: `shards=7 active=false`. Same stale new-death-cache assumption. | test-stale |
| boss defeat opens exit and records legacy id | `game/tests/overseer_integration.gd:113-115`: after clearing `first`, `duelist`, `guard` and killing the boss, `gate_open` is true and `"brute"` is in `cleared`. | The boss kill records `"brute"` (`game/lab_route.gd:419-423`), but the exit gate opens only when all eight current encounters are cleared (`lab_route.gd:437-439`; `game/modules/world/notstrom_layout.gd:9-18`). Observed: `cleared=["first","duelist","guard","brute"] gate=false`. The M1 route has eight encounters, not four. | test-stale |
| completed legacy id prevents boss respawn | `game/tests/overseer_integration.gd:123-127`: after reload the overseer is not spawned and `gate_open` is true. | The legacy id does prevent respawn: `_ready` skips cleared ids (`game/lab_route.gd:155-156`). The gate assertion fails for the same reason as the row above, because the saved `cleared` list has only four of eight ids (`lab_route.gd:177,437-439`). Observed: `overseer_valid=false gate=false cleared=["first","duelist","guard","brute"]`. | test-stale |

## Root causes

1. **Stale legacy arena coordinates (5 checks).** The test still uses the old arena around x=47-49, while the M1 layout moved the arena gate to 70 and the overseer to 73 (`notstrom_layout.gd:4-5`). Activation, HUD, repeat damage, retreat reset and autonomous attacks all depend on that first activation, and the retreat check additionally expects the old home x=49 instead of `BOSS_X` 73.

2. **Stale base-role recovery table (4 checks).** The base enemy recovery durations are now 0.40/0.32/0.62/0.40, while the test still expects 0.48/0.38/0.70/0.48 (`enemy.gd:1145-1149`). The overseer overrides both timing methods (`lab_overseer.gd:48-55`), so it did not cause this change; the regular role table was retuned independently and the test's copy is stale.

3. **Stale death-cache model (2 checks).** The current contract keeps the wallet on a new death and treats the cache as legacy compatibility only (`death_cache.gd:1-4`); `on_player_death` resets the boss but does not call `death_cache.replace` (`lab_route.gd:1101-1116`). The test still expects every death to create a reclaimable cache.

4. **Stale four-encounter route assumption (2 checks).** The route now has eight encounters (`notstrom_layout.gd:9-18`), and the exit gate needs all eight (`lab_route.gd:437-439`). The test pre-clears only the old three plus the boss, so the gate stays closed; the legacy-id respawn suppression itself works.

## Proposed fixes

- **RC1:** In `game/tests/overseer_integration.gd`, `run()`, replace the hard-coded arena x values (45, 47.7, 47.8 and the expected 49) with values derived from `MISSION.BOSS_ENTRY_X` and `MISSION.BOSS_X`, and assert the reset position against `BOSS_X`.
- **RC2:** In `game/tests/overseer_integration.gd`, `run()`, change the expected recovery array to `[.40,.32,.62,.40]` (or read the values from the enemy instance) and keep the unchanged windup expectations.
- **RC3:** In `game/tests/overseer_integration.gd`, `run()`, either seed the cache with `route.death_cache.replace(7, Vector3(47,0,0))` before the death checks, or replace those checks with the current no-new-cache wallet contract.
- **RC4:** In `game/tests/overseer_integration.gd`, `run()`, mark every id in `MISSION.ENCOUNTERS` as cleared before killing the boss so `_open_gate()` can run, and use that full list for the reload check.
