# Review: docs/architecture.md and docs/qa.md (F6, task #49)

Checked all 12 `path:line` references in `docs/architecture.md` (11 distinct locations; the `enemy.gd` STRIKES reference appears twice): **5 are wrong**. The checks below use the code at the task base commit.

## Wrong

- `_build_route()` is cited at line 575 of `lab_route.gd`, but it is defined at `game/lab_route.gd:577`.
- `_save_progress()` is cited at line 551 of `lab_route.gd`, but it is defined at `game/lab_route.gd:553`.
- `_restore_progress()` is cited at line 474 of `lab_route.gd`, but it is defined at `game/lab_route.gd:476`.
- `hurt_height()` is cited at line 211 of `player.gd`, but it is defined at `game/player.gd:210`.
- `CRATE_POSITIONS` is cited at line 52 of `game/lab_route.gd`; line 52 is `supply_crates`, the alias is at `game/lab_route.gd:54`, and the definition is `game/data/route_layout.gd:24`.
- `lab_route.gd` is said to have 1235 lines, but the file ends at `game/lab_route.gd:1230`.
- The `persistence` module row says 3 scripts, but the area has 4 (`game/modules/persistence/settings_store.gd:1`).
- The `ui` module row says 11 scripts, but the area has 13 (`game/modules/ui/menu_screen.gd:1`, `game/modules/ui/options_menu.gd:1`).
- The `audio` row says it depends on nothing (the "one way" paragraph repeats this), but `robot_voice.gd` preloads the settings store at `game/modules/audio/robot_voice.gd:51` and `game/modules/audio/robot_voice.gd:74`.
- The `world` row calls `notstrom_layout.gd` "route layout data"; that file holds mission beats and encounters (`game/modules/world/notstrom_layout.gd:2`), while route placements are in `game/data/route_layout.gd:2`.
- "E11.2 (#52) adds a `MenuScreen` base" is already present at `game/modules/ui/menu_screen.gd:1` and extended by `game/modules/ui/options_menu.gd:1`.
- QA exit: the command `JOBS=3 tools/run_tests.sh --headless` cannot include a quarantined test ("with the test included"), because `--headless` selects only headless and hook (`tools/run_tests.sh:29`, `tools/run_tests.sh:72`); `--quarantine` or a named run is required (`tools/run_tests.sh:30`, `tools/run_tests.sh:71`).
- QA retired-test example `machinery_chamber_integration` is not retired or deleted: it is still a `quarantine` line (`game/tests/manifest.txt:68`) and the chamber script still exists (`game/modules/visuals/machinery_chamber.gd:1`).
- QA says the pipeline "reruns red tests once" and runs a counter-check; `run_tests.sh` runs each selected test once (`tools/run_tests.sh:82`, `tools/run_tests.sh:85`) and `swarvex.yaml:7` contains no retry.
- QA says probes need a display; probes are not run by the suite at all (`tools/run_tests.sh:26`), and at least `encounter_probe` is documented as `--headless` (`game/tests/encounter_probe.gd:17`; see also `game/tests/jump_timing_probe.gd:11`).

## Missing

- `game/data/route_layout.gd` and `game/data/route_texts.gd` are absent from the Modules table; only the later F3 paragraph names them (`game/data/route_layout.gd:1`, `game/data/route_texts.gd:1`).
- `settings_store.gd` is missing from the persistence responsibility list, and `menu_screen.gd`, `options_menu.gd`, `combat_hint_text.gd`, `feedback_priority.gd` are missing from the ui list (`game/modules/persistence/settings_store.gd:1`, `game/modules/ui/menu_screen.gd:1`).
- `fx.gd` also depends on `modules/persistence/settings_store.gd` (`game/fx.gd:105`), but the core table lists only `modules/vfx`.
- No rule says that the default and `--headless` runs skip the `probe` and `fixture` manifest kinds; only the manifest header does (`game/tests/manifest.txt:6`, `game/tests/manifest.txt:9`).

## Unclear

- "`main.tscn` ... owns ... the HUD, the pause controller and the route": `main.tscn` contains only the camera and the player (`game/main.tscn:148`, `game/main.tscn:152`); the pause controller and route are created in `game/main.gd:26` and the HUD in `game/lab_route.gd:87`.
- "Robot type ... attached through the `script` field of an encounter" with `sentinel.gd` as the reference: the sentinel is created directly at `game/lab_route.gd:670`, while the encounter `script` field is shown by the `hound` entry (`game/modules/world/notstrom_layout.gd:13`).
- "The dependencies point one way" is contradicted by the `combat` ↔ `world` cycle (`game/modules/combat/maintenance_drone.gd:29`, `game/modules/world/power_sector.gd:72`); does "one way" mean gameplay direction or import direction?
- The doc states its state is "game code as released in `3b3f444`" (`docs/architecture.md:3`), but this review targets base commit `ec135d9`; a reader cannot tell which code the stale rows are supposed to describe.
