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
