#!/usr/bin/env python3
"""Ranged tells and gunshot for gun guards (stdlib only).

Priority-1 attack tells (`docs/design/sound-bible.md`, pillar 1 "Read before
hit"): the ranged guard's 0.85 s windup needs an audible tell that starts with
the windup and lasts 700-800 ms, keeping its energy in 1-5 kHz. Pure machine
material — servo whine, latch click, electrical charge — no breath, growl or
voice (sound bible "Do and don't").

Writes three mono 48 kHz / 16-bit PCM takes with `synth_common.save_wav`
(peak -1.5 dBFS, so the -1.0 dBTP ceiling holds) into `game/audio/combat/`:

    robot_guard_ranged_windup_01.wav  weapon-raise servo: 1.5->3.5 kHz whine
                                      plus a metallic latch click at 450 ms
    robot_energy_whine_01.wav         energy rifle charge: clean whine rising
                                      1.2->4.8 kHz with slight tremolo
    robot_guard_gunshot_01.wav        short dry crack: 40-120 Hz body thump
                                      for 30 ms, 2-8 kHz crack, thin tail,
                                      <= 500 ms total

Run from the repo root:  python3 tools/audio/gen_tells_ranged.py
Check the result:        python3 tools/audio/check_spec.py tell game/audio/combat/robot_guard_ranged_windup_01.wav game/audio/combat/robot_energy_whine_01.wav
                           python3 tools/audio/check_spec.py effect game/audio/combat/robot_guard_gunshot_01.wav

Determinism: the noise of each take comes from a SHA-512 counter stream keyed
by the take name (`HashRng`), so repeated runs are byte-identical on every
Python build. `synth_common.seeded()` is deliberately not used for the noise
draw: it wraps `random.Random(name)`, whose str-seeding changed in CPython
3.11 (sha512 conversion), and these takes are committed binaries that must
stay reproducible. Same take name, same bytes; nothing reads wall-clock time.
"""
import hashlib
import math
import os

from synth_common import SR, bandpass, env_ar, mix, noise, save_wav, sine

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


def sweep(n: int, f_start: float, f_end: float, curve_exp: bool = False) -> list[float]:
    """`n` samples of a sine gliding from `f_start` to `f_end` Hz.

    Phase is accumulated from the instantaneous frequency, so the glide stays
    smooth; `curve_exp` travels the range exponentially (charge-up feel)."""
    out: list[float] = []
    phase = 0.0
    last = max(1, n - 1)
    for i in range(n):
        t = i / last
        if curve_exp:
            freq = f_start * (f_end / f_start) ** t
        else:
            freq = f_start + (f_end - f_start) * t
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


def am(track: list[float], rate_hz: float, depth: float) -> list[float]:
    """Amplitude modulation: track * (1 + depth * sine(rate_hz))."""
    return [
        s * (1.0 + depth * math.sin(2.0 * math.pi * rate_hz * i / SR))
        for i, s in enumerate(track)
    ]


def band_noise(rng: HashRng, seconds: float, lo_hz: float, hi_hz: float,
               tau_s: float | None, passes: int) -> list[float]:
    """Band-limited noise, optionally with an exponential decay of `tau_s`.

    Each `bandpass` stage is one-pole, so two stages are used for a steep
    enough edge to keep a tell's energy inside 1-5 kHz; `tau_s` of None keeps
    the burst level steady (bed layers)."""
    n = max(1, int(seconds * SR))
    samples = [noise(rng) for _ in range(n)]
    for _ in range(passes):
        samples = bandpass(samples, lo_hz, hi_hz)
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


def ranged_windup() -> list[float]:
    """Weapon-raise servo: 1.5->3.5 kHz whine plus a metallic latch click at 450 ms."""
    rng = HashRng("robot_guard_ranged_windup_01")
    n = int(0.75 * SR)
    samples = sweep(n, 1500.0, 3500.0)
    envelope = gains_product(env_ar(n, 0.005, 0.06), ramp(n, 0.5, 1.0, 1.0))
    apply_envelope(samples, envelope)
    click = int(0.45 * SR)
    place(scaled(band_noise(rng, 0.012, 1200.0, 6500.0, 0.0025, 2), 1.6), click, samples)
    place(scaled(ring(3300.0, 0.040, 0.008), 0.5), click, samples)
    return samples


def energy_whine() -> list[float]:
    """Energy rifle charge: clean whine rising 1.2->4.8 kHz with slight tremolo."""
    n = int(0.76 * SR)
    samples = am(sweep(n, 1200.0, 4800.0, True), 22.0, 0.12)
    envelope = gains_product(env_ar(n, 0.004, 0.05), ramp(n, 0.15, 1.0, 1.4))
    apply_envelope(samples, envelope)
    return samples


def gunshot() -> list[float]:
    """Short dry crack: 40-120 Hz body thump for 30 ms, 2-8 kHz crack, thin tail."""
    rng = HashRng("robot_guard_gunshot_01")
    n = int(0.22 * SR)
    tracks: list[list[float]] = []
    # body thump, 40-120 Hz, 30 ms
    m = int(0.030 * SR)
    body = sine(90.0, m)
    apply_envelope(body, env_ar(m, 0.001, 0.029))
    tracks.append(scaled(body, 1.0))
    # crack, 2-8 kHz
    crack = band_noise(rng, 0.010, 2000.0, 8000.0, 0.005, 2)
    tracks.append(scaled(crack, 2.5))
    # thin tail, band-limited noise decaying over the take
    tail = band_noise(rng, n / SR, 900.0, 3200.0, 0.12, 2)
    apply_envelope(tail, env_ar(n, 0.002, n / SR))
    tracks.append(scaled(tail, 0.10))
    return mix(*tracks)


GENERATORS = (
    ("robot_guard_ranged_windup_01.wav", ranged_windup),
    ("robot_energy_whine_01.wav", energy_whine),
    ("robot_guard_gunshot_01.wav", gunshot),
)


def main() -> int:
    """Build the three takes and write them to `game/audio/combat/`."""
    for name, build in GENERATORS:
        path = os.path.join(OUT_DIR, name)
        save_wav(path, build(), PEAK_DB)
        print(f"wrote {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
