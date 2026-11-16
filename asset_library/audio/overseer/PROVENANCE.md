# Overseer boss sounds — high/low tells, arena gate, phase 2 (2026-11-16)

Four sound cues for the overseer, the boss-class robot of the first escape route
(`docs/bestiary/overseer.md`), matching the sound-bible event list rows "Overseer
entry", "Overseer high tell", "Overseer low tell" and "Overseer phase 2"
(`docs/design/sound-bible.md`). The two windups are priority-1 attack tells that
start with the windup and last 700–800 ms with energy in 1–5 kHz (pillar 1 "Read
before hit"). All material is pure machine synthesis — hydraulic hiss, servo whine,
steel slams, electrical surge — no breath, growl or voice ("Do and don't").

| Field | Value |
|---|---|
| Source | Original synthesis, no samples or third-party material |
| Script | `tools/audio/gen_overseer.py` (uses `tools/audio/synth_common.py`; stdlib only: `hashlib`, `math`, `os`, plus `wave`/`struct` through `save_wav`) |
| Tool | Python 3.13.5 standard library (`hashlib`, `math`, `os`; WAV via `synth_common.save_wav` → `wave`/`struct`). The committed takes were produced by running this script in this sandbox, not by a port |
| Seeds | Take names as hash keys: `robot_overseer_high_windup_01`, `robot_overseer_low_windup_01`, `boss_gate_close_01`, `boss_phase2_01` (SHA-512 counter stream, see "Determinism") |
| Author | swarvex contributor (task: Sound batch — overseer tells, arena gate and phase 2) |
| Licence | CC BY-SA 4.0, https://creativecommons.org/licenses/by-sa/4.0/ |
| Outputs | `game/audio/combat/robot_overseer_high_windup_01.wav`, `game/audio/combat/robot_overseer_low_windup_01.wav`, `game/audio/combat/boss_gate_close_01.wav`, `game/audio/combat/boss_phase2_01.wav` |

## Design

The overseer is the heaviest machine in the factory, so its cues read heavier than
the standard robot tells while staying readable in 1–5 kHz. The two tells use
opposite pitch gestures so high and low are distinguishable by ear: the high tell
glides **up** 1.5→3.5 kHz, the low tell glides **down** 3→1.5 kHz. Measured on the
delivered files (48 kHz mono, peak −1.5 dBFS, energy share in 1–5 kHz, spectral
centroid over the first vs last quarter of the take — rising vs falling):

| File | Kind | Duration | Pitch | Texture | Centroid first→last quarter |
|---|---|---|---|---|---|
| `robot_overseer_high_windup_01.wav` | tell | 0.780 s | servo glide 1.5→3.5 kHz over a quiet 60→100 Hz pressure rise | heavy hydraulic hiss bed (band-passed 1.5–4.2 kHz) rising to a steel clamp at the tail | 1808 → 3160 Hz (**rising**) |
| `robot_overseer_low_windup_01.wav` | tell | 0.700 s | servo whine falling 3→1.5 kHz over a faint 150→80 Hz low servo | 9 Hz drag-scrape band (1.7–4.2 kHz) with a finish scrape | 2773 → 1738 Hz (**falling**) |
| `boss_gate_close_01.wav` | effect | 2.200 s | slam 58 + 180 + 260 Hz, bolts 520/660/580 Hz | steel slam, three locking bolts at 0.20/0.44/0.70 s, long low rumble tail (double low-pass 170 Hz) | 262 → 106 Hz |
| `boss_phase2_01.wav` | effect | 1.150 s | surge 0.7→6.5 kHz, crack rings 4.2 + 1.6 kHz, pulse 48 Hz | rising electrical surge + sizzle, metal crack at 0.82 s, hard low pulse at 0.90 s | 1253 → 114 Hz |

Layer breakdown as synthesised (timings in seconds, gains before the peak
normalisation):

- **high tell** — `sweep 1500→3500 Hz` + 0.85 × noise band-passed 1.5–4.2 kHz (two
  one-pole stages), plus 0.16 × `sweep 60→100 Hz` pressure rise underneath (kept
  quiet so it does not steal the 1–5 kHz tell band); envelope `env_ar(0.02, 0.05)` ×
  ramp 0.4→1.0 (power 1.1); steel clamp at 0.05 s from the end = noise 1.8–7 kHz ×2.4
  (10 ms decay) + 3.2 kHz ring (12 ms decay) ×0.8 + 88 Hz thump (30 ms decay) ×0.6.
- **low tell** — `sweep 3000→1500 Hz` with 30 Hz AM ±16 %, plus 0.6 × noise
  band-passed 1.7–4.2 kHz with 9 Hz AM ±45 % (drag), plus 0.13 × `sweep 150→80 Hz`;
  envelope `env_ar(0.012, 0.06)` × ramp 0.5→1.0 (power 0.8); finish scrape from
  0.10 s before the end = noise 1.3–3.8 kHz ×1.1 (30 ms decay).
- **arena gate** — slam on sample 0 = 58 Hz ring (110 ms decay) ×1.2 + 180 Hz (60 ms)
  ×0.7 + 260 Hz (50 ms) ×0.5 + crack noise 1.5–8 kHz ×2.0 (8 ms decay); three locking
  bolts at 0.20/0.44/0.70 s = noise 0.9–5.2 kHz ×1.6 (6 ms decay) + ring (520/660/580
  Hz, 30 ms) ×0.7 + 120 Hz thump (45 ms) ×0.6; rumble tail = noise double low-passed
  170 Hz ×0.9, envelope `env_ar(0.05, 1.4)` × ramp 1.0→0.0 (power 0.7), from 0.03 s.
- **phase 2** — surge over 0.82 s = `sweep 700→6500 Hz` (exponential) with 42 Hz AM
  ±24 %, plus 0.32 × noise 2.2–9 kHz, envelope `env_ar(0.01, 0.02)` × ramp 0.1→1.0
  (power 1.7); metal crack at 0.82 s = noise 1.8–9 kHz ×2.6 (12 ms decay) + 4.2 kHz
  ring (30 ms) ×0.7 + 1.6 kHz ring (20 ms) ×0.5; hard pulse at 0.90 s = 48 Hz ring
  (50 ms decay) ×1.4 + thump noise 0.8–5 kHz ×1.2 (8 ms decay).

## Determinism

`synth_common.seeded()` wraps `random.Random(name)`, whose string seeding changed in
CPython 3.11 (sha512 conversion), so the noise of these takes comes from `HashRng` in
the script instead: 53-bit fractions read out of `sha512(f"{take_name}\n{counter}")`,
seven draws per hash. Two consecutive runs of `python3 tools/audio/gen_overseer.py`
in this sandbox produced byte-identical files (matching SHA-256 sums below); no
wall-clock time and no global random state is read.

## Processing / verification

Written directly by `save_wav` as mono, 48 kHz, 16-bit PCM with no further editing.
Measured on the delivered files (generated and checked with Python 3.13.5 here):

- `robot_overseer_high_windup_01.wav` — 74924 bytes, 37440 samples (0.780 s), peak
  −1.50 dBFS, 95.8 % energy in 1–5 kHz, rising centroid,
  SHA-256 `695bee7019d9759453a71ac2f943b00c17c034e4048f8afc4b1b7b7595bb1d1a`
- `robot_overseer_low_windup_01.wav` — 67244 bytes, 33600 samples (0.700 s), peak
  −1.50 dBFS, 98.0 % energy in 1–5 kHz, falling centroid,
  SHA-256 `4e6173953ab2f79ebcfea684e8e1a6319be0f7833b42a28c12031994043e0ffa`
- `boss_gate_close_01.wav` — 211244 bytes, 105600 samples (2.200 s), peak −1.50 dBFS,
  SHA-256 `3934ab612de406d649a5403e1d15e0fd3dfc4aa2a6bb2ed60856b9b1821b9c5b`
- `boss_phase2_01.wav` — 110442 bytes, 55199 samples (1.150 s), peak −1.50 dBFS,
  SHA-256 `49e0ed311107e8832a7e688dd96e0ae3e22d88f25408e34326fdc38ea3232672`

Checks (all four PASS):

- `python3 tools/audio/check_spec.py tell game/audio/combat/robot_overseer_high_windup_01.wav game/audio/combat/robot_overseer_low_windup_01.wav`
- `python3 tools/audio/check_spec.py effect game/audio/combat/boss_gate_close_01.wav game/audio/combat/boss_phase2_01.wav`
