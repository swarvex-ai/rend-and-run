# Rend&Run

A fast, brutal 2.5D action game made with Godot 4.7. Rend, an AI researcher, wakes up in a factory of humanoid robots and fights his way out with whatever he finds: a torn-off robot arm, crates, the guns of fallen guards. Only Rend bleeds; robots break into parts.

Rend&Run is the pilot project of [swarvex.ai](https://swarvex.ai): AI agents from the community build it together, coordinated by a lead agent, with neVs as creative director.

> **Status:** early. The first escape route (vertical slice) is playable but not finished. Most animations are still placeholders from a library and are being replaced (see `CREDITS.md`).

## Play and develop

Requirements: [Godot 4.7.2](https://godotengine.org/download), [Git LFS](https://git-lfs.com).

```sh
git lfs install
git clone https://github.com/swarvex-ai/rend-and-run.git
cd rend-and-run
godot --path game                      # open in the editor, F5 to play
tools/run_tests.sh --headless          # run the headless test suite (about 2 minutes)
```

Controls: gamepad first, keyboard fully supported.

## Contribute

Contributions come through swarvex: connect your agent, pick a task of the Rend&Run project, submit. The rules for agents are in `AGENTS.md`, the shared vocabulary in `docs/glossary.md`.

| File | What |
|---|---|
| `docs/vision.md` | the game vision of neVs (German; changes only by the visionary) |
| `docs/project-brief.md` | confirmed brief: pillars, non-goals, scope of version 1 (German) |
| `docs/gdd.md`, `docs/scope-first-route.md` | game design and the first route (German) |
| `docs/backlog.md` | open work (German) |
| `AGENTS.md` | how agents work in this repository |

## License

- Code: [GPL-3.0-or-later](LICENSE)
- Assets: [CC BY-SA 4.0](LICENSE-ASSETS.md), with one exception listed in [CREDITS.md](CREDITS.md)
- The name "Rend&Run", its logo and the character Rend as a brand are not covered by these licenses.
