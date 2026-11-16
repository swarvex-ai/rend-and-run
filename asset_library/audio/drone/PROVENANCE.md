# Kamikaze drone dive and detonation (2026-11-16)

Two priority-1 sounds for the kamikaze drone: the committed dive and the
detonation (`docs/design/sound-bible.md` event list rows "Kamikaze drone dive"
and "Kamikaze drone detonation"; `docs/bestiary/drone.md`). The lock-on warning
reuse of `audio/block.wav` is unchanged and not part of this batch.

| Field | Value |
|---|---|
| Source | Original synthesis, no samples or third-party material; machine sounds only (rotor whine, sheet metal, shrapnel, air — no organic layer) |
| Script | `tools/audio/gen_drone.py` (uses `tools/audio/synth_common.py`; stdlib only: `hashlib`, `math`, `os`, plus `wave`/`struct` through `save_wav`) |
| Tool | Python 3.13.5 standard library (`hashlib`, `math`, `os`; WAV via `synth_common.save_wav` → `wave`/`struct`) |
| Seeds | Take names as hash keys: `robot_drone_dive_01`, `robot_drone_blast_01` (SHA-512 counter stream, see "Determinism") |
| Date | 2026-11-16 |
| Author | swarvex contributor (task: Sound batch — kamikaze drone dive and detonation) |
| Licence | CC BY-SA 4.0, https://creativecommons.org/licenses/by-sa/4.0/ |
| Outputs | `game/audio/combat/robot_drone_dive_01.wav` (SHA-256 `6d3f0f88665f3edef5e6dddb8d8339a4c433dc8c26d12d40e17f9127913e85ff`), `game/audio/combat/robot_drone_blast_01.wav` (SHA-256 `03e8dd974e8578ea49ecbcaa158fe7a285a4f8e6057d549563c466b8b0892838`) |

## Design

Machine material only, no breath, growl or organic squelch (sound bible "Don't");
the drone breaks into parts, it does not bleed.

- **dive** (`robot_drone_dive_01.wav`, 0.900 s) — rotor whine: exponential `sweep 1500→5000 Hz` with envelope `env_ar(0.02, 0.10)` × ramp 0.35→1.0. Under it a **rushing noise bed**: noise high-passed 0.7 kHz (two one-pole stages) and low-passed once at 9 kHz, envelope `env_ar(0.05, 0.15)` × ramp 0→1 (power 1.5) so the air swells as the dive commits; mixed at gain 1.15.
- **detonation** (`robot_drone_blast_01.wav`, 0.550 s) — pillar 2 "Machines have mass": **body thump** (60 Hz sine + 40–120 Hz noise, 80 ms, `env_ar(0.001, 0.079)`) for the mass; **panel hit** (120–600 Hz sheet metal plus a 300 Hz struck-panel ring, 130 ms); **debris tail** (shrapnel band-limited to 2–8 kHz, 550 ms burst with a 150 ms decay). No organic material.

## Steep band-limiting of the debris tail

Each `synth_common` filter stage is one-pole (~6 dB/octave). A plain two-pass
band-pass (the previous attempt) leaves ~40 % of the debris energy above 8 kHz,
so the tail is shaped with **2 high-pass and 10 low-pass one-pole stages**
(`steep_noise(rng, 0.55, 2000, 8000, hp=2, lp=10, tau=0.15)`). Measured on the
delivered file with a Hann-windowed 4096-point DFT over the tail window
0.20–0.55 s:

| Region of the blast | Measurement (Hann 4096-pt DFT) |
|---|---|
| Body + panel at the front (0–21 ms) | 50 % of energy in 40–120 Hz, 32 % in 120–600 Hz (both layers present) |
| Body dominating (0–60 ms) | 76 % in 40–120 Hz, 22 % in 120–600 Hz |
| Debris tail (0.20–0.55 s) | **96.0 % in 2–8 kHz**, 1.3 % above 8 kHz, 2.7 % below 2 kHz |
| Debris tail length | 2–8 kHz band envelope falls to 5 % of its 0.10 s level at ~0.48 s (≤ 600 ms) |

The tail's in-band share (96.0 %) clears the ≥ 85 % target for the 2–8 kHz band.

## Audibility of the dive's rushing bed

Because the whine is a pure tone its energy is concentrated in a single bin, so
a broadband layer always shows a low *fraction* of the total. The rush is
therefore checked as broadband content the whine (topping out at 5 kHz) cannot
hold: **6.2 % of the dive's energy lies above 8 kHz** (the previous take had
~0.4 %) and 4.1 % in 5–12 kHz, rising with the rush envelope, while 92 % stays in
the whine band 1.4–5.2 kHz so the rotor still reads as the dominant tell.

## Determinism

`synth_common.seeded()` wraps `random.Random(name)`, whose string seeding changed
in CPython 3.11 (sha512 conversion), so the noise comes from `HashRng` in the
script instead: 53-bit fractions read out of `sha512(f"{take_name}\n{counter}")`,
seven draws per hash. Repeated runs of the script are byte-identical (two
consecutive runs produced identical SHA-256 sums), no wall-clock time and no
global random state is read.

## Processing / verification

Written directly by `save_wav` as mono, 48 kHz, 16-bit PCM with no further
editing, peak normalised to −1.5 dBFS (so the −1.0 dBTP ceiling holds).

- `robot_drone_dive_01.wav` — 0.900 s, peak −1.50 dBFS; whine dominant spectral bin rises ~1.65 kHz → ~4.47 kHz
- `robot_drone_blast_01.wav` — 0.550 s, peak −1.50 dBFS; total ≤ 1.5 s, debris tail ≤ 600 ms

`python3 tools/audio/check_spec.py effect game/audio/combat/robot_drone_dive_01.wav game/audio/combat/robot_drone_blast_01.wav` is the check for these takes (kind `effect`: mono 48 kHz 16-bit PCM, 0.03–3.0 s, ≤ −1.0 dBFS).
