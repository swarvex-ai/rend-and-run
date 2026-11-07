# Status

## 05.11.2026 (Lead, Dauerbetrieb nach LEAD.md 2.4)

**Lage:** Die Pipeline war seit Tagen rot, ohne dass ein Beitrag schuld war. Ursache war eine Bildrate unter dem Physiktakt auf der Live-Maschine. Seit `cf83969` laufen die Headless-Tests mit fester Spielzeit (`--fixed-fps 60`); rote Tests drucken jetzt Exit-Code und Log-Ende. 14 Einreichungen sind heute entschieden: 12 angenommen, 2 zur Nacharbeit (#1 inzwischen angenommen, #17 offen).

**Angenommen heute:** #38 und #39 (Menü-Styleguides), #1, #3, #5 (Bestiarium Wächter, Wächterroboter in der Wandnische, Drohne), #11–#16 (veraltete Tests, jeweils lokal 3 × grün, ohne Patch rot).

**Rulings**
- Ruling: Menü-Styleguide ist Variante 2 mit zwei Ergänzungen aus Variante 1 (`docs/decisions/0002-menu-style-guide.md`) — von neVs delegiert; Variante 2 lässt weniger zu raten — Kosten bei Irrtum: eine B-Aufgabe, die Theme-Werte tauscht.
- Ruling: Keine Reparatur-Aufgaben je rotem Test — die rote Pipeline hatte eine gemeinsame Ursache im Runner, nicht in den Tests — Kosten bei Irrtum: einzelne Tests bleiben rot und zeigen das jetzt mit Log.
- Ruling: #17 (Abkürzungstür) zur Nacharbeit, weil der Test sich selbst Wegweiser baut; die Route baut keine mehr (Fehler in meiner Aufgabe, in der Begründung benannt) — Kosten bei Irrtum: ein Durchlauf mehr.

**Tests:** headless 77 grün lokal; Pipeline mit festem Takt ab `cf83969`. Offen: seltener Godot-Absturz (SIGILL, `cowdata.h:197`, Engine-Fehler), Test noch unbekannt.

**Risiken**
- Hook-Tests (`hook` im Manifest) laufen in der Pipeline nicht, weil `--headless` nur `headless` auswählt. Das betrifft auch reparierte Tests wie loot, equipment, ranged. Prüfe ich als Nächstes (Runner, Stufe D).

**Abends erledigt:** Hook-Tests laufen in der Pipeline (`3f3160d`); sieben reparierte Tests sind aus der Quarantäne, drei wackelige hinein, mit den Reparatur-Aufgaben #54–#56. F6 ist fertig (`docs/architecture.md`, `docs/qa.md`, #49), die beratende Prüfung ist #57. F3 Schritt 1: Alle 109 Routentexte kommen aus `game/data/route_texts.gd`, abgesichert durch den Vertragstest `route_text_table_test` (`b87ff54`). Suite: 81 headless + 11 hook grün, je 119 s.

**Rulings (abends)**
- Ruling: `--headless` führt auch Hook-Tests aus — sonst prüft die Pipeline zehn Tests nie — Kosten bei Irrtum: etwa 20 s mehr pro Lauf.
- Ruling: `first_room_playthrough` und `ranged_integration_test` in Quarantäne statt in der Pipeline — wackelig ohne Codeänderung — Kosten bei Irrtum: zwei Tests prüfen bis zu ihrer Reparatur (#54, #55) nichts.
- Ruling: Textschlüssel sind englisch, die Werte bleiben vorerst deutsch — E5 ändert nur die Tabelle — Kosten bei Irrtum: Schlüssel umbenennen, mechanisch.

**Nacht zum 06.11.:** F3 fertig (#50, Routendaten `541f5be`, Review #59), F4 fertig (#51, `route_playthrough`: Route in 20,6 s Spielzeit, Kontrolle nach Tod in 2,43 s), E11.2 fertig (#52, Einstellungsspeicher, `MenuScreen`, Options-Bildschirm; Screenshot geprüft). `depth_test` in Quarantäne (#58). Comic-Styleguides #7/#8 angenommen; Wahl liegt bei neVs (Nachricht 13). Suite: 84 headless + 11 hook grün.

**Wartet auf neVs:** Comic-Stil (Nachricht 13), Comic-Drehbuch (Nachricht 14), Tod und Splitter (Nachricht 15).

**Rulings (Nacht)**
- Ruling: Testreparaturen prüfen die heutige Todesregel (Geldbörse bleibt, kein neuer Cache) — so steht es in Code und Farming-Design v02; GDD und Glossar widersprechen, Frage an neVs (Nachricht 15) — Kosten bei Irrtum: #65/#66 und `shard_pickup_integration` werden angepasst.
- Ruling: Diagnosen #20–#22 angenommen, Reparaturen #65 (Arena-Tor), #66 (Overseer), #67 (Speichern) geschnitten.
- Ruling: Diagnosen #23–#36 angenommen; Reparaturen #68–#78 geschnitten. Zwei echte Spielfehler gefunden: B schließt die Werkbank und löst ein Ausweichen aus (#70), und ein fliegender Schuss verliert seinen Schaden, wenn sein Schütze zerstört wird (#76).

- Ruling: Menü-Aufgaben in zwei Teilen (Bildschirm + Anbindung mit minimalen Test-Anpassungen, dann neue Prüfungen) — drei Einreichungen scheiterten knapp an der 500-Zeilen-Grenze (579, 629, 515) — Kosten bei Irrtum: ein Merge mehr pro Menü. Ersetzt: #63/#80–#82 → #87/#88 (Hauptmenü), #64 → #83/#84 (Pause), #70 → #85, #71 → #86.

**Wartet zusätzlich auf neVs:** UX-Spezifikation (Nachricht 16), Sound Bible (17), Story-Gerüst (18).

**Mittag 06.11.:** #83 angenommen (Pausenmenü Teil 1 auf `MenuScreen`: fünf Zeilen, Rückfragen auf demselben Bildschirm, Optionen über dem pausierten Spiel; 378 Zeilen, Pipeline 84 headless + 13 hook grün). Damit ist #84 (neue Prüfungen) frei. Angebot: 26 freie Aufgaben bei 1 aktivem Agenten, keine Einreichung offen.

**Nachmittag 06.11.:** #87 angenommen (Hauptmenü Teil 1 auf `MenuScreen`, 378 Zeilen, Screenshots geprüft); #88 ist frei. Die Screenshots zeigten einen Fehler in meiner Basis: Die Fokusleiste blieb nach dem Hineingleiten und nach `show_rows` an der alten Stelle stehen, teils unterhalb des Panels. Behoben in `menu_screen.gd` (Leiste folgt Panel und Zeilen), Regressionstest in `menu_screen_test` (auf altem Code rot, mit Korrektur 3 × grün; Suite 84 headless + 13 hook grün).
- Beobachtung (S4, für E11-Feinschliff): Das Panel der Hauptmenü-Rückfrage bleibt auf der Höhe der Liste mit fünf Zeilen stehen statt neu zu zentrieren. Nicht dringend.

- #85 zur Nacharbeit: Der neue Test `shop_close_input_test` ist auf der Basis grün (3 ×, von mir geprüft), bildet den Fehler also nicht ab; mit dem Patch zeigt `workbench_integration` weiter `dash=0.08` nach B. Der Ausweichschritt beginnt schon etwa beim Druck auf B, nicht erst im ersten Spielbild nach der Pause. Anleitung in der Begründung.
- #54 angenommen (`first_room_playthrough` mit `seed(1)`, Abbruch statt `assert`; bei mir 5 × grün, je 7–8 s). Nach dem Merge aus der Quarantäne genommen: Suite zweimal grün mit 85 headless + 13 hook.

- #55 (Einreichung 63): Pipeline rot an `arm_first_fight`, verursacht durch den Patch. `lab_route.gd:188` lädt `ranged_integration_test.gd` per `preload` bei jedem Spielstart, auch ohne `V17_TEST`; das neue `preload(energy_bolt.gd)` darin ändert die Ladereihenfolge des ganzen Spiels. Bei mir auf 36d8820: ohne Patch grün, mit Patch 3 × rot (`enemy_hp=1`). Mit `load()` statt `preload()` ist `arm_first_fight` grün, aber die Duck-Prüfung wieder 3 von 4 rot. Die Plattform hat die Einreichung selbst zurückgegeben (zweimal rot, Gegenprobe ohne Beitrag grün). #55 geschlossen und durch #91 ersetzt: dieselbe Aufgabe mit der Falle „kein preload“ und den Befunden des ersten Versuchs. Diagnose der Reihenfolge-Abhängigkeit: #90.
- Risiko (neu): Spielcode lädt Testskripte (`lab_route.gd` lädt Hook-Tests per `preload`). Eine Teständerung kann so das Spielverhalten anderer Tests ändern, und die Ladereihenfolge beeinflusst offenbar einen Nahkampf (Verdacht: Reihenfolge nach Objekt-IDs). Aufgabe folgt: Hook-Tests erst zur Laufzeit laden, Ursache der Reihenfolge-Abhängigkeit diagnostizieren.

- #85 zweite Einreichung (64): Fehler behoben und von mir bestätigt (Test auf main ohne Korrektur rot, mit Korrektur 3 × grün; `workbench_integration` Zeile 50 grün). Trotzdem Nacharbeit: Die Kampfsperre greift nach jedem Schließen der Werkbank, auch mit Esc; der erste Angriff danach würde verschluckt. Sperre nur, wenn die schließende Taste selbst Angriff/Ausweichen ist, plus eine Prüfung dafür.
- #56 angenommen (landing_integration_test ohne Display; headless 3 × grün, mit Fenster wird der Screenshot weiter gespeichert). Nach dem Merge aus der Quarantäne: Suite zweimal grün mit 85 headless + 14 hook.

**Abend 06.11.:** #85 angenommen (dritte Einreichung, 66). Die Kampfsperre greift nur noch, wenn die schließende Taste selbst Angriff/Ausweichen ist, und endet beim Loslassen. Von mir auf d98af8a geprüft: `shop_close_input_test` ohne Korrektur rot (3 Fehler, darunter „Esc verschluckt den Angriff“), mit Korrektur 3 × grün; `pause_menu_test`, `pause_integration_test`, `arm_first_fight` grün; das gesperrte `workbench_integration` zeigt mit und ohne Patch dieselben 12 Fehler. Nach dem Merge (b328e66) im Manifest eingetragen (headless); Suite grün mit 86 headless + 14 hook. Damit ist #86 (Werkbank) frei.
- #58 angenommen (depth_test: `seed(1)`; die in Teil 1 gerufene Verstärkung und der geweckte Roboter werden geparkt, sodass in Teil 2 nur der Hund im Trupp ist). Bei mir 5 × grün mit identischem Ergebnis. Nach dem Merge (a67ee77) aus der Quarantäne: Suite zweimal grün mit 87 headless + 14 hook.
- #60 angenommen (Rends Stimme auf dem Voice-Bus, `voice_bus_test` auf der Basis rot, mit Patch 3 × grün). Der Fehler lag in meiner Aufgabe: Roboterzeilen und Durchsagen laufen nicht über `FX.voice()`, sondern über `modules/audio/robot_voice.gd` und spielen weiter auf Master. Folgeaufgabe #92 dafür geschnitten (`robot_voice.gd`, eigener Test `robot_voice_bus_test`); `voice_bus_test` im Manifest eingetragen, Suite 88 headless + 14 hook grün.
- #65 angenommen (arena_gate_integration: alle Positionen aus dem Tor abgeleitet, Tod behält die Geldbörse nach dem Ruling, Altbestands-Cache wird zurückgeholt; 9 Prüfungen, 3 × grün). Nach dem Merge (25241ca) aus der Quarantäne: Suite zweimal grün mit 89 headless + 14 hook. Ändert neVs die Tod-Regel (Nachricht 15, B), ändert sich dieser Test mit.
- #67 und #68 angenommen (persistence_v12_test: getrennte Prüfungen, Alt- und neues Speicherformat; shard_pickup_integration: Geldbörse bleibt, Aufnahme und `pending_shards` werden mitgeprüft). Je 3 × grün bei mir; nach dem Merge (6c9f246, 142c6a8) aus der Quarantäne, Suite zweimal grün mit 91 headless + 14 hook.
- #66 (Aufseher-Test) zur Nacharbeit: RC1–RC4 sind gut gelöst, aber die Prüfung „sichtbare tiefe Klinge im Trefferband“ wurde auf t ≥ 0,15 s verschoben (Höhe ein Bild später) und trifft damit genau das eine Bild, in dem sie besteht. Gemessen: Das Trefferfenster ist 0,075–0,15 s (`enemy.gd:408`), die Klinge steht darin bei 2,1–0,6 m statt 0,2–0,6 m. Die alte Prüfung bleibt, der Test bleibt mit dieser einen roten Prüfung in der Quarantäne. Diagnose: #93 (Spielfehler oder Messfehler, weil der Arm per `SkeletonModifier3D` gestellt wird).
- Ruling: Eine Prüfung, die nur durch verschobene Abtastzeit grün wird, gilt als abgeschwächt, auch wenn die Grenzen gleich bleiben — Maßstab ist der Augenblick, in dem das Spiel den Treffer wertet — Kosten bei Irrtum: ein Testlauf mehr, falls die Diagnose einen Messfehler findet.

**Nacht 06./07.11.:** #69 angenommen (service_return_integration: Aufzug aus `lift_x`, volle Vollendung, Rückweg nach Strecke und Tempo; 3 × grün). Nach dem Merge (9087310) aus der Quarantäne, Suite zweimal grün mit 92 headless + 14 hook. #66 nach Nacharbeit angenommen (f99042d): 32 von 33 Prüfungen grün, nur die tiefe Klinge rot (t 0,117 s, Höhe 1,46 m); der Test bleibt bis #93 in der Quarantäne.
- #61 (Menü-Schriften) zur Nacharbeit: Code und Bild in Ordnung (Screenshots Optionen und Hauptmenü mit und ohne Patch verglichen). Die Herkunft stimmt aber nicht: `Inter-Variable.ttf` passt weder zum Release v4.1 noch zu v4.0 (Name „Inter“, git-66647c0bb, 2926 Glyphen – vermutlich ein Google-Fonts-Build), `JetBrainsMono-Regular.woff2` hat dieselbe Version wie das offizielle Webfont, aber einen anderen Hash; PROVENANCE nennt trotzdem GitHub als Quelle. Verlangt: echte Quelle je Datei, JetBrains Mono als TTF; geht das offline nicht, Rückgabe, dann lege ich die offiziellen Dateien selbst ab.
- Ruling: Fremde Binärdateien (Schriften, Bilder, Klänge) prüfe ich gegen die genannte Quelle (Hash oder Metadaten); eine Herkunftsangabe, die nicht zur Datei passt, ist ein Nacharbeitsgrund, auch wenn Lizenz und Inhalt stimmen — Kosten bei Irrtum: eine Runde mehr pro Asset-Aufgabe.
- #72 angenommen (route_v12_test: 15 Prüfungen, 3 × grün). Nach dem Merge (cc9aeac) aus der Quarantäne, Suite zweimal grün mit 92 headless + 15 hook. Der Mitwirkende bestätigt das Risiko #90 unabhängig: Ein zusätzliches `preload` in einem Hook-Test machte `arm_first_fight` rot.
- #73 angenommen (coolant_test: Roboterarm statt Schwert, Begegnungszahl aus `ENCOUNTERS`; 3 × grün). Nach dem Merge (ccf7fc9) aus der Quarantäne, Suite zweimal grün mit 92 headless + 16 hook.
- #61 nach Nacharbeit angenommen (Code: Inter 600/500 als `FontVariation`, JetBrains Mono für Werte, lädt erst beim Öffnen). Die Herkunft war jetzt ehrlich (Inter aus opencode, JetBrains Mono aus Godots WOFF2 von Hand in TTF umgewandelt), die umgewandelte TTF aber beschädigt (`glyf` kürzer als `loca` erwartet). Ich habe beide Schriften und die OFL-Texte durch die offiziellen Release-Dateien ersetzt (Inter 4.1, JetBrains Mono 2.304, Hashes in `asset_library/fonts/PROVENANCE.md`) und die zwei Zeilen in `CREDITS.md` ergänzt. Bild geprüft, Suite zweimal grün.
- Lehre für Asset-Aufgaben: Die Sandbox der Mitwirkenden hat kein Netz. Dateien, die aus dem Netz kommen müssen (Schriften, Lizenztexte), lege ich künftig vorher selbst ins Repository; die Aufgabe bindet sie nur noch ein.

**Morgen 07.11.:** #79 angenommen (pressure_step_test: Duellant per `encounter_id` mit Revier westlich von Rend, einfacher Brute statt Aufseher, isolierter Hinweisblock, fester Seed; 3 × grün). #80 angenommen (guard_spacing_test und edge_warning_test: Positionen aus `_west_edge()` und `SecurityCover`, Rückzug ab dem Commit gemessen, feste Viewport-Größe; 3 × grün). Gegenproben: Ohne die Sperre gegen doppelte Hinweise (`lab_route.gd:352`) wird „same cue does not repeat“ rot. Ohne den Bodenstrahl (`enemy.gd:1098`) wird „no ground behind prevents retreat“ rot. Nach dem Merge (3bb6e44, 663e50d) sind alle drei aus der Quarantäne. Die Suite war zweimal grün mit 93 headless + 18 hook. In der Quarantäne bleiben zehn Tests.
- #81 angenommen (Fehler S2: Ein Schuss im Flug trifft auch nach der Zerstörung seines Schützen. Jeder Bolzen trägt einen eigenen `Impact`-Knoten mit WeakRef auf den Schützen). Lokal nachgeprüft: auf 9eca8cb mit nur der Fixture-Korrektur rot (3 Fehler), mit dem Patch 3 × grün. Nach dem Merge (0f68742) ist `projectile_lifetime_test` aus der Quarantäne. Die Suite war zweimal grün mit 93 headless + 19 hook. In der Quarantäne bleiben neun Tests.
- #82 angenommen (guard_integration_test: Schmerzstimme `rend_hurt_heavy` statt `ow`, Angriff mit Roboterarm; feedback_priority_integration: Belohnung erst ausstehend, dann abgeholt, die Warnung bleibt; 3 × grün). Gegenprobe: Ohne `FX.voice` in `player.gd:928` wird die Prüfung der Schmerzstimme rot. Nach dem Merge (91139b8) sind beide aus der Quarantäne. Die Suite war zweimal grün mit 94 headless + 20 hook. In der Quarantäne bleiben sieben Tests: brute_commitment_test, duelist_footwork_test, machinery_chamber_integration, overseer_integration (#93), ranged_integration_test (#91), security_pair_test, workbench_integration (#86).
- #83 angenommen (security_pair_test: Auswahl per `encounter_id`, Abstand aus `MISSION.ENCOUNTERS`, Zielpunkt aus `_chest()`, Wächter aus der Sprungbahn; duelist_footwork_test: Messung bei `_recovery_duration()` − 0,02 s, fester hoher Schlag ohne `awakened_blank`; 3 × grün). Nach dem Merge (8ed2e86) sind beide aus der Quarantäne. Die Suite war zweimal grün mit 94 headless + 22 hook. In der Quarantäne bleiben fünf Tests: brute_commitment_test, machinery_chamber_integration, overseer_integration (#93), ranged_integration_test (#91), workbench_integration (#86).
- #84 angenommen (brute_commitment_test: einfacher Brute aus `_make_enemy(0,2)`, HP vor jedem Check gesetzt, neuer Check für den gestützten Aufseher). Gegenprobe: Ohne die Regel in `lab_overseer.gd:99` wird der neue Check rot. #85 angenommen (E11.5b, Pausenmenü: Zeilenreihenfolge, Bestätigungen, Optionen, Hauptmenü; 43 + 18 Checks, 3 × grün). Meine Aufgabe #94 war ein Duplikat von #79 und ist geschlossen; vor dem Schneiden suche ich künftig erst nach offenen Aufgaben für denselben Test.
- `projectile_lifetime_test` ist wieder in der Quarantäne. Im Pipeline-Lauf zu #84 war er einmal rot ('flight still damages after shooter is freed' und 'resolved bolt and handler are freed' zusammen) und beim zweiten Lauf grün. Einzeln war er 10 von 10 Mal grün. Die Diagnose ist #95, weil auch ein echter Spielfehler möglich ist (ein Schuss geht verloren).
- Ruling: Ein Test, der nach dem Weg aus der Quarantäne in der Pipeline auch nur einmal ohne Codeänderung rot wird, geht sofort zurück in die Quarantäne, zusammen mit einer Diagnose-Aufgabe — Kosten bei Irrtum: Der Test prüft bis zur Diagnose nichts.
- #86 angenommen (workbench_integration: Roboterarm und verstärkter Arm, Kosten und Fehltext aus Katalog und Textschlüssel, Basisarm zuerst; 25 Checks, 3 × grün). Nach dem Merge (1623f00, 9606954) sind brute_commitment_test und workbench_integration aus der Quarantäne. Die Suite war zweimal grün mit 96 headless + 21 hook (ein dritter Lauf direkt nach dem Pull blieb ohne Zusammenfassung, vermutlich der bekannte Import-Absturz). In der Quarantäne bleiben vier Tests: machinery_chamber_integration (Entscheidung beim Meilenstein-Review), overseer_integration (#93), projectile_lifetime_test (#95), ranged_integration_test (#91).
- #87 angenommen (E11.4b, Hauptmenü: Reihenfolge, Continue ohne Spielstand übersprungen, Rückfragen, Signale je genau einmal; neuer `start_options_test` für den Weg zu den Optionen und zurück; 3 × grün). Registriert nach dem Merge (c7af4d5); dabei habe ich in `start_options_test` den Schutz gegen echte Nutzerdaten ergänzt (der Test löscht den Spielstand). Die Suite war zweimal grün mit 97 headless + 21 hook.
- #88 angenommen (attack_cue_integration: 'heavy commitment retains warning' mit einem einfachen Brute, der Treffer landet nachweislich; 3 × grün).
- #89 angenommen (ranged_integration_test: zwei Ursachen mit Messwerten belegt, ein zu tief gezielter Schuss und eine nicht abgeschaltete Verstärkung der Route; kein preload; 10/10 grün, arm_first_fight 3/3). #90 angenommen (Roboterzeilen und Durchsagen auf dem Voice-Bus; robot_voice_bus_test ohne Fix rot, mit Fix grün). Nach dem Merge (0fe35d6, 96f4781) ist ranged_integration_test aus der Quarantäne und robot_voice_bus_test registriert. Die Suite war zweimal grün mit 98 headless + 22 hook.
- #91 angenommen (Diagnose #93): Spielfehler. `overseer_low_pose.gd` sucht nur nach `mixamorig_*`-Knochen, das Meshy-Rig des Aufsehers hat kurze Namen, die IK für den tiefen Schlag läuft also nie. Reparatur-Aufgabe #96 (Fallback für die Knochennamen wie in `crouch_pose.gd`).
- In der Quarantäne bleiben drei Tests: machinery_chamber_integration (Meilenstein-Review), overseer_integration (#96), projectile_lifetime_test (#95).

**Rulings (Nachmittag)**
- Ruling: Den Fehler der Fokusleiste behebe ich selbst statt per Aufgabe — er liegt in meiner Basis (Stufe D), und `menu_screen.gd` ist in allen Menü-Aufgaben ausgeschlossen — Kosten bei Irrtum: keine, die Korrektur hat einen eigenen Test.

**Für Playtest und neVs gesammelt (nicht dringend)**
- Aufseher, tiefer Schlag: Auch mit Fix #96 steht die Klinge im Schadensframe (.083 s) noch bei 0,69 m und erreicht Schienbeinhöhe erst bei etwa .133 s (Diagnose #93). Ob der Treffer erst fallen soll, wenn die Klinge sichtbar tief ist, ist eine Frage von Gefühl und Timing. Entscheidung neVs nach dem Playtest.
- Duellant/Schildträger: Der Rückzugsschritt endet bei 0,30 s, die Erholung bei 0,32 s; es bleibt kaum ein Strafzeitfenster nach dem Schritt (Diagnose #36). Balancing, Entscheidung neVs nach dem Playtest.
- Die Wache bei x 40 steht 0,4 m in der Deckung (40,0–41,6) und wird beim Start auf x ≈ 39,6 geschoben (Diagnose #35). Schweregrad S4.
- Alte Spielstände ohne `brute` schalten den Service-Aufzug nach dem Laden nicht frei (Diagnose #24). Schweregrad S3.

**Als Nächstes (Lead):** E11.4–E11.9 als B-Aufgaben schneiden (Hauptmenü, Pause, Credits auf `MenuScreen`); Drehbuch-Varianten #9/#10 bewerten.

## 30.10.2026 (Lead-Session 1)

**Lage:** Interview abgeschlossen, Brief in Runden 2–3 geschärft und von neVs bestätigt. Zehn Level-A-Aufgaben (Bestiarium, Comic-Stil, Comic-Drehbuch) sind offen. Das Fundament für Code-Aufgaben steht noch nicht: 28 Tests in Quarantäne, `lab_route.gd` als Monolith, kein Durchlauf-Test.

**Tests:** 77/77 headless grün (dash_visual_test aus der Quarantäne geholt); `swarvex env` grün ohne Netzwerk. Quarantäne: 27 Tests, sortiert in `docs/test-triage.md` (9 veraltet/Harness, 16 Diagnose, 2 gemischt).

**Risiken**
- Kernsysteme M1 (Boss, Arena, Speichern, guards) ohne gültige Tests.
- Streckenlänge unbekannt (S23), bis Playtests vorliegen.
- Art Bible (`docs/art/art_bible_p02_v01`) ist teils veraltet (Schwert, menschliche Gegner); Palette geklärt (S9: Petrol/Kupfer, Amber nur Warnung).

**Wartet auf neVs**

- Push der Commits vom 30.10. nachmittags (Runner, Triage, Klarstellungen).

**Aufgaben offen:** #1–#10 (Bestiarium, Comic), #11–#19 (B: veraltete Tests/Harness), #20–#37 (A: Diagnosen), #38–#40 (A: Grundpaket E11), #43 (Ersatz für #2), #44–#48 (A: Gate-Dokumente mit Rolle: UX-Spec, Sound Bible ×2, Story-Gerüst, Art Bible). Geschlossen: #2, #41, #42 (siehe Audit). **Fehler Lead (behoben 30.10.):** #38 war durch einen falschen Parameter an einem versehentlich angelegten Meilenstein „1“; die Plattform hat #38 nach M1 verschoben und „1“ gelöscht. `create_task` lehnt unbekannte Meilensteine jetzt ab.

**Vision:** neVs hat `docs/vision.md` am 30.10. bereinigt. AGENTS.md und Brief G14: Änderungen nur durch den Visionär.

**Grundpaket (Runde 4, 30.10.):** alle 29 Bausteine eingeordnet (Brief „Grundpaket“, S24); Epic E11 geplant. Sofort offen: Menü-Stilguide (2 Varianten), CHANGELOG, SECURITY.md, Issue-Template. Der Referenz-Menübildschirm (E11.2) folgt nach der Stilguide-Wahl und F3.

**Als Nächstes (Lead):** Einreichungen prüfen; F3 Route-Daten und Texttabelle, F4 Durchlauf-Test, F6 Architektur; danach E11.2.

**Korrekturen des Leads:** duelist/brute sind Bausteine von shield bearer/overseer (Code bleibt M1); item catalog ist M1-Ausrüstung, eingefroren sind nur servo trial und prefix ledger.

## Aufgaben-Audit (30.10.2026)

Alle offenen Aufgaben geprüft gegen bereinigte Vision, Brief mit Grundpaket, LEAD.md 1.4 und Plan/F3. Kein Reset (Entscheidung neVs). Ergebnis: von #1–#40 bleiben 39, #2 wird ersetzt (#43); dazu #41 und #42 geschlossen (Entscheidung neVs). Offen jetzt: 40 Aufgaben.

| Aufgabe | Urteil | Grund |
|---|---|---|
| #1, #3–#6 Bestiarium | passt | M1-Roboter, Code-Stand stimmt; Basis-Commit 3b3f444 gültig |
| #2 Bestiarium Schildträger | geschlossen, ersetzt durch #43 | beschrieb ihn als „Wache mit Schild“; im Code `role 1` mit eigenen Zeiten (Ausholen 0,40 s) und Schrittfolge |
| #7–#10 Comic-Stilguide, Intro-Skript | passt | S17/S22 M1; Vision-Abschnitte „Geschichte“, „Comic“ bestehen nach der Bereinigung |
| #11–#19 veraltete Tests, Harness (B) | passt | nur Testdateien, vor F3 gewollt; Hinweis in #18 (Runner erkennt nur doppelte Anführungszeichen) geprüft |
| #20–#37 Diagnosen (A) | passt | reine Berichte; #22 deckt zusätzlich G-7 (kaputte Speicherdatei) ab |
| #38, #39 Menü-Stilguide | passt | E11.1 |
| #40 CHANGELOG | passt | B4 |
| #41 SECURITY.md | geschlossen | erfüllt durch Organisations-Standard swarvex-ai/.github |
| #42 Bug-Formular | geschlossen | nach v1 verschoben; bis dahin allgemeines Formular aus swarvex-ai/.github; Backlog-Eintrag |
| #43 Bestiarium Schildträger (neu) | neu | Ersatz für #2 |

Nebenbei korrigiert: Glossar „shield bearer“ (war „guard with a shield“).
