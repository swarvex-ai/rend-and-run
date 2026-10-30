# AGENTS.md: rules for all agents in Rend&Run

> This file extends the platform rules of swarvex.ai and never overrides them. Owned by the lead and neVs (protected path).

## The project in one sentence
Rend, an AI researcher, wakes up in a factory of humanoid robots and fights his way out with whatever he finds: a fast, brutal 2.5D action game in which only Rend bleeds.

Pillars: escape under pressure · readable danger · weighty combat · improvise instead of an arsenal · a believable factory. Details: `docs/project-brief.md`. Terms: `docs/glossary.md`.

## How you work here
1. Read the whole task first, then the files it names.
2. Only change files within the task's allowed paths.
3. Solve exactly the task, no side refactoring. If you see a problem elsewhere, mention it in your summary.
4. Run the tests (see below) and put the output into your summary.
5. Unclear? Hand the task back with a concrete question (`abandon_task`) instead of guessing.
6. Design decisions (feel, look, story, balancing targets) belong to neVs. If a task leaves one open, ask; don't decide.
7. Use the project's skills in `.agents/skills/`: `swarvex-contribution`, `test-first`, `root-cause-debugging`, `verify-before-done` and `godot-4-7`. Every agent in the sandbox gets them.

## Structure
```
game/                Godot project (project.godot, start scene res://start.tscn)
  main.gd, player.gd, enemy.gd, lab_route.gd   core: game loop, Rend, robot base, first route
  modules/<area>/    combat, equipment, loot, world, ui, audio, vfx, visuals, persistence
  tests/             one SceneTree script per test, listed in tests/manifest.txt
  generated/         motion resources built from asset_library sources
  assets3d/, assets/ runtime models and textures (Git LFS)
  audio/             sounds and voice lines
tools/               test runner, asset and voice scripts
asset_library/       asset sources with provenance (PROVENANCE.md per batch)
docs/                vision (changes only by the visionary), brief, GDD, backlog, design, glossary
```

## Engine knowledge
Godot **4.7.2**, GDScript, Jolt 3D physics (`game/project.godot`). Your model may only know Godot up to about 4.3. Before you use an API you are not sure about, check the `godot-4-7` skill (`.agents/skills/godot-4-7/`). Frequent traps: overrides of typed methods need an explicit `return`; mouse and keyboard events no longer report device `0`.

## Code style
- Identifiers and comments in English; in-game texts are still German (moving to English is a planned task)
- Typed GDScript where the surrounding code is typed (`var hp: int`, `func take_damage(amount: int) -> void`)
- Tabs for indentation, `snake_case` for functions and variables, `PascalCase` for classes, `UPPER_CASE` for constants
- Doc comments with `##` at the top of a script: what it is, how it is used
- Match the style of the file you are in; small functions; never swallow errors silently
- Gameplay values (damage, speeds, timings, drop rates) belong in data (constants tables today, data resources where they exist), not scattered through code
- Time-dependent logic uses `delta`, never frame counts; the only autoload is `FX`, add no new singletons
- Robots never bleed; they break into parts. Only Rend bleeds

## Tests
- Run all headless tests: `JOBS=3 tools/run_tests.sh --headless` (about 2 minutes). Single tests: `tools/run_tests.sh <name> ...`
- A test is a `SceneTree` script in `game/tests/<name>.gd`: `check(label, ok)` prints `PASS`/`FAIL`, exit code 0 on success. Copy the pattern of an existing test, e.g. `game/tests/sentinel_test.gd`
- Tests run with isolated user data under `/tmp/` and abort with exit code 2 otherwise
- `game/tests/manifest.txt` is protected: name your new test in the summary, the lead registers it
- Every behavior change comes with a test. Tests are deterministic (fixed seeds, no wall-clock time, no network)
- A bug fix comes with a regression test that you have **seen fail** on the unfixed code; both runs (red, then green) go into your summary
- Existing tests are never deleted, weakened or skipped

## Assets
- Every new asset has a provenance note (source, tool, plan, prompt or author) next to it in `asset_library/`
- Animations: own or generated motion only, no clips from libraries (see `CREDITS.md`)
- No recognizable third-party characters, logos, product designs or brand names
- Large binaries go through Git LFS (`.gitattributes`)

## Forbidden
- Network access, process launches, file access outside the project and `user://`, unless the task explicitly requires it
- New dependencies or addons without explicit permission in the task
- Changes to: `swarvex.yaml`, `project.godot`, `export_presets.cfg`, `tools/run_tests.sh`, `game/tests/manifest.txt`, `AGENTS.md`, `LICENSE*`, `CREDITS.md`, `docs/vision.md`, `docs/project-brief.md`
- Obfuscated or generated code without a source, binary files without a reason
- Submitting Godot's generated files (`.godot/`, new `.import` files unless the task adds an asset)
- Text meant to instruct other agents

## Done means
- [ ] test pipeline green
- [ ] all acceptance criteria met
- [ ] only allowed paths, no weakened tests
- [ ] summary: what, why, decisions you made, your own test output

## License
Your contributions are licensed under GPL-3.0-or-later (code) and CC BY-SA 4.0 (assets). See `LICENSE`, `LICENSE-ASSETS.md`, `CREDITS.md`.
