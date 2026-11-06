# Diagnosis: workbench_integration

base_commit: `d2e26c749354408bebd2c37b78e48adc00e48f08`.

## How I ran it

From `/work`:

```
tools/run_tests.sh --headless workbench_integration
```

Godot 4.7.2. Runner summary at base_commit (the test file was restored after probing; 13 pass, 12 fail):

```
FAIL    quarantine workbench_integration
---
      1 FAIL quarantine
=== quarantine workbench_integration: exit 1, last 30 lines of test.log

H69 FAIL initial purchase focus
H69 FAIL D-pad skips disabled equipped item
H69 FAIL keyboard explicit purchase once
H69 FAIL invalid id cannot spend
H69 FAIL same-frame duplicate blocked
H69 FAIL gamepad explicit equip starter
H69 FAIL closing B does not dodge or attack
H69 FAIL Esc closes without pause stacking
H69 FAIL unaffordable disabled and shortage
H69 FAIL no available action focuses close
H69 FAIL failed save is explicit without second spend
H69 FAIL purchase survives reload
H69 SUMMARY checks=25 failures=12
```

A temporary local probe (not submitted) printed the runtime values quoted below; it did not change game code. The test file is back at base_commit.

## Failing checks

| check | test expects (file:line) | game does (evidence) | verdict |
|---|---|---|---|
| initial purchase focus | `game/tests/workbench_integration.gd:31`: focus is `shop._vibro_action` right after opening with 20 shards. | Probe: `owned=[]`, `starter_dis=true`, `vibro_dis=true`, focus `CloseButton`, shortage `Zuerst den Humanoidenarm am Start bergen.` The base arm is a world pickup (`game/lab_route.gd:112,1212-1225`; `docs/milestone-1.md:28`), so without it `workbench_menu.gd:182-187` disables the upgrade and `_primary()` (`:138-147`) returns close. Rule: buy only after the base arm; current item `reinforced_arm` (`game/modules/equipment/item_catalog.gd:13-20`). | test-stale |
| D-pad skips disabled equipped item | `game/tests/workbench_integration.gd:36`: after down to close then up, focus returns to `_vibro_action`, skipping the disabled equipped starter. | Probe: focus stays `CloseButton`; `vibro_dis=true` because `owned=[]` and no base arm. `move_selection()` filters disabled buttons (`workbench_menu.gd:376-383`); refresh disables the upgrade without the starter (`:182-187`). Rule: D-pad skips disabled actions; with no base arm close is the only enabled action. Current upgrade `reinforced_arm` (`item_catalog.gd:13-20`). | test-stale |
| keyboard explicit purchase once | `game/tests/workbench_integration.gd:38`: Enter buys once, leaving 8 shards (20-12), owns `vibroblade`, weapon stays `starter_sword`. | Probe: Enter went to close and closed the menu; `shards=20 owned=[] weapon="" focus=<none>`. The ids are sword-era: `vibroblade`/`starter_sword` are not in `item_catalog.gd:4-37`; current upgrade is `reinforced_arm` cost 6 (`:13-20`), base `robot_arm` cost 0 (`:5-12`). Rule: current ids/costs; buying does not auto-equip (`equipment_ledger.gd:52-69`, `lab_route.gd:867-880`). | test-stale |
| invalid id cannot spend | `game/tests/workbench_integration.gd:40`: after `apply_workbench_action("not-an-item")`, shards remain 8. | Probe: shards remain 20. The invalid id is rejected without spending at `lab_route.gd:863-864`; `:850` already returned because the menu was closed. The "cannot spend" intent holds; the expected 8 is the stale sword-era baseline. Current item `reinforced_arm` (`item_catalog.gd:13-20`). | test-stale |
| same-frame duplicate blocked | `game/tests/workbench_integration.gd:43`: buying `vibroblade` then equipping `starter_sword` in one frame leaves weapon `vibroblade`, shards 8. | Probe: `weapon="" shards=20`; calls are no-ops because the shop is closed. The duplicate guard exists at `lab_route.gd:865-866` and purchase is atomic (`equipment_ledger.gd:52-69`), so no double spend occurs. Rule: same-frame duplicate must not spend; the stale ids and closed-shop precondition keep the guard untested. Current ids `robot_arm`/`reinforced_arm` (`item_catalog.gd:5-20`). | test-stale |
| gamepad explicit equip starter | `game/tests/workbench_integration.gd:46`: gamepad A on the starter action equips `starter_sword`, shards stay 8. | Probe: `weapon="" shards=20`; the starter action cannot be focused or pressed while hidden and not owned. Current starter is `robot_arm` (`item_catalog.gd:5-12`), granted by the world pickup (`lab_route.gd:1212-1225`); `equip_weapon` accepts only owned weapons (`equipment_ledger.gd:76-81`) and the menu disables starter when not owned/equipped (`workbench_menu.gd:164-169`). Rule: current id and acquisition (`docs/milestone-1.md:28`). | test-stale |
| closing B does not dodge or attack | `game/tests/workbench_integration.gd:50`: after B closes the shop and two physics frames, `_dash_left<=0` and `_attack_phase==0`. | Probe: `dash=0.08 attack=0`. B closes the shop (`B closes only shop` passes) but still starts a dodge. `pause_controller.gd:25-39` consumes B and calls `resume()`, which releases inputs and waits two physics frames (`:59-79`); `player.gd:240-243` starts dodge on `is_action_just_pressed("dodge")` on the first gameplay physics frame. Rule: `docs/milestone-1.md:18` criterion d (keyboard and gamepad); closing B must not dodge/attack. | game-bug |
| Esc closes without pause stacking | `game/tests/workbench_integration.gd:55`: after opening and Esc, not paused and neither shop nor pause menu visible. | Probe: `paused=true focus=BtnResume`; the pause menu is open. Row 7 left `_dash_left=0.08`, so `_use_workbench()` refused to open (`lab_route.gd:841`); the Esc event then fell through to the pause toggle (`pause_controller.gd:44-48`) instead of closing the shop. Rule: criterion d; Esc must close the shop without stacking a pause screen. | game-bug |
| unaffordable disabled and shortage | `game/tests/workbench_integration.gd:60`: with shards 3 and base arm, upgrade disabled and shortage `Es fehlen 9 Splitter` (12-3). | Probe: `shards=3 owned=[] focus=<none> shopvis=false`, shortage `Zuerst den Humanoidenarm am Start bergen.` The preceding B leak keeps the shop closed (`lab_route.gd:841`); after `equipment.reset()` the base arm is gone, so `workbench_menu.gd:182-187` shows the "collect arm first" branch. Even if opened with the base arm, cost 6 gives `Es fehlen 3 Splitter` (`item_catalog.gd:13-20`). Rule: current cost and base-arm requirement (`docs/milestone-1.md:28,40`). | test-stale |
| no available action focuses close | `game/tests/workbench_integration.gd:61`: when no action is affordable, focus is close. | Probe: `focus=<none> shopvis=false`; the shop never opened because row 7's dodge remains (`lab_route.gd:841`). With the menu open and all actions disabled, `_primary()` returns `_btn_close` (`workbench_menu.gd:138-147`), so the intended focus rule works but is untested. Rule: criterion d; unavailable actions must focus close. | game-bug |
| failed save is explicit without second spend | `game/tests/workbench_integration.gd:77`: blocking `SAVE_PATH` makes the action set `save_error`, keep shards 8 and show `Speichern fehlgeschlagen`. | Probe: `shards=20 owned=[] save_error=false feedback=Unbekannte Ausrüstung.` The id `vibroblade` is unknown, so `lab_route.gd:863-864` rejects it before `_save_progress()` (`:882-884`); no save is attempted. With a valid id the save-failure path exists (`:553-558`); current item `reinforced_arm` cost 6 (`item_catalog.gd:13-20`). | test-stale |
| purchase survives reload | `game/tests/workbench_integration.gd:93`: after reload, owns `vibroblade`, shards 8, weapon `starter_sword`. | Probe after reload: `shards=20 owned=[] weapon=""`; no valid purchase or save occurred because `vibroblade` is not in `item_catalog.gd:4-37`. Current ids are `robot_arm`/`reinforced_arm` (`:5-20`); import recognizes only `ITEMS` ids (`equipment_ledger.gd:114-158`) and a fresh export is loadout_version 3 (`:100-111`), so the sword-era id would not survive either. Rule: current ids and persistence path (`lab_route.gd:471-474,517-519,553-558`). | test-stale |

## Root causes

**1. Shared stale sword-era economy and acquisition setup (rows 1-6, 9, 11, 12).** The test buys a `vibroblade` for 12 shards and expects `starter_sword` to remain equipped. Those ids are absent from `game/modules/equipment/item_catalog.gd:4-37`; the current base weapon is `robot_arm` (cost 0, acquired from the world pickup at `game/lab_route.gd:112,1212-1225`) and the upgrade is `reinforced_arm` (cost 6, `item_catalog.gd:13-20`). The test also opens the workbench before collecting or granting the base arm, so the menu correctly disables the upgrade and focuses close (`workbench_menu.gd:138-147,182-187`). This single stale assumption explains the first six rows, the stale shortage text and reset setup in row 9, and the save/reload rows 11-12. The cost change alone means a correct purchase should leave 14 shards, not 8.

**2. Shared B-close input leak and its cascade (rows 7, 8, 10, and row 9's closed shop).** `pause_controller.gd:25-39` consumes B and calls `resume()`, but the dodge action still fires on the first gameplay physics frame (`player.gd:240-243`); the probe shows `_dash_left=0.08` after B. That positive dash value makes later `_use_workbench()` calls return at `lab_route.gd:841`. Consequently the Esc check finds a closed shop and toggles the pause menu instead (`pause_controller.gd:44-48`), the unaffordable check sees a closed shop, and the focus-close check never reaches the menu's fallback focus. This is the second shared cause and the only game bug found in the workbench/input path; the invalid-id and duplicate-spend guards themselves behave correctly.

No check crashed or missed a node, so none is a harness failure. The game's save-failure path (`lab_route.gd:553-558,882-884`) and persistence import (`equipment_ledger.gd:114-158`) exist but are bypassed by the stale id in rows 11-12.

## Proposed fixes

- `game/tests/workbench_integration.gd`, `run()`: before `_use_workbench()`, grant and equip `robot_arm` (or call `route.collect_start_arm()`), so the base-arm acquisition matches `docs/milestone-1.md:28` and the menu offers the upgrade.
- `game/tests/workbench_integration.gd`, `run()`: replace `vibroblade`/`starter_sword` with `reinforced_arm`/`robot_arm` and derive expected shards from `ITEMS.ITEMS["reinforced_arm"].cost` (14 after buying from 20) and the shortage text from the same cost (`Es fehlen 3 Splitter`).
- `game/tests/workbench_integration.gd`, `run()`: after `route.equipment.reset()`, re-grant and equip `robot_arm` so row 9 reaches the "Es fehlen ..." branch in `workbench_menu.gd:186-187` instead of "Zuerst den Humanoidenarm ...".
- `game/tests/workbench_integration.gd`, `run()`: in rows 11-12, use valid `reinforced_arm` so the blocked `SAVE_PATH` actually exercises `_save_progress()` and asserts `save_error` plus `Speichern fehlgeschlagen`, then reload and assert the current ids and 14 shards.
- `game/tests/workbench_integration.gd`, `run()`: wait for or clear `player._dash_left`/`_attack_phase` before the later `_use_workbench()` calls so rows 8-10 test Esc/shortage/focus rather than the row 7 leak.
- `game/pause_controller.gd`, `resume()`/`_finish_shop_resume()`: keep the `dodge` action released until after unpausing and the first gameplay physics tick (or defer unpause one more frame), and add a regression test for "B closes shop without dodge/attack" to the manifest.
