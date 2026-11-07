# Fonts: Inter and JetBrains Mono

Menu fonts chosen in the menu style guide (decision 0002). Both use the SIL Open Font
License 1.1; the licence text from each release sits next to the font as `OFL.txt`.

The binaries are the official release files, downloaded by the lead on 2026-11-07 and
checked against the release archives (SHA-256 below). They replace the first versions
from task #61: those came from copies inside the contributor's sandbox (an Inter build
bundled with opencode 1.19.4, and Godot's JetBrains Mono WOFF2 converted by hand to TTF).
The hand-converted TTF had a damaged `glyf` table (fontTools: "not enough 'glyf' table
data"), so both fonts were replaced with the release files.

## Inter

| Field | Value |
|---|---|
| Source | https://github.com/rsms/inter/releases/download/v4.1/Inter-4.1.zip (SHA-256 `9883fdd4a49d4fb66bd8177ba6625ef9a64aa45899767dde3d36aa425756b11e`) |
| File in archive | `InterVariable.ttf`, stored as `game/assets/fonts/inter/Inter-Variable.ttf` |
| Font version | `Version 4.001;git-9221beed3` (release 4.1), family "Inter Variable", axes `opsz` 14–32, `wght` 100–900 |
| Licence | SIL OFL 1.1, `LICENSE.txt` from the archive, stored as `OFL.txt` |
| Used weights | `wght` 600 (titles), 500 (rows) via `FontVariation` in `game/modules/ui/menu_screen.gd` |

## JetBrains Mono

| Field | Value |
|---|---|
| Source | https://github.com/JetBrains/JetBrainsMono/releases/download/v2.304/JetBrainsMono-2.304.zip (SHA-256 `6f6376c6ed2960ea8a963cd7387ec9d76e3f629125bc33d1fdcd7eb7012f7bbf`) |
| File in archive | `fonts/ttf/JetBrainsMono-Regular.ttf` |
| Font version | `Version 2.304`, weight 400 |
| Licence | SIL OFL 1.1, `OFL.txt` from the archive |
| Used for | values (numbers, switch states) in menus |

## Files

| Path | SHA-256 |
|---|---|
| `game/assets/fonts/inter/Inter-Variable.ttf` | `4989b125924991b90d05b2d16e0e388c48f7d5bb8b30539bbf9c755278d0ccaf` |
| `game/assets/fonts/inter/OFL.txt` | `262481e844521b326f5ecd053e59b98c8b2da78c8ee1bdbb6e8174305e54935a` |
| `game/assets/fonts/jetbrains_mono/JetBrainsMono-Regular.ttf` | `a0bf60ef0f83c5ed4d7a75d45838548b1f6873372dfac88f71804491898d138f` |
| `game/assets/fonts/jetbrains_mono/OFL.txt` | `30f0c136e3c88e422d0791acd97238870f9054a9729bc34cf2ff0d4ed8cac4ad` |
