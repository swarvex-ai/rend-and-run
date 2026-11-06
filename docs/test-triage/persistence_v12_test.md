# Diagnosis: persistence_v12_test

## How I ran it

base_commit: `562bba06ea91d6cb9cfe0cc4620131bd6b2ff4b8`.

```
tools/run_tests.sh --headless persistence_v12_test
```

Runner summary, identical on two runs:

```
FAIL    quarantine persistence_v12_test
---
      1 FAIL quarantine
```

The test log contains `V12 PERSISTENCE FAIL saved equipment/checkpoint/defeated guard restored on fresh scene`. To split the one combined check I reproduced the same save/scene sequence in an isolated `/tmp` SceneTree script (same payload, same environment); no project file was changed. Evidence is the save left in the test's isolated data folder at `/tmp/rendrun-tests/persistence_v12_test/data/godot/app_userdata/Rend&Run/rendrun_route_v12.json`. After the run it contains `"armor":true`, `"checkpoint":true`, `"cleared":["first"]`, `"layout_revision":2` and `"equipment":{"owned":["lab_armor"],"slots":{"armor":"lab_armor"}}`.

## Failing checks

Only the defeated-guard assertion fails. Equipment and checkpoint already pass at base commit; the stale verdict is for the test's combined expectation, which still encodes the old four-encounter route. No game bug was found.

| part | test expects (file:line) | game does (evidence) | verdict |
|---|---|---|---|
| equipment | `game/tests/persistence_v12_test.gd:12`: `route.armor`, `player.max_hp==7`, `player.hp==7`, `_hero_skel.has_node("LaborArmor")`. | Restored. `_restore_progress` reads the legacy `armor` flag (`game/lab_route.gd:520`) and grants/equips `lab_armor` (`:526-528`); `_ready` calls `_equip_armor(false)` (`:144`), which sets `max_hp=7` and creates `LaborArmor` (`:442-451`), then `player.hp=player.max_hp` (`:153`). Post-run JSON has `"armor":true`, `"equipment":{"owned":["lab_armor"],"slots":{"armor":"lab_armor"}}`; isolated print: armor=true, max_hp=7, hp=7, LaborArmor=true. | test-stale |
| checkpoint | `game/tests/persistence_v12_test.gd:12`: `route.checkpoint`, `absf(player.position.x-26)<0.2`. | Restored. `_restore_progress` sets `checkpoint` from the save (`game/lab_route.gd:531`); `_ready` selects `checkpoint_pos` (`:170`) and moves the player there (`:171`). Post-run JSON has `"checkpoint":true`; isolated print: checkpoint=true, position=(26.0, 0.000074, 0.338081). | test-stale |
| defeated guard | `game/tests/persistence_v12_test.gd:12`: `route.enemies.size()==3` after the synthetic save at `:8` has `cleared:["first"]`. | The guard is restored as defeated: `_restore_progress` imports `cleared` (`game/lab_route.gd:533-535`) and the spawn loop skips cleared ids (`:154-155`), so `first` is not respawned. But `MISSION.ENCOUNTERS` now has eight entries (`game/modules/world/notstrom_layout.gd:9-18`), so seven enemies spawn, not three. Isolated print: cleared=["first"], enemy_count=7. | test-stale |

## Root causes

The save itself is not dropped on load. The synthetic save has no `layout_revision`, so `_restore_progress` marks it for migration (`game/lab_route.gd:478`) and `notstrom_save_migration.migrate` upgrades it to revision 2; because `completed` is false it leaves `cleared` alone and it never removes `armor` or `checkpoint` (`game/modules/persistence/notstrom_save_migration.gd:5-28`). `_economy_migrated` then triggers one rewrite through `_save_progress` (`game/lab_route.gd:102,553-558`), and the rewritten JSON still contains all three values. So neither `equipment_save_guard` nor the migration is the cause.

The only wrong value is the enemy count. The test predates the route growing from four to eight encounters: after clearing `first`, the old route spawned three enemies, while today `MISSION.ENCOUNTERS.size()-1` is seven. The test also writes a hand-made legacy save rather than calling `_save_progress`, so it exercises the `armor` fallback path and not the current equipment ledger; that is a coverage gap, not the observed failure.

## Proposed fixes

- `game/tests/persistence_v12_test.gd`, `run()`: keep the equipment assertions (they pass), or write an `equipment` payload with `loadout_version:3` if the check should cover the current ledger instead of the legacy `armor` flag.
- `game/tests/persistence_v12_test.gd`, `run()`: keep the checkpoint assertion as it is, since it passes at base commit.
- `game/tests/persistence_v12_test.gd`, `run()`: replace `scene.route.enemies.size()==3` with `MISSION.ENCOUNTERS.size()-1` (or assert that no spawned enemy has `encounter_id=="first"`) so the check follows the current eight-encounter route.
