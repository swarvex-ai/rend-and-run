# Fonts: Inter and JetBrains Mono

Both fonts use the SIL Open Font License 1.1. The binaries were not downloaded
from GitHub; they come from distributions already installed in the sandbox.
GitHub links are listed only as the upstream projects.

## Inter

| Field | Value |
|---|---|
| Local source | `/opt/swarvex-agent/bin/opencode`, opencode 1.19.4, bundled web asset `assets/Inter.ttf` (bunfs path `/$bunfs/root/Inter-ceqabf1v.ttf`) |
| Distribution and version | opencode 1.19.4 |
| Upstream project | https://github.com/rsms/inter |
| Font version | 4.001 (`Version 4.001;git-66647c0bb`); variable font, `wght` 100-900, `opsz` 14-32 |
| Date | Extracted 2026-11-07 (not downloaded) |
| Licence | SIL OFL 1.1 |
| Extraction | The TTF was extracted unchanged from the opencode binary; the name table still reports family `Inter`, style `Regular`, version 4.001. |
| OFL source | Standard OFL 1.1 body from the licence block bundled in Godot 4.7.2-stable (`/opt/Godot_v4.7.2-stable_linux.x86_64`); copyright line from the Inter name table. |

## JetBrains Mono

| Field | Value |
|---|---|
| Local source | `/opt/Godot_v4.7.2-stable_linux.x86_64`, Godot 4.7.2-stable, bundled `thirdparty/fonts/JetBrainsMono_Regular.woff2` |
| Distribution and version | Godot 4.7.2-stable |
| Upstream project | https://github.com/JetBrains/JetBrainsMono |
| Font version | 2.304 (`Version 2.304; ttfautohint (v1.8.4.7-5d5b)`) |
| Date | Extracted and converted 2026-11-07 (not downloaded) |
| Licence | SIL OFL 1.1 |
| Conversion | WOFF2 to TTF: tables read with FreeType 2.13.3 (`/lib/x86_64-linux-gnu/libfreetype.so.6`, `FT_Sfnt_Table_Info` / `FT_Load_Sfnt_Table`) and rebuilt as an SFNT with standard table directory, checksums and `head.checkSumAdjustment`. Source WOFF2 SHA-256: `d0cf58a74d14dbb42fb9b4191d254d5bc03fc5613f45cb3815f1d5ee4e6a3584`. |
| OFL source | Standard OFL 1.1 body from the licence block bundled in Godot 4.7.2-stable; copyright line from the JetBrains Mono name table. |

## Files

| Path | SHA-256 |
|---|---|
| `game/assets/fonts/inter/Inter-Variable.ttf` | `0be2399ea925f1f83ff974764761da9860ec50742ed29a5d4c1ffd0c5c7ac3a8` |
| `game/assets/fonts/inter/OFL.txt` | `f8dd4dad713fb93fc5be8cfb5347aa25e30f121251d5dabb177511c919821219` |
| `game/assets/fonts/jetbrains_mono/JetBrainsMono-Regular.ttf` | `893b28f3d08283aba9e8eee257b612a05544a978886668d002d545d1af974f1d` |
| `game/assets/fonts/jetbrains_mono/OFL.txt` | `460cdbc17c4fbaa8fbe26d43fa1c655484d7bc1b46e37951d1c4e81b8cee66d1` |
