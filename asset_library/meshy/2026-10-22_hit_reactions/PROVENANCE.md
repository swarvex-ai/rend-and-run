# Meshy — Treffer-Reaktionen (22.10.2026)

Erzeugt von Claude für Rend&Run. Freigegebenes Budget: 300 Credits (neVs).

| Datei | Meshy-Task | Inhalt | Credits |
|---|---|---|---|
| (Rig Roboter) | rigging 01a16463-7ff2-72da-9a59-e7525ec426fb | light_humanoid_v1 neu geriggt | 5 |
| (Rig Rend) | rigging 01a16463-9dc2-7685-af0c-9f854aa34bfa | hero_rendrun neu geriggt (T-Pose, +Z) | 5 |
| robot_hits.glb | animation 01a16464-2c0c-7061-9fb3-46d1e493c875 | Hit_Reaction, Hit_Reaction_1, Face_Punch_Reaction_1, Hit_Reaction_to_Waist, Electrocution_Reaction, Knock_Down, Knock_Down_1, Electrocuted_Fall, Stand_Dodge | 27 |
| rend_hits.glb | animation 01a16464-a25f-73e9-b488-0daef60f25f6 | Hit_Reaction, Hit_Reaction_1, Face_Punch_Reaction, Hit_Reaction_to_Waist, Gunshot_Reaction, Knock_Down, Stand_Dodge, Roll_Dodge, Shot_and_Fall_Backward, Shot_and_Fall_Forward | 30 |
| rend_hold_arm.glb | text-to-motion 01a16464-a53c-724e-aced-607b9f495805 + animation 01a16465-059e-754e-94dd-de1a19ad6a9e | „hält sich nach Treffer den linken Arm“ | 13 |
| rend_hold_ribs.glb | text-to-motion 01a16464-a7d4-748b-a79b-2bb9ca2839bd + animation 01a16465-1a30-72cc-a343-c7f48200811c | „klappt nach Rippentreffer zusammen“ | 13 |

Pipeline: `tools/blender/prepare_rig_source.py` → `tools/meshy_rig_upload.py` → MCP `meshy_animate` → `tools/retarget_clips.gd` (INPLACE=1) → `game/generated/robot_hit_motion.tres`, `game/generated/rend_hit_motion.tres`.
Lizenz: Meshy-Ausgabe aus bezahltem Abo (siehe Meshy Terms of Use, Abschnitt 3.2).
