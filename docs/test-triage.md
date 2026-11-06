# Quarantined tests: triage (plan F2)

> Lead, 30.10.2026. Baseline: `tools/run_tests.sh --headless <all 28 quarantined>` on main of 30.10.2026, including the runner change of the same day. Logs were identical with and without a window (except `attack_cue_integration`: 2 red checks headless, 1 with a window).
> Result: 1 green, 23 red, 4 timeouts. Milestone-1 criterion (f) needs all M1 tests out of quarantine.

## Classes

| Class | Meaning | What happens |
|---|---|---|
| **G** green | passes headless | lead moves it to `headless` in the manifest |
| **S** stale | the test asserts a design or API that no longer exists (counts of props, removed functions, sword era) | level-B task: rewrite the test against `docs/milestone-1.md` and the current code; test files only |
| **H** harness | the test crashes in its own setup (null file, missing node) | level-B task: repair the test harness; test files only |
| **D** diagnose | M1 behaviour fails and nobody knows yet whether the code or the test is wrong | level-A task: written diagnosis per failing check; the lead then cuts the fix |

## Pipeline-red tests (05.11.2026)

The live test pipeline (official Godot 4.7.2 build, `JOBS=3`) failed docs-only submissions 2–12 at changing tests: arm_first_fight, dash_visual_test, nav_test, first_room_playthrough, crouch_gait_integration, hound_test, throwable_crate_test, farming_input_playthrough, movement_quality_integration. The same commit is green locally and in the pipeline image via `swarvex env`.

**Cause:** the live machine renders fewer headless frames per second than the 60 physics ticks. Godot then runs several physics ticks in one frame, and the tests' real-time waits (`create_timer`) drift against physics. Evidence: a VPS log of dash_visual_test shows a dash of 2.933 m (one tick too many) and a burst not yet retired; locally, throttling the old runner to 40 or 20 fps (`--max-fps`) turns arm_first_fight, crouch_gait_integration and hound_test red in 2 of 2 rounds.

**Fix:** `tools/run_tests.sh` runs headless tests with `--fixed-fps 60` (one physics tick and 1/60 s of game time per frame). On one contended core all 77 stay green (full suite in 285 s, arm_first_fight and dash_visual_test also 2 of 2 separately). Red tests now print their exit code and log tail to stdout, so the pipeline report keeps the details.

**Still open:** a Godot crash `SIGILL` seen twice live at `0x4fa5f1` of the official binary, a `ud2` right after a `cowdata.h:197` `get()` index error (`CRASH_BAD_INDEX`). That is an engine-side out-of-bounds access; the triggering test is still unknown.

## Quarantine changes (05.11.2026, evening)

- **Out of quarantine** after accepted repairs (#11–#15, #18): `loot_integration_test`, `equipment_integration_test` (hook), `crouch_combat_integration`, `service_lamp_integration`, `world_service_details_integration`, `attack_cadence_integration` (headless).
- **Hook tests run in the pipeline now:** `--headless` selects headless and hook tests and runs both in parallel. Before, the pipeline never ran hook tests. The runner also reads `get_environment('…')` in single quotes; that was the root cause of #18.
- **Into quarantine, flaky or broken without display:**
  - `first_room_playthrough`: the first fight uses unseeded enemy RNG (`enemy.gd:1115`); when Rend does not win it, the `assert` at line 38 does not end the script and the run hangs into the 240 s timeout. Red 4 times in a row locally on 05.11.; the game code is unchanged since 3b3f444.
  - `ranged_integration_test` (accepted #16): 'crouch evades committed high projectile' red once in five runs.
  - `landing_integration_test`: saves a screenshot without a headless guard (line 25), so it crashes without a display.
  - `depth_test` (added later the same evening): 'the dog comes round the cover and attacks' red in 2 of 7 full-suite runs (`dog x=39.17 z=0.82 state=2`), before and after F3 step 2; the test is unseeded.
- **Out of quarantine on 06.11.:** `shortcut_integration_test` (hook) after #17; full suite green twice with it (84 headless + 12 hook).
- **Out of quarantine on 06.11.:** `attack_cue_integration` (hook) after #53; full suite green twice with it (84 headless + 13 hook). Follow-up #89 makes its heavy-commitment check hit a robot that can take damage.
- **Out of quarantine on 06.11.:** `first_room_playthrough` (headless) after #54 (`seed(1)`, fail-fast checks); full suite green twice with it (85 headless + 13 hook).
- **Out of quarantine on 06.11.:** `landing_integration_test` (hook) after #56 (screenshot only with a display); full suite green twice with it (85 headless + 14 hook).
- **Out of quarantine on 06.11.:** `depth_test` (headless) after #58 (`seed(1)`, leftover fighters from part 1 parked so the dog is the only squad melee robot); full suite green twice with it (87 headless + 14 hook).
- **Out of quarantine on 06.11.:** `arena_gate_integration` (headless) after #65 (positions derived from `arena_gate`, death keeps the wallet, legacy cache reclaim); full suite green twice with it (89 headless + 14 hook).
- **Out of quarantine on 06.11.:** `persistence_v12_test` (headless) after #67 (split checks, legacy and current save format) and `shard_pickup_integration` (headless) after #68 (wallet kept on death, pickup and pending checked); full suite green twice with both (91 headless + 14 hook).
- **Out of quarantine on 07.11.:** `service_return_integration` (headless) after #69 (lift from `lift_x`, full completion, distance-based walk); full suite green twice with it (92 headless + 14 hook). `overseer_integration` stays in quarantine after #66: 32 of 33 green, only "visible low blade matches hit band" red (diagnosis #93).
- **Stays in quarantine:** `machinery_chamber_integration`. #19 found that nothing builds the machinery chamber any more (`lab_dressing.gd:17-26`); the test now fails fast instead of hanging.

Full suite after these changes: 79 headless + 11 hook, green twice in 120 s each.

## Per test

| Test | Result (pass/fail) | Class | Note |
|---|---|---|---|
| dash_visual_test | 17/0 green | G | move to headless |
| loot_integration_test | 0/1 | S | expects 3 supply crates, route has 4 (`CRATE_POSITIONS`) |
| service_lamp_integration | 15/3 | S | expects 4 lamps, route has 6 |
| world_service_details_integration | 10/1 | S | expects 11 cable segments |
| equipment_integration_test | 4/10 | S | sword era: "heavy blade", "fast sword"; today robot arm / reinforced arm (`item_catalog.gd`) |
| crouch_combat_integration | 7/10 | S | sword timing and "starter/heavy model" |
| coolant_test | 8/4 | S + D | one check uses "sword input"; three about brute/ranged interruption need diagnosis |
| ranged_integration_test | 0/1, timeout | S | calls removed `gun.get_charge()` |
| shortcut_integration_test | 1/2, timeout | S | reads removed `route.wayfinding` |
| attack_cadence_integration | 17/0, timeout | H | null file at line 99 (output path) |
| machinery_chamber_integration | 0/0, timeout | H | null node at line 17 |
| route_v12_test | 9/6 | S + D | "four authored encounters" is stale (8 today); death/checkpoint, gate, exit completion need diagnosis |
| arena_gate_integration | 4/5 | D | entry lock, return block, cache on death |
| overseer_integration | 19/13 | D | boss HUD, legacy timings, death reset, exit opening |
| persistence_v12_test | 0/1 | D | save not restored on fresh scene |
| shard_pickup_integration | 5/7 | D | pickup through walls, other elevation, dead player, atomic save |
| service_return_integration | 7/7 | D | shortcut lift back to the first room |
| workbench_integration | 13/12 | D | purchase, focus, gamepad/keyboard, save |
| pressure_step_test | 2/5 | D | roles 1 and 2 do not close distance or punish |
| guard_spacing_test | 9/5 | D | retreat step |
| edge_warning_test | 4 red | D | off-screen threat indicator |
| projectile_lifetime_test | 6/3 | D | bolt damage after the shooter is freed |
| guard_integration_test | 18/2 | D | guard break cue, stamina |
| attack_cue_integration | 8/2 | D | high cue, heavy commitment warning |
| feedback_priority_integration | 6/1 | D | supply reward hides save warning |
| security_pair_test | 6/3 | D | security pair engagement, jump over barrier |
| duelist_footwork_test | 11/2 | D | shield bearer base (role 1) |
| brute_commitment_test | 1/3 | D | overseer base (role 2) |

## Order

1. **G and S/H now** (tests only, no game code): they give back a safety net before the lead splits `lab_route.gd` (F3).
2. **D diagnoses now** (level A, no code): one written report per test.
3. **Fixes after F3**: the lead cuts fix tasks from the diagnoses; the code changes then land in the split files instead of the monolith.

## Corrections found on the way

- `item_catalog.gd` is not farming: it holds robot arm, reinforced arm, salvage shield and lab armour, the M1 equipment. Frozen farming = servo trial and prefix ledger only.
