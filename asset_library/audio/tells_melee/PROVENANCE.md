# Melee windup tells — guard, shield bearer, sentinel, dog (2026-11-14)

Four priority-1 attack tells for the melee robots, one per robot, so a windup can
be heard before the hit (`docs/design/sound-bible.md`, pillar 1 "Read before hit",
event list rows "Guard melee tell", "Shield bearer tell", "Sentinel tell", "Dog tell").

| Field | Value |
|---|---|
| Source | Original synthesis, no samples or third-party material |
| Script | `tools/audio/gen_tells_melee.py` (uses `tools/audio/synth_common.py`; stdlib only: `hashlib`, `math`, `os`, plus `wave`/`struct` through `save_wav`) |
| Tool | Python 3 standard library (`hashlib`, `math`, `os`; WAV via `synth_common.save_wav` → `wave`/`struct`). This sandbox image ships no `python3`, so the takes were built and measured with a line-for-line port of `gen_tells_melee.py`; the port reproduces `check_spec.py --self-test`'s verdicts, and the Python script stays the canonical generator |
| Seeds | Take names as hash keys: `robot_guard_windup_01`, `robot_shield_windup_01`, `robot_sentinel_windup_01`, `robot_dog_windup_01` (SHA-512 counter stream, see "Determinism") |
| Author | swarvex contributor (task: Sound batch — melee windup tells) |
| Licence | CC BY-SA 4.0, https://creativecommons.org/licenses/by-sa/4.0/ |
| Outputs | `game/audio/combat/robot_guard_windup_01.wav`, `game/audio/combat/robot_shield_windup_01.wav`, `game/audio/combat/robot_sentinel_windup_01.wav`, `game/audio/combat/robot_dog_windup_01.wav` |

## Design

Machine material only, no breath, growl or voice (sound bible "Don't"). Each tell is
meant to be recognisable by pitch range, texture and envelope alone, so four robots
winding up at once still read apart. Measured on the delivered files (48 kHz mono,
peak normalised to −1.5 dBFS, energy share in 1–5 kHz, spectral flatness = tonal→noisy,
crest = transient density, 40 ms RMS window):

| File | Duration | Pitch (core, centroid) | Texture | Envelope |
|---|---|---|---|---|
| `robot_guard_windup_01.wav` | 0.580 s | glide 2→4 kHz plus 1–2 kHz gear partial, centroid 2957 Hz | tonal servo whine, flatness 0.14, one relay click | 5 ms attack, steady rise −5→0 dB, 60 ms release |
| `robot_shield_windup_01.wav` | 0.640 s | hiss band 1–3 kHz, ring 1.8 + 2.65 kHz, centroid 2536 Hz | broad hydraulic hiss, flatness 0.48 (noisiest), heavy clamp transient, crest 4.9 | 20 ms attack, swell −7→−3 dB, clamp on sample 0, shield-edge ring from 0.44 s |
| `robot_sentinel_windup_01.wav` | 0.700 s | exponential glide 1.5→4.5 kHz, centroid 3419 Hz (highest) | pure charge-up tone with 24 Hz and 83 Hz flutter, flatness 0.10 | 4 ms attack, long crescendo −15→0 dB over the whole take |
| `robot_dog_windup_01.wav` | 0.560 s | whine bed 1→3 kHz, clicks 2.5→4.9 kHz, centroid 2158 Hz | pulsed ratchet, flatness 0.25, 7 clicks at 85→70 ms (~12/s rising) | 10 ms attack, flat body with click spikes, 50 ms release |

Layer breakdown as synthesised (all timings in seconds, gains before the peak
normalisation):

- **guard** — `sweep 2000→4000 Hz` + 0.32 × `sweep 1000→2000 Hz`, 7 Hz vibrato ±6 %,
  envelope `env_ar(0.005, 0.06)` × ramp 0.55→1.0; relay click at 0.060 s = noise
  band-passed 1.3–5.2 kHz (two one-pole stages) ×1.8, 2.2 ms decay, plus a 2.8 kHz
  ring (6 ms decay) ×0.5.
- **shield bearer** — noise bed band-passed 1–3.2 kHz (two stages) ×2.4, envelope
  `env_ar(0.02, 0.08)` × ramp 0.4→1.0 (power 0.8); clamp on sample 0 = noise 0.8–6 kHz
  ×1.2, 3 ms decay, plus a 170 Hz body thump (9 ms decay) ×0.3; shield edge from
  0.440 s = 1800 Hz (80 ms decay) + 0.7 × 2650 Hz (60 ms decay), ×0.3.
- **sentinel** — single sine sweeping 1.5→4.5 kHz exponentially, AM ±24 % at 24 Hz and
  ±9 % at 83 Hz, envelope `env_ar(0.004, 0.03)` × ramp 0.16→1.0 (power 1.6), plus a
  discharge hiss band-passed 2.6–5.2 kHz ×0.16 under the same envelope.
- **dog** — whine `sweep 1000→3000 Hz`, 12 Hz vibrato ±10 %, ×0.5, envelope
  `env_ar(0.01, 0.05)` × ramp 0.6→1.0 (power 0.7); clicks from 0.020 s, gap 0.088 s
  shrinking 5 % per click, each = noise 2.2–6 kHz ×(1.6 + 0.12 k) with 1.6 ms decay
  plus a ring at 2500 + 400 k Hz (4.5 ms decay) ×0.55.

## Determinism

`synth_common.seeded()` wraps `random.Random(name)`, whose string seeding changed in
CPython 3.11 (sha512 conversion), so the noise of these takes comes from
`HashRng` in the script instead: 53-bit fractions read out of
`sha512(f"{take_name}\\n{counter}")`, seven draws per hash. Repeated runs of the
script are byte-identical on every Python build (two consecutive runs produced
identical SHA-256 sums), no wall-clock time and no global random state is read.

## Processing / verification

Written directly by `save_wav` as mono, 48 kHz, 16-bit PCM with no further editing.
Measured on the delivered files:

- `robot_guard_windup_01.wav` — 55722 bytes, 27840 samples (0.580 s), peak −1.50 dBFS,
  first sample above −40 dBFS at 0.1 ms, 100.0 % energy in 1–5 kHz,
  SHA-256 `4b35ab7a1e2f84407423cc110869e3d2220b63b8622e645e1a4c6361cc8c53b5`
- `robot_shield_windup_01.wav` — 61484 bytes, 30720 samples (0.640 s), peak −1.50 dBFS,
  audible from sample 0, 77.4 % energy in 1–5 kHz,
  SHA-256 `c1c2cdd07d14fe6826563d40b468e63d1e098051631eb049f4839d1af1c231f9`
- `robot_sentinel_windup_01.wav` — 67244 bytes, 33600 samples (0.700 s), peak −1.50 dBFS,
  first sample above −40 dBFS at 0.4 ms, 100.0 % energy in 1–5 kHz,
  SHA-256 `c8a43ac12fb1ee2c3a5840fb3b734c68ba8adba9e3978a6545af8eee77b1c4c6`
- `robot_dog_windup_01.wav` — 53804 bytes, 26880 samples (0.560 s), peak −1.50 dBFS,
  first sample above −40 dBFS at 0.6 ms, 99.3 % energy in 1–5 kHz,
  SHA-256 `13956fd12a71457207a332ad013bf43a9f99218b7e3f5e3ace85b1b73e44ea79`

`python3 tools/audio/check_spec.py tell game/audio/combat/robot_*_windup_01.wav` is the
check for these takes (kind `tell`: 0.50–0.80 s, ≥ 60 % energy in 1–5 kHz, ≤ 20 ms
leading silence, ≤ −1.0 dBFS).
