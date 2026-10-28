#!/usr/bin/env python3
"""H27 — Deterministischer Generator fuer drei Verteidigungs-Kontaktsounds.

Lokal prozedurale Synthese, Python-stdlib-only (wave/struct/math/random),
fester Seed -> bitidentische Wiederholung. Keine externen Samples, kein
Netzwerk, keine Paid-Provider.

  block.wav        dumpfer Metall-Impact (Schildtreffer, bestaetigt geblockt)
  parry.wav        knackiger heller Metall-Transient + kurzer tonaler Tail
  guard_break.wav  tiefer gestresster Metall-Crack/Rattle (Guardbruch)

Zielformat: Mono PCM16, 44100 Hz, je 0.12..0.55 s, Peak <= -3 dBFS
(Normalisierung auf -4.5 dBFS), DC-Mittel ~0, glatte Start/End-Envelope.
Pegel bewusst zurueckhaltender als die vorhandenen hit/swing-Dateien
(-0.92 dBFS Peak): -4.5 dBFS Peak, RMS ca. -16..-13 dBFS.

Aufruf:  python3 generate_defense_audio.py --output-dir DIR
Schreibt NUR in DIR (wird angelegt); keine Loesch-/Ueberschreibaktionen
ausserhalb des Ziels. Zusaetzlich preview_all_three_PREVIEW-ONLY.wav
(Vorschausequenz mit kurzer Stille — nur zum Anhoeren, NICHT einbinden).
"""
import argparse
import math
import os
import random
import struct
import wave

SEED = 20261006
RATE = 44100
TARGET_PEAK = 0.597          # -4.5 dBFS (Vertrag: <= -3 dBFS)
FADE_IN = 0.003              # s, glatter Start
TAIL_FADE = 0.035            # s, glatter Endausklang


# ---------------------------------------------------------------- DSP-Bausteine
def _alpha(cutoff_hz: float) -> float:
    return 1.0 - math.exp(-2.0 * math.pi * cutoff_hz / RATE)


def lowpass(xs, cutoff_hz: float) -> list:
    a = _alpha(cutoff_hz)
    y = 0.0
    out = []
    for x in xs:
        y += a * (x - y)
        out.append(y)
    return out


def highpass(xs, cutoff_hz: float) -> list:
    lp = lowpass(xs, cutoff_hz)
    return [x - l for x, l in zip(xs, lp)]


def decay(dur: float, tau: float) -> list:
    n = int(dur * RATE)
    return [math.exp(-i / (tau * RATE)) for i in range(n)]


def tone(dur: float, freq: float, tau: float, phase: float = 0.0) -> list:
    n = int(dur * RATE)
    w = 2.0 * math.pi * freq / RATE
    return [math.sin(w * i + phase) * math.exp(-i / (tau * RATE)) for i in range(n)]


def noise_burst(rng, dur: float, tau: float) -> list:
    n = int(dur * RATE)
    return [(rng.random() * 2.0 - 1.0) * math.exp(-i / (tau * RATE)) for i in range(n)]


def add(dst: list, src: list, at: float = 0.0) -> None:
    i0 = int(at * RATE)
    for i, v in enumerate(src):
        j = i0 + i
        if j < len(dst):
            dst[j] += v


def shape(xs: list, fade_in: float = FADE_IN, fade_out: float = TAIL_FADE) -> list:
    n = len(xs)
    fi = max(1, int(fade_in * RATE))
    fo = max(1, int(fade_out * RATE))
    out = list(xs)
    # DC-Korrektur VOR den Rampen, damit die asymmetrische Ein-/Ausblendung
    # (3 ms in vs. 35-45 ms out) den Mittelwert nicht wieder verlagert.
    out = [v - sum(out) / n for v in out]
    for i in range(min(fi, n)):
        out[i] *= i / fi
    for i in range(min(fo, n)):
        k = n - 1 - i
        out[k] *= i / fo
    # Nachkorrektur: Rest-DC der Rampen entfernen (Ziel: Mittel ~0).
    out = [v - sum(out) / n for v in out]
    return out


def normalize(xs: list, target: float = TARGET_PEAK) -> list:
    pk = max(abs(min(xs)), abs(max(xs))) or 1.0
    g = target / pk
    return [v * g for v in xs]


def write_wav(path: str, xs: list) -> dict:
    pcm = [max(-32767, min(32767, int(round(v * 32767)))) for v in xs]
    raw = struct.pack("<%dh" % len(pcm), *pcm)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(raw)
    pk = max(abs(min(pcm)), abs(max(pcm)))
    rms = math.sqrt(sum(v * v for v in pcm) / len(pcm))
    dc = sum(pcm) / len(pcm)
    db = lambda v: 20.0 * math.log10(v / 32768.0) if v else -120.0
    return {"frames": len(pcm), "dur": len(pcm) / RATE, "peak": pk,
            "peak_db": db(pk), "rms": rms, "rms_db": db(rms), "dc": dc}


# ------------------------------------------------------------------ Synthesen
def synth_block(rng) -> list:
    """Dumpfer Metall-Impact: tiefer Sub-Wumms, tiefe Resonanzmoden (70..428 Hz,
    tau <= 0.07 s), Rauschen stark tiefpassgefiltert (~700 Hz). Kein Oberton-
    Klingeln; klar 'zugedrueckt' im Vergleich zum hellen parry."""
    dur = 0.20
    n = int(dur * RATE)
    x = [0.0] * n
    add(x, tone(dur, 70.0, 0.055))                                  # Sub
    add(x, tone(dur, 147.0, 0.065))
    add(x, tone(dur, 221.0, 0.050))
    add(x, tone(dur, 294.0, 0.040))
    add(x, [0.35 * v for v in tone(dur, 428.0, 0.030)])
    thud = lowpass(noise_burst(rng, dur, 0.045), 700.0)
    add(x, [0.9 * v for v in thud])
    x = lowpass(x, 1600.0)                                          # 'dumpf'
    return shape(x)


def synth_parry(rng) -> list:
    """Knackig heller Anschlag: 6 ms hochpass-Rausch-Transient (~3 kHz),
    dann kirchenglocken-artige INHARMONISCHE Partialpaare (Ratios 1/2.76/5.4/8.9
    ueber 740 Hz) mit kurzem tonalem Tail (max tau 0.10 s, kein Dauereton)."""
    dur = 0.26
    n = int(dur * RATE)
    x = [0.0] * n
    click = highpass(noise_burst(rng, 0.006, 0.0016), 3000.0)
    add(x, [0.9 * v for v in click])
    base = 740.0
    for ratio, amp, tau in [(1.0, 1.0, 0.100), (2.76, 0.55, 0.070),
                            (5.40, 0.30, 0.050), (8.93, 0.14, 0.035)]:
        add(x, [amp * v for v in tone(dur, base * ratio, tau,
                                      rng.random() * 6.283)])
    return shape(x, fade_in=0.002)


def synth_guard_break(rng) -> list:
    """Tiefer Stress-Crack/Ratter: absteigender Creak-Sweep 140->85 Hz mit
    Frequenz-Jitter, Crack-Cluster aus 5 tiepassgefilterten Rausch-Koernern
    fallender Energie (0/30/90/180/300 ms) plus Ratter-Schwanz mit
    exponential wachsenden Abstaenden. Deutlich laenger und 'muellerhafter'
    als block/parry."""
    dur = 0.45
    n = int(dur * RATE)
    x = [0.0] * n
    # Creak: Sweep mit Jitter (random-walk-artige Modulation)
    f = 140.0
    ph = 0.0
    env = []
    for i in range(n):
        f += rng.uniform(-6.0, 4.0)
        f = min(150.0, max(85.0, f))
        ph += 2.0 * math.pi * f / RATE
        t = i / RATE
        a = math.sin(min(1.0, t / 0.12) * math.pi * 0.5) * math.exp(-max(0.0, t - 0.12) / 0.16)
        env.append(0.5 * a * math.sin(ph))
    add(x, env)
    add(x, [0.8 * v for v in tone(dur, 110.0, 0.08)])               # Boom unter erstem Crack
    for at, amp, dur_g, tau, cut in [(0.000, 1.00, 0.030, 0.010, 1500.0),
                                     (0.030, 0.65, 0.018, 0.007, 1800.0),
                                     (0.090, 0.50, 0.014, 0.006, 2200.0),
                                     (0.180, 0.38, 0.012, 0.005, 2600.0),
                                     (0.300, 0.24, 0.010, 0.004, 3000.0)]:
        add(x, [amp * v for v in lowpass(noise_burst(rng, dur_g, tau), cut)], at)
    # Ratter-Schwanz: kleine Koerner, zeitlich auffaecher
    at = 0.21
    gap = 0.022
    while at < dur - 0.02:
        amp = 0.30 * math.exp(-at / 0.14)
        add(x, [amp * v for v in lowpass(noise_burst(rng, 0.006, 0.002), 2400.0)], at)
        gap *= 1.45
        at += gap
    return shape(x, fade_in=0.003, fade_out=0.045)


# ------------------------------------------------------------------------- CLI
def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--output-dir", required=True,
                    help="Zielverzeichnis (wird angelegt); NUR hierher wird geschrieben")
    args = ap.parse_args()
    out = os.path.abspath(args.output_dir)
    os.makedirs(out, exist_ok=True)
    specs = [("block.wav", synth_block),
             ("parry.wav", synth_parry),
             ("guard_break.wav", synth_guard_break)]
    cues = []
    for name, fn in specs:
        rng = random.Random("%d-%s" % (SEED, name))  # String-Seed ist prozessstabil
        xs = normalize(fn(rng))
        m = write_wav(os.path.join(out, name), xs)
        cues.append((name, m))
        print("%-16s dur=%.3fs peak=%.2f dBFS rms=%.2f dBFS dc=%.4f frames=%d" % (
            name, m["dur"], m["peak_db"], m["rms_db"], m["dc"], m["frames"]))
    # Preview-Sequenz (nur zum Anhoeren, nicht als Spiel-Sample verwenden)
    seq = []
    sil = [0.0] * int(0.15 * RATE)
    for name, _ in cues:
        with wave.open(os.path.join(out, name)) as w:
            raw = w.readframes(w.getnframes())
        vals = struct.unpack("<%dh" % (len(raw) // 2), raw)
        seq.extend(v / 32767.0 for v in vals)
        seq.extend(sil)
    pm = write_wav(os.path.join(out, "preview_all_three_PREVIEW-ONLY.wav"), seq)
    print("%-16s dur=%.3fs peak=%.2f dBFS" % ("preview", pm["dur"], pm["peak_db"]))
    print("seed=%d rate=%d format=mono-PCM16 (deterministisch, wiederholbar)" % (SEED, RATE))


if __name__ == "__main__":
    main()
