# PROVENANCE — intro comic panel 03 "The door breaks", art variant 2 (of 2)

**Asset:** `game/assets/comic/intro_panel_03_art.png` — 1920×1080, 8-bit sRGB
PNG (colour type 2 RGB, no alpha, non-interlaced), art only: no caption, no SFX,
no letters anywhere; the "KRRSSH!" sound-effect lettering is added at runtime per
the style guide. Delivered through Git LFS (`*.png` in `.gitattributes`).

**Author:** swarvex contributor agent working for the Rend&Run team.
**Tool:** Python 3.13.5, stdlib only (`math`, `struct`, `sys`, `zlib`);
no third-party libraries, no image-generation model, no borrowed imagery. The
working source is a deterministic rasterizer plus PNG chunk writer (own `IHDR`/
`sRGB`/filter-0 `IDAT`/`IEND`). Rerunning the generator reproduces this exact
file (verified byte-identical) and prints the self-check.
**Date:** 2026-11-26.

**References:** `docs/design/comic/style-guide-variant-2.md` (adopted look,
decision 0003: eight-colour closed palette, flat fills, 8/4/3/2 px lines, 16:9,
96 px safe margin, no gradients/glow/baked text; ruling 1: no blood in the
intro; ruling 5: SFX amber, panels 3 and 4 only); `docs/design/comic/
intro-storyboard.md` panel 3 (vanishing point x 960 y 420; door breaching
x ≈ 960 y ≈ 420; crowd x 560–1360 y 480–950, front-row heads y ≈ 520; Rend
head x 1560 y 620 backing away, half-raised arms, open jacket, intact glasses;
brute x 1150 y 600 broad with cleaver; one guard wrenches the door frame loose;
flat #CAD5CF glass shards raining down; caption box 96,844,720,140; SFX box
700,130,600,220); `docs/design/comic/intro-script-variant-1.md` panel 3;
`game/assets/comic/intro_panel_01_art.png` for style/character consistency
(Rend's glasses, fringe, open petrol jacket, copper skin); `docs/asset-src/
hero_portrait.jpg` for Rend's fixed markers; `docs/art/art_bible_p02_v01/
ART_BIBLE.txt` section 2 for the eight palette values; glossary silhouettes
for the guard (narrow waist, rounded shoulder caps, sensor-slot face) and the
brute (broad shoulders, low head, heavy cleaver).

**Verification (performed by the generator on the written file, from raw bytes):**
PNG signature, per-chunk CRC, explicit sRGB chunk, 1920×1080, bit depth 8,
colour type 2 (RGB), interlace 0; pixel set = 6 of the 8 palette values only
(#11151E, #23525B, #B77850, #51436E, #CAD5CF, #F2B05E); zero #62D6CC and zero
#992D3C pixels — no red anywhere in the file; AMBER (#F2B05E) appears only as
the 6 px pre-strike rings on the door guard and the two front guards; robots in
#23525B / #CAD5CF shells with #11151E joints and #B77850 contact wear, robots
break into parts, no blood, no robot injury marks; line weights 8/4/3/2 px
(8 px Rend/foreground contours, 4 px interior folds); 96 px safe margin
respected; no baked text pixels; readable in grayscale (copper skin and
#CAD5CF lenses/rim against #11151E). Measured shares approx. GND 48 %,
PET 20 %, VIO 19 %, LIT 13 %, COP 1 %, AMBER <1 % (door-breach tilt, brighter
backlit panel vs panel 1).

**Originality/licence:** original scene, corridor, door, guard/brute humanoid
silhouettes and Rend figure; no third-party characters, logos, product designs
or brand names. CC BY-SA 4.0 (see `LICENSE-ASSETS.md`).
