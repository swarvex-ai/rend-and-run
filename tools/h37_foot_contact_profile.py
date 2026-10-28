#!/usr/bin/env python3
"""H37 — Fuss-Kontaktprofil aus BESTEHENDEN hero_rendrun walk/run-Clips.

Reines stdlib-Python (kein Godot, keine Pip-Pakete): liest die glTF-Animation
direkt aus der GLB (gleiche Binärdaten, die Godot importiert), wertet die
absolute Node-TRS der Clips auf (LINEAR: SLERP/lerp mit Hemisphere-Korrektur,
STEP: halten) und kompositioniert Szenen-Wurzel -> Bone-Kette, um die
WELTPOSITIONEN von LeftFoot/LeftToeBase/RightFoot/RightToeBase bei 60 Hz ueber
genau eine Clip-Laenge (inkl. Wrap-Abdeckung) zu bestimmen.

Aufruf:  python3 h37_foot_contact_profile.py --glb PFAD --out-dir DIR
Danach:  python3 h37_foot_contact_profile.py --glb PFAD --out-dir DIR --derive

Output: walk_samples.csv, run_samples.csv, foot_contact_profile.json
Keine Gameplay-Aenderung, kein Resampling der Animation, nur Messung.
"""
import argparse
import json
import math
import os
import struct

HZ = 60
FEET = {
    "left_foot": "mixamorig:LeftFoot",
    "left_toe": "mixamorig:LeftToeBase",
    "right_foot": "mixamorig:RightFoot",
    "right_toe": "mixamorig:RightToeBase",
}


# ------------------------------------------------------------- GLB-Container
def load_glb(path):
    data = open(path, "rb").read()
    magic, ver, total = struct.unpack_from("<III", data, 0)
    assert magic == 0x46546C67, "not a GLB"
    off = 12
    jc = None
    binchunk = b""
    while off < total:
        clen, ctype = struct.unpack_from("<I4s", data, off)
        off += 8
        if ctype == b"JSON":
            jc = json.loads(data[off:off + clen])
        elif ctype == b"BIN\x00":
            binchunk = data[off:off + clen]
        off += clen
    return jc, binchunk


COMP = {5126: ("<f", 4), 5123: ("<H", 2), 5125: ("<I", 4)}
TYPES = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}


def accessor(jc, binchunk, idx):
    a = jc["accessors"][idx]
    bv = jc["bufferViews"][a["bufferView"]]
    fmt, esize = COMP[a["componentType"]]
    n = TYPES[a["type"]]
    base = bv.get("byteOffset", 0) + a.get("byteOffset", 0)
    stride = bv.get("byteStride", esize * n)
    out = []
    for i in range(a["count"]):
        vals = struct.unpack_from(f"<{n}{fmt[1]}", binchunk, base + i * stride)
        out.append(list(vals))
    return out


# ------------------------------------------------------------------ Mathe
def quat_mat(q):  # glTF xyzw, Standardform (Spaltenvektor-Konvention p' = M·p)
    x, y, z, w = q
    return [
        [1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w), 0],
        [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w), 0],
        [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y), 0],
        [0, 0, 0, 1],
    ]


def trs(t, r, s):
    # M = T · R · S (Spaltenkonvention): Rotation skalieren, Translation in Spalte 3
    m = quat_mat(r)
    for i in range(3):
        for j in range(3):
            m[i][j] *= s[j]
    for i in range(3):
        m[i][3] = t[i]
    return m


def matmul(a, b):
    out = [[0.0] * 4 for _ in range(4)]
    for i in range(4):
        for j in range(4):
            out[i][j] = sum(a[i][k] * b[k][j] for k in range(4))
    return out


def origin(m):
    return (m[0][3], m[1][3], m[2][3])


def slerp(q1, q2, f):
    d = sum(a * b for a, b in zip(q1, q2))
    if d < 0:
        q2 = [-v for v in q2]
        d = -d
    if d > 0.9995:
        q = [a + (b - a) * f for a, b in zip(q1, q2)]
        n = math.sqrt(sum(v * v for v in q))
        return [v / n for v in q]
    th = math.acos(max(-1.0, min(1.0, d)))
    s = math.sin(th)
    return [(math.sin((1 - f) * th) * a + math.sin(f * th) * b) / s
            for a, b in zip(q1, q2)]


def lerp(a, b, f):
    return [x + (y - x) * f for x, y in zip(a, b)]


# ------------------------------------------------------- Animations-Auswertung
def build_channels(jc, binchunk, clip_name):
    anim = next(a for a in jc["animations"] if a.get("name") == clip_name)
    ch = {}
    clip_len = 0.0
    for c in anim["channels"]:
        node = c["target"]["node"]
        path = c["target"]["path"]
        s = anim["samplers"][c["sampler"]]
        times = [v[0] for v in accessor(jc, binchunk, s["input"])]
        vals = accessor(jc, binchunk, s["output"])
        ch[(node, path)] = (s["interpolation"], times, vals)
        clip_len = max(clip_len, times[-1])
    return ch, clip_len


def sample(ch, node, path, t, default):
    key = (node, path)
    if key not in ch:
        return default
    interp, times, vals = ch[key]
    if t <= times[0]:
        return vals[0]
    if t >= times[-1]:
        return vals[-1]
    lo, hi = 0, len(times) - 1
    while hi - lo > 1:
        mid = (lo + hi) // 2
        if times[mid] <= t:
            lo = mid
        else:
            hi = mid
    if interp == "STEP":
        return vals[lo]
    f = (t - times[lo]) / (times[hi] - times[lo])
    if path == "rotation":
        return slerp(vals[lo], vals[hi], f)
    return lerp(vals[lo], vals[hi], f)


def globals_at(jc, ch, t):
    """node_idx -> Weltmatrix zur Zeit t (Szenen-Wurzel inkl. TRS, Kette ab."""
    nodes = jc["nodes"]
    scene = jc["scenes"][jc.get("scene", jc.get("defaultScene", 0))]
    out = {}

    def walk(nidx, parent_m):
        n = nodes[nidx]
        trs_t = sample(ch, nidx, "translation", t, n.get("translation", [0, 0, 0]))
        rot_q = sample(ch, nidx, "rotation", t, n.get("rotation", [0, 0, 0, 1]))
        scl = sample(ch, nidx, "scale", t, n.get("scale", [1, 1, 1]))
        g = matmul(parent_m, trs(trs_t, rot_q, scl))
        out[nidx] = g
        for c in n.get("children", []):
            walk(c, g)

    ident = [[1 if i == j else 0 for j in range(4)] for i in range(4)]
    for r in scene["nodes"]:
        walk(r, ident)
    return out


def sample_clip(jc, binchunk, clip, hz=HZ):
    ch, clip_len = build_channels(jc, binchunk, clip)
    nodes = jc["nodes"]
    name2idx = {n.get("name", ""): i for i, n in enumerate(nodes)}
    bone_idx = {k: name2idx.get(v) for k, v in FEET.items()}
    steps = math.ceil(clip_len * hz)
    rows = []
    for i in range(steps):
        t = clip_len * i / steps
        g = globals_at(jc, ch, t)
        row = {"t": t, "phase": t / clip_len}
        for k, idx in bone_idx.items():
            row[k] = origin(g[idx]) if idx is not None else None
        rows.append(row)
    return {"clip": clip, "length_s": clip_len, "hz": hz, "samples": steps,
            "bone_names": dict(FEET), "rows": rows}


# ----------------------------------------------------- Kontakt-/Standphasen
def derive_contacts(data, foot_key, toe_key, band=0.08):
    """Hohen-basierte Kontaktfenster: Kontakt = Zehe nahe Zyklusminimum.
    Rueckgabe: Fenster [p0,p1) in normalisierter Phase, Tritt-Marke = Fenster-
    eintritt (Abwaertskreuzung der Band-Schwelle), Amplituden, Konfidenz."""
    ys = [r[toe_key][1] for r in data["rows"]]
    y0 = [r[foot_key][1] for r in data["rows"]]
    ymin, ymax = min(ys), max(ys)
    amp = ymax - ymin
    thr = ymin + band * amp
    rows = data["rows"]
    n = len(rows)
    windows = []
    inside = ys[0] <= thr
    start = 0 if inside else None
    for i in range(1, n):
        now = ys[i] <= thr
        if now and not inside:
            start = i
        elif not now and inside:
            windows.append((start, i))
            start = None
        inside = now
    if inside and start is not None:
        # Fenster laeuft ueber Zyklusende -> Wrap mit Anfang zusammenfuehren
        if windows and windows[0][0] == 0:
            windows[0] = (start, windows[0][1] + n)  # Phase >1 = Wrap
        else:
            windows.append((start, n))
    contacts = []
    for (a, b) in windows:
        p0 = rows[a % n]["phase"]
        # Fensterlaenge in Phasen:Sample-Indexdifferenz / n (wrap-sicher)
        width = (b - a) / n
        contacts.append({
            "contact_start_phase": round(p0 % 1.0, 4),
            "contact_end_phase": round((p0 + width) % 1.0, 4),
            "wrapped": bool(b > n or (p0 + width) > 1.0),
            "stride_fraction": round(width, 4),
        })
    conf = "medium"
    if amp < 0.02:
        conf = "low"      # Zehe hebt kaum ab -> Fenster unzuverlaessig
    if len(contacts) == 0:
        conf = "low"
    # Wrap-Stetigkeit
    jump = abs(ys[-1] - ys[0])
    return {
        "toe_y_min_m": round(ymin, 4), "toe_y_max_m": round(ymax, 4),
        "toe_lift_amplitude_m": round(amp, 4),
        "foot_y_min_m": round(min(y0), 4),
        "band_fraction_of_amplitude": band,
        "contact_windows": contacts,
        "wrap_height_jump_m": round(jump, 4),
        "confidence": conf,
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--glb", required=True)
    ap.add_argument("--out-dir", required=True)
    ap.add_argument("--derive", action="store_true")
    args = ap.parse_args()
    os.makedirs(args.out_dir, exist_ok=True)
    jc, binchunk = load_glb(args.glb)

    profile = {
        "glb_path_hint": args.glb,
        "sampling": {"hz": HZ, "scheme": "t = len*i/ceil(len*hz), i in [0,steps); "
                     "genau ein Zyklus inkl. Wrap-Abdeckung bis <1.0",
                     "interp": "LINEAR=SLERP/lerp (Hemisphere-Korrektur), STEP=halten; "
                               "vor erstem Key: erster Key (wie Godot-Clamp)"},
        "bones": dict(FEET),
        "coordinate_frame": "glTF-Szenen-Wurzel (Y oben); konstanter Root-TRS "
                            "wie im Import. Konstanten verschieben KEINE Phase.",
        "clips": {},
        "method_note": "Messung: absolute glTF-Node-TRS-Komposition (identisch zu "
                       "Godots importierten Daten). INFERENZ: Kontakt = Zeehenhoehe "
                       "innerhalb band*Amplitude ueberm Zyklusminimum; Tritt-Marke = "
                       "Fenster-Eintritt. Clip-Inspektions beweist NICHT die finale "
                       "Bodenalignierung im Level (player.collision/Grund-Kontakte "
                       "koennen die Maeuse verschieben).",
    }
    for clip in ("walk", "run"):
        data = sample_clip(jc, binchunk, clip)
        hdr = "t,phase," + ",".join(
            [f"{k}_{a}" for k in ("left_foot", "left_toe", "right_foot", "right_toe")
             for a in "xyz"])
        lines = [hdr]
        for r in data["rows"]:
            cells = [f"{r['t']:.6f}", f"{r['phase']:.6f}"]
            for k in ("left_foot", "left_toe", "right_foot", "right_toe"):
                x, y, z = r[k]
                cells += [f"{x:.6f}", f"{y:.6f}", f"{z:.6f}"]
            lines.append(",".join(cells))
        open(os.path.join(args.out_dir, f"{clip}_samples.csv"), "w").write(
            "\n".join(lines) + "\n")
        entry = {
            "length_s": round(data["length_s"], 6),
            "samples": data["samples"],
        }
        if args.derive:
            entry["left"] = derive_contacts(data, "left_foot", "left_toe")
            entry["right"] = derive_contacts(data, "right_foot", "right_toe")
        profile["clips"][clip] = entry
        print(f"{clip}: len={data['length_s']:.4f}s samples={data['samples']}")
    out = os.path.join(args.out_dir, "foot_contact_profile.json")
    json.dump(profile, open(out, "w"), indent=2, ensure_ascii=False)
    print("written:", out)


if __name__ == "__main__":
    main()
