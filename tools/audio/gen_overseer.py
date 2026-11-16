#!/usr/bin/env python3
"""Overseer boss sounds: high/low windup tells, arena gate, phase 2 (stdlib only).

The overseer is the heaviest machine on the first route (`docs/bestiary/overseer.md`),
so its cues read heavier than the standard robot tells while staying pure machine
material — hydraulic hiss, servo whine, steel slams, electrical surge — with no
breath, growl or voice (`docs/design/sound-bible.md`, "Do and don't").

Writes four mono 48 kHz / 16-bit PCM takes with `synth_common.save_wav`
(peak -1.5 dBFS, so the -1.0 dBTP ceiling holds) into `game/audio/combat/`:

    robot_overseer_high_windup_01.wav  high cleaver tell (0.78 s): heavy hydraulic
                                       wind-up, 1.5->3.5 kHz rising hiss over a quiet
                                       60->100 Hz pressure rise, ending in a steel clamp
    robot_overseer_low_windup_01.wav   low sweep tell (0.70 s): sweeping low servo,
                                       3->1.5 kHz whine falling with a drag-scrape texture
    boss_gate_close_01.wav             arena gate slams shut (2.20 s): steel slam,
                                       locking bolts, long low rumble tail
    boss_phase2_01.wav                 overload (1.15 s): rising electrical surge,
                                       a metal crack, a hard low pulse

Run from the repo root:  python3 tools/audio/gen_overseer.py
Check the result:        python3 tools/audio/check_spec.py tell game/audio/combat/robot_overseer_high_windup_01.wav game/audio/combat/robot_overseer_low_windup_01.wav
                         python3 tools/audio/check_spec.py effect game/audio/combat/boss_gate_close_01.wav game/audio/combat/boss_phase2_01.wav

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

from synth_common import SR, bandpass, env_ar, lowpass, mix, noise, save_wav

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


def high_tell() -> list[float]:
    """High cleaver: hydraulic hiss rising 1.5->3.5 kHz over a quiet pressure rise.

    A swept tone gives the priority-1 1-5 kHz energy a servo glide 1.5->3.5 kHz,
    a band-passed hiss bed adds hydraulic weight, a 60->100 Hz pressure rise runs
    underneath (kept quiet so it never steals the tell band), and the windup ends
    in a steel clamp at the very tail."""
    rng = HashRng("robot_overseer_high_windup_01")
    n = int(0.78 * SR)
    hiss = scaled(band_noise(rng, n / SR, 1500.0, 4200.0, None, 2), 0.85)
    core = mix(sweep(n, 1500.0, 3500.0), hiss)
    sub = scaled(sweep(n, 60.0, 100.0), 0.16)
    samples = mix(core, sub)
    apply_envelope(
        samples, gains_product(env_ar(n, 0.02, 0.05), ramp(n, 0.4, 1.0, 1.1))
    )
    clamp = n - int(0.05 * SR)
    place(scaled(band_noise(rng, 0.06, 1800.0, 7000.0, 0.010, 2), 2.4), clamp, samples)
    place(scaled(ring(3200.0, 0.06, 0.012), 0.8), clamp, samples)
    place(scaled(ring(88.0, 0.09, 0.03), 0.6), clamp, samples)
    return samples


def low_tell() -> list[float]:
    """Low sweep: servo whine falling 3->1.5 kHz with a drag-scrape texture.

    Descending pitch (the opposite gesture to the rising high tell) plus a
    slow-AM scrape band reads as the crouched shin-blade dragging in; a faint
    150->80 Hz low servo sits under the in-band energy."""
    rng = HashRng("robot_overseer_low_windup_01")
    n = int(0.70 * SR)
    whine = am(sweep(n, 3000.0, 1500.0), 30.0, 0.16)
    scrape = scaled(am(band_noise(rng, n / SR, 1700.0, 4200.0, None, 2), 9.0, 0.45), 0.6)
    sub = scaled(sweep(n, 150.0, 80.0), 0.13)
    samples = mix(whine, scrape, sub)
    apply_envelope(
        samples, gains_product(env_ar(n, 0.012, 0.06), ramp(n, 0.5, 1.0, 0.8))
    )
    place(scaled(band_noise(rng, 0.09, 1300.0, 3800.0, 0.03, 2), 1.1),
          n - int(0.10 * SR), samples)
    return samples


def gate_close() -> list[float]:
    """Arena gate slams shut: steel slam, locking bolts, long low rumble tail."""
    rng = HashRng("boss_gate_close_01")
    n = int(2.20 * SR)
    out = [0.0] * n
    # main slam on sample 0: low body, mid panel hit, bright crack
    body = ring(58.0, 0.30, 0.11)
    place(scaled(body, 1.2), 0, out)
    place(scaled(ring(180.0, 0.18, 0.06), 0.7), 0, out)
    place(scaled(ring(260.0, 0.15, 0.05), 0.5), 0, out)
    place(scaled(band_noise(rng, 0.03, 1500.0, 8000.0, 0.008, 2), 2.0), 0, out)
    # three locking bolts land in sequence
    for k, (t, freq) in enumerate([(0.20, 520.0), (0.44, 660.0), (0.70, 580.0)]):
        pos = int(t * SR)
        place(scaled(band_noise(rng, 0.02, 900.0, 5200.0, 0.006, 2), 1.6), pos, out)
        place(scaled(ring(freq, 0.12, 0.03), 0.7), pos, out)
        place(scaled(ring(120.0, 0.14, 0.045), 0.6), pos, out)
    # long low rumble tail from the slam
    rumble = lowpass(lowpass([noise(rng) for _ in range(n)], 170.0), 170.0)
    apply_envelope(rumble, gains_product(env_ar(n, 0.05, 1.4), ramp(n, 1.0, 0.0, 0.7)))
    place(scaled(rumble, 0.9), int(0.03 * SR), out)
    return out


def phase2() -> list[float]:
    """Overload: rising electrical surge, a metal crack, a hard low pulse."""
    rng = HashRng("boss_phase2_01")
    n = int(1.15 * SR)
    out = [0.0] * n
    # rising electrical surge for the first ~0.8 s
    sn = int(0.82 * SR)
    surge = am(sweep(sn, 700.0, 6500.0, True), 42.0, 0.24)
    sizzle = scaled(band_noise(rng, sn / SR, 2200.0, 9000.0, None, 2), 0.32)
    surge_track = mix(surge, sizzle)
    apply_envelope(
        surge_track, gains_product(env_ar(sn, 0.01, 0.02), ramp(sn, 0.1, 1.0, 1.7))
    )
    place(surge_track, 0, out)
    # metal crack at the surge peak
    crack = int(0.82 * SR)
    place(scaled(band_noise(rng, 0.05, 1800.0, 9000.0, 0.012, 2), 2.6), crack, out)
    place(scaled(ring(4200.0, 0.12, 0.03), 0.7), crack, out)
    place(scaled(ring(1600.0, 0.08, 0.02), 0.5), crack, out)
    # hard low pulse just after the crack
    pulse = int(0.90 * SR)
    place(scaled(ring(48.0, 0.22, 0.05), 1.4), pulse, out)
    place(scaled(band_noise(rng, 0.02, 800.0, 5000.0, 0.008, 2), 1.2), pulse, out)
    return out


GENERATORS = (
    ("robot_overseer_high_windup_01.wav", high_tell, "tell"),
    ("robot_overseer_low_windup_01.wav", low_tell, "tell"),
    ("boss_gate_close_01.wav", gate_close, "effect"),
    ("boss_phase2_01.wav", phase2, "effect"),
)


def main() -> int:
    """Build the four takes and write them to `game/audio/combat/`."""
    for name, build, _kind in GENERATORS:
        path = os.path.join(OUT_DIR, name)
        save_wav(path, build(), PEAK_DB)
        print(f"wrote {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
