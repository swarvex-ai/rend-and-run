# PROVENANCE — intro comic panel 02 "Red screens", art variant 2 (of 2)

**Asset:** `game/assets/comic/intro_panel_02_art.png` — 1920×1080, 8-bit sRGB
PNG (colour type 2 RGB, no alpha, non-interlaced), art only: no caption, no SFX,
no letters anywhere; lettering is runtime text per the style guide. Delivered
through Git LFS (`*.png` in `.gitattributes`).

**Author:** swarvex contributor agent working for the Rend&Run team.
**Tool:** Python 3.13.5, stdlib only (`math`, `struct`, `os`, `sys`, `zlib`);
no third-party libraries, no image-generation model, no borrowed imagery. The
working source is a deterministic rasterizer plus PNG chunk writer (own
`IHDR`/`sRGB`/filter-0 `IDAT`/`IEND`). Rerunning the generator reproduces this
exact file (verified byte-identical) and prints the self-check.
**Date:** 2026-11-25.

**References:** `docs/design/comic/style-guide-variant-2.md` (adopted look,
decision 0003: eight-colour closed palette, flat fills, 8/4/3/2 px lines, 16:9,
96 px safe margin, no gradients/glow/baked text, ruling 6: red only as flat
alarm glyph on dark monitors); `docs/design/comic/intro-storyboard.md` panel 2
(monitor bank x 96–1150 full height, glass divider at x≈1120–1150, test bay
right third, guards at x 1380/1560/1740 y ≈ 470–520 lifting heads simultaneously,
alarm glyph field x 200–1050 y 200–700, two #62D6CC standby marks, caption box
96,888,520,96); `docs/design/comic/intro-script-variant-1.md` panel 2;
`docs/art/art_bible_p02_v01/ART_BIBLE.txt` section 2 for the eight palette
values; glossary silhouettes for the guard (narrow waist, rounded shoulder caps,
baton at hip, horizontal sensor-slot face).

**Verification (performed by the generator on the written file, from raw bytes):**
PNG signature, per-chunk CRC, explicit `sRGB` chunk, 1920×1080, bit depth 8,
colour type 2 (RGB), interlace 0; pixel set = exactly the 8 palette values only;
`#992D3C` (0.25% of panel, well under the 8% glyph-mark cap) appears only as flat
alarm glyphs on the six monitor screens within x 200–1050, y 200–700 — zero red
on any robot, zero red wash over the panel; `#F2B05E` appears only as the 6 px
head rings of the three guards (pre-strike amber, exactly with the head lift);
`#62D6CC` on two small standby terminal marks; robots in `#23525B`/`#CAD5CF`
shells with `#11151E` joints and `#B77850` contact wear, no red on robots;
line weights 8/4/3/2 px only; 96 px safe margin respected (robot heads inside,
glass frame may cross); no baked text pixels; readable in grayscale (dark
`#11151E`/`#23525B` robots against `#CAD5CF` glass and `#51436E` bay depth).

**Originality/licence:** original scene, monitor bank and guard silhouettes, no
third-party characters, logos, product designs or brand names. CC BY-SA 4.0
(see `LICENSE-ASSETS.md`).
