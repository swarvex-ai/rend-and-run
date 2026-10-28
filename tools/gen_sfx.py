#!/usr/bin/env python3
"""Prozedurale Combat-SFX (stdlib only): swing, hit, die, ow -> game/audio/*.wav
Laufen lassen im Repo-Root; braucht Godot-Headless-Import danach (oder Editorstart)."""
import math, os, random, struct, wave

SR = 44100
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "game", "audio")
os.makedirs(OUT, exist_ok=True)
random.seed(666)

def save(name, samples):
    peak = max(abs(s) for s in samples) or 1.0
    data = b"".join(struct.pack("<h", int(max(-1, min(1, s / peak)) * 32767 * 0.9)) for s in samples)
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(data)
    print(name, len(samples) / SR, "s")

def noise():
    return random.uniform(-1, 1)

# SWING: Noise-Wumm der von hoch nach tief fegt (Zischen)
n = int(SR * 0.18)
prev = 0.0
samples = []
for i in range(n):
    t = i / n
    env = math.sin(math.pi * t) ** 0.6 * (1.0 - t * 0.3)
    x = noise()
    x = 0.35 * x + 0.65 * prev
    prev = x
    hp = x - prev * (0.85 - 0.6 * t)
    f = 900 - 700 * t
    tone = math.sin(2 * math.pi * f * i / SR) * 0.25
    samples.append((hp * 0.9 + tone) * env)
save("swing", samples)

# HIT: tiefer Dröhn-Knarz (Wumme!)
n = int(SR * 0.3)
samples = []
lp = 0.0
for i in range(n):
    t = i / SR
    env = math.exp(-t * 14)
    thump = math.sin(2 * math.pi * (70 - 30 * min(t * 4, 1)) * t) * math.exp(-t * 9)
    crunch = (noise() * math.exp(-t * 30)) * 0.7
    lp = lp * 0.6 + crunch * 0.4
    samples.append((thump * 1.4 + lp) * env)
save("hit", samples)

# DIE: laengeres Zerplatzen + fallender Schock
n = int(SR * 0.5)
samples = []
for i in range(n):
    t = i / SR
    env = math.exp(-t * 7)
    thump = math.sin(2 * math.pi * (55 - 25 * min(t * 3, 1)) * t) * math.exp(-t * 5)
    splat = noise() * math.exp(-t * 12) * (0.5 + 0.5 * math.sin(2 * math.pi * 30 * t))
    samples.append((thump * 1.5 + splat * 0.8) * env)
save("die", samples)

# OW: Spieler-Treffer, kurz und boesartig
n = int(SR * 0.22)
samples = []
for i in range(n):
    t = i / SR
    env = math.exp(-t * 16)
    tone = math.sin(2 * math.pi * (140 - 60 * t) * t)
    grit = noise() * math.exp(-t * 22) * 0.5
    samples.append((tone * 0.9 + grit) * env)
save("ow", samples)
