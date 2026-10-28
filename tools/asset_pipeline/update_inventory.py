#!/usr/bin/env python3
"""Erneuert docs/asset-manifest.json: sha256 aller versionierten Dateien unter game/assets3d/.

Vertrag P00/P03: Das Repo-Inventar enthaelt sha256/bytes jeder versionierten
assets3d-Datei (Pfad relativ zu game/). Verwendet nach jeder erfolgreichen
publish-Aktion. Loescht keine Eintraege, die nicht (mehr) unter assets3d liegen?
Doch: Inventar = exakte Abbildung des aktuellen assets3d-Bestands; alte
Asset-Staende bleiben als Dateien erhalten, verschwinden also nicht.
"""
import hashlib, json, sys
from datetime import datetime, timezone
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
GAME = REPO / 'game'
MANIFEST = REPO / 'docs' / 'asset-manifest.json'

def digest(path: Path) -> str:
    with open(path, 'rb') as f:
        return hashlib.file_digest(f, 'sha256').hexdigest()

def main() -> int:
    data = json.loads(MANIFEST.read_text())
    assets = []
    for p in sorted(GAME.glob('assets3d/**/*')):
        if not p.is_file() or p.name == '.publish.lock':
            continue
        assets.append({
            'path': str(p.relative_to(GAME)),
            'bytes': p.stat().st_size,
            'sha256': digest(p),
        })
    data['assets'] = assets
    data['generated_utc'] = datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
    MANIFEST.write_text(json.dumps(data, indent=2, ensure_ascii=False) + '\n')
    print(f'{len(assets)} assets inventorisiert')
    return 0

if __name__ == '__main__':
    sys.exit(main())
