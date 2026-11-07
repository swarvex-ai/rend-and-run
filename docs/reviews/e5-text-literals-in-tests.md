## From the text table

- `game/tests/checkpoint_feedback_test.gd:24` — `fehlgeschlagen` in the checkpoint-failure toast; source `game/data/route_texts.gd` key `msg_checkpoint_save_failed` (`Speichern fehlgeschlagen — Kontrollpunkt nur für diese Sitzung aktiv. Erneut E / Y versuchen.`).
- `game/tests/farming_guidance_test.gd:26` — `Humanoidenarm` in the mission objective; source `game/data/route_texts.gd` key `objective_take_arm` (`Humanoidenarm am Ablagetisch bergen →`).
- `game/tests/farming_guidance_test.gd:28` — `Optional:` at the start of the mission objective; source `game/data/route_texts.gd` key `objective_servo_optional` (`Optional: Servoteile an der Werkbank bergen →`).
- `game/tests/farming_guidance_test.gd:35` — `zweitem Hieb` in the mission objective; source `game/data/route_texts.gd` key `objective_servo_bearer` (`Servoträger: Arm mit zweitem Hieb abtrennen`).
- `game/tests/farming_guidance_test.gd:37` — `Träger noch aktiv` in the mission objective; source `game/data/route_texts.gd` key `objective_servo_exposed` (`Servo freigelegt · Träger noch aktiv`).
- `game/tests/farming_guidance_test.gd:48` — `herstellen` in the mission objective; source `game/data/route_texts.gd` key `objective_servo_craft` (`Werkbank: Servomodul herstellen →`).
- `game/tests/feedback_priority_integration.gd:19` — `PARIERT — Gegenangriff!` compared with the combat toast; source `game/data/route_texts.gd` key `msg_parried`.
- `game/tests/feedback_priority_integration.gd:21` — `PARIERT — Gegenangriff!` compared with the combat toast; source `game/data/route_texts.gd` key `msg_parried`.
- `game/tests/feedback_priority_integration.gd:23` — `SCHILDBRUCH` at the start of the combat toast; source `game/data/route_texts.gd` key `msg_shield_broken` (`SCHILDBRUCH — Loslassen und erholen!`).
- `game/tests/guard_spacing_test.gd:73` — `PARIERT — Gegenangriff!` compared with the combat toast; source `game/data/route_texts.gd` key `msg_parried`.
- `game/tests/hud_integration_test.gd:40` — `Werkbank` in the workbench prompt label; source `game/data/route_texts.gd` key `prompt_workbench_open` (`E / Y — Werkbank öffnen`).
- `game/tests/mission_teaching_integration.gd:30` — `STANDHAFT` in the feedback text; source `game/data/route_texts.gd` key `msg_overseer_braced` (`STANDHAFT: Treffer stoppen den Hieb nicht. `).
- `game/tests/mission_teaching_integration.gd:30` — `Parieren` in the feedback text; source `game/data/route_texts.gd` key `advice_parry_or_dodge` (`Parieren oder ausweichen!`).
- `game/tests/overseer_brace_integration.gd:28` — `STANDHAFT` in the feedback text; source `game/data/route_texts.gd` key `msg_overseer_braced` (`STANDHAFT: Treffer stoppen den Hieb nicht. `).

## From other game code

- `game/tests/ammo_test.gd:41` — `Laservisier` in the gun-bench prompt label; source literal `game/modules/combat/gun.gd:14` (`MODS.laser.label`).
- `game/tests/ammo_test.gd:48` — `Schnellladegriff` in the gun-bench prompt label; source literal `game/modules/combat/gun.gd:16` (`MODS.quickload.label`).
- `game/tests/checkpoint_feedback_test.gd:19` — `BEREIT` compared with the checkpoint console label; source literal `game/modules/world/checkpoint_console.gd:99`.
- `game/tests/checkpoint_feedback_test.gd:25` — `FEHLER` compared with the checkpoint console label; source literal `game/modules/world/checkpoint_console.gd:152`.
- `game/tests/checkpoint_feedback_test.gd:29` — `GESICHERT` compared with the checkpoint console label; source literal `game/modules/world/checkpoint_console.gd:177`.
- `game/tests/checkpoint_feedback_test.gd:42` — `GESICHERT` compared with the checkpoint console label; source literal `game/modules/world/checkpoint_console.gd:177`.
- `game/tests/farming_guidance_test.gd:54` — `in %d` in the servo-trial info label; source literal `game/modules/ui/workbench_menu.gd:156` (`12 Splitter + 1 Servo sicher · Extra spätestens in %d %s`).
- `game/tests/mission_teaching_integration.gd:20` — `ducken` in the feedback text; source literal `game/modules/ui/combat_hint_text.gd:15` (`Hoher Hieb: ducken oder parieren.`), shortened for the shieldless path at `game/lab_route.gd:356`.
- `game/tests/mission_teaching_integration.gd:20` — `parieren` absence-checked in the feedback text; same source literal `game/modules/ui/combat_hint_text.gd:15` and replacement at `game/lab_route.gd:356`.
- `game/tests/mission_teaching_integration.gd:26` — `springen` in the feedback text for the overseer's low band; source literal `game/modules/ui/combat_hint_text.gd:24` (`Tiefer Aufseher-Hieb: springen oder ausweichen.`).
- `game/tests/mission_teaching_integration.gd:26` — `ducken` in the feedback text for the overseer's high band; source literal `game/modules/ui/combat_hint_text.gd:23` (`Hoher Aufseher-Hieb: ducken oder parieren.`).
- `game/tests/notstrom_sequence_integration.gd:29` — `03 / VERSORGUNG` compared with the HUD zone label; source literal `game/modules/world/notstrom_layout.gd:39`.
- `game/tests/notstrom_sequence_integration.gd:29` — `05 / SCHLEUSE` compared with the HUD zone label; source literal `game/modules/world/notstrom_layout.gd:41`.
- `game/tests/overseer_brace_integration.gd:20` — `STANDHAFT` compared with the overseer's `RoleLabel`; source literal `game/modules/combat/lab_overseer.gd:95`.
- `game/tests/overseer_brace_integration.gd:30` — `STANDHAFT` compared with the boss HUD phase label; source literal `game/modules/ui/overseer_status.gd:106`.
- `game/tests/overseer_integration.gd:65` — `Phase 2` compared with the boss HUD phase label; source literal `game/modules/ui/overseer_status.gd:106` (`Phase %d`).
- `game/tests/pressure_step_test.gd:47` — `springen` in the low-attack hint toast; source literal `game/modules/ui/combat_hint_text.gd:21` (`Tiefer Hieb: springen oder ausweichen.`).
- `game/tests/sector_complete_test.gd:89` — `Fortschritt gespeichert` compared with the completion save label; source literal `game/modules/ui/sector_complete.gd:142`.
- `game/tests/sector_complete_test.gd:103` — `Speichern fehlgeschlagen — Fortschritt nur in dieser Sitzung.` compared with the completion save label; source literal `game/modules/ui/sector_complete.gd:145`.
- `game/tests/sector_complete_test.gd:141` — `— keine —` compared with the empty weapon/armor value labels; source literal `game/modules/ui/sector_complete.gd:139`.
- `game/tests/sector_complete_test.gd:156` — `Zum Hauptmenü` in the collected completion-menu text; source literal `game/modules/ui/sector_complete.gd:109`.
- `game/tests/sector_complete_test.gd:156` — `Zurück` in the collected completion-menu text; source literal `game/modules/ui/sector_complete.gd:121`.
- `game/tests/sector_complete_test.gd:157` — `SEKTOR GESICHERT` in the collected completion-menu text; source literal `game/modules/ui/sector_complete.gd:92`.
- `game/tests/sector_complete_test.gd:157` — `Rüstung` in the collected completion-menu text; source literal `game/modules/ui/sector_complete.gd:103`.
- `game/tests/servo_upgrade_test.gd:54` — `Abbauen` compared with the servo action button text; source literal `game/modules/ui/workbench_menu.gd:159`.
- `game/tests/workbench_prerequisite.gd:8` — `Start bergen` in the workbench shortage label; source literal `game/modules/ui/workbench_menu.gd:185` (`Zuerst den Humanoidenarm am Start bergen.`).
- `game/tests/workbench_prerequisite.gd:10` — `Es fehlen 4 Splitter` compared with the workbench shortage label; source literal `game/modules/ui/workbench_menu.gd:187` (`Es fehlen %d Splitter`).

## Summary

14 test files, 41 hits: 14 from the text table and 27 from other game code. The most changes are needed in `sector_complete_test.gd` (7 hits), `farming_guidance_test.gd` (6) and `mission_teaching_integration.gd` (6), followed by `checkpoint_feedback_test.gd` (5). Self-set test literals that only feed the game output (for example `feedback_priority_integration.gd:13`–`17`/`27`, `guard_spacing_test.gd:71` and `feedback_layout_test.gd:43`/`84`/`92`) are not counted because a translation would not break them.
