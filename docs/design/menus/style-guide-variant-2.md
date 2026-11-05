# Menu style guide — variant 2

The menu is a dim control terminal inside the factory: petrol surfaces, copper edges and one cool interaction colour, with amber reserved for warnings. Every screen shares one grid, focus marker, motion timing and sound set, so the Options reference screen can be copied without guessing.

## Mood in three words

**Controlled. Mechanical. Provisional.** A working terminal, not a consumer product: calm layout, visible seams, no decoration that does not explain state. The factory stays behind the glass; menus never compete with combat.

## Palette

All colours come from the art bible palette except the panel neutral marked `new`. Values are sRGB.

| Hex | Name | Source | Use | Text contrast (WCAG 2.x) |
|---|---|---|---|---|
| `#11151E` | Grundschatten | Art Bible §2 | Backdrop; text field behind labels | — |
| `#1A2028` | Panel graphite | new | Panel and dialog fill | — |
| `#CAD5CF` | Gebrochene helle Kante | Art Bible §2 | Primary text, labels, icons | 12.11:1 on `#11151E`; 10.87:1 on `#1A2028`; 5.73:1 on `#23525B` |
| `#62D6CC` | Interaktion / Kontrollpunkt | Art Bible §2 | Focus accent, active value, marker | 10.44:1 on `#11151E`; 9.37:1 on `#1A2028`; 4.94:1 on `#23525B` |
| `#B77850` | Oxidiertes Kupfer | Art Bible §2 | 2 px border, title rule, divider; not body text | 5.06:1 on `#11151E` |
| `#23525B` | Petrol | Art Bible §2 | Focused row fill | — |
| `#F2B05E` | Telegraph | Art Bible §2 | Warning only: unsaved progress and destructive confirm; never focus, selection or decoration | 9.69:1 on `#11151E`; 8.70:1 on `#1A2028` |
| `#992D3C` | Gefahr / Blut | Art Bible §2 | 4 px destructive-confirm bar; never text | — |

All text pairs are at least 4.5:1; `#B77850` is decorative and `#992D3C` never carries text.

## Typography

Both fonts use SIL OFL 1.1, compatible with GPL-3.0-or-later code and CC BY-SA 4.0 assets.

| Font | Licence | Source | Use |
|---|---|---|---|
| Inter | SIL OFL 1.1 | https://github.com/rsms/inter | Titles, items, body, credits |
| JetBrains Mono | SIL OFL 1.1 | https://github.com/JetBrains/JetBrainsMono | Values, keycaps, licences |

Sizes at 1920×1080:

| Role | Font | Weight | Size / line | Tracking |
|---|---|---|---|---|
| Title | Inter | 600 | 96 / 104 | −1% |
| Menu item | Inter | 500 | 36 / 44 | 0 |
| Body / option | Inter | 400 | 26 / 35 | 0 |
| Hint | JetBrains Mono | 400 | 22 / 28 | 0 |

Menu items are at least 32 px and body at least 24 px. Hints never carry a state alone.

## Layout and grid

Reference is 1920×1080. Safe margins are 96 px left/right and 64 px top/bottom. The content area is 1728 px: 12 columns of 122 px with 24 px gutters.

The main menu panel is 720 px wide and centred with 32 px padding; pause is 640 px; options and credits are 960 px. Panels use a `#1A2028` fill, 2 px `#B77850` border and 8 px radius. Rows are 56 px high with 12 px gaps. Option rows have a 32 px label column and a 240 px control column. Sliders use a 240×4 px track, 16 px knob and 96 px readout. The focus marker is 8×32 px, placed 24 px left of the row; row text is inset 32 px.

Title screen: wordmark y = 380, subtitle y = 492, prompt y = 640; build string bottom-right at 96/64 px. Headings are left-aligned with a 2 px copper rule 12 px below the baseline.

## Screens

**Title.** Wordmark `REND&RUN`; subtitle `Humanoid Research Facility · Sector 01`; prompt `Press any button`; build string bottom-right. Back: none. A/Enter/Space or click advances.

**Main.** `Continue`; `New run`; `Options`; `Credits`; `Quit`. Continue is disabled and skipped without a save. New run confirms if a save exists. B/Esc does nothing; Quit opens a confirmation.

**Pause.** `Resume`; `Options`; `To checkpoint`; `Quit to main menu`. B/Esc activates Resume. The last two open confirmations; B/Esc in one returns to the list.

**Options.** `Master volume`; `Music volume`; `Effects volume`; `Voices volume`; `Window mode`; `VSync`; `Subtitles`; `Slow motion`; `Screen shake`; `Back`. Volumes run 0–100 in steps of 5. Window mode cycles Windowed, Borderless, Fullscreen. VSync, Subtitles, Slow motion and Screen shake are On/Off. Changes apply and save immediately; there is no Apply button. B/Esc activates Back. No key-rebinding row exists in M1.

**Credits.** Project name and version; roles; tools and font licences; `Back`. Right stick or wheel scrolls; Back is pinned at the list end. B/Esc returns to the main menu, or to the end card when credits were opened there.

## Focus and navigation

Focus is not colour alone. The focused row gets an 8×32 px solid marker bar at its left edge, a 2 px full outline and an 8 px rightward text offset. The bar and outline survive grayscale; fill is secondary.

Gamepad: D-pad or stick up/down moves focus; left/right adjusts; A confirms; B goes back. Stick deadzone is 0.45 with 0.2 hysteresis. Key repeat starts after 260 ms, then every 90 ms. Keyboard: arrows move or adjust, Enter/Space confirms, Esc goes back. Mouse hover focuses; click activates.

Focus wraps within each screen: Up on the first enabled row goes to the last, and Down on the last goes to the first. Disabled rows are skipped. Sliders clamp at 0/100 and do not wrap. Confirm dialogs wrap only between their two actions; B/Esc cancels. Each screen remembers its last row; on open, focus the first enabled row unless a confirmation is open. Hints follow the last used device (`A`/`B` or `Enter`/`Esc`).

## Motion

All durations are at 1920×1080 and each is at most 300 ms. Use Godot `Tween` names.

| Event | Duration | Property | Transition | Ease |
|---|---|---|---|---|
| Screen in | 180 ms | Overlay alpha 0→1; panel y +24→0 | `Tween.TRANS_QUAD` | `Tween.EASE_OUT` |
| Screen out | 140 ms | Overlay alpha 1→0; panel y 0→−12 | `Tween.TRANS_QUAD` | `Tween.EASE_IN` |
| Focus change | 110 ms | Marker y and label x offset | `Tween.TRANS_CUBIC` | `Tween.EASE_OUT` |
| Title prompt pulse | 220 ms | Alpha 0.55→1→0.55 | `Tween.TRANS_SINE` | `Tween.EASE_IN_OUT` |

Motion uses only opacity, one position axis and the focus marker. No bounce, rotation or full-screen flashes.

## Sound

UI sounds play on the Effects bus and follow the Effects volume. Nothing plays on the Music bus; M1 has no menu music.

| Event | File | Treatment |
|---|---|---|
| Focus move | `game/audio/radio_chirp.wav` | Trimmed to 60 ms, −18 dBFS, pitch 1.06; only on actual focus change, throttled to one per 40 ms |
| Confirm | `game/audio/block.wav` | 90 ms, −14 dBFS, pitch 0.92; dry mechanical contact |
| Back | new `game/audio/menu_back.wav` | One-line description: a short downward relay click, 70 ms, mono, 48 kHz, −16 dBFS |

All screens use these three sounds; destructive confirmations add no extra sound.

## Do and don't

| Do | Don't |
|---|---|
| Use `#F2B05E` only for warnings and destructive confirmations | Use amber for focus, selection, headings or decoration |
| Show focus with marker, outline and text offset | Rely on colour change alone |
| Keep one left-aligned column of menu items | Use multi-column or radial main menus |
| Reuse the same panel, row height and grid | Invent a new panel shape per screen |
| Keep transitions at or below 300 ms | Add bounce, rotation or full-screen flashes |

## Open questions for neVs

1. **Title background:** live drifting 3D corridor or static dark field? Recommendation: static `#11151E` field with the wordmark and a 2 px copper rule for M1.
2. **Wordmark case:** `REND&RUN` all caps or `Rend&Run` mixed case? Recommendation: all caps at 96 px with −1% tracking, matching the current title label.
3. **Credits presentation:** plain scrolling list or in-world terminal window? Recommendation: terminal panel with Inter for names and JetBrains Mono for licences.
4. **Destructive confirmation:** single A press or hold A for 600 ms? Recommendation: single A with an amber warning icon and B to cancel.
5. **Pause wording:** `To checkpoint` or `Restart from checkpoint`? Recommendation: `To checkpoint`; it is short, matches the brief and lets the confirmation explain the consequence.
