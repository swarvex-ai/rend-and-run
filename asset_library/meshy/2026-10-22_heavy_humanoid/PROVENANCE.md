# Meshy — Schwerer Humanoid (22.10.2026)

Modell: Hermes P3-Welle `enemy_humanoid_heavy_chassis` (siehe asset_library/hermes_p3/PROVENANCE.md), neu geriggt.

| Datei | Meshy-Task | Inhalt | Credits |
|---|---|---|---|
| heavy_rigged.glb, heavy_walk.glb, heavy_run.glb | rigging 01a164a1-db9d-7370-a793-3b5a21e53247 | Rig + Gehen/Rennen | 5 |
| heavy_anims.glb | animation 01a164a2-ee78-76ef-8828-2475982d9e36 | Combat_Stance, Charged_Axe_Chop, Heavy_Hammer_Swing, Hit_Reaction, Hit_Reaction_to_Waist, Electrocution_Reaction, Knock_Down, Electrocuted_Fall | 24 |

Lizenz: Meshy-Ausgabe aus bezahltem Abo.

Game files: `game/assets3d/characters/heavy_humanoid_v1/model.glb`, libraries `game/generated/heavy_{combat,react,walk,run}.tres` (tools/retarget_clips.gd, INPLACE=1; slash_light = Heavy_Hammer_Swing retimed with WARP 1.2,1.65,1.8).
