# Art bible

**Smooth. Industrial. Tense.** Rend&Run looks like a clean, expensive humanoid factory that has quietly turned hostile: smooth modern surfaces, warm copper wear and cold petrol shadows. Everything is built for clear silhouettes and readable danger at speed: a fight must parse in under a second.

This is a gate document: no image, 3D, animation or UI asset task ships before neVs approves it. Menu look: variant 2 with two additions from variant 1 (decision 0002), `docs/design/menus/style-guide-variant-2.md`. Comic look: variant 2, `docs/design/comic/style-guide-variant-2.md` (decision 0003, five panels).

## Look

The machine built this place and is still running it. Surfaces are smooth and engineered, not rusty or post-apocalyptic: clean panels, precise seams, rounded housings and copper busbars. The factory is alive but not cosy — server hum, gantries, work-light pools, dark gaps between machines. Rend is the only organic, bleeding thing in frame; the world stays metallic, ceramic and glassy.

Big shapes before detail: a guard reads from stance and silhouette before panel lines. Damage is placed — dents, scorch marks, severed parts — never generic grime. Keep the play-space centre calm so robots, hazards and pickups do not vanish. The feel of contemporary humanoids is welcome; their names, logos and recognisable designs are not.

## Palette

Sample under neutral light at 1920×1080; except *new*, values are quoted from `docs/art/art_bible_p02_v01/ART_BIBLE.txt` §2.

|Name|sRGB hex|P02|Use|
|---|---|---|---|
|Ground shadow|`#11151E`|§2|Deepest neutrals, unlit gaps, title field|
|Petrol|`#23525B`|§2|Load-bearing lab surfaces, Rend's jacket, calm mid-tones|
|Oxidised copper|`#B77850`|§2|Wear edges, busbars, warm accents, robot joints|
|Distant violet|`#51436E`|§2|Far depth layers, haze, non-playable silhouettes|
|Broken light edge|`#CAD5CF`|§2|Playable floor top edges, rim highlights|
|Interaction / checkpoint|`#62D6CC`|§2|Checkpoints, pickups, usable controls|
|Danger / blood|`#992D3C`|§2|Rend's blood, lethal hazard cores; never a permanent UI signal|
|Telegraph|`#F2B05E`|§2|Warnings and attack tells only|

Rough visible mix: 60 % dark neutrals, 25 % petrol, 10 % violet, 5 % copper and signals. Amber `#F2B05E` never marks a pickup, friendly object or decoration: if it glows amber, it is about to hurt Rend. Interaction reads through shape and motion, danger through pose, timing and contour, so colour is never the only cue. Blood red is not a permanent target or interaction cue.

## Shape language

- **Rend:** recognisably human, slightly soft and nerdy, not a power-armour hero. Glasses, hair, short open jacket, strong forearms; pockets, tools and tech details on a believable researcher body.
- **Robots:** smooth shells with clear joint gaps. Humanoids use broad shoulder blocks, tapered waists and simple heads; no spikes, no fantasy armour.
- **Dog:** low, forward-heavy quadruped with a compact back unit and visible leg mechanics.
- **Drones:** small rounded bodies, one bright lens, minimal rotor clutter; silhouette is a hovering dot, not a cloud of blades.
- **Overseer:** tall humanoid with one oversized asymmetric shoulder/back aggregate; phases read through posture and lit components, not a new body.
- **Props and modules:** rounded industrial rectangles, chamfered corners, one dominant function per object. Seams and handles carry scale; no decorative filigree.
- **UI and comic:** follow their own guides. Icons are simple geometric marks with one copper or signal accent, never tiny illustrations shrunk to 16 px.

## Lighting and readability

Gameplay stays near Z = 0, camera at +Z looking toward −Z. Foreground sits at +Z and must never cover heads, weapon arcs or landing edges. Mid scenery starts near Z ≈ −2 m, far structures near Z ≈ −6 m; values follow the gameplay camera, never collision assumptions.

Playable floors get a clear light top edge (`#CAD5CF`) and calm side face. Non-playable far catwalks use lower contrast and no matching edge marker. Background emissives stay weaker than combat telegraphs; no constant flashes behind glasses or enemy hands. Fog must not hide a jump target.

Readability is a review gate, not a paint style. At 1920×1080 and 1280×720, and in greyscale, hero, three robot classes and the next landing zone must be identifiable within one second. Use value contrast first, rim light to separate a dark robot from a dark wall, then silhouette: guard narrow, shield bearer wide, sentinel lit ring, dog low and long, drone small and high, overseer tall with a broken shoulder. Hazards get amber pulses and a readable wind-up that survives VFX, gore and shake.

## Characters and robots

**Rend** is an AI researcher with glasses, hair and a short open jacket over a petrol work layer. Reference: `docs/asset-src/hero_portrait.jpg`; keep his face, no soldier redesign. He has **no sword**. His first weapon is a **robot arm** torn from a humanoid: a blunt club with visible joint, cable and severed shoulder cap. Later he uses dropped firearms, a shield and throwable crates. Only Rend bleeds; blood is dark red `#992D3C`, short and sparse.

**Guard:** light humanoid, about 1.8 m, narrow stance, baton or gun; simple upright outline.
**Shield bearer:** 1.85–1.95 m, wide riot shield, heavy front silhouette; frontal hits are blocked, so it must read as a wall.
**Sentinel:** 1.8 m humanoid waiting in a wall alcove. Its head ring is the tell: dark at rest, `#62D6CC` while waking, red before a strike.
**Dog:** four-legged robot about 0.8 m long and 0.55 m high, low charge posture, exposed leg actuators and compact back unit.
**Kamikaze drone:** 0.35–0.45 m hovering body, one lens, amber blink during the dive; approach reads as a line, not a particle cloud.
**Overseer:** 2.4 m boss humanoid, asymmetric shoulder and large back aggregate, two phases via posture and lit parts. Every strike is announced at least 0.5 s ahead with light and sound.

Robots break into parts: severance, panels, sparks and debris. No blood, no human corpses, no human enemy faction.

## Environment

One smooth, modern humanoid factory: clean panels, rounded machine housings, copper busbars, cable trays, server walls and work lights. Zones are arrival, maintenance, supply, security and airlock, each with one function and palette emphasis. Damage is placed and specific: a dented crate, scorched floor, severed arm, not a uniform dirty layer.

Construction uses a 0.5 m grid with 0.25 m fine grid, 3 m wall height as a start value, and platforms 1.0–1.6 m above the floor. Floors come in 2 m and 4 m pieces, end caps, inner/outer corners, platforms, supports, wall panels, door frames and shaft segments. Backgrounds use three depth layers: near pipes and frames, middle test chambers, far shaft silhouettes. Repeat with variants, never arbitrary scaling of doors or people. Later outdoor areas keep this material language; no new palette.

## Asset specifications

Budgets are review targets, not import gates. Sources: `docs/art/art_bible_p02_v01/budgets.json` and `ART_BIBLE.txt` §7. Triangles count triangulated per visible asset, including separated arm parts. One material per mesh; glass and transparency sparing.

|Asset class|Format|Scale / size|Poly budget LOD0 (target / review)|Texture|Naming|Pivot|
|---|---|---|---|---|---|---|
|Character (Rend)|GLB 2.0, PBR metallic-roughness|1.80 m tall|35k / 45k (budgets.json `hero`)|2048 edge target, 4K only by review|`hero_rend_v01.glb`|Soles at Y0, +X front|
|Robot|GLB 2.0|guard 1.8 m; dog 0.8 m long; drone 0.4 m; overseer 2.4 m|15k / 22k (`enemy`); overseer 45k / 60k (`boss`)|2048 (`enemy`, `boss`)|`robot_<type>_v01.glb`|Feet or hover centre at Y0, +X front|
|Prop|GLB 2.0|small ≤ 0.8 m; large 0.8–3 m|1.5k / 3k (`small_prop`); 5k / 8k (`large_prop`)|512 small, 1024 large|`prop_<name>_<size>_v01.glb`|Bottom-centre, +X front|
|Weapon|GLB 2.0|robot arm 0.75 m; guns 0.25–0.9 m|5k / 8k (`weapon`)|1024 (`weapon`)|`weapon_<name>_v01.glb`|Grip point at origin, +X barrel|
|Environment module|GLB 2.0|2 m / 4 m floor, 1 m platform, 3 m wall|3k / 6k (`module`)|1024 (`module`)|`mod_<type>_<size>_v01.glb`|Bottom-left-front on grid edge|
|Texture|PNG, sRGB albedo plus linear normal/ORM|power of two; atlas or trim sheet preferred|n/a|512, 1024, 2048, 4096 only by review|`tex_<asset>_<map>_<size>.<ext>`|n/a|
|UI image|PNG with alpha, no mipmaps|1920×1080 canvas; icons 16/24/32/64 px|n/a|n/a (pixel native)|`ui_<screen>_<name>_<size>.png`|Top-left origin; icon centre|

LOD1 is about 50 % of LOD0 and LOD2 20–25 %; keep silhouette, glasses, hands and severance seams. Maximum four bone influences per vertex. Export in metres, +X front, Y up, soles at Y0, no collision bodies. Stress target as a profiling hypothesis: 1 hero + 6 enemies + 1 boss, 600k visible triangles, 350 draw calls, 512 MiB resident textures, 60 fps = 16.67 ms, reference hardware still to be established. VFX start limits: 256 particles per normal hit, 2048 visible, 64 active blood decals. Audio: 48 kHz sources, mono spatial SFX, at most 24 simultaneous voices.

## Carried over from P02

|Item|P02 source|Kept / changed / dropped|Why|
|---|---|---|---|
|Eight-colour palette and hex values|`ART_BIBLE.txt` §2|kept|Still matches the petrol/copper base and amber-only warning rule|
|Readability, depth layers, greyscale review|`ART_BIBLE.txt` §3|kept|Serves the "readable danger" pillar at 720p and 1080p|
|Triangle, texture, LOD and stress budgets|`budgets.json`; `ART_BIBLE.txt` §7|kept as starting values|Measurable review targets, not hard import gates|
|Modular lab kit, 0.5 m grid, pivots|`ART_BIBLE.txt` §5|kept|Keeps environment modules consistent across contributors|
|Movement, VFX and audio limits|`ART_BIBLE.txt` §6|kept, re-scoped|Numbers remain useful; sword timings are gone|
|GLB delivery contract, metres, +X front|`ART_BIBLE.txt` §9|kept|Stable technical baseline for every asset task|
|Rend's sword and blade timings|`ART_BIBLE.txt` §Ziel, §4, §6|dropped|Rend has no sword; his first weapon is a robot arm|
|Human enemies and human gore|`ART_BIBLE.txt` §4|dropped|M1 enemies are robots; only Rend bleeds|
|"Abandoned research facility" mood|`ART_BIBLE.txt` §Ziel, §1|changed|Today's world is a smooth, modern, running factory|
|Chaser as a 0.90 m test robot|`ART_BIBLE.txt` §4|changed|Replaced by the M1 robot set named above|
|Second blade follow-ups|`ART_BIBLE.txt` §4; `FOLLOWUP_BRIEFS.txt` P20|dropped|Weapon line is robot arm, guns, shield and throwables|

## Open questions for neVs

1. **Rend's height and build.** Recommendation: 1.80 m, ordinary build, stronger forearms; keep the portrait face.
2. **How much copper?** Recommendation: wear edges and joints only, max ~5 % of visible surface.
3. **Overseer silhouette.** Recommendation: one oversized left shoulder/back aggregate for side readability.
4. **Robot finish.** Recommendation: satin ceramic shells, exposed metal joints, no mirror chrome.
5. **Outdoor continuation.** Recommendation: defer; reuse lab materials and cold rock, no new palette.
