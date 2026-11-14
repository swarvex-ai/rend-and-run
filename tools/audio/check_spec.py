#!/usr/bin/env python3
"""Sound-bible spec checker for synthesised sounds (stdlib only).

Checks one WAV against `docs/design/sound-bible.md` (Technical specs plus
the attack-tell rules): uncompressed PCM 16-bit, 48,000 Hz, mono, sample
peak at or below -1.0 dBFS, a duration window per sound kind and, for
priority-1 tells, at least 60 % of the signal energy in the 1-5 kHz band
(iterative radix-2 FFT over the whole zero-padded file) and no more than
20 ms of leading silence.

Use as a script:
    python3 tools/audio/check_spec.py tell file1.wav file2.wav
    python3 tools/audio/check_spec.py --self-test
or import `check_file(path, kind)` from a sound generator and treat a
non-empty problem list as a build failure.
"""
import argparse
import math
import os
import struct
import tempfile
import wave

SR = 48000
PEAK_MAX_DBFS = -1.0
# Duration windows in seconds (sound bible, Technical specs); heavy impacts
# are a 0.12-0.25 s body plus a debris tail, capped at 0.85 s total.
DURATION_LIMITS_S: dict[str, tuple[float, float]] = {
    "tell": (0.50, 0.80),
    "impact_light": (0.03, 0.08),
    "impact_heavy": (0.12, 0.85),
    "ui": (0.04, 0.12),
    "effect": (0.03, 3.0),
    "loop": (4.0, 150.0),
}
TELL_BAND_HZ: tuple[float, float] = (1000.0, 5000.0)
TELL_BAND_MIN_RATIO = 0.60
TELL_MAX_SILENCE_S = 0.020
SILENCE_FLOOR = 0.01  # -40 dBFS: a sample below this counts as silent


def check_file(path: str, kind: str) -> list[str]:
    """Return the sound-bible problems of one file; an empty list means pass."""
    if kind not in DURATION_LIMITS_S:
        return [
            f"unknown kind '{kind}', expected one of: "
            + ", ".join(sorted(DURATION_LIMITS_S))
        ]
    try:
        with wave.open(path, "rb") as wav:
            channels = wav.getnchannels()
            sampwidth = wav.getsampwidth()
            rate = wav.getframerate()
            comptype = wav.getcomptype()
            raw = wav.readframes(wav.getnframes())
    except Exception as exc:
        return [f"not a readable WAV file: {exc}"]
    problems: list[str] = []
    if comptype != "NONE":
        problems.append(f"compressed WAV ({comptype}): PCM 16-bit required")
    if sampwidth != 2:
        problems.append(f"{sampwidth * 8}-bit samples: PCM 16-bit required")
    if channels != 1:
        problems.append(f"{channels} channels: mono required")
    if problems:
        return problems
    if rate != SR:
        return [f"sample rate {rate} Hz: {SR} Hz required"]
    raw = raw[: len(raw) // 2 * 2]
    if not raw:
        return ["file contains no samples"]
    samples = [s / 32768.0 for s in struct.unpack("<%dh" % (len(raw) // 2), raw)]
    peak = max(abs(s) for s in samples)
    if peak <= 0.0:
        return ["file is completely silent"]
    peak_db = 20.0 * math.log10(peak)
    if peak_db > PEAK_MAX_DBFS + 1e-9:
        problems.append(
            f"sample peak {peak_db:.2f} dBFS exceeds {PEAK_MAX_DBFS:.1f} dBFS"
        )
    duration = len(samples) / rate
    low, high = DURATION_LIMITS_S[kind]
    if duration < low or duration > high:
        problems.append(
            f"duration {duration:.3f} s outside {low:.2f}-{high:.2f} s for {kind}"
        )
    if kind == "tell":
        first = len(samples)
        for i, s in enumerate(samples):
            if abs(s) >= SILENCE_FLOOR:
                first = i
                break
        if first / rate > TELL_MAX_SILENCE_S:
            problems.append(
                f"starts with {1000.0 * first / rate:.0f} ms of silence, "
                f"max {1000.0 * TELL_MAX_SILENCE_S:.0f} ms"
            )
        ratio = _band_energy_ratio(samples, TELL_BAND_HZ[0], TELL_BAND_HZ[1])
        if ratio < TELL_BAND_MIN_RATIO:
            problems.append(
                f"only {100.0 * ratio:.0f}% of energy in "
                f"{TELL_BAND_HZ[0]:.0f}-{TELL_BAND_HZ[1]:.0f} Hz band, "
                f"need at least {100.0 * TELL_BAND_MIN_RATIO:.0f}%"
            )
    return problems


def _fft(re: list[float], im: list[float]) -> None:
    """In-place iterative radix-2 Cooley-Tukey FFT of power-of-two lists."""
    n = len(re)
    j = 0
    for i in range(1, n):
        bit = n >> 1
        while j & bit:
            j ^= bit
            bit >>= 1
        j |= bit
        if i < j:
            re[i], re[j] = re[j], re[i]
            im[i], im[j] = im[j], im[i]
    length = 2
    while length <= n:
        half = length >> 1
        angle = -2.0 * math.pi / length
        w_step_r = math.cos(angle)
        w_step_i = math.sin(angle)
        for start in range(0, n, length):
            w_r = 1.0
            w_i = 0.0
            for k in range(start, start + half):
                m = k + half
                v_r = re[m] * w_r - im[m] * w_i
                v_i = re[m] * w_i + im[m] * w_r
                re[m] = re[k] - v_r
                im[m] = im[k] - v_i
                re[k] += v_r
                im[k] += v_i
                w_r, w_i = w_r * w_step_r - w_i * w_step_i, w_r * w_step_i + w_i * w_step_r
        length <<= 1


def _band_energy_ratio(samples: list[float], lo_hz: float, hi_hz: float) -> float:
    """Share of the signal power in [lo_hz, hi_hz], via a zero-padded FFT."""
    n = 2
    while n < len(samples):
        n <<= 1
    re = list(samples) + [0.0] * (n - len(samples))
    im = [0.0] * n
    _fft(re, im)
    total = 0.0
    for k in range(n):
        total += re[k] * re[k] + im[k] * im[k]
    if total <= 0.0:
        return 0.0
    band = 0.0
    for k in range(1, n // 2):
        freq = SR * k / n
        if lo_hz <= freq <= hi_hz:
            mirror = n - k
            band += (
                re[k] * re[k]
                + im[k] * im[k]
                + re[mirror] * re[mirror]
                + im[mirror] * im[mirror]
            )
    return band / total


def _write_wav(path: str, samples: list[float], rate: int, channels: int) -> None:
    """Write a PCM-16 WAV with explicit rate and channel count (fixtures)."""
    frames = b"".join(
        struct.pack("<h", int(max(-1.0, min(1.0, s)) * 32767)) for s in samples
    )
    with wave.open(path, "wb") as wav:
        wav.setnchannels(channels)
        wav.setsampwidth(2)
        wav.setframerate(rate)
        wav.writeframes(frames)


def _expect_fail(path: str, kind: str, keyword: str) -> None:
    problems = check_file(path, kind)
    assert problems and any(keyword in p for p in problems), (
        f"{os.path.basename(path)} must fail {kind} with a '{keyword}' "
        f"problem, got {problems}"
    )


def _run_self_test() -> int:
    """Generate fixtures in a temp folder and assert check_file's verdicts."""
    import synth_common

    tell_n = int(0.6 * SR)
    with tempfile.TemporaryDirectory(prefix="check_spec_selftest_") as tmp:
        good = os.path.join(tmp, "tell_good.wav")
        short = os.path.join(tmp, "tell_short.wav")
        low = os.path.join(tmp, "tell_low.wav")
        rate_bad = os.path.join(tmp, "tell_44k.wav")
        stereo = os.path.join(tmp, "tell_stereo.wav")
        clipped = os.path.join(tmp, "tell_clipped.wav")
        synth_common.save_wav(good, synth_common.sine(2000.0, tell_n))
        synth_common.save_wav(short, synth_common.sine(2000.0, int(0.3 * SR)))
        synth_common.save_wav(low, synth_common.sine(200.0, tell_n))
        _write_wav(rate_bad, synth_common.sine(2000.0, int(0.6 * 44100)), 44100, 1)
        _write_wav(stereo, synth_common.sine(2000.0, tell_n), SR, 2)
        _write_wav(clipped, synth_common.sine(2000.0, tell_n), SR, 1)

        problems = check_file(good, "tell")
        assert problems == [], f"0.6 s tell at 2 kHz must pass, got {problems}"
        _expect_fail(short, "tell", "duration")
        _expect_fail(rate_bad, "tell", "sample rate")
        _expect_fail(stereo, "tell", "mono")
        _expect_fail(clipped, "tell", "dBFS")
        _expect_fail(low, "tell", "energy")
    print("SELFTEST OK")
    return 0


def main(argv: list[str] | None = None) -> int:
    """CLI entry: check files of one kind, or run the self test."""
    parser = argparse.ArgumentParser(
        description="Check synthesised sounds against docs/design/sound-bible.md."
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="generate fixtures in a temp folder and verify the checker itself",
    )
    parser.add_argument(
        "kind", nargs="?", choices=sorted(DURATION_LIMITS_S),
        help="sound category to check the files against",
    )
    parser.add_argument("files", nargs="*", help="WAV files to check")
    args = parser.parse_args(argv)
    if args.self_test:
        return _run_self_test()
    if not args.kind or not args.files:
        parser.error("a kind and at least one file are required, or --self-test")
    ok = True
    for path in args.files:
        problems = check_file(path, args.kind)
        if problems:
            ok = False
            for problem in problems:
                print(f"FAIL {path}: {problem}")
        else:
            print(f"PASS {path}")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
