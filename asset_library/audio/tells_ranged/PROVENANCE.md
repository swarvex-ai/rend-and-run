# Ranged tells and gunshot — guard (2026-11-16)

Three sounds for the ranged guard so its 0.85 s windup is audible before the
shot (`docs/design/sound-bible.md`, event list rows "Guard gunshot" and the
energy rifle "rising electrical whine before the shot"; bestiary/guard.md).

| Field | Value |
|---|---|
| Source | Original synthesis, no samples or third-party material; machine sounds only |
| Script | `tools/audio/gen_tells_ranged.py` (uses `tools/audio/synth_common.py`; stdlib only: `hashlib`, `math`, `os`, plus `wave`/`struct` through `save_wav`) |
| Tool | Python 3 standard library (`hashlib`, `math`, `os`; WAV via `synth_common.save_wav` → `wave`/`struct`) |
| Seeds | Take names as hash keys: `robot_guard_ranged_windup_01`, `robot_energy_whine_01`, `robot_guard_gunshot_01` (SHA-512 counter stream, see "Determinism") |
| Date | 2026-11-16 |
| Author | swarvex contributor (task: Sound batch — ranged tells and gunshot) |
| Licence | CC BY-SA 4.0, https://creativecommons.org/licenses/by-sa/4.0/ |
| Outputs | `game/audio/combat/robot_guard_ranged_windup_01.wav`, `game/audio/combat/robot_energy_whine_01.wav`, `game/audio/combat/robot_guard_gunshot_01.wav` |

## Design

Machine material only, no breath, growl or voice (sound bible "Don't").

- **ranged windup** — `sweep 1500→3500 Hz` servo whine, envelope `env_ar(0.005, 0.06)` × ramp 0.5→1.0; metallic latch click at 0.450 s = noise band-passed 1.2–6.5 kHz (two one-pole stages) ×1.6, 2.5 ms decay, plus a 3.3 kHz ring ×0.5, 8 ms decay. Duration 0.750 s.
- **energy whine** — exponential `sweep 1200→4800 Hz` rising for the whole take, slight tremolo (AM 22 Hz, depth 0.12), envelope `env_ar(0.004, 0.05)` × ramp 0.15→1.0 (power 1.4). Duration 0.760 s. No click.
- **gunshot** — body thump: 90 Hz sine over 30 ms (`env_ar(0.001, 0.029)`); crack: noise band-passed 2–8 kHz, 5 ms decay; thin tail: noise band-passed 0.9–3.2 kHz decaying over the 0.220 s take. Pistol-like; no recognisable product sound.

Layer breakdown as synthesised (all timings in seconds, gains before the peak
normalisation):

- **ranged windup** — whine `sweep 1500→3500 Hz` × envelope; click at 0.450 s.
- **energy whine** — exponential sweep `1200→4800 Hz` × tremolo × envelope.
- **gunshot** — 90 Hz body thump 0.030 s, 2–8 kHz crack 0.010 s, thin tail 0.9–3.2 kHz over 0.220 s.

## Determinism

`synth_common.seeded()` wraps `random.Random(name)`, whose string seeding changed in
CPython 3.11 (sha512 conversion), so the noise of these takes comes from
`HashRng` in the script instead: 53-bit fractions read out of
`sha512(f"{take_name}\\n{counter}")`, seven draws per hash. Repeated runs of the
script are byte-identical on every Python build (two consecutive runs produced
identical SHA-256 sums), no wall-clock time and no global random state is read.

## Processing / verification

Written directly by `save_wav` as mono, 48 kHz, 16-bit PCM with no further editing,
peak normalised to −1.5 dBFS (so the −1.0 dBTP ceiling holds).

- `robot_guard_ranged_windup_01.wav` — 0.750 s, tell, peak −1.50 dBFS, ≤ 20 ms leading silence
- `robot_energy_whine_01.wav` — 0.760 s, tell, peak −1.50 dBFS, ≤ 20 ms leading silence
- `robot_guard_gunshot_01.wav` — 0.220 s, effect, peak −1.50 dBFS, body thump 30 ms, tail ≤ 500 ms

`python3 tools/audio/check_spec.py tell game/audio/combat/robot_guard_ranged_windup_01.wav game/audio/combat/robot_energy_whine_01.wav` and
`python3 tools/audio/check_spec.py effect game/audio/combat/robot_guard_gunshot_01.wav` are the checks for these takes (kind `tell`: 0.50–0.80 s, ≥ 60 % energy in 1–5 kHz, ≤ 20 ms leading silence, ≤ −1.0 dBFS; kind `effect`: 0.03–3.0 s, ≤ −1.0 dBFS).
