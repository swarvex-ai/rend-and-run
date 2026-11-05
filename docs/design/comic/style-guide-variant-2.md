# Comic style guide — variant 2

This guide fixes one look for every Rend&Run comic panel: an eight-colour closed palette, flat two-tone shading, heavy dark contours and separate lettering at 1920×1080. It covers the six-panel intro and later in-game inserts so different contributors produce one continuous comic.

## Mood in three words

**Trapped. Precise. Violent.** Clean laboratory geometry, hard edges and dark space around Rend. Violence comes from pose, severed parts and one restrained red mark, not texture noise.

## Palette

All colours are from `docs/art/art_bible_p02_v01/ART_BIBLE.txt`, section 2; no other hue is allowed. Only the shadow and highlight opacities vary.

| sRGB hex | Name | Use |
|---|---|---|
| `#11151E` | Ground shadow | Lines, deepest shadow, panel gutter. |
| `#23525B` | Petrol | Rend's jacket, lab mid-tones, robot shadow. |
| `#B77850` | Oxidised copper | Rend's skin base, worn edges, robot coils. |
| `#51436E` | Far violet | Distant corridors, fog, recessed depth. |
| `#CAD5CF` | Broken light edge | Highlights, caption fill, bright paper. |
| `#62D6CC` | Interaction / checkpoint | Idle robot rings, terminals, safe cues. |
| `#F2B05E` | Telegraph | Robot pre-strike ring, warnings only. |
| `#992D3C` | Danger / blood | Rend's blood and alarm glyph only. |

Text is `#11151E` on `#CAD5CF` boxes (12.11:1). Do not tint, gradient or multiply the palette into new hues.

## Line and shading

Pixels at 1920×1080; at 1280×720 multiply by 0.667.

- Outer contour (Rend, foreground robots): 8 px.
- Interior forms, folds, limb separations: 4 px.
- Robot seams, small mechanism: 3 px.
- Background, distant robots: 2 px.
- Lines are `#11151E`; no black or coloured outlines.
- Two-tone cel: base plus `#11151E` at 35% multiply for shadow and `#CAD5CF` at 20% screen for one highlight; hard shadow edges.
- Hatching only in deepest shadow: 3 px at 12 px spacing, max 15% of a figure.
- No gradients, blur, airbrush, paper texture or glow wider than 6 px; light rings are flat.

## Panel format

- One panel per file: 1920×1080, 16:9, sRGB 8-bit PNG, no bleed; intro max 6.
- Safe margin 96 px all sides; faces, hands, captions and SFX stay inside, background may cross.
- Max text area per panel: all caption and SFX boxes ≤25% (518,400 px²); one block ≤900×260 px; max three captions plus one SFX.
- Review assembly: 24 px `#11151E` gutter, no frame or shadow.
- Reading order left to right, top to bottom; panel number in the file name, not the image.

## Lettering

Both fonts are SIL OFL 1.1, compatible with CC BY-SA 4.0; ship licence texts and a `CREDITS.md` entry.

| Role | Font | Licence | Source |
|---|---|---|---|
| Captions, dialogue, machine labels | Inter | SIL OFL 1.1 | https://github.com/rsms/inter |
| Sound effects | Bangers | SIL OFL 1.1 | https://github.com/google/fonts/tree/main/ofl/bangers |

- Caption: Inter 600, 38/46 px, `#11151E`, sentence case, left-aligned, max 42 characters/line, max three lines.
- Dialogue: Inter 400, 34/42 px, `#CAD5CF` balloon, 4 px `#11151E` outline.
- Machine label: Inter 600, 30/36 px uppercase in a square-cornered box.
- Caption box: `#CAD5CF` fill, 4 px `#11151E` border, 24 px padding, square corners.
- SFX: Bangers, 96–220 px cap height, `#F2B05E` or `#CAD5CF` fill, 8 px `#11151E` outline, max 8° rotation, max one per panel.
- Lettering is a separate transparent layer or runtime text, never rasterised.

## Characters

Rend follows `docs/asset-src/hero_portrait.jpg`. Fixed markers: two visible lenses with a clear bridge on dark frames, dark hair with the reference fringe, and a short open petrol `#23525B` jacket over a dark shirt. Strong forearms and tech details, no sword.

- Medium shot: seven heads tall; close-up: glasses at least 60 px wide with both lenses and the bridge visible.
- Keep the jacket open every panel; if hidden, glasses and hair must identify him within one second.
- Skin: `#B77850` base, `#CAD5CF` highlight, `#23525B` shadow; no tattoos, jewellery or extra markings.
- Only Rend bleeds: `#992D3C`, one or two short directional marks, never spray or a pool.

## Robots

Glossary silhouettes: guard (light humanoid, narrow waist, rounded shoulder caps, baton or gun), sentinel (wall alcove unit, large head ring) and brute (broad shoulders, low head, heavy cleaver). No real robot companies, products, logos or commercial designs.

- Materials: matte painted steel in `#23525B` or `#CAD5CF`, `#11151E` joints, `#B77850` contact wear; no mirror chrome, carbon-fibre weave or brand graphics.
- One continuous 6 px light ring at head or chest: `#62D6CC` idle, `#F2B05E` pre-strike, dark when disabled. Never red.
- Machine faces only: two small dark lenses or one horizontal sensor slot; no human mouth, nose or eyebrows. Blank panels or abstract vent ticks, no legible letters.
- Severance at a 3 px dark seam; broken ends show an `#11151E` cavity with `#B77850` coils, no blood or fleshy wound.
- Full body: guard 620 px tall, brute 620 px tall and 1.3× wider, sentinel ring 72 px.

## Production rules

- Checklist: Rend's glasses, hair and open jacket match the reference; only eight palette values; line weights match; 1920×1080 with 96 px safe margin; text within 25%.
- Art-only panels: captions, dialogue and SFX are separate layers or files; no text is baked into an image, including signs and labels.
- Every final image gets an entry in the batch `PROVENANCE.md` next to the asset in `asset_library/`: author, tool and version, date, references, and for generated imagery prompt and model version. Name CC BY-SA 4.0.
- Review at 1920×1080 and 1280×720, colour and grayscale, 25% zoom; Rend, threat and action must read in one second.
- No third-party characters, logos, product designs or brand names.

## Do and don't

| Do | Don't |
|---|---|
| Use the eight palette values and the 8/4/3/2 px hierarchy. | Add off-palette hues, gradients or soft airbrush. |
| Give robots blank panels, seams and a cyan or amber ring. | Copy recognisable real robot products or brand logos. |
| Break robots into parts with copper coils and empty housings. | Show robots bleeding, red splatter or fleshy wounds. |
| Reserve `#992D3C` for Rend's blood and the alarm glyph. | Use blood red as robot detail, decoration or focus. |
| Keep Rend's glasses, hair and open jacket identical. | Redesign Rend per panel or give him a sword. |
| Deliver art plates and lettering separately. | Bake captions, SFX or any text into the image. |
| Use original silhouettes and generic lab markings. | Use third-party characters, logos or product designs. |

## Open questions for neVs

1. **Rend's blood in the intro:** how explicit is the first injury? Recommendation: one 40 px `#992D3C` streak where he is knocked down, no spray or pool.
2. **Narration voice:** first-person past tense or neutral third person? Recommendation: first-person past tense, max 18 words per caption.
3. **Robot speech:** balloons or machine labels only? Recommendation: machine labels and PA captions only, no robot speech balloons.
4. **Panel shape:** strict 16:9 or occasional taller frames? Recommendation: strict full-frame 16:9 for all six panels.
5. **SFX frequency:** one per panel or only the heaviest impacts? Recommendation: only the two heaviest impacts, in `#F2B05E`.
