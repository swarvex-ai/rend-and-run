# Hermes P3-Welle (11.10.2026) — übernommen am 22.10.2026

Quelle: Hermes-Arbeitsstand `~/wt-rig` (Branch `main`, Commit c3934b3 „assets: P3-Welle done“), erzeugt von Hermie mit Meshy (meshy-7.1), Journal `game/assets/manifest/meshy-journal.json` dort.

| Ordner | Meshy-Task | Hinweis |
|---|---|---|
| enemy_humanoid_heavy_chassis | 01a12acb-7a46-71db-9034-570ba5795a78 | Meshy-Biped-Rig, walk/run mitgeliefert |
| enemy_dog_kessel_v2 | (Journal-Commit 38e96f9 auf Hermes-Server, lokal nicht vorhanden) | Unitree-artiger Vierbeiner, ungeriggt; v1 „Kessel“ (Steampunk) verworfen |
| drone_suicide | 01a12acb-8d07-70a9-911f-5d8f695aac2c | Kamikaze-Drohne; Meshy-Biped-Rig unbrauchbar, wird prozedural animiert |

Projektregel (vision.md-Notiz von Hermie): Roboter-Designs nach echten Vorbildern — Hund → Unitree, Humanoid → Figure/Atlas/Optimus.
Lizenz: Meshy-Ausgabe aus bezahltem Abo.

Robot dog in game: `game/assets3d/characters/robot_dog_v1/model.glb`, rigged and animated (idle, trot, run, lunge, hit, death) by `tools/blender/rig_quadruped.py` from enemy_dog_kessel_v2/model.glb.
