# Credits and asset sources

## People and agents
- **neVs**: idea, vision, creative direction, playtests
- **Claude** (Anthropic): lead developer since 22.10.2026
- **Codex** (OpenAI) and **Hermes** agents: development until 22.10.2026, on behalf of neVs
- swarvex contributors: see the Git history and the project page on swarvex.ai

## Engine and tools
| What | License |
|---|---|
| [Godot Engine](https://godotengine.org) 4.7 | MIT |
| [Blender](https://www.blender.org) (bakes, edits) | GPL (the tool; its output belongs to the author) |
| [Piper](https://github.com/rhasspy/piper) text to speech, voices `en_US-norman-medium` and `en_US-kristin-medium` | voices trained on public-domain LibriVox recordings |
| Godot 4.7 engine reference for agents (`.agents/skills/godot-4-7/`), from [Claude Code Game Studios](https://github.com/Donchitos/Claude-Code-Game-Studios) via swarvex | MIT, Copyright (c) 2026 Donchitos |

## Asset sources
| Source | What | Status |
|---|---|---|
| [Meshy](https://www.meshy.ai), paid plan: text/image to 3D, texturing, remesh, rigging, text to image | characters, robots, weapons, props, concept images | generated results owned by neVs, published under CC BY-SA 4.0; provenance in `asset_library/meshy/*/PROVENANCE.md` |
| Meshy text to motion | Rend's clips `rend_hold_arm` and `rend_hold_ribs` | owned by neVs, CC BY-SA 4.0 |
| image generated with AI by neVs | look reference `docs/vision-referenz.jpg` | owned by neVs, CC BY-SA 4.0 |
| own synthesis (scripts in `tools/`) | combat sounds, siren, radio, ambience | CC BY-SA 4.0 (ambience also CC0, see `game/audio/ambience/manifest.json`) |

## Exception: animations from the Meshy animation library

Most motion clips (idle, walk, run, jumps, strikes, hit reactions, deaths, carrying, throwing, shooting) come from **Meshy's animation library**. Meshy licenses them only as part of a generated result, not on their own. They are therefore **not** covered by CC BY-SA 4.0 and may only be used as part of Rend&Run. This concerns:

- the animation tracks inside the character models under `game/assets3d/characters/**` and `game/assets3d/releases/**`
- the motion resources in `game/generated/*.tres`, except the two text-to-motion clips named above

They are being replaced step by step with own or generated motions (project task series). Each replacement removes its clip from this list.
