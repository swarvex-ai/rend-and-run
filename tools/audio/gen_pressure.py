#!/usr/bin/env python3
"""Pressure-task sounds: door announce, countdown tick, failure burst (stdlib only).

The pressure task (S16, `docs/milestone-1.md`) is a quick-maths door just after
the relay checkpoint, announced by sound and light and ending in an explosion if
Rend fails. These are the three machine cues from the sound bible's M1 event list
(`docs/design/sound-bible.md`): "Pressure door announce" (2 m before the door),
"Pressure countdown" (a 90 ms tick every whole second) and "Pressure failure"
(countdown reaches 0). The spoken "Ten seconds" is a separate task; nothing here
is wired up yet.

Writes three mono 48 kHz / 16-bit PCM takes with `synth_common.save_wav`
(peak -1.5 dBFS, so the -1.0 dBTP ceiling holds):

    game/audio/combat/pressure_announce_01.wav  effect: two-note rising electronic
                                                warning chirp (680 -> ~1000 Hz,
                                                gated, AM) plus a relay clack;
                                                urgent, distinct from the siren (0.90 s)
    game/audio/ui/pressure_tick_01.wav          ui: dry clock-like tick at ~2.5 kHz,
                                                short decay, clean and repeatable (0.090 s)
    game/audio/combat/pressure_fail_01.wav      effect: falling error buzz into a
                                                charge, then a burst layered body
                                                40-120 Hz / panel 120-600 Hz / debris
                                                2-8 kHz (1.40 s)

Run from the repo root:  python3 tools/audio/gen_pressure.py
Check the result:        python3 tools/audio/check_spec.py effect game/audio/combat/pressure_announce_01.wav game/audio/combat/pressure_fail_01.wav
                         python3 tools/audio/check_spec.py ui game/audio/ui/pressure_tick_01.wav

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

_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT_COMBAT = os.path.join(_ROOT, "game", "audio", "combat")
OUT_UI = os.path.join(_ROOT, "game", "audio", "ui")
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
    """`n` gains from `start` to `end` with an `x ** power` easing."""
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
    enough edge; `tau_s` of None keeps the burst level steady (bed layers)."""
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


def announce() -> list[float]:
    """Two-note rising chirp plus a relay clack: the door announcing itself.

    Two gated electronic notes a rising minor-third apart (680 Hz then a
    slight upward glide to ~1000 Hz) with a harmonic and 36 Hz AM give an
    urgent warning that is clearly not the continuous escape-siren wail; a
    mechanical relay clack (bright latch plus a low 150 Hz thunk) answers
    after the chirp and again, softer, as the latch releases."""
    rng = HashRng("pressure_announce_01")
    n = int(0.90 * SR)
    out = [0.0] * n

    def chirp(start: float, dur: float, f0: float, f1: float, gain: float) -> None:
        m = int(dur * SR)
        seg = mix(sweep(m, f0, f1), scaled(sweep(m, 2.0 * f0, 2.0 * f1), 0.25))
        apply_envelope(am(seg, 36.0, 0.18), env_ar(m, 0.006, 0.05))
        place(scaled(seg, gain), int(start * SR), out)

    chirp(0.03, 0.14, 680.0, 690.0, 0.85)
    chirp(0.26, 0.20, 900.0, 1010.0, 1.0)

    latch = int(0.55 * SR)
    place(scaled(band_noise(rng, 0.02, 800.0, 6000.0, 0.006, 2), 2.2), latch, out)
    place(scaled(ring(150.0, 0.05, 0.02), 0.8), latch, out)
    place(scaled(ring(2200.0, 0.03, 0.006), 0.5), latch, out)
    release = int(0.78 * SR)
    place(scaled(band_noise(rng, 0.012, 900.0, 5200.0, 0.004, 2), 1.3), release, out)
    place(scaled(ring(180.0, 0.04, 0.015), 0.5), release, out)
    return out


def tick() -> list[float]:
    """Dry clock tick at ~2.5 kHz: a mechanical click into a short decay.

    A few milliseconds of bright high-passed noise form the escapement click,
    a 2.5 kHz tone (with a touch of 5 kHz for metal) rings out and decays with
    a 6 ms time constant, so the sound is done by ~50 ms and leaves clean
    silence inside the 90 ms window - it stays crisp when repeated every second."""
    rng = HashRng("pressure_tick_01")
    n = int(0.090 * SR)
    out = [0.0] * n
    place(scaled(band_noise(rng, 0.003, 1800.0, 9000.0, 0.0008, 2), 1.5), 0, out)
    place(mix(ring(2500.0, 0.05, 0.006), scaled(ring(5000.0, 0.04, 0.004), 0.4)), 0, out)
    return out


def fail_burst() -> list[float]:
    """Falling error buzz into a charge, then the failure burst.

    A descending buzzy tone (880->190 Hz with octave and fifth-harmonic grit,
    24 Hz AM) reads as the countdown going wrong; a rising electrical charge
    builds for ~0.3 s; the burst at 0.78 s layers a 40-120 Hz body, a 120-600
    Hz panel hit and a 2-8 kHz debris crack and tail (sound bible pillar 2)."""
    rng = HashRng("pressure_fail_01")
    n = int(1.40 * SR)
    out = [0.0] * n

    # falling error buzz 0 -> 0.45 s
    an = int(0.45 * SR)
    buzz = mix(
        sweep(an, 880.0, 190.0),
        scaled(sweep(an, 1760.0, 380.0), 0.30),
        scaled(sweep(an, 2640.0, 570.0), 0.12),
    )
    apply_envelope(
        am(buzz, 24.0, 0.5),
        gains_product(env_ar(an, 0.005, 0.03), ramp(an, 1.0, 0.7, 1.0)),
    )
    place(buzz, 0, out)

    # rising electrical charge 0.45 -> 0.78 s
    bs = int(0.45 * SR)
    bn = int(0.33 * SR)
    charge = am(sweep(bn, 320.0, 3200.0, True), 50.0, 0.25)
    apply_envelope(charge, gains_product(env_ar(bn, 0.02, 0.01), ramp(bn, 0.15, 1.0, 1.8)))
    place(scaled(charge, 0.7), bs, out)
    charge_hiss = band_noise(rng, bn / SR, 2500.0, 8000.0, None, 2)
    apply_envelope(charge_hiss, ramp(bn, 0.02, 1.0, 2.0))
    place(scaled(charge_hiss, 0.4), bs, out)

    # burst at 0.78 s: body 40-120 Hz, panel 120-600 Hz, debris 2-8 kHz
    hit = int(0.78 * SR)
    place(scaled(ring(52.0, 0.30, 0.10), 1.4), hit, out)
    place(scaled(ring(90.0, 0.22, 0.07), 1.0), hit, out)
    place(scaled(ring(110.0, 0.16, 0.05), 0.7), hit, out)
    place(scaled(ring(46.0, 0.35, 0.12), 1.2), hit, out)
    place(scaled(ring(200.0, 0.16, 0.05), 0.9), hit, out)
    place(scaled(ring(340.0, 0.13, 0.04), 0.7), hit, out)
    place(scaled(ring(480.0, 0.10, 0.03), 0.55), hit, out)
    place(scaled(band_noise(rng, 0.08, 120.0, 600.0, 0.03, 2), 1.1), hit, out)
    place(scaled(band_noise(rng, 0.03, 2000.0, 8000.0, 0.010, 2), 2.2), hit, out)
    debris = band_noise(rng, 0.45, 2000.0, 8000.0, 0.16, 2)
    apply_envelope(
        debris,
        gains_product(env_ar(len(debris), 0.002, 0.30), ramp(len(debris), 1.0, 0.0, 0.6)),
    )
    place(scaled(debris, 0.6), hit + int(0.01 * SR), out)
    return out


GENERATORS = (
    (OUT_COMBAT, "pressure_announce_01.wav", announce),
    (OUT_UI, "pressure_tick_01.wav", tick),
    (OUT_COMBAT, "pressure_fail_01.wav", fail_burst),
)


def main() -> int:
    """Build the three takes and write them under `game/audio/`."""
    for out_dir, name, build in GENERATORS:
        path = os.path.join(out_dir, name)
        save_wav(path, build(), PEAK_DB)
        print(f"wrote {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
