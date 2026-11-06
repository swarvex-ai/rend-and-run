# Diagnosis: shard_pickup_integration

base_commit: `b40d28d410f1e1eadd3addb6e83a054b69fbb036`.

## How I ran it

From `/work`:

```
tools/run_tests.sh --headless shard_pickup_integration
```

Godot 4.7.2. Runner summary at base_commit:

```
FAIL    quarantine shard_pickup_integration
---
      1 FAIL quarantine
=== quarantine shard_pickup_integration: exit 1, last 30 lines of test.log
PICKUP PASS break has visible reward before credit
PICKUP PASS scene reload reconstructs uncollected drop
PICKUP FAIL death preserves uncollected reward separately
PICKUP FAIL nearby drop does not pass through walls
PICKUP FAIL cannot collect from another elevation
PICKUP FAIL dead player cannot collect
PICKUP FAIL nearby living player attracts reward
PICKUP PASS pickup emits metal sound
PICKUP FAIL duplicate completion never credits twice
PICKUP FAIL saved collection and pending removal are atomic
PICKUP PASS legacy rewarded crate generates no second drop
PICKUP PASS invalid or unbroken crate records rejected
PICKUP SUMMARY checks=12 failures=7
```

Temporary local probes (not submitted) printed the runtime values below and, in a second run, reset `r.shards` to 0 between the independent pickup checks. With that reset only the death check still failed.

## Failing checks

| check | test expects (file:line) | game does (evidence) | verdict |
|---|---|---|---|
| death preserves uncollected reward separately | `game/tests/shard_pickup_integration.gd:30-31`: with wallet 2 and `on_player_death()`, pending `entry_supply` is 3, wallet becomes 0 and `death_cache.amount()` becomes 2. | Probe: `shards=2 cache=0 pending={entry_supply:3}`. `on_player_death()` releases the gate, resets the overseer and saves, but never calls `death_cache.replace()` (`game/lab_route.gd:1101-1114`); `game/modules/loot/death_cache.gd:2` calls the cache legacy compatibility only. Farming v0.2 says collected resources are kept, no body sack or drop penalty (`docs/design/farming-design-v02.txt:169-171`). | test-stale, judged against farming v0.2 and `lab_route.gd:1110-1111`: current policy keeps the wallet, so no cache is created; the old Hollow-Knight drop rule in `docs/glossary.md:22`/`docs/gdd.md:30` is no longer code. |
| nearby drop does not pass through walls | `game/tests/shard_pickup_integration.gd:32-36`: wall at x=3.65 between pickup at x=4 and player at x=3.3; after 0.7 s wallet is still 0. | Probe: wallet is still `2` (the value from the previous check), pickup stayed at `(4,0.28,0)`, `_collecting=false`; a manual layer-1 ray from the pickup hit the wall at x=3.725. Attraction requires `near` plus an empty ray (`game/modules/loot/shard_pickup.gd:39-43`). With the wallet reset to 0 this check passes and stays 0. | harness: the game honours the wall; the assertion carries the stale 2 from the death check and compares it to absolute 0. |
| cannot collect from another elevation | `game/tests/shard_pickup_integration.gd:37-40`: player at `(4,2,0)`; wallet is still 0. | Probe: wallet is still `2`, pickup `_collecting=false`. `near` requires `absf(player.y-(_home.y-.28))<.65` (`game/modules/loot/shard_pickup.gd:39`), so y=2 is outside the band. With the wallet reset to 0 this check passes. | harness: the elevation rule is enforced; the same carried 2 breaks the absolute assertion. |
| dead player cannot collect | `game/tests/shard_pickup_integration.gd:41-42`: player at `(4,0,0)` with `_dying=true`; wallet is still 0. | Probe: wallet is still `2`, pickup returned to `(4,0.28,0)`, `_collecting=false`. A dying player makes the pickup reset and drop collection (`game/modules/loot/shard_pickup.gd:34-37`), and `_collect_shard_pickup()` refuses while `_dying` (`game/lab_route.gd:778`). With the wallet reset to 0 this check passes. | harness: the death guard works; the carried 2 alone makes the check red. |
| nearby living player attracts reward | `game/tests/shard_pickup_integration.gd:43-46`: after `_dying=false` at x=4, wallet is exactly 3, pending and pickups are empty. | Probe: `shards=5` (2 carried plus 3 credited), pending empty, pickup freed. Credit runs through `reached` into `_collect_shard_pickup()` (`game/modules/loot/shard_pickup.gd:44-48`, `game/lab_route.gd:776-786`). With the wallet reset to 0 the probe gives `shards=3`, pending empty, pickup freed. | harness: attraction and credit work; the test expects a fresh wallet but starts at 2. |
| duplicate completion never credits twice | `game/tests/shard_pickup_integration.gd:48`: a second `_collect_shard_pickup("entry_supply")` leaves wallet 3. | Probe: wallet is 5 before and after the duplicate; the guard `if not pending_shards.has(id):return` rejects it (`game/lab_route.gd:777`). With a clean wallet the duplicate leaves 3. | harness: the game rejects the duplicate; only the stale carried total makes the equality fail. |
| saved collection and pending removal are atomic | `game/tests/shard_pickup_integration.gd:49-50`: saved JSON has shards 3, empty pending and `entry_supply` in `broken_crates`. | Probe: save holds shards=5, pending empty and the broken crate; the erase, credit and one `_save_progress()` happen together (`game/lab_route.gd:779-786,553-556`). With a clean wallet the save has `data.shards=3`, empty pending and the crate entry. | harness: persistence is atomic; the assertion fails only because it expects 3 instead of the carried total 5. |

## Root causes

**1. Stale death-drop expectation (row 1).** The test still expects every death to move the wallet into the death cache. The current game deliberately keeps collected currency and keeps uncollected rewards as pending state (`game/lab_route.gd:1110-1112`); `on_player_death()` has no `death_cache.replace()` call (`game/lab_route.gd:1101-1114`). This matches `docs/design/farming-design-v02.txt:169-171` and `game/modules/loot/death_cache.gd:2`, while `docs/glossary.md:22`, `docs/gdd.md:30` and `docs/scope-first-route.md:29` still describe the older drop rule. `docs/milestone-1.md:40` only requires that a death cache be recoverable once, not that a new death creates one. The probe values (`shards=2`, `cache=0`, pending 3) are therefore current behaviour, not a broken cache.

**2. One stale assertion cascades into six (rows 2-7).** The test sets `r.shards=2`, then expects the death call to zero it. Because the game keeps the 2, every later absolute assertion (`r.shards==0`, later `==3`) starts two shards too high. This is why the wall check looked like a through-wall pickup although the pickup never moved (`_collecting=false`) and the wall ray hit; why elevation and dead-player checks failed although the pickup stayed uncollected; why the living check saw 5 instead of 3; and why the duplicate and atomic-save checks saw 5. Resetting the wallet to 0 before the independent pickup checks made all six pass, and a separate probe confirmed the pickup stays pending through wall, elevation and death, then credits exactly once for a living nearby player. There is no shared "pickup never attracts" bug; if anything, the failure is the test not isolating state between checks.

No check failed from a crash or missing node; the seven failures are one stale rule plus test-state contamination.

## Proposed fixes

- Row 1: `game/tests/shard_pickup_integration.gd`, `run()`: assert the current keep-wallet rule (shards stay 2, pending stays 3, cache inactive); only if neVs restores the old drop rule, change `game/lab_route.gd`, `on_player_death()`, to call `death_cache.replace(shards, _last_grounded)` and zero the wallet before saving.
- Rows 2-7 (shared cause): `game/tests/shard_pickup_integration.gd`, `run()`: reset the wallet to a known value (or assert deltas and pending state) after the death check and before the wall, elevation, dead, living, duplicate and save checks, so the death result cannot leak into them.
- Rows 2-4: `game/tests/shard_pickup_integration.gd`, `run()`: assert the pickup remains valid and `pending_shards` is unchanged instead of only asserting `shards==0`, which makes the wall, elevation and death rules independent of the wallet.
