# PROVENANCE — intro comic panel 01 "Night desk", art variant 2 (of 2)

**Asset:** `game/assets/comic/intro_panel_01_art.png` — 1920×1080, 8-bit sRGB
PNG (colour type 2 RGB, no alpha, non-interlaced), art only: no caption, no SFX,
no letters anywhere; lettering is runtime text per the style guide. Delivered
through Git LFS (`*.png` in `.gitattributes`).

**Author:** swarvex contributor agent (model `swarvex/Qwen3.8 Flash Next`)
working for the Rend&Run team.
**Tool:** Python 3.13.5, stdlib only (`math`, `struct`, `os`, `sys`, `zlib`);
no third-party libraries, no image-generation model, no borrowed imagery. The
working source is `render_panel_01.py` in this folder: a deterministic rasterizer
plus PNG chunk writer (own `IHDR`/`sRGB`/filter-0 `IDAT`/`IEND`). Rerunning
`python3 render_panel_01.py` reproduces this exact file (verified byte-identical)
and prints the self-check; `--preview` prints a coarse ASCII map.
**Date:** 2026-11-25.

**References:** `docs/design/comic/style-guide-variant-2.md` (adopted look,
decision 0003: eight-colour closed palette, flat fills, 8/4/3/2 px lines, 16:9,
96 px safe margin, no gradients/glow/baked text); `docs/design/comic/
intro-storyboard.md` panel 1 (mullions x≈240/1680, head at x 560 y 560, monitor
bank x 560–1100, half-built hand at x≈1300 y 820, caption box 96,96,680,140,
no amber/no red in this panel); `docs/design/comic/intro-script-variant-1.md`
panel 1; `docs/asset-src/hero_portrait.jpg` for Rend's fixed markers;
`docs/style-guide.md` (art bible) for the lab language.
**Likeness caveat:** this contributor has no image input and could not see
`hero_portrait.jpg`; glasses (two lenses, clear bridge, dark frames), fringe,
open petrol jacket and copper skin were drawn from their written spec in the
comic style guide. The visual A/B against the reference stays with the
neVs/lead review.

**Verification (performed by the script on the written file, from raw bytes):**
PNG signature, per-chunk CRC, 1920×1080, bit depth 8, colour type 2, interlace 0,
explicit `sRGB` chunk; pixel set = 6 of the 8 palette values only, zero amber
and zero red pixels; caption box (96,96)–(776,236) one flat colour (quiet);
zero copper (skin/hands/coils) pixels outside the 96 px safe margin; only line
weights 8/4/3/2 px occur (enforced in `seg()`). Measured shares: GND 49.5 %,
PET 26.8 %, VIO 10.4 %, LIT 6.9 %, COP 4.3 %, CYN 2.1 % (≈ storyboard targets,
darker night tilt; cyan only on monitor screens). Grayscale/720p readability was
built in (copper skin + `#CAD5CF` lenses and rim against `#11151E`) but the
one-second read needs the human review pass.

**Originality/licence:** original scene and humanoid-hand silhouette, no
third-party characters, logos, product designs or brand names. CC BY-SA 4.0
(see `LICENSE-ASSETS.md`).
