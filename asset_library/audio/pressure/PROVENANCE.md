# Pressure task — door announce, countdown tick, failure burst (2026-11-16)

Three machine cues for the pressure task (S16), the quick-maths door just after the
relay checkpoint (`docs/milestone-1.md`): a door announce 2 m before the door, the
per-second countdown tick and the failure that ends the countdown at 0
(`docs/design/sound-bible.md`, event-list rows "Pressure door announce", "Pressure
countdown", "Pressure failure"). The spoken "Ten seconds" PA line is a separate task;
nothing here is wired into the door yet.

| Field | Value |
|---|---|
| Source | Original synthesis, no samples or third-party material |
| Script | `tools/audio/gen_pressure.py` (uses `tools/audio/synth_common.py`; stdlib only: `hashlib`, `math`, `os`, plus `wave`/`struct` through `save_wav`) |
| Tool | CPython 3.13.5, standard library (`hashlib`, `math`, `os`; WAV via `synth_common.save_wav` → `wave`/`struct`). The delivered files are the direct output of `python3 tools/audio/gen_pressure.py` run in this repository (no external port). |
| Seeds | Take names as hash keys: `pressure_announce_01`, `pressure_tick_01`, `pressure_fail_01` (SHA-512 counter stream, see "Determinism") |
| Author | swarvex contributor (task: Sound batch — pressure announce/tick/failure) |
| Licence | CC BY-SA 4.0, https://creativecommons.org/licenses/by-sa/4.0/ |
| Outputs | `game/audio/combat/pressure_announce_01.wav`, `game/audio/ui/pressure_tick_01.wav`, `game/audio/combat/pressure_fail_01.wav` |

## Design

Pure machine material, no organic layer (sound bible "Do and don't"). Written as three
priority-1 cues around a maths door; the announce reads as an urgent warning without
becoming the continuous escape-siren wail. Measured on the delivered files (48 kHz mono,
peak normalised to −1.5 dBFS, energy share per band from `check_spec.py`'s FFT):

| File | Duration | Content (core bands) | Shape |
|---|---|---|---|
| `pressure_announce_01.wav` | 0.900 s | two gated electronic notes 680 Hz then a slight glide to ~1000 Hz + a 2f harmonic; 96 % of energy in 600–2000 Hz | staccato chirp, 36 Hz AM, 6 ms attack / 50 ms release, then a relay clack |
| `pressure_tick_01.wav` | 0.090 s | dry clock tone at 2.5 kHz with a touch of 5 kHz metal; 97 % of energy in 2–8 kHz, 93 % in 1–5 kHz | mechanical click into a 6 ms decay, audibly done by ~50 ms, clean silence tail |
| `pressure_fail_01.wav` | 1.400 s | falling buzzy tone 880→190 Hz (octave + fifth-harmonic grit, 24 Hz AM) → rising charge 320→3200 Hz → burst | burst layers body 40–120 Hz, panel 120–600 Hz, debris 2–8 kHz (sound bible pillar 2) |

Layer breakdown as synthesised (timings in seconds, gains before peak normalisation):

- **announce** — note 1 `sweep 680→690 Hz` and note 2 `sweep 900→1010 Hz`, each mixed
  with 0.25 × its octave, AM ±18 % at 36 Hz, `env_ar(0.006, 0.05)`, gains 0.85 / 1.0 at
  0.03 s / 0.26 s; relay latch at 0.55 s = noise band-passed 0.8–6 kHz ×2.2 (6 ms decay)
  + 150 Hz thunk ×0.8 + 2.2 kHz ring ×0.5; a softer release clack at 0.78 s.
- **tick** — escapement click at 0 s = noise band-passed 1.8–9 kHz ×1.5, 0.8 ms decay;
  tone = 2.5 kHz ring (6 ms decay) + 0.4 × 5 kHz ring (4 ms decay); window 90 ms.
- **failure** — buzz = `sweep 880→190 Hz` + 0.30 × `1760→380 Hz` + 0.12 ×
  `2640→570 Hz`, AM ±50 % at 24 Hz, `env_ar(0.005, 0.03)` × ramp 1.0→0.7; charge from
  0.45 s = `sweep 320→3200 Hz` (exponential) AM ±25 % at 50 Hz, crescendo ramp
  0.15→1.0 (power 1.8), ×0.7, plus a rising 2.5–8 kHz hiss ×0.4; burst at 0.78 s =
  body rings 52/90/110/46 Hz (×1.4/1.0/0.7/1.2), panel rings 200/340/480 Hz
  (×0.9/0.7/0.55) + noise 120–600 Hz ×1.1, debris crack 2–8 kHz ×2.2 (10 ms decay) +
  a 2–8 kHz debris tail ×0.6 with a 300 ms release.

## Determinism

`synth_common.seeded()` wraps `random.Random(name)`, whose string seeding changed in
CPython 3.11 (sha512 conversion), so the noise of these takes comes from `HashRng` in
the script instead: 53-bit fractions read out of `sha512(f"{take_name}\n{counter}")`,
seven draws per hash. Repeated runs of the script are byte-identical (two consecutive
`python3 tools/audio/gen_pressure.py` runs produced identical SHA-256 sums, see below);
no wall-clock time and no global random state is read.

## Processing / verification

Written directly by `save_wav` as mono, 48 kHz, 16-bit PCM, no further editing. All
figures below were produced in this repository with the canonical Python script and the
project checker, not from a port.

Two consecutive runs of `python3 tools/audio/gen_pressure.py` gave identical SHA-256
sums:

- `pressure_announce_01.wav` — 86444 bytes, 43200 samples (0.900 s), peak −1.50 dBFS,
  RMS −14.4 dBFS, 0 clipped samples,
  SHA-256 `587e4773e4335831ffe3802e5531207d47a6080366c8bb6ebb77a0cfdff01702`
- `pressure_tick_01.wav` — 8684 bytes, 4320 samples (0.090 s, within ±10 ms),
  peak −1.50 dBFS, RMS −20.6 dBFS, 0 clipped samples,
  SHA-256 `d49fdf206b035e8f0520bd107b25486c2d5bddc25279e22d39c566b236821f6c`
- `pressure_fail_01.wav` — 134444 bytes, 67200 samples (1.400 s), peak −1.50 dBFS,
  RMS −18.8 dBFS, 0 clipped samples,
  SHA-256 `36865a8ad6ebbf5b262f374bef0cf784e59d21b6e339796e281b64ab110e36ce`

Checks run against these files:

- `python3 tools/audio/check_spec.py effect game/audio/combat/pressure_announce_01.wav game/audio/combat/pressure_fail_01.wav`
  → `PASS` for both (kind `effect`: 0.03–3.0 s, mono, 48 kHz, 16-bit, ≤ −1.0 dBFS).
- `python3 tools/audio/check_spec.py ui game/audio/ui/pressure_tick_01.wav`
  → `PASS` (kind `ui`: 0.04–0.12 s).
