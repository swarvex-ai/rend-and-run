# Menu style guide — variant 1

This guide defines a gamepad-first menu system for Rend&Run: a flat dark lab field, petrol and off-white surfaces, copper rules, and a cyan focus marker, with all text in Saira and IBM Plex Mono. It fixes colours, sizes, timings, contents, focus and sounds so the Options screen can be the reference and every other menu copies it.

## Mood in three words

**Controlled — mechanical — urgent.** Flat dark surfaces, thin copper rules, no glow or blur; focus moves in 90 ms.

## Palette

Source: `docs/art/art_bible_p02_v01/ART_BIBLE.txt`, section 2. Only its palette and the "colour is not the only signal" rule are used.

| sRGB hex | Name | Use |
|---|---|---|
| `#11151E` | Grundschatten | Full-screen background and page frame; not text. |
| `#23525B` | Petrol | Focused row fill and slider track; text on it is `#CAD5CF`. |
| `#CAD5CF` | Broken light edge | Primary text: menu items, body, hints, focus marker. |
| `#62D6CC` | Interaction | Focus ring, active slider fill, subtitle; never warnings. |
| `#B77850` | Oxidised copper | 2 px page-frame border, 1 px dividers, section underlines; never text. |
| `#F2B05E` | Telegraph | warning: warning icon and "Unsaved changes" text in confirmation dialogs only; never normal focus. |

Text/background pairs (WCAG 2.x formula, sRGB):
- `#CAD5CF` on `#11151E` = **12.11:1** (menu items, body, hints).
- `#CAD5CF` on `#23525B` = **5.73:1** (focused row text).
- `#62D6CC` on `#11151E` = **10.44:1** (subtitle).
- `#F2B05E` on `#11151E` = **9.69:1** (warning text only).
- `#F2B05E` on `#23525B` = **4.59:1** (warning text only).
- `#B77850` is never used for text.

## Typography

Both fonts are SIL OFL 1.1, compatible with GPL-3.0-or-later and CC BY-SA 4.0.

| Font | Licence | Source | Use |
|---|---|---|---|
| **Saira** | SIL OFL 1.1 | https://github.com/google/fonts/tree/main/ofl/saira | Title, menu items, body, hints. |
| **IBM Plex Mono** | SIL OFL 1.1 | https://github.com/IBM/plex | Option values, percentages, version, key hints. |

Sizes at 1920×1080:
- **Title**: 96 px Saira SemiBold, uppercase, line height 104 px.
- **Menu item**: 36 px Saira Medium, line height 52 px.
- **Body**: 24 px Saira Regular, line height 34 px.
- **Hint**: 18 px Saira Regular, line height 26 px.
- **Option value**: 24 px IBM Plex Mono Medium.

## Layout and grid

Measurements at 1920×1080; base unit 8 px; safe margin 96 px.

- Page frame: 880×888 px, x=520, y=96; background `#11151E`; 2 px `#B77850` border; 0 px radius; no shadow; 32 px inner padding.
- Menu rows: 52 px high, 8 px apart, 16 px left/right padding; text left-aligned at frame+32.
- Options split: label column 360 px, control column 416 px; slider track 320×4 px; knob 20×20 px.
- Title screen: wordmark x=160, y=160; subtitle y=280; prompt y=920; version x=1744, y=1016.
- Pause: same frame over an 88% `#11151E` scrim.

## Screens

**Title**
1. Wordmark `REND&RUN`, 96 px, `#CAD5CF`.
2. Subtitle `LABORSEKTOR 01`, 24 px, `#62D6CC`.
3. Prompt `Press any button`, 24 px, `#CAD5CF`.
4. Version `0.1.0-prealpha`, 18 px, bottom-right.
- Back: nothing. A, Start, Enter, Space or click advances to Main; Esc/B do nothing.

**Main**
1. Continue (default focus with a save; disabled and skipped without one).
2. New run (confirmation if a save exists).
3. Options.
4. Credits.
5. Quit (Cancel / Quit confirmation).
- Version `0.1.0-prealpha`, 18 px, bottom-right.
- Back: Esc/B do nothing on the list. In confirmations B/Esc returns to Main with focus on the opener.

**Pause**
1. Resume (default focus).
2. Restart at checkpoint (Cancel / Restart confirmation).
3. Options.
4. Main menu (Cancel / Main menu confirmation).
5. Quit to desktop (Cancel / Quit confirmation).
- Back: Esc, B or Start resumes; in confirmations B/Esc cancels.

**Options**
1. Master volume.
2. Music volume.
3. Effects volume.
4. Voices volume.
5. Window mode: Windowed / Fullscreen / Borderless.
6. VSync: Off / On.
7. Subtitles: Off / On.
8. Slow motion: On / Off.
9. Screen shake: On / Off.
10. Back.
- Volumes 0–100% in 5% steps; defaults Master 100, Music 70, Effects 85, Voices 90. VSync, subtitles, slow motion and screen shake default On.
- No key rebinding. Changes apply and save immediately; Back never discards.
- Back: Esc/B returns to the opener and keeps all values; focus returns to the Options item.

**Credits**
1. Heading `CREDITS`.
2. Project line `REND&RUN — Pre-Alpha 0.1.0`.
3. Role lines: Game design, Code, 3D art, Audio, Fonts.
4. Licence lines: Code GPL-3.0-or-later; Assets CC BY-SA 4.0; Saira and IBM Plex Mono under SIL OFL 1.1.
5. Back (default focus; pinned to the bottom).
- Back: Esc/B returns to Main or the end card.

## Focus and navigation

Focused state (not colour-only):
- Fill `#23525B`; 3 px `#62D6CC` ring inset 2 px; a 6×24 px `#CAD5CF` marker bar at the left edge, 16 px from the frame.
- Text stays `#CAD5CF`. The marker is a shape cue in grayscale.

Gamepad:
- D-pad/left stick up/down moves one row; repeat 300 ms initial, then 90 ms.
- Up from the first row wraps to the last, down from the last wraps to the first; Back is the last row.
- Left/right: 5% per press on volumes, cycle Window mode, toggle the other switches; hold 300 ms, then 90 ms.
- A confirms; B backs/cancels; Start opens Pause and resumes from Pause.
- Disabled rows are skipped.

Keyboard:
- Up/Down (or W/S) moves; Left/Right (or A/D) changes values.
- Enter/Space confirms; Esc backs, except on Main and Title where it does nothing.
- Wrap-around matches gamepad. In two-button confirmations focus wraps; Esc/B cancels, Enter/A confirms.

## Motion

Timings use Godot `Tween`; none exceeds 300 ms.

| Event | Duration | Transition / ease | Motion |
|---|---|---|---|
| Screen in | 180 ms | `Tween.TRANS_QUART`, `Tween.EASE_OUT` | Frame fades 0→1 and moves +16 px to 0. |
| Screen out | 140 ms | `Tween.TRANS_QUAD`, `Tween.EASE_IN` | Frame fades 1→0 and moves 0→+8 px. |
| Focus change | 90 ms | `Tween.TRANS_QUAD`, `Tween.EASE_OUT` | Fill and ring fade; marker moves to the row. |
| Value change | 60 ms | `Tween.TRANS_QUAD`, `Tween.EASE_OUT` | Slider fill and knob only. |
| Backdrop fade | 120 ms | `Tween.TRANS_LINEAR` | Scrim opacity only. |

No bounce, overshoot, blur or full-screen slide.

## Sound

All UI sounds use the Effects bus; no menu music or ambience in M1.

| Event | File | Treatment |
|---|---|---|
| Focus move | `game/audio/radio_chirp.wav` (existing) | -18 dB, no pitch change. |
| Confirm | `game/audio/block.wav` (existing) | -14 dB, pitch 0.95. |
| Back | `new` — dry, low servo click with a 2-semitone downward tail, 90 ms, no reverb. | -16 dB. |

## Do and don't

| Do | Don't |
|---|---|
| Use `#F2B05E` only for warning text and icons. | Use amber for normal focus, hover or sliders. |
| Show focus with fill, 3 px ring and 6×24 px marker. | Rely on colour alone. |
| Keep menu items at 36 px and body at 24 px. | Go below 18 px for menu text. |
| Keep transitions at 300 ms or less. | Add bounce, overshoot, blur or full-screen slides. |
| Keep corners square and surfaces flat. | Add glass, glow, gradients or shadows. |
| Use exactly Saira and IBM Plex Mono. | Add a third or unlicensed font. |
| Use the three sounds above. | Add menu music or ambience in M1. |

## Open questions for neVs

1. **Title treatment:** text wordmark or logo beside it? Recommendation: text-only `REND&RUN` at 96 px for M1; logo when B8 has one.
2. **Settings:** save immediately or only on Back? Recommendation: immediate apply and save, no Apply button.
3. **Pause exit:** `Quit to desktop` as well as `Main menu`? Recommendation: keep both, each with its own confirmation.
4. **Menu backdrop:** flat `#11151E` or frozen game behind Pause? Recommendation: flat for Title, Main and Credits; an 88% scrim over the frozen frame for Pause.
5. **Accessibility defaults:** subtitles, slow motion and screen shake start On? Recommendation: all three On, so players opt out of the complete default.
