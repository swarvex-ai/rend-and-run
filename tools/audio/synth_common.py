#!/usr/bin/env python3
"""Shared synthesis toolkit for all E12 sound scripts (stdlib only).

Every synthesised sound batch builds its waveform with these helpers and
writes it with `save_wav`: mono, PCM 16-bit, 48,000 Hz, sample peak
normalised to a target in dBFS, so the sound bible's -1.0 dBTP ceiling is
met by construction (`docs/design/sound-bible.md`, Technical specs).
`seeded()` returns a deterministic RNG for a name, so the same script run
twice yields identical noise; never touch the global random state. The
filters are cheap one-pole stages, enough for game SFX without numpy.

Usage from a sound generator:
    from synth_common import SR, save_wav, seeded, noise, sine, env_ar, mix
    rng = seeded("guard_tell_01")
    tone = sine(2400.0, int(0.6 * SR))
    save_wav("build/guard_tell_01.wav", mix(tone, [...]))
"""
import math
import os
import random
import struct
import wave

SR = 48000


def save_wav(path: str, samples: list[float], peak_db: float = -1.5) -> None:
    """Normalise the sample peak to `peak_db` dBFS and write a mono WAV.

    Format is PCM 16-bit at `SR` (48,000 Hz); the folder of `path` is
    created when missing. Silence (no samples above zero) is written as is."""
    folder = os.path.dirname(path)
    if folder:
        os.makedirs(folder, exist_ok=True)
    peak = max((abs(s) for s in samples), default=0.0)
    if peak > 0.0:
        gain = 10.0 ** (peak_db / 20.0) / peak
        samples = [s * gain for s in samples]
    frames = b"".join(
        struct.pack("<h", int(max(-1.0, min(1.0, s)) * 32767)) for s in samples
    )
    with wave.open(path, "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(SR)
        wav.writeframes(frames)


def seeded(name: str) -> random.Random:
    """Deterministic RNG for a string: same name, same noise, every run."""
    return random.Random(name)


def noise(rng: random.Random) -> float:
    """One white-noise sample in [-1, 1] from the given RNG."""
    return rng.uniform(-1.0, 1.0)


def env_ar(n: int, attack: float, release: float) -> list[float]:
    """`n` gains: linear attack over `attack` s, sustain, linear release.

    Attack and release are in seconds; both are clamped so they fit into
    `n` samples, release occupying the last `release` seconds."""
    attack_n = max(0, min(int(attack * SR), n))
    release_n = max(0, min(int(release * SR), n - attack_n))
    gains: list[float] = []
    for i in range(n):
        if i < attack_n:
            gains.append(i / attack_n)
        elif release_n > 0 and i >= n - release_n:
            gains.append(max(0.0, (n - i) / release_n))
        else:
            gains.append(1.0)
    return gains


def lowpass(samples: list[float], cutoff_hz: float) -> list[float]:
    """One-pole low-pass filter with -3 dB point at `cutoff_hz`."""
    alpha = 1.0 - math.exp(-2.0 * math.pi * cutoff_hz / SR)
    out: list[float] = []
    y = 0.0
    for x in samples:
        y += alpha * (x - y)
        out.append(y)
    return out


def highpass(samples: list[float], cutoff_hz: float) -> list[float]:
    """One-pole high-pass: the signal minus its one-pole low-pass."""
    lp = lowpass(samples, cutoff_hz)
    return [x - y for x, y in zip(samples, lp)]


def bandpass(samples: list[float], lo_hz: float, hi_hz: float) -> list[float]:
    """One-pole band-pass: high-pass at `lo_hz` into low-pass at `hi_hz`."""
    return lowpass(highpass(samples, lo_hz), hi_hz)


def sine(freq_hz: float, n: int, phase: float = 0.0) -> list[float]:
    """`n` samples of a sine at `freq_hz`, starting at `phase` radians."""
    step = 2.0 * math.pi * freq_hz / SR
    return [math.sin(step * i + phase) for i in range(n)]


def mix(*tracks: list[float]) -> list[float]:
    """Sum tracks sample-wise, shorter ones padded with silence."""
    n = max((len(t) for t in tracks), default=0)
    out = [0.0] * n
    for track in tracks:
        for i, s in enumerate(track):
            out[i] += s
    return out
