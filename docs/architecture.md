# Architecture

How the Godot project under `game/` is put together: which script owns what, who depends on whom, how data flows, and where new content plugs in. State: `main` on 05.11.2026 (game code as released in `3b3f444`). Terms follow `docs/glossary.md`.

## Start and scene tree

- `project.godot` starts `res://start.tscn` (`start.gd`): the title and start menu. It reads the route save to offer Continue and then loads `main.tscn`.
- `main.tscn` (`main.gd`) is the game level. It owns the camera, Rend (`player.gd`), the HUD, the pause controller and the route (`lab_route.gd`). Robots are created through `main._make_enemy(x, role, script, gun, shield)` (`main.gd:124`).
- `lab_route.gd` builds the authored route in `_build_route()` (`lab_route.gd:575`): world dressing, encounters, pickups, doors, checkpoints. It also saves and restores progress.
- The only autoload is `FX` (`fx.gd`): hit stop, screen shake, sound playback and effect counters that tests read (`FX.metal_contacts`, `FX.landing_events`, `fx_stats`). No other singletons (AGENTS.md).

## Core scripts

| Script | Responsibility | Depends on |
|---|---|---|
| `start.gd` | title and start menu, Continue / New run | `pause_controller.gd`, modules/ui, modules/persistence |
| `main.gd` | level root: camera with shake, respawn, HP display, robot factory `_make_enemy`, starts hook tests | `lab_route.gd`, `enemy.gd`, `pause_controller.gd`, modules/combat |
| `player.gd` | Rend: movement, jump, crouch, dash, arm melee, guard and parry, shield, damage and death | `crouch_pose.gd`, `guard_pose.gd`, `shield_visual.gd`, modules/combat, equipment, audio, vfx, visuals |
| `enemy.gd` | robot base class: state machine IDLE → ALERT → CHASE → WINDUP → SWING → RECOVERY (`enemy.gd:86`), strikes (`STRIKES`, `enemy.gd:71`), roles 0–3, damage, breaking apart | `crouch_pose.gd`, `death_fragments.gd`, modules/combat, vfx, visuals |
| `lab_route.gd` | the route: building, encounters, shards and wallet, workbench, checkpoints, shortcut, save/restore, PA cues; starts hook tests | `lab_dressing.gd`, `shield_visual.gd`, all modules |
| `lab_dressing.gd` | visual-only background behind the playable plane | modules/world |
| `pause_controller.gd` | pause and resume, pause menu | modules/ui |
| `fx.gd` | autoload `FX` (see above) | modules/vfx |
| `crouch_pose.gd`, `guard_pose.gd` | pose layers (crouch with leg IK, guard arm) for Rend and robots | – |
| `death_fragments.gd` | pieces a destroyed robot breaks into | modules/combat |
| `shield_visual.gd` | Rend's shield models (salvage, riot) | – |

`lab_route.gd` (1235 lines), `enemy.gd` (1161) and `player.gd` (997) are large. Splitting `lab_route.gd` into route data and route logic is lead work F3 (#50); until then, two tasks never change the same core script at the same time.

## Modules (`game/modules/<area>/`)

| Area | Scripts | Responsibility | Depends on |
|---|---|---|---|
| `audio` | 3 | factory ambience, foot contact clock, robot voice lines (`robot_voice.gd`) | – |
| `combat` | 24 | robot types beyond the base (`sentinel.gd`, `enemy_dog.gd`, `lab_overseer.gd`, `maintenance_drone.gd`), guns (`gun.gd`, `energy_bolt.gd`, pickups), guard and parry (`guard_state.gd`), squad behaviour (`squad_director.gd`, `guard_spacing.gd`, `attack_cadence.gd`), throwable crates, arena gate, hit physics | `crouch_pose.gd`, `shield_visual.gd`, modules/vfx, modules/world |
| `equipment` | 3 | item catalog (`item_catalog.gd` `ITEMS`), wallet and loadout (`equipment_ledger.gd`), prefix ledger (frozen for M1) | – |
| `loot` | 6 | supply crates, shard pickups, coolant canister, death cache, servo trial and ledger (servo trial frozen for M1) | modules/visuals |
| `persistence` | 3 | atomic JSON writer, equipment save guard, save migration | modules/loot, modules/world |
| `ui` | 11 | start, pause, equipment and workbench menus, combat HUD, ammo HUD, boss status, edge threat indicator, end card | modules/equipment |
| `vfx` | 11 | effects without gameplay: attack cue chevron, sparks, debris, dust, trails, explosion, blood spray (Rend only) | – |
| `visuals` | 16 | static or decorative models: lamps, cables, canisters, weapon visuals, world service details | – |
| `world` | 17 | route layout data (`notstrom_layout.gd`), doors, checkpoints, cameras, assembly line, power sector, corridor, wayfinding module | modules/audio, combat, visuals |

The dependencies point one way: core → modules, and inside modules toward `vfx`, `visuals` and `audio`, which depend on nothing. Module scripts have no `class_name` (except `AtomicJsonWriter`) and are loaded with `preload("res://modules/...")`. Many module headers state their limits ("no scene/input/file access"); keep them.

## Data flows

- **Player ↔ robots.** Robots read Rend's position and `hurt_height()` (`player.gd:211`). A hit goes through `player.take_damage()`, or through `guard_state.resolve_hit()` (block, parry). Rend's hits reach robots through `take_melee_hit()`. A parry stuns the robot.
- **Robots ↔ squad.** `squad_director.gd` lets robots radio each other, pick a flanker and allow one melee windup at a time; `attack_cadence.gd` spaces attacks across robots.
- **Robots → route.** A destroyed robot emits `defeated`. The route records the encounter id in `cleared`, credits shards (`_enemy_defeated`) and opens doors when all encounters are cleared.
- **Route → save.** `lab_route._save_progress()` (`lab_route.gd:551`) writes `user://rendrun_route_v12.json` through the atomic JSON writer. It holds encounters cleared, shards, pending shards, broken crates, equipment, checkpoint and shortcut state. `_restore_progress()` (`lab_route.gd:474`) reads it; `start.gd` reads it for Continue. Tests use `user://rendrun_route_v12_test.json` and isolated user data under `/tmp/`.
- **Everything → FX.** Gameplay code calls `FX.play()`, `FX.add_shake()`, hit stop and metal contact; tests read FX counters to prove feedback happened.

## Extension points

Each extension point has one reference example. A new variant copies it and is a level B task.

| Extension point | Where it is defined | Reference example | Contract or behaviour test |
|---|---|---|---|
| Robot type | subclass of `enemy.gd`, attached through the `script` field of an encounter | `game/modules/combat/sentinel.gd` | `sentinel_test`, `hound_test` (dog) |
| Encounter on the route | `ENCOUNTERS` in `game/modules/world/notstrom_layout.gd:9` (id, x, role, territory, gun, shield, script) | the `hound` entry | `route_rewards_integration`, `mission_extent_integration` |
| Gun | `SPECS` in `game/modules/combat/gun.gd:20` | `pistol` | `gun_test`, `ammo_test` |
| Robot strike | `STRIKES` in `game/enemy.gd:71` (clip, band low/high, depth, cue kind) | `slash` | `strike_review` (window), `crouch_gait_integration` |
| Equipment item | `ITEMS` in `game/modules/equipment/item_catalog.gd:4` | `reinforced_arm` | `equipment_integration_test`, `loadout_test` |
| Supply crate | `CRATE_POSITIONS` in `game/lab_route.gd:52` | `entry_supply` | `loot_integration_test`, `supply_crate_test` |
| Effect | standalone `Node3D` in `game/modules/vfx/` with a counter for tests | `landing_dust.gd` | `landing_dust_test` |
| Robot voice line | `game/modules/audio/robot_voice.gd` lines and subtitles | `intruder` | `voice_test` |

Planned (F3, #50): route data and an English text table move out of `lab_route.gd`. That adds two extension points (route beats as data, texts by key). E11.2 (#52) adds a `MenuScreen` base for menus.

## Tests and the contract

- One `SceneTree` script per test in `game/tests/`, listed in `game/tests/manifest.txt` with its kind: `headless`, `hook` (started by the game with an env flag), `window`, `probe`, `fixture`, `quarantine`.
- `tools/run_tests.sh --headless` runs headless and hook tests in parallel, without a display, with a fixed game clock (`--fixed-fps 60`). That is what the test pipeline runs (`swarvex.yaml`).
- Rules for severity, quarantine and regression tests: `docs/qa.md`.
