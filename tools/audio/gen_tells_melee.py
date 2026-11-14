#!/usr/bin/env python3
"""Melee windup tells for guard, shield bearer, sentinel and dog (stdlib only).

Priority-1 attack tells (`docs/design/sound-bible.md`, pillar 1 "Read before
hit"): every melee robot gets a sound that starts with the windup, lasts
500-800 ms and keeps its energy in 1-5 kHz. Pure machine material — servo
whine, hydraulics, relay and ratchet clicks, electrical charge — no breath,
growl or voice (sound bible "Do and don't").

Writes four mono 48 kHz / 16-bit PCM takes with `synth_common.save_wav`
(peak -1.5 dBFS, so the -1.0 dBTP ceiling holds) into `game/audio/combat/`:

    robot_guard_windup_01.wav      light humanoid: servo whine 2->4 kHz glide
                                   plus one relay click at 60 ms (0.58 s)
    robot_shield_windup_01.wav     shield bearer: hydraulic hiss 1-3 kHz,
                                   clamp click at the start, shield-edge ring
                                   1.5-3 kHz at the end (0.64 s)
    robot_sentinel_windup_01.wav   wall alcove: cold electrical charge-up,
                                   sine 1.5->4.5 kHz with small flutter (0.70 s)
    robot_dog_windup_01.wav        four-legged: ratcheting servo clicks rising
                                   to ~12/s over a 1-3 kHz whine (0.56 s)

Run from the repo root:  python3 tools/audio/gen_tells_melee.py
Check the result:        python3 tools/audio/check_spec.py tell game/audio/combat/robot_*_windup_01.wav

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

from synth_common import SR, bandpass, env_ar, mix, noise, save_wav

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


def guard_tell() -> list[float]:
    """Light humanoid: two rising servo partials, one relay click at 60 ms.

    Thin tonal glide 2-4 kHz over a faint 1-2 kHz gear partial, quick attack,
    steady rise, hard stop: a baton shoulder winding up."""
    rng = HashRng("robot_guard_windup_01")
    n = int(0.58 * SR)
    samples = mix(sweep(n, 2000.0, 4000.0), scaled(sweep(n, 1000.0, 2000.0), 0.32))
    apply_envelope(
        samples, gains_product(env_ar(n, 0.005, 0.06), ramp(n, 0.55, 1.0, 1.0))
    )
    click = int(0.06 * SR)
    place(scaled(band_noise(rng, 0.009, 1300.0, 5200.0, 0.0022, 2), 1.8), click,
          samples)
    place(scaled(ring(2800.0, 0.030, 0.006), 0.5), click, samples)
    return samples


def shield_tell() -> list[float]:
    """Shield bearer: hydraulic hiss swell, clamp click at the start, ring at the end.

    Broadband but band-limited hiss (1-3 kHz) instead of a tone, a heavier
    metal clamp on sample 0 and the shield edge ringing 1.5-3 kHz as the arm
    commits."""
    rng = HashRng("robot_shield_windup_01")
    n = int(0.64 * SR)
    samples = scaled(band_noise(rng, n / SR, 1000.0, 3200.0, None, 2), 2.4)
    apply_envelope(
        samples, gains_product(env_ar(n, 0.02, 0.08), ramp(n, 0.4, 1.0, 0.8))
    )
    place(scaled(band_noise(rng, 0.014, 800.0, 6000.0, 0.003, 2), 1.2), 0, samples)
    place(scaled(ring(170.0, 0.035, 0.009), 0.3), 0, samples)
    edge = mix(ring(1800.0, 0.220, 0.080), scaled(ring(2650.0, 0.220, 0.060), 0.7))
    place(scaled(edge, 0.3), int(0.44 * SR), samples)
    return samples


def sentinel_tell() -> list[float]:
    """Alcove sentinel: cold electrical charge-up 1.5-4.5 kHz with small flutter.

    Single pure tone with an exponential pitch travel and a long crescendo,
    amplitude flutter at 24 Hz and 83 Hz plus a whisper of high discharge
    hiss: the ring charging before the punch."""
    rng = HashRng("robot_sentinel_windup_01")
    n = int(0.70 * SR)
    samples = am(am(sweep(n, 1500.0, 4500.0, True), 24.0, 0.24), 83.0, 0.09)
    envelope = gains_product(env_ar(n, 0.004, 0.03), ramp(n, 0.16, 1.0, 1.6))
    apply_envelope(samples, envelope)
    hiss = gains_product(
        scaled(band_noise(rng, n / SR, 2600.0, 5200.0, None, 2), 0.16), envelope
    )
    place(hiss, 0, samples)
    return samples


def dog_tell() -> list[float]:
    """Four-legged: ratcheting clicks over a 1-3 kHz whine.

    A click every ~88 ms at first, gaps shrinking by 5 % per step and each
    click pitched a fourth higher: a paw-and-back-arm ratchet winding tighter
    as the lunge approaches."""
    rng = HashRng("robot_dog_windup_01")
    n = int(0.56 * SR)
    samples = scaled(am(sweep(n, 1000.0, 3000.0), 12.0, 0.1), 0.5)
    apply_envelope(
        samples, gains_product(env_ar(n, 0.01, 0.05), ramp(n, 0.6, 1.0, 0.7))
    )
    offset = int(0.02 * SR)
    gap = 0.088
    for k in range(12):
        if offset >= n - int(0.03 * SR):
            break
        place(scaled(band_noise(rng, 0.004, 2200.0, 6000.0, 0.0016, 2),
                     1.6 + 0.12 * k), offset, samples)
        place(scaled(ring(2500.0 + 400.0 * k, 0.020, 0.0045), 0.55), offset, samples)
        offset += int(gap * SR)
        gap *= 0.95
    return samples


GENERATORS = (
    ("robot_guard_windup_01.wav", guard_tell),
    ("robot_shield_windup_01.wav", shield_tell),
    ("robot_sentinel_windup_01.wav", sentinel_tell),
    ("robot_dog_windup_01.wav", dog_tell),
)


def main() -> int:
    """Build the four takes and write them to `game/audio/combat/`."""
    for name, build in GENERATORS:
        path = os.path.join(OUT_DIR, name)
        save_wav(path, build(), PEAK_DB)
        print(f"wrote {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
