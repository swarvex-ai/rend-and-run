# 0003: Comic style guide, variant 2

- Status: accepted · 14.11.2026 · decided by neVs (message 13)
- Context: two style guides were accepted (`style-guide-variant-1.md`, `style-guide-variant-2.md`). The look of the whole comic is neVs's call.

## Decision

1. **Variant 2** is the comic style guide: `docs/design/comic/style-guide-variant-2.md` (Inter for captions, Bangers for SFX, 8/4/3/2 px lines, red only for Rend's blood and the alarm glyph, robots warn in amber, text area ≤ 25 %).
2. The guide assumed six panels; it now says **five**, matching the chosen script (decision 0005).
3. Its open questions are settled by the lead's recommendations, with one change (third-person narration, because the chosen script is third person). See the guide, "Rulings on the open questions".
4. The per-panel production check of variant 1 (Rend at 100 %, zero baked text pixels, flat palette areas, grayscale readability) is added to the guide's rules.

## Consequences

- `docs/style-guide.md` points to the adopted guide; comic asset tasks may go out against it.
- Inter is already the menu font (decision 0002): one type system for game and comic.
- Fonts need their licence texts and a `CREDITS.md` entry (neVs/lead owns `CREDITS.md`).
