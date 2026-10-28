#!/usr/bin/env python3
"""H35 — Deterministischer Generator fuer Metall-Bewegungs-SFX (Bodenkontakt).

Lokal prozedurale Synthese, Python-stdlib-only (wave/struct/math/random),
fester Seed -> bitidentische Wiederholung. Keine Samples, kein Netzwerk,
keine bezahlten Provider. Codex uebernimmt Trigger/Playback (Laufen/Landen);
dieses Skript beruehrt KEINE Gameplay-Dateien.

  footstep_metal_a.wav  Sohlen-Kontakt, fokusiert/kurz (~0.09 s):
                        gedaempfter Vorusschlag + kurzer Ballen-Ton.
  footstep_metal_b.wav  Sohlen-Kontakt, breiter/rauer (~0.14 s):
                        mehr Schleif-Anteil, andere Resonanzpaarung.
  land_metal.wav        schwerere Landung (~0.26 s): breiter Impact-Kern,
                        tieferer Koerper, schneller metallischer Anschlag.

Bewusst KEINE Laser-Beeps, keine tonalen Noten, kein langes Nachklingen,
kein fetter Bass. a/b unterscheiden sich in Timing und Spektralmischung,
nicht nur in der Tonhoehe.

Zielformat: Mono PCM16, 44100 Hz, Peak <= -6 dBFS (Normalisierung -6.2 dBFS),
DC-Mittel ~0, geglaetteter Einsatz und exponentieller Ausklang.

Aufruf:  python3 generate_traversal_audio.py --output-dir DIR
Schreibt drei SFX + preview.wav (A, Stille, B, Stille, Landung — NUR
Vorschau, nicht einbinden) in DIR (wird angelegt).
"""
import argparse
import math
import os
import random
import struct
import wave

SEED = 20261006
RATE = 44100
TARGET_PEAK = 0.4898          # -6.2 dBFS (Vertrag: <= -6 dBFS)
SILENCE = 0.25                # s Pausen in der Vorschausequenz


# ---------------------------------------------------------------- DSP-Bausteine
def _alpha(cutoff_hz: float) -> float:
    return 1.0 - math.exp(-2.0 * math.pi * cutoff_hz / RATE)


def lowpass(samples, cutoff_hz):
    a = _alpha(cutoff_hz)
    y = 0.0
    out = []
    for x in samples:
        y += a * (x - y)
        out.append(y)
    return out


def highpass(samples, cutoff_hz):
    a = _alpha(cutoff_hz)
    prev_x = 0.0
    prev_y = 0.0
    out = []
    for x in samples:
        prev_y = a * (prev_y + x - prev_x)
        prev_x = x
        out.append(prev_y)
    return out


def resonator(samples, freq_hz, decay_s, q_cap=0.999):
    """2-Pol-Klangglied; Amplituene ~ rho^n mit rho = exp(-pi/(decay*RATE)),
    klingt also nach ca. decay_s auf ~4 % ab — kurzer metallischer Kontakt,
    kein Daueroton."""
    f = min(max(freq_hz, 20.0), RATE * 0.45)
    w = 2.0 * math.pi * f / RATE
    rho = min(math.exp(-math.pi / max(decay_s * RATE, 1e-6)), q_cap)
    y1 = y2 = 0.0
    out = []
    for x in samples:
        y = x + rho * (2.0 * math.cos(w) * y1) - rho * rho * y2
        y1, y2 = y, y1
        out.append(y)
    return out


def noise_burst(rng, dur_s, low_hz=None, high_hz=None):
    n = int(dur_s * RATE)
    s = [rng.uniform(-1.0, 1.0) for _ in range(n)]
    if low_hz:
        s = lowpass(s, low_hz)
    if high_hz:
        s = highpass(s, high_hz)
    return s


def env_exp(n, attack_s, tau_s):
    out = []
    na = max(1, int(attack_s * RATE))
    for i in range(n):
        e = 1.0 - math.exp(-i / max(na * 0.35, 1.0))
        e *= math.exp(-i / max(tau_s * RATE, 1.0))
        out.append(e)
    return out


def mix(dst, src, gain=1.0, offset=0):
    if offset > 0:
        src = [0.0] * offset + src
    if len(src) > len(dst):
        dst += [0.0] * (len(src) - len(dst))
    for i, v in enumerate(src):
        dst[i] += v * gain
    return dst


def normalize_dc_smooth(samples, peak=TARGET_PEAK):
    m = sum(samples) / len(samples)
    samples = [s - m for s in samples]                      # DC ~ 0
    p = max(max(samples), -min(samples))
    if p > 1e-9:
        g = peak / p
        samples = [s * g for s in samples]
    # harter Endausklang -> kurze cosine-fade
    f = int(0.006 * RATE)
    for i in range(min(f, len(samples))):
        samples[i] *= 0.5 - 0.5 * math.cos(math.pi * i / f)
    j = len(samples)
    for i in range(min(f, len(samples))):
        samples[j - 1 - i] *= 0.5 - 0.5 * math.cos(math.pi * i / f)
    return samples


def write_wav(path, samples):
    frames = b"".join(
        struct.pack("<h", max(-32767, min(32767, int(round(s * 32767)))))
        for s in samples)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(frames)


# ---------------------------------------------------------------- Step-Kerne
def step_a(rng):
    """Fokusierter Vorusschlag: kurzerhell + gedaempfter Kern, ~0.09 s."""
    n = int(0.09 * RATE)
    click = highpass(noise_burst(rng, 0.012), 1800.0)
    click = [v * math.exp(-i / (0.004 * RATE)) for i, v in enumerate(click)]
    body = resonator([v * math.exp(-i / (0.02 * RATE)) for i, v in
                      enumerate(noise_burst(rng, 0.05, low_hz=900.0))],
                     240.0, decay_s=0.028)
    s = [0.0] * n
    s = mix(s, click, gain=0.55)
    s = mix(s, body, gain=1.0)
    return s


def step_b(rng):
    """Rauer Schleiftritt: breiteres Zeitfenster, Mittelband + Schaben."""
    dur = 0.14
    n = int(dur * RATE)
    scuff = noise_burst(rng, 0.09, low_hz=1400.0)
    scuff = highpass(scuff, 500.0)
    scuff = [v * (1.0 - i / len(scuff)) ** 1.6 for i, v in enumerate(scuff)]
    body = resonator([v * math.exp(-i / (0.045 * RATE)) for i, v in
                      enumerate(noise_burst(rng, 0.08, low_hz=650.0))],
                     165.0, decay_s=0.05)
    s = [0.0] * n
    s = mix(s, scuff, gain=0.5, offset=int(0.012 * RATE))
    s = mix(s, body, gain=1.0)
    return s


def land(rng):
    """Schwere Landung: breiter Impact-Kern + tiefer, schneller Anschlag."""
    dur = 0.26
    n = int(dur * RATE)
    impact = noise_burst(rng, 0.05, low_hz=2600.0)
    impact = [v * math.exp(-i / (0.012 * RATE)) for i, v in enumerate(impact)]
    thump = lowpass(noise_burst(rng, 0.12, low_hz=320.0), 300.0)
    thump = [v * math.exp(-i / (0.05 * RATE)) for i, v in enumerate(thump)]
    ring = resonator([v * math.exp(-i / (0.06 * RATE)) for i, v in
                      enumerate(noise_burst(rng, 0.1, low_hz=800.0))],
                     210.0, decay_s=0.055)
    s = [0.0] * n
    s = mix(s, impact, gain=0.5)
    s = mix(s, thump, gain=1.0)
    s = mix(s, ring, gain=0.55, offset=int(0.004 * RATE))
    return s


def main():
    ap = argparse.ArgumentParser(description="H35 Metall-Bewegungs-SFX")
    ap.add_argument("--output-dir", required=True)
    args = ap.parse_args()
    os.makedirs(args.output_dir, exist_ok=True)

    rng = random.Random(SEED)
    files = {
        "footstep_metal_a.wav": step_a(rng),
        "footstep_metal_b.wav": step_b(rng),
        "land_metal.wav": land(rng),
    }
    norm = {name: normalize_dc_smooth(s) for name, s in files.items()}
    for name, s in norm.items():
        write_wav(os.path.join(args.output_dir, name), s)

    # Vorschausequenz: A, Stille, B, Stille, Landung (NICHT einbinden)
    sil = [0.0] * int(SILENCE * RATE)
    preview = []
    for part in (norm["footstep_metal_a.wav"], sil, norm["footstep_metal_b.wav"],
                 sil, norm["land_metal.wav"]):
        preview += part
    p = max(max(preview), -min(preview))
    if p > 1e-9:
        g = 0.891 / p                      # -1 dBFS nur fuer die Vorschau
        preview = [v * g for v in preview]
    write_wav(os.path.join(args.output_dir, "preview.wav"), preview)

    for name, s in norm.items():
        rms = math.sqrt(sum(v * v for v in s) / len(s))
        peak = max(max(s), -min(s))
        print(f"{name}: {len(s)/RATE:.3f}s peak={20*math.log10(peak):+.1f}dBFS "
              f"rms={20*math.log10(rms):+.1f}dBFS")
    print("preview.wav geschrieben (VORSCHAU, nicht einbinden)")


if __name__ == "__main__":
    main()
