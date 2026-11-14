# Intro comic storyboard — per-panel layout (five panels)

One layout for five separate contributors, so the intro reads as one continuous comic.
Script: `intro-script-variant-1.md` (decision 0005). Look and lettering: `style-guide-variant-2.md`
(decision 0003). Canvas for every art plate: 1920×1080, strict full-frame 16:9, safe margin 96 px
(usable area x 96–1824, y 96–984). Palette: only the eight values of the style guide
(`#11151E #23525B #B77850 #51436E #CAD5CF #62D6CC #F2B05E #992D3C`), shadows at `#11151E` 35 %
multiply and highlights at `#CAD5CF` 20 % screen. No blood anywhere in the intro; the only red is
the alarm glyph in panel 2; the only injury is Rend's cracked glasses. Rend never speaks: no
balloons. Text areas below are shares of 2,073,600 px² and must stay ≤25 %.

Conventions used below: coordinates are pixel centers in the 1920×1080 plate; "thirds" refer to
the 3×3 grid (columns at x 640/1280, rows at y 360/720). Captions: Inter 600 38/46 px, `#11151E`
on `#CAD5CF`, 4 px `#11151E` border, 24 px padding, square corners. Machine label: Inter 600
30/36 px uppercase, square-cornered. SFX: Bangers, `#F2B05E` fill, 8 px `#11151E` outline, max 8°
rotation, panels 3 and 4 only. Lettering is delivered as a JSON text layer next to each plate,
never rasterised.

## Panel 1 — Night desk (10 s)

1. **File names**: art plate `intro_panel_01_art.png` (1920×1080, art only, zero baked text
   pixels); lettering data `intro_panel_01_text.json`.
2. **Composition**: wide eye-level shot through the lab's glass wall, slow push-in handled by the
   player. Foreground: dark glass mullions as two vertical 8 px `#11151E` contours at x ≈ 240 and
   x ≈ 1680, desk edge crossing the bottom edge. Midground: Rend seated lower-left third, head at
   x 560 y 560; monitor bank center, x 560–1100 y 260–640. Background: dark lab depth and a
   server wall in the top and right thirds. Light: cool work light from above left, warm monitor
   glow from the right; hard cel shadows to the lower right.
3. **Poses and props**: Rend hunched over the keyboard, both hands typing, calm focused frown
   visible in three-quarter view; glasses **intact**, jacket open. Markers: dark-framed glasses
   with both lenses and clear bridge, dark fringe, open petrol jacket over dark shirt, skin
   `#B77850`. Prop: half-built humanoid hand on the desk at x 1300 y 820 (lower-right third,
   foreground, palm up like a mirrored echo of his typing); cold coffee mug beside it. The hand is
   a part, not a robot: `#11151E` cavity, `#B77850` coil hints, no ring.
4. **Palette use**: `#11151E` mullions, deepest shadow and outlines ≈40 %; `#23525B` desk,
   monitor shells and jacket ≈28 %; `#51436E` lab depth and fog ≈14 %; `#CAD5CF` rim light,
   paper and code highlights ≈9 %; `#B77850` skin and wear edges ≈6 %; `#62D6CC` terminal text
   and idle screen glyphs ≈3 %. No `#F2B05E`, no `#992D3C` in this panel.
5. **Text layer**: caption, word-for-word: "Rend spends his nights teaching machines to move."
   Box 680×140 px at x 96 y 96 (top-left, inside the safe margin), two lines
   ("Rend spends his nights teaching" / "machines to move."). No SFX. Text area 95,200 px² =
   4.6 % of the panel.
6. **Timing**: 10 s. Transition to panel 2: hard cut on the first screen color change.
7. **Check list** (the seven production checks of the style guide):
   - [ ] Rend's glasses, hair and open jacket match `docs/asset-src/hero_portrait.jpg`
   - [ ] only the eight palette values (plus the two fixed shadow/highlight opacities)
   - [ ] line weights: 8 px contours, 4 px interior, 3 px mechanisms, 2 px background
   - [ ] 1920×1080, faces, hands and the caption inside the 96 px safe margin
   - [ ] all text ≤25 % of the panel (here 4.6 %)
   - [ ] zero baked text pixels; lettering is the separate `intro_panel_01_text.json`
   - [ ] Rend, threat-free calm and the typing action read in one second at 25 % zoom, in
         color and in grayscale
   - panel specific: half-built hand reads as the same robot family as the later arm; `#62D6CC`
     only on screens; no amber, no red pixels in the file.

## Panel 2 — Red screens (9 s)

1. **File names**: art plate `intro_panel_02_art.png` (1920×1080, art only); lettering data
   `intro_panel_02_text.json`.
2. **Composition**: close-up on a monitor bank filling the left half (x 96–1150, full height),
   rack focus through the observation glass to the test bay in the right third. Foreground:
   monitor bezels and the glass frame edge. Midground: the screens themselves. Background: test
   bay behind glass, **guard** silhouettes in a row lifting their heads at the same moment;
   heads at x 1380/1560/1740 y ≈ 470–520, three depths, 2 px line weight for the farthest.
   Light: flat screen glow toward camera upper-left, bay lit from its ceiling strips.
3. **Poses and props**: no Rend in this panel. Three guards (narrow waist, rounded shoulder
   caps, baton at hip, machine face: horizontal sensor slot) in simultaneous head-lift, identical
   posture, shells matte `#23525B` and `#CAD5CF`, `#11151E` joints, `#B77850` contact wear.
   Monitors: dark `#11151E` screens with flat alarm glyphs.
4. **Palette use**: `#11151E` screens, bezels, lines ≈38 %; `#992D3C` **only** as flat alarm
   glyphs on the dark screens, glyph field within x 200–1050 y 200–700, glyph marks ≤8 % of the
   panel area, no red wash over the panel; `#23525B` bay structure and robot shells ≈22 %;
   `#51436E` bay depth ≈12 %; `#CAD5CF` glass edge and highlights ≈14 %; `#B77850` wear ≈3 %;
   `#62D6CC` two small standby terminal marks left ≈2 %; `#F2B05E` on the head rings of the
   three guards: the wake/pre-strike amber, one 6 px ring each, appears exactly with the head
   lift (≈1 %).
5. **Text layer**: caption, word-for-word: "Every screen turns red." One line. Box 520×96 px at
   x 96 y 888 (bottom-left). No SFX. Text area 49,920 px² = 2.4 % of the panel.
6. **Timing**: 9 s. Transition to panel 3: hard cut on the klaxon's first full pulse.
7. **Check list**: the seven production checks (as panel 1, items 1–7; item 1 is vacuous here —
   no Rend, note it as "no Rend in panel") plus:
   - `#992D3C` appears only as alarm glyphs on screens, nowhere else in the file
   - amber rings only on the three guard heads; no red on any robot
   - head lift reads in one second in grayscale; robot faces: slots only, no mouths
   - glass frame may cross the safe margin, robot heads may not.

## Panel 3 — The door breaks (9 s)

1. **File names**: art plate `intro_panel_03_art.png` (1920×1080, art only); lettering data
   `intro_panel_03_text.json`.
2. **Composition**: wide, low angle looking down the corridor; vanishing point at x 960 y 420.
   Foreground: shattered glass raining down across the top third and Rend's chair toppling at
   x 1500 y 930. Midground: lab door breaching center-upper at x ≈ 960 y ≈ 420; humanoid crowd
   pouring through shoulder to shoulder, x 560–1360 y 480–950, front row heads at y ≈ 520.
   Background: corridor depth in the center column, receding to `#51436E`. Light: strong
   backlight from the breach behind the robots (rim edges `#CAD5CF`), ceiling work lights
   overhead, long shadows toward the camera.
3. **Poses and props**: Rend in the right third backing away, head at x 1560 y 620, arms half
   raised, frightened wide eyes behind **intact** glasses, open jacket; knocking the chair with
   his calf. Robots: crowd of **guards** (narrow, rounded shoulder caps, batons) plus one
   **brute** silhouette (broad shoulders, low head, heavy cleaver slung) at x 1150 y 600; one
   guard at the door wrenches the frame loose, bent arms on the frame edge. Glass shards flat
   `#CAD5CF`, 4 px edges.
4. **Palette use**: `#11151E` silhouettes, shadows, lines ≈35 %; `#23525B` corridor floor side
   faces and robot shells ≈25 %; `#51436E` corridor depth ≈12 %; `#CAD5CF` breach light, rim
   light, floor light edges and glass ≈16 %; `#B77850` wear on robot feet and hands ≈3 %;
   `#62D6CC` none or one far door indicator ≤1 %; `#F2B05E` pre-strike rings on the door guard
   and the two front guards, 6 px each; the SFX word is amber too. No `#992D3C` in this panel.
5. **Text layer**: caption, word-for-word: "They were built to serve. Tonight they move like
   hunters." Two lines ("They were built to serve." / "Tonight they move like hunters."), box
   720×140 px at x 96 y 844 (bottom-left). SFX (one per panel, this panel and panel 4 only):
   "KRRSSH!" for tearing metal and raining glass; Bangers, 180 px cap height, `#F2B05E` fill,
   8 px `#11151E` outline, box 600×220 px at x 700 y 130 (above the crowd, top-center),
   rotation −6° about the box center, corners stay inside the safe margin. Text area
   100,800 + 132,000 = 232,800 px² = 11.2 % of the panel.
6. **Timing**: 9 s. Transition to panel 4: hard cut to the grab.
7. **Check list**: the seven production checks plus:
   - exactly one SFX in the panel; caption two lines, ≤42 chars/line
   - Rend's markers legible within one second even at this distance
   - brute reads 1.3× wider than the guards; all robot rings amber or dark, never red
   - door break (not robots already loose) is visible; no blood, no red pixels in the file.

## Panel 4 — Knock-down (8 s)

1. **File names**: art plate `intro_panel_04_art.png` (1920×1080, art only); lettering data
   `intro_panel_04_text.json`.
2. **Composition**: over Rend's shoulder, whip-into close-up on his face; the frame tightens to
   Rend's head and upper torso in the left and center. Foreground: a big metal hand (the brute's)
   entering from the right edge, gripping his jacket at x 1150 y 620, fingers overlapping his
   chest. Midground: Rend's face, head center at x 780 y 560, glasses 240 px wide with both
   lenses and the bridge visible. Background: server rack in the right third, x 1400–1824,
   terminal lights dying row by row; the outer 20 % of the panel falls to near-full `#11151E`
   as the lights go out. Light: single work light from above left, hard shadow side right,
   fading with the rack.
3. **Poses and props**: Rend mid-slam, head snapping back slightly, eyes shut, jaw clenched;
   jacket open, bunched in the fist. Glasses **crack in this panel** — first appearance of the
   crack: a single 3 px `#11151E` fracture across the left lens (viewer left), starting at the
   frame edge, not the eyes; no blood on his face. The brute's hand: `#CAD5CF` matte shell
   plates, `#11151E` joint gaps, `#B77850` wear at the fingertips; machine thumb with a sensor
   slot; no ring visible on the hand.
4. **Palette use**: `#11151E` ≈40 % and rising toward the edges (lights out); `#23525B` jacket
   and rack bodies ≈20 %; `#B77850` skin base ≈8 %; `#CAD5CF` skin highlight, rim and shell
   plates ≈14 %; `#51436E` a thin depth strip behind the rack ≈8 %; `#62D6CC` three rack
   terminal lights, top row lit, bottom rows dark (≤1.5 %); `#F2B05E` only the SFX word; no
   `#992D3C` in this panel.
5. **Text layer**: caption, word-for-word: "Everything goes dark." One line. Box 500×96 px at
   x 96 y 888 (bottom-left, readable against the dark art). SFX: "KRAK!" for the impact and the
   glass crack; Bangers, 200 px cap height, `#F2B05E` fill, 8 px `#11151E` outline, box
   560×240 px at x 1180 y 130 (top-right over the dark rack), rotation +6° about the box center,
   corners inside the safe margin. Text area 48,000 + 134,400 = 182,400 px² = 8.8 % of the
   panel.
6. **Timing**: 8 s. Transition to panel 5: **through black** — the art already sinks to
   `#11151E` in the last ~20 % of the panel; player fades out 0.5 s and in 0.5 s across the cut.
7. **Check list**: the seven production checks plus:
   - glasses ≥60 px in close-up (here 240 px), both lenses and bridge visible, crack on one lens
     only, no blood anywhere
   - the crack in `intro_panel_04` matches `intro_panel_05` exactly (same lens, same path)
   - exactly one SFX; hand is a brute hand: same shell family as the later torn arm
   - the panel stays readable in its dark state (grayscale check on the shadow areas).

## Panel 5 — Factory floor (12 s)

1. **File names**: art plate `intro_panel_05_art.png` (1920×1080, art only); lettering data
   `intro_panel_05_text.json`.
2. **Composition**: floor-level wide with a slow push toward the arm (zoom done by the player,
   lettering stays fixed to the plate). Foreground: Rend lying on the floor in the lower-left
   third, head at x 520 y 690, and the **torn-off humanoid arm** at x 1050–1500 y 800–950
   (lower center-right third) within reach; Rend's right hand closes around the forearm at
   x 1000 y 870. Midground: factory floor plates and low machine housings crossing the center
   band. Background: assembly gantry across the top third carrying head-down humanoid shells in
   three depths; far factory depth in violet, upper-right third. Light: cold work-light pools
   straight down from above, violet ambient from the right; hard pools of `#CAD5CF` floor edge.
3. **Poses and props**: Rend half awake on his side, propped on one elbow, dazed half-lidded
   stare focusing on the arm; glasses **cracked** (the panel 4 crack, unchanged), jacket open,
   hair fringe fallen over one lens. Torn arm: blunt club silhouette with visible joint, cable
   and severed shoulder cap; 3 px dark `#11151E` severance seam, `#11151E` cavity with
   `#B77850` coils; shell `#23525B` with `#CAD5CF` panels; head ring dark (disabled). Shells on
   the line: unpowered, rings dark, two lens faces blank.
4. **Palette use**: `#11151E` floor gaps, cavities, lines ≈32 %; `#23525B` floor side faces,
   machine housings, arm shell ≈30 %; `#51436E` factory depth ≈14 %; `#CAD5CF` floor light
   edges, shell bodies, highlights ≈14 %; `#B77850` skin, coils, wear ≈7 %; `#62D6CC` a strip
   of far terminal lights ≤2 %; `#F2B05E` none — no visible robot is about to strike; no
   `#992D3C` in this panel.
5. **Text layer**: caption, word-for-word: "Rend wakes where the machines are born." One line
   (39 chars ≤42), box 780×96 px at x 96 y 888 (bottom-left). PA line as a caption in a
   **machine-label box** (square corners, Inter 600 30/36 px uppercase; the words are
   word-for-word from the script, only case follows the machine-label rule):
   "UNREGISTERED INTRUDER ON THE FACTORY FLOOR. SECURITY UNITS DISPATCHED." Two lines
   ("UNREGISTERED INTRUDER ON THE FACTORY" / "FLOOR. SECURITY UNITS DISPATCHED."), box
   900×120 px at x 924 y 864 (bottom-right). No SFX (the heaviest impacts were panels 3 and 4).
   Text area 74,880 + 108,000 = 182,880 px² = 8.8 % of the panel.
6. **Timing**: 12 s. Transition: the comic ends on the grab — cut to gameplay with the arm
   already in Rend's hand; nothing follows the panel.
7. **Check list**: the seven production checks plus:
   - crack matches panel 4; markers (glasses, fringe, open jacket) read within one second
   - torn arm is the same silhouette the player will hold at game start
   - PA is a machine-label box, not a balloon; no balloon anywhere in the intro
   - no amber ring on any robot (all visible units unpowered); no blood, no red pixels.

## Continuity

- **Rend's markers in every panel he appears in (1, 3, 4, 5)**: dark-framed glasses with two
  visible lenses and a clear bridge; dark hair with the `hero_portrait.jpg` fringe; short open
  petrol `#23525B` jacket over a dark shirt; skin `#B77850` base, `#CAD5CF` highlight,
  `#23525B` shadow; no tattoos, jewellery or extra markings; glasses never hidden. Panel 2 shows
  no Rend.
- **Glasses**: intact in panels 1 and 3; the single 3 px `#11151E` crack across the viewer-left
  lens first appears at the impact in **panel 4**; it persists unchanged in panel 5 and later.
- **Robots**: guard silhouette (narrow waist, rounded shoulder caps, sensor slot) in panels 2
  and 3; brute silhouette (broad, low head, cleaver) in panel 3, and its hand in panel 4; the
  torn arm in panel 5 comes from the same shell family (`#23525B`/`#CAD5CF` shells, `#B77850`
  coils, 3 px dark seam). Rings: `#62D6CC` idle, `#F2B05E` pre-strike (panels 2 and 3), dark
  when disabled (panel 5); never red.
- **Color rules across the intro**: `#992D3C` exists only as the panel 2 alarm glyph;
  `#F2B05E` rings appear only in panels 2 and 3 (pre-strike); amber SFX only in panels 3 and 4;
  no blood anywhere, robots break into parts only.
- **Text rules**: three captions plus the panel 5 machine label; two SFX total; no dialogue
  balloon in any panel; all text English; lettering layers carry the fonts Inter and Bangers.
- **Timing across the intro**: 10 + 9 + 9 + 8 + 12 = 48 s; hard cuts after panels 1, 2 and 3,
  through black after panel 4; the last frame cuts straight into gameplay.

## Machine-readable table

For the player loader. Boxes are `x,y,w,h` in the 1920×1080 plate, all inside the 96 px safe
margin; `;;` separates cells that carry two text blocks (panel 5: caption first, PA label
second). `—` means empty. Caption texts are word-for-word from the script; the PA renders
uppercase in its machine-label box.

| panel | art_file | duration_s | caption_en | caption_box_xywh | sfx_en | sfx_box_xywh |
|---|---|---|---|---|---|---|
| 1 | intro_panel_01_art.png | 10 | Rend spends his nights teaching machines to move. | 96,96,680,140 | — | — |
| 2 | intro_panel_02_art.png | 9 | Every screen turns red. | 96,888,520,96 | — | — |
| 3 | intro_panel_03_art.png | 9 | They were built to serve. Tonight they move like hunters. | 96,844,720,140 | KRRSSH! | 700,130,600,220 |
| 4 | intro_panel_04_art.png | 8 | Everything goes dark. | 96,888,500,96 | KRAK! | 1180,130,560,240 |
| 5 | intro_panel_05_art.png | 12 | Rend wakes where the machines are born. ;; FACILITY PA: Unregistered intruder on the factory floor. Security units dispatched. | 96,888,780,96 ;; 924,864,900,120 | — | — |

Durations sum to 48 s. Per-panel text area (caption + SFX, from the boxes above): panel 1
4.6 %, panel 2 2.4 %, panel 3 11.2 %, panel 4 8.8 %, panel 5 8.8 % — all ≤25 % of 2,073,600 px².
Each single box ≤900×260 px; rotations −6°/panel 3 and +6°/panel 4 stay within 8°.

## Open points

1. **Panel 2 wording**: the script says "Every screen turns red", the guide ruling 6 allows the
   red only as flat alarm glyphs on dark monitors, "no red wash". I followed the ruling
   (glyphs ≤8 % of the panel). Recommendation: keep the ruling; the caption still lands because
   the glyphs light up row by row. Needs neVs confirmation only if a full red screen is wanted.
2. **SFX words**: the script's sound column describes audio ("tearing metal", "heavy impact"),
   not lettering. "KRRSSH!" and "KRAK!" are my layout proposals in the guide's amber SFX slot.
   Recommendation: keep as-is or let neVs set the two words; changing them does not move boxes.
3. **PA capitalisation**: the script quotes the PA sentence in sentence case, the guide forces
   machine labels to uppercase. I render uppercase on the plate and keep the script casing in
   the data table for subtitles. Recommendation: keep both; no silent resolution needed beyond
   this note.
