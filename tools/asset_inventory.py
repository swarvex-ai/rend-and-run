#!/usr/bin/env python3
"""H21 — Reusable visual asset inventory (read-only, stdlib only).

Enumerates GLB files under one or more --root paths and writes a
machine-readable JSON inventory: path, bytes, SHA256, and counts parsed
from the GLB JSON chunk (nodes, meshes, materials, animations, plus
animation names). Identical hashes are grouped as canonical-reuse
candidates (informational only — never deletes or modifies anything).

Malformed inputs are reported per-file and never abort the scan.
.git/.godot directories and symlink traversal are ignored. No binaries
are embedded in the output; paths only. No network, no new packages.

Usage:
    python3 asset_inventory.py --root /path/a --root /path/b --output inventory.json
    python3 asset_inventory.py --selftest          # fixture validation, exit!=0 on bug
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import struct
import sys
from pathlib import Path

GLB_MAGIC = 0x46546C67  # 'glTF' little-endian
SKIP_DIR_NAMES = {".git", ".godot"}
HASH_CHUNK = 1 << 20


def sha256_of(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        while True:
            b = f.read(HASH_CHUNK)
            if not b:
                break
            h.update(b)
    return h.hexdigest()


def parse_glb(path: Path) -> dict:
    """Parse GLB header + JSON chunk. Returns metadata dict or raises ValueError."""
    with path.open("rb") as f:
        head = f.read(12)
        if len(head) < 12:
            raise ValueError("file shorter than 12-byte GLB header")
        magic, version, total = struct.unpack("<III", head)
        if magic != GLB_MAGIC:
            raise ValueError(f"bad magic 0x{magic:08X} (not a GLB)")
        if version != 2:
            raise ValueError(f"unsupported glTF version {version}")
        # First chunk must be JSON.
        chead = f.read(8)
        if len(chead) < 8:
            raise ValueError("truncated: no first chunk header")
        clen, ctype = struct.unpack("<II", chead)
        if ctype != 0x4E4F534A:  # 'JSON'
            raise ValueError(f"first chunk type 0x{ctype:08X} is not JSON")
        raw = f.read(clen)
        if len(raw) < clen:
            raise ValueError("truncated JSON chunk")
    try:
        gltf = json.loads(raw.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as e:
        raise ValueError(f"JSON chunk unreadable: {e}") from e
    if not isinstance(gltf, dict):
        raise ValueError("JSON chunk is not an object")

    meshes = gltf.get("meshes", [])
    materials = gltf.get("materials", [])
    animations = gltf.get("animations", [])
    nodes = gltf.get("nodes", [])
    primitive_count = sum(len(m.get("primitives", [])) for m in meshes if isinstance(m, dict))
    used_materials = sorted({
        p["material"]
        for m in meshes if isinstance(m, dict)
        for p in m.get("primitives", [])
        if isinstance(p, dict) and "material" in p
    })
    anim_names = [a.get("name", f"animation_{i}") for i, a in enumerate(animations) if isinstance(a, dict)]
    out = {
        "glb_version": version,
        "generator": gltf.get("asset", {}).get("generator") if isinstance(gltf.get("asset"), dict) else None,
        "gltf_version": gltf.get("asset", {}).get("version") if isinstance(gltf.get("asset"), dict) else None,
        "node_count": len(nodes),
        "mesh_count": len(meshes),
        "primitive_count": primitive_count,
        "material_count": len(materials),
        "material_indices_used": used_materials,
        "animation_count": len(animations),
        "animation_names": anim_names,
        "scene_count": len(gltf.get("scenes", [])),
    }
    return out


def iter_glb_files(root: Path):
    """Yield GLB files under root, skipping .git/.godot and never following symlinks."""
    if root.is_file() and root.suffix.lower() == ".glb":
        yield root
        return
    for dirpath, dirnames, filenames in os.walk(root, followlinks=False):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIR_NAMES]
        for fn in filenames:
            if fn.lower().endswith(".glb"):
                p = Path(dirpath) / fn
                if p.is_symlink():
                    continue  # ignore symlink traversal
                yield p


def scan(roots: list[Path]) -> dict:
    assets = []
    errors = []
    for root in roots:
        if not root.exists():
            errors.append({"root": str(root), "error": "root does not exist"})
            continue
        for p in sorted(iter_glb_files(root)):
            try:
                size = p.stat().st_size
            except OSError as e:
                errors.append({"path": str(p), "error": f"stat failed: {e}"})
                continue
            entry = {
                "path": str(p),
                "root": str(root),
                "bytes": size,
                "sha256": sha256_of(p),
            }
            try:
                entry["metadata"] = parse_glb(p)
                entry["valid"] = True
            except (ValueError, OSError) as e:
                entry["valid"] = False
                entry["error"] = str(e)
            assets.append(entry)

    by_hash: dict[str, list[str]] = {}
    for a in assets:
        by_hash.setdefault(a["sha256"], []).append(a["path"])
    duplicate_groups = [
        {"sha256": h, "bytes": next(a["bytes"] for a in assets if a["sha256"] == h), "paths": ps}
        for h, ps in sorted(by_hash.items())
        if len(ps) > 1
    ]
    return {
        "tool": "asset_inventory.py (H21, read-only stdlib)",
        "roots": [str(r) for r in roots],
        "counts": {
            "glb_files": len(assets),
            "valid": sum(1 for a in assets if a["valid"]),
            "malformed": sum(1 for a in assets if not a["valid"]),
            "unique_hashes": len(by_hash),
            "duplicate_groups": len(duplicate_groups),
        },
        "assets": assets,
        "duplicate_groups": duplicate_groups,
    }


# ---------------------------------------------------------------------------
# Fixture self-test: valid GLB header, malformed file, duplicate hashes.

def _write_min_glb(path: Path, name: str) -> None:
    """Smallest valid GLB: header + JSON chunk (padded)."""
    doc = {
        "asset": {"version": "2.0", "generator": "fixture"},
        "scene": 0,
        "scenes": [{"nodes": [0]}],
        "nodes": [{"name": "root"}],
        "meshes": [{"name": name, "primitives": [{"attributes": {"POSITION": 0}}]}],
        "materials": [{"name": "mat_" + name}],
        "animations": [{"name": "idle_" + name}],
        "accessors": [],
    }
    raw = json.dumps(doc).encode("utf-8")
    pad = (-len(raw)) % 4
    raw += b" " * pad
    json_chunk = struct.pack("<II", len(raw), 0x4E4F534A) + raw
    body = struct.pack("<III", GLB_MAGIC, 2, 12 + len(json_chunk)) + json_chunk
    path.write_bytes(body)


def selftest() -> int:
    import os
    import tempfile
    fails = 0

    def check(label: str, ok: bool, detail: str = "") -> None:
        nonlocal fails
        if not ok:
            fails += 1
        print(f"H21 {'PASS' if ok else 'FAIL'} {label} {detail}")

    with tempfile.TemporaryDirectory(prefix="h21_fixture_") as td:
        tdp = Path(td)
        a = tdp / "a.glb"
        b = tdp / "sub" / "b.glb"
        b.parent.mkdir()
        _write_min_glb(a, "a")
        _write_min_glb(b, "b")
        dup = tdp / "dup_of_a.glb"
        dup.write_bytes(a.read_bytes())
        bad = tdp / "broken.glb"
        bad.write_bytes(b"not a glb at all")
        trunc = tdp / "trunc.glb"
        trunc.write_bytes(a.read_bytes()[:20])
        skipdir = tdp / ".godot" / "imported"
        skipdir.mkdir(parents=True)
        hidden = skipdir / "hidden.glb"
        _write_min_glb(hidden, "hidden")
        link = tdp / "link_a.glb"
        link.symlink_to(a)

        inv = scan([tdp])
        paths = {Path(x["path"]).name for x in inv["assets"]}
        check("valid GLB parsed", {"a.glb", "b.glb", "dup_of_a.glb"} <= paths)
        check("malformed reported not fatal", {"broken.glb", "trunc.glb"} <= paths
              and inv["counts"]["malformed"] == 2)
        e_bad = next(x for x in inv["assets"] if Path(x["path"]).name == "broken.glb")
        check("malformed has clear error text", bool(e_bad.get("error")), e_bad.get("error", ""))
        e_a = next(x for x in inv["assets"] if Path(x["path"]).name == "a.glb")
        md = e_a["metadata"]
        check("metadata counts correct",
              md["node_count"] == 1 and md["mesh_count"] == 1
              and md["material_count"] == 1 and md["animation_count"] == 1
              and md["animation_names"] == ["idle_a"] and md["primitive_count"] == 1
              and md["scene_count"] == 1, str(md))
        check("hash groups a==dup", any(
            set(g["paths"]) == {str(a), str(dup)} for g in inv["duplicate_groups"]),
            str(inv["duplicate_groups"]))
        check(".godot skipped", "hidden.glb" not in paths)
        check("symlink not traversed", "link_a.glb" not in paths)
        check("unique hash count", inv["counts"]["unique_hashes"] == 4,
              str(inv["counts"]))  # a==dup teilen sich einen, b/broken/trunc je eigen
        # JSON round-trip: output must be serialisable with no binary content.
        s = json.dumps(inv)
        check("inventory serialises to JSON", len(s) > 0)

    print(f"H21 SELFTEST checks=9 failures={fails}")
    return 1 if fails else 0


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser(description=(__doc__ or "GLB asset inventory").splitlines()[0])
    ap.add_argument("--root", action="append", default=[], type=Path,
                    help="directory (or single .glb) to scan; repeatable")
    ap.add_argument("--output", type=Path, help="JSON file to write")
    ap.add_argument("--selftest", action="store_true", help="run fixture validation")
    args = ap.parse_args(argv)

    if args.selftest:
        return selftest()
    if not args.root:
        ap.error("at least one --root is required (or use --selftest)")
    inv = scan(args.root)
    text = json.dumps(inv, indent=2, ensure_ascii=False)
    if args.output:
        args.output.write_text(text + "\n", encoding="utf-8")
        print(f"wrote {args.output}: {inv['counts']}")
    else:
        print(text)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
