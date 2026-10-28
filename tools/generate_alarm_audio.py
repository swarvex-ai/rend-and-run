#!/usr/bin/env python3
"""Synthesises the factory alarm siren (seamless loop) and the robots' radio chirp.

Pure stdlib (wave + math). Output: game/audio/alarm_siren.wav, game/audio/radio_chirp.wav.
"""
import math, struct, wave, random, os

RATE = 44100
OUT = os.path.join(os.path.dirname(__file__), "..", "game", "audio")

def write(name, samples):
    path = os.path.join(OUT, name)
    with wave.open(path, "w") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, s)) * 32000)) for s in samples))
    print("wrote", path, len(samples) / RATE, "s")

def siren(seconds=2.4):
    # Two-tone industrial wail: pitch glides 520 -> 760 Hz and back once per loop,
    # square-ish timbre softened by a low-pass, so the loop point is seamless.
    out, phase, lp = [], 0.0, 0.0
    n = int(RATE * seconds)
    for i in range(n):
        t = i / n
        f = 520 + 240 * (0.5 - 0.5 * math.cos(2 * math.pi * t))
        phase += 2 * math.pi * f / RATE
        raw = math.tanh(3.0 * math.sin(phase)) * 0.6 + 0.25 * math.sin(2 * phase)
        lp += (raw - lp) * 0.18
        out.append(lp * 0.55)
    return out

def chirp():
    # Short digital radio burst: two rising blips with a little static.
    out = []
    for blip, (f0, f1) in enumerate([(900, 1400), (1200, 1900)]):
        n = int(RATE * 0.07)
        phase = 0.0
        for i in range(n):
            t = i / n
            phase += 2 * math.pi * (f0 + (f1 - f0) * t) / RATE
            env = math.sin(math.pi * t) ** 0.5
            out.append((math.copysign(1, math.sin(phase)) * 0.35 + random.uniform(-0.12, 0.12)) * env * 0.5)
        out += [random.uniform(-0.03, 0.03) for _ in range(int(RATE * 0.03))]
    return out

random.seed(7)
write("alarm_siren.wav", siren())
write("radio_chirp.wav", chirp())
