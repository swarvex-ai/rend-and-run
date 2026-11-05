# 0002: Menu style guide for M1

- Status: accepted · 05.11.2026 · decided by the lead (neVs delegated the choice: "du hast die freie Wahl")
- Context: tasks #38 and #39 produced two menu style guides (`docs/design/menus/style-guide-variant-1.md`, `docs/design/menus/style-guide-variant-2.md`). Both meet all twelve acceptance criteria. E11.2 (#52) builds the reference screen "Options" from one binding guide.

## Decision

**Variant 2 is the binding menu style guide**, with the amendments below. Variant 1 is credited and stays in the repo as reference.

Why variant 2:
- It leaves less to guess for the swarm: 12-column grid with fixed panel widths, stick deadzone and hysteresis, key repeat, focus memory per screen, and clamping rules for sliders.
- Larger hint text (22 px instead of 18 px) helps readability from the couch (pillar "readable danger", brief G-5).
- Its in-game texts are English throughout (variant 1 has the German subtitle `LABORSEKTOR 01`).
- Same palette rules as variant 1 (amber only for warnings, focus not by colour alone), with all contrast values checked.

Amendments taken from variant 1:
1. **Pause** gets a fifth item: `Quit to desktop` after `Quit to main menu`, with its own confirmation (variant 1, Screens → Pause).
2. **Options defaults**: Master 100, Music 70, Effects 85, Voices 90. VSync, Subtitles, Slow motion and Screen shake start On (variant 1, Screens → Options).

The five open questions in variant 2 are decided as recommended there:
1. Title background: static `#11151E` field with the wordmark and a 2 px copper rule.
2. Wordmark: `REND&RUN` in caps, 96 px, −1 % tracking.
3. Credits: terminal panel, Inter for names, JetBrains Mono for licences.
4. Destructive confirmation: a single A press, amber warning icon, B cancels.
5. Pause wording: `To checkpoint`.

## Consequences

- E11.2 (#52) and E11.3–E11.9 build from `style-guide-variant-2.md` plus this record. Where they disagree, this record wins.
- Fonts Inter and JetBrains Mono (SIL OFL 1.1) come in with E11.2, with an entry in `CREDITS.md`.
- `game/audio/menu_back.wav` is a new sound; E11.2 gets it as an asset task (level A).
- Cost if wrong: small. Palette, fonts and timings live in one theme resource from E11.2 onward, so swapping in variant 1's values is a level B task.
