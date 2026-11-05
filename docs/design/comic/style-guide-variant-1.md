# Comic style guide — variant 1

This guide fixes Rend&Run's comic look: flat cel-shaded colour, hard ink contours, petrol and copper surfaces, and separate lettering. It keeps the six-panel intro and later inserts consistent.

## Mood in three words

**Contained. Mechanical. Personal.**

## Palette

All values are from `docs/art/art_bible_p02_v01/ART_BIBLE.txt` section 2 (§2); no new hues, only opacity tints.

| sRGB hex | Name | Use | Source |
|---|---|---|---|
| `#11151E` | Grundschatten | Lines, gutters, captions, robot joints, hair. | §2 |
| `#23525B` | Petrol | Jacket, robot armour, lab fields, metal shadow. | §2 |
| `#B77850` | Oxidised copper | Worn edges, seams, cables, skin shadow. | §2 |
| `#51436E` | Distant violet | Deep corridors, fog, far silhouettes. | §2 |
| `#CAD5CF` | Broken light edge | Text, lit metal, edges, highlights, skin base. | §2 |
| `#62D6CC` | Interaction | Idle rings, terminals, safe light. | §2 |
| `#F2B05E` | Telegraph | Warning light, sparks, SFX, imminent danger. | §2 |
| `#992D3C` | Danger / blood | Rend's blood and lethal strike light only. | §2 |

## Line and shading

At 1920×1080:

- Outer contour 6 px `#11151E` for Rend, robots and foreground props.
- Interior structure 3 px; fine detail 2 px minimum; nothing at 1 px.
- Background contour 2 px at 50% opacity.
- Two hard steps per material, no gradients. Shadow `#11151E` 35%; light `#CAD5CF` 20%. One 4 px `#62D6CC` rim at 30% on lab technology, never faces.
- Metal: one 2 px `#CAD5CF` specular line, one `#B77850` wear line; no chrome or bloom.
- Blood: flat `#992D3C`, max three drops or one short streak per panel; no spray or red reflection on robots.

## Panel format

Each panel is 1920×1080 px, 16:9, sRGB, 8-bit, PNG or lossless WebP, composed separately and never cropped.

- Safe margin 96 px left/right/top, 120 px bottom; safe area 1728×864 px at x=96, y=96.
- Silhouettes, hands and weapons stay 144 px from any edge.
- Captions plus SFX cover at most 30% of the panel (622,080 px²); one caption box max 640×180 px; no text in the outer margin.
- The intro is at most six panels and 60 s, and cannot be skipped on first start.
- An 8 px `#11151E` gutter separates panels; no outer border.

## Lettering

Both fonts use **SIL OFL 1.1**, compatible with CC BY-SA 4.0 and GPL-3.0-or-later; no third font.

| Role | Font | Licence | Source | Specification |
|---|---|---|---|---|
| Captions | **Saira Condensed** | SIL OFL 1.1 | https://github.com/google/fonts/tree/main/ofl/sairacondensed | 40 px Medium, line 46 px, sentence case, 0.5 px tracking, `#CAD5CF` on 90% `#11151E`; min 34 px. |
| Sound effects | **Bangers** | SIL OFL 1.1 | https://github.com/google/fonts/tree/main/ofl/bangers | 72–180 px, uppercase, 6 px `#11151E` outline, fill `#F2B05E` or `#CAD5CF`, rotation −8° to +8°; max five words. |

Captions sit bottom-left or top-left, never over faces, rings or hands. SFX follow the action and may cross one panel border, not the safe margin. All text is English, in an editable layer, never baked in.

## Characters

Rend is the only human in the intro. Three features from `docs/asset-src/hero_portrait.jpg` and `reference_board.png` are fixed in every panel:

- **Glasses:** 4 px `#11151E` frames, both lenses visible in front and three-quarter views, 2 px `#CAD5CF` highlight; never opaque.
- **Hair:** short, dark `#11151E`, swept back, `#51436E` highlight at 20%, same three-clump silhouette in every view.
- **Jacket:** short, open, petrol `#23525B`, 2 px `#B77850` seam, sleeves ending below the elbow; chest and heavy bare forearms visible.

Full-body Rend: 620–760 px sole to hairline, head 96–112 px, shoulders 220–260 px; five separated fingers at 2 px. Skin is flat `#CAD5CF` plus `#B77850` at 25%; no second skin hue.

## Robots

Robots are original factory equipment, not existing product lines.

- **Silhouette:** humanoids are 7.5 heads tall, narrow-waisted, broad-shouldered. Guards are wider at the shoulders; sentinels upright and narrow; dogs low and horizontal. No robot copies Rend's outline.
- **Materials:** matte steel in `#23525B` or `#CAD5CF`, `#11151E` joints, `#B77850` copper wear at hinges. No chrome, white plastic, carbon-fibre or brand-shaped chest plate.
- **Light ring:** one circular status ring, 6 px thick: idle `#62D6CC` 60%, warning `#F2B05E`, lethal `#992D3C`; glow radius max 24 px, never behind Rend's glasses.
- **Damage:** robots break into parts. Hits open shells, bend plates, show `#11151E` interiors and throw `#F2B05E` sparks or `#B77850` cable ends. No red fluid, mist or pool.
- **Identity:** no real robot-company proportions, product designs, logos or brand text; abstract factory glyphs only.

## Production rules

A panel is accepted only after this checklist is recorded with the image:

1. **Rend check:** glasses, hair and jacket match above in every panel; compare with `hero_portrait.jpg` at 100%.
2. **Text check:** no baked text; captions and SFX arrive in a separate editable file with positions. Confirm zero text pixels.
3. **Provenance:** every image gets a note next to it as required by AGENTS.md: author, tool and version, plan/prompt or source, date, licence. A batch `PROVENANCE.md` must list each panel.
4. **Palette check:** only the eight hex values as flat fills; anti-aliasing is fine, new flat colours are not.
5. **Format check:** 1920×1080, 16:9, sRGB, 8-bit; measure the safe margin and 30% text limit.
6. **Readability check:** at 50% and in grayscale, Rend, one robot and the focal action remain identifiable within one second.
7. **Line check:** no contour below 2 px; character outer contours stay 6 px.
8. **Naming:** `comic_intro_p01_v01.png`, `comic_intro_p02_v01.png`, etc.; increment on every visible change.

## Do and don't

| Do | Don't |
|---|---|
| Use only the eight Art Bible colours. | Add a hue, gradient or photo texture. |
| Keep glasses, hair and open petrol jacket identical. | Redesign Rend per panel or close the jacket. |
| Let robots break into shells, cables and sparks. | Show red blood, mist or pools from a robot. |
| Reserve `#992D3C` for Rend's blood and lethal strike light. | Use blood red as decoration or a safe-zone marker. |
| Design original factory robots with abstract glyphs. | Copy a recognisable real robot product, logo or brand silhouette. |
| Use Saira Condensed and Bangers under SIL OFL 1.1. | Use a personal-use-only or unlicensed font. |
| Keep all text in a separate editable layer. | Bake captions or SFX into the image. |
| Invent original characters and machines. | Use a third-party character, mascot or licensed design. |

## Open questions for neVs

1. **Caption voice:** first-person past or neutral third? Recommendation: first-person past in the intro, neutral later.
2. **Rend's jacket:** petrol or off-white with petrol lining? Recommendation: petrol, distinct from pale robot armour.
3. **Robot status language:** one ring for all classes or class-specific shapes? Recommendation: identical ring geometry; class told by silhouette and ring size.
4. **Blood intensity:** one short streak per panel or a stronger awakening wound? Recommendation: one short streak, no spray; heavier damage in gameplay.
5. **Panel framing:** full-bleed with an 8 px gutter or a 4 px frame? Recommendation: full-bleed with the gutter, so the comic reads as one memory.
