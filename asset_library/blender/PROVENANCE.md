# Blender — eigene Assets (24.10.2026)

Prozedural per Skript gebaut (reproduzierbar), keine Fremdquellen:

| Asset | Skript | Laufzeitkopie |
|---|---|---|
| robot_arm/robot_arm.glb — 6-Achs-Industriearm mit Schweißbrenner (Knoten pro Gelenk) | `tools/blender/build_robot_arm.py` | `game/assets3d/env/robot_arm_v1/model.glb` |
| security_camera/security_camera.glb — Wandkamera mit Schwenk-/Neigegelenk und LED | `tools/blender/build_security_camera.py` | `game/assets3d/env/security_camera_v1/model.glb` |

Aufruf: `blender -b -P tools/blender/<skript>.py -- <out.glb> [vorschau.png]`
