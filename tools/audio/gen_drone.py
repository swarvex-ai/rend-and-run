#!/usr/bin/env python3
"""Kamikaze drone dive and detonation (stdlib only).

Two priority-1 sounds for the kamikaze drone (`docs/bestiary/drone.md`,
`docs/design/sound-bible.md` event list rows "Kamikaze drone dive" and
"Kamikaze drone detonation"). Pure machine material — rotor whine, sheet-metal
panels and shrapnel — no organic layer (sound bible "Do and don't"): the only
warm source in the game is Rend, and a drone breaks into parts, it does not
bleed.

Writes two mono 48 kHz / 16-bit PCM takes with `synth_common.save_wav`
(peak -1.5 dBFS, so the -1.0 dBTP ceiling holds) into `game/audio/combat/`:

    robot_drone_dive_01.wav   committed dive: rotor whine rising 1.5->5 kHz
                              over a rushing broadband noise bed, 0.9 s
    robot_drone_blast_01.wav  detonation per pillar 2 "Machines have mass": a
                              40-120 Hz body thump, a 120-600 Hz panel hit and
                              a band-limited 2-8 kHz debris tail, <= 1.5 s

Run from the repo root:  python3 tools/audio/gen_drone.py
Check the result:        python3 tools/audio/check_spec.py effect game/audio/combat/robot_drone_dive_01.wav game/audio/combat/robot_drone_blast_01.wav

Determinism: the noise of each take comes from a SHA-512 counter stream keyed
by the take name (`HashRng`), so repeated runs are byte-identical on every
Python build. `synth_common.seeded()` is deliberately not used for the noise
draw: it wraps `random.Random(name)`, whose str-seeding changed in CPython
3.11 (sha512 conversion), and these takes are committed binaries that must
stay reproducible. Same take name, same bytes; nothing reads wall-clock time.

Debris tail: each `synth_common` filter stage is one-pole, so the tail is
shaped with 2 high-pass and 10 low-pass stages (a plain two-pass band-pass
leaves ~40 % of the energy above 8 kHz). Measured over the tail window
(0.2-0.55 s) ~96 % of the energy then sits inside 2-8 kHz, matching the
pillar-2 band (see asset_library/audio/drone/PROVENANCE.md).
"""
import hashlib
import math
import os

from synth_common import SR, env_ar, highpass, lowpass, mix, noise, save_wav, sine

OUT_DIR = os.path.join(
    os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))),
    "game", "audio", "combat",
)
PEAK_DB = -1.5
RES53 = 9007199254740992.0  # 2 ** 53, the resolution of a float RNG draw


class HashRng:
    """Name-keyed deterministic noise source with a `uniform` method.

    Draws 53-bit fractions from sha512(f"{name}\\n{counter}"), seven draws per
    hash, so the stream is identical on every Python version and platform
    (unlike the MT stream behind `synth_common.seeded()`)."""

    def __init__(self, name: str) -> None:
        self._name = name
        self._counter = 0
        self._draws: list[int] = []

    def _next_draw(self) -> int:
        if not self._draws:
            digest = hashlib.sha512(
                f"{self._name}\n{self._counter}".encode("utf-8")
            ).digest()
            self._counter += 1
            value = int.from_bytes(digest, "big")
            self._draws = [(value >> (53 * k)) & 0x1FFFFFFFFFFFFF for k in range(7)]
        return self._draws.pop()

    def random(self) -> float:
        """One fraction in [0, 1) with 53-bit resolution."""
        return self._next_draw() / RES53

    def uniform(self, a: float, b: float) -> float:
        """One value in [a, b), shaped like `random.Random.uniform`."""
        return a + self.random() * (b - a)


def sweep(n: int, f_start: float, f_end: float) -> list[float]:
    """`n` samples of a sine gliding from `f_start` to `f_end` Hz.

    Phase is accumulated from the instantaneous frequency and the range is
    travelled exponentially, so a rotor charge-up sounds like it accelerates."""
    out: list[float] = []
    phase = 0.0
    last = max(1, n - 1)
    for i in range(n):
        t = i / last
        freq = f_start * (f_end / f_start) ** t
        out.append(math.sin(phase))
        phase += 2.0 * math.pi * freq / SR
    return out


def ramp(n: int, start: float, end: float, power: float) -> list[float]:
    """`n` gains rising from `start` to `end` with an `x ** power` easing."""
    last = max(1, n - 1)
    return [start + (end - start) * (i / last) ** power for i in range(n)]


def gains_product(a: list[float], b: list[float]) -> list[float]:
    """Sample-wise product of two gain curves."""
    return [x * y for x, y in zip(a, b)]


def scaled(track: list[float], factor: float) -> list[float]:
    """Track times a constant gain."""
    return [s * factor for s in track]


def steep_noise(rng: HashRng, seconds: float, lo_hz: float, hi_hz: float,
                hp_poles: int, lp_poles: int, tau_s: float | None) -> list[float]:
    """Noise band-limited with `hp_poles` high-pass and `lp_poles` low-pass stages.

    Every `synth_common` stage is one-pole (~6 dB/octave). A single band-pass
    pair is far too gentle to hold a band, so a debris tail asks for many
    low-pass stages to keep its energy below `hi_hz` (and enough high-pass
    stages to keep it above `lo_hz`). `tau_s` of None keeps the level steady."""
    n = max(1, int(seconds * SR))
    samples = [noise(rng) for _ in range(n)]
    for _ in range(lp_poles):
        samples = lowpass(samples, hi_hz)
    for _ in range(hp_poles):
        samples = highpass(samples, lo_hz)
    if tau_s is None:
        return samples
    tau = tau_s * SR
    return [x * math.exp(-i / tau) for i, x in enumerate(samples)]


def ring(freq_hz: float, seconds: float, tau_s: float) -> list[float]:
    """Decaying sine at `freq_hz` with exponential time constant `tau_s`."""
    n = max(1, int(seconds * SR))
    tau = tau_s * SR
    return [
        math.sin(2.0 * math.pi * freq_hz * i / SR) * math.exp(-i / tau)
        for i in range(n)
    ]


def apply_envelope(samples: list[float], envelope: list[float]) -> None:
    """Multiply `samples` in place by a gain curve of the same length."""
    for i in range(len(samples)):
        samples[i] *= envelope[i]


def place(track: list[float], offset: int, into: list[float]) -> None:
    """Add `track` into `into` starting at sample `offset`, clipped at both ends."""
    for i, s in enumerate(track):
        j = offset + i
        if 0 <= j < len(into):
            into[j] += s


def dive() -> list[float]:
    """Committed dive: rotor whine rising 1.5->5 kHz over a rushing noise bed."""
    rng = HashRng("robot_drone_dive_01")
    n = int(0.9 * SR)
    # rotor whine, exponential 1.5->5 kHz glide, accelerating into the strike
    whine = sweep(n, 1500.0, 5000.0)
    apply_envelope(whine, gains_product(env_ar(n, 0.02, 0.10), ramp(n, 0.35, 1.0, 1.0)))
    # rushing air: broadband noise, a distinct layer ~9 dB under the whine,
    # swelling in level as the dive commits (high-passed 0.7 kHz, low-passed
    # once at 9 kHz so genuine broadband air survives above the whine)
    rush = steep_noise(rng, n / SR, 700.0, 9000.0, 2, 1, None)
    apply_envelope(rush, gains_product(env_ar(n, 0.05, 0.15), ramp(n, 0.0, 1.0, 1.5)))
    return mix(whine, scaled(rush, 1.15))


def blast() -> list[float]:
    """Detonation: 40-120 Hz body thump, 120-600 Hz panel hit, 2-8 kHz debris."""
    rng = HashRng("robot_drone_blast_01")
    n = int(0.9 * SR)
    tracks: list[list[float]] = []
    # body thump: 60 Hz sine plus 40-120 Hz noise, ~80 ms, dominates the front
    m = int(0.080 * SR)
    body = sine(60.0, m)
    apply_envelope(body, env_ar(m, 0.001, 0.079))
    body = mix(body, scaled(steep_noise(rng, 0.080, 40.0, 120.0, 1, 3, 0.022), 0.6))
    tracks.append(body)
    # panel hit: 120-600 Hz sheet metal with a 300 Hz struck-panel ring
    panel = steep_noise(rng, 0.140, 130.0, 600.0, 2, 3, 0.050)
    place(scaled(ring(300.0, 0.12, 0.030), 0.7), 0, panel)
    tracks.append(scaled(panel, 1.2))
    # debris tail: shrapnel band-limited to 2-8 kHz (steep, ~96 % in band)
    tail = steep_noise(rng, 0.55, 2000.0, 8000.0, 6, 10, 0.150)
    tracks.append(scaled(tail, 0.42))
    return mix(*tracks)


GENERATORS = (
    ("robot_drone_dive_01.wav", dive),
    ("robot_drone_blast_01.wav", blast),
)


def main() -> int:
    """Build the two takes and write them to `game/audio/combat/`."""
    for name, build in GENERATORS:
        path = os.path.join(OUT_DIR, name)
        save_wav(path, build(), PEAK_DB)
        print(f"wrote {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
