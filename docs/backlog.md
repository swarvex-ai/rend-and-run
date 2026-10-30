# Backlog Rend&Run

Stand 2026-10-23. Ersetzt das Hermes-Kanban (Board `gamedev`), das nicht mehr gepflegt wird.
Erledigte Karten wurden dort geschlossen bzw. archiviert; alles Offene steht hier.
Quelle der Vision: `docs/vision.md`. Prioritäten setzt neVs, Reihenfolge innerhalb einer Gruppe ist ein Vorschlag.

Format: `- [ ] Titel — Kurzbeschreibung (alte Kartennummer)`. Erledigtes wird abgehakt und mit Commit versehen,
dann beim nächsten Aufräumen entfernt.

## Laufende Runde (neVs, 23.10.2026)

- [x] Kisten beweglich: Rend hebt sie auf und wirft sie (Wurf trifft Roboter) — 9eb1aae
- [x] Schusswaffen aus Meshy (Pistole, MP, Streugewehr, Energiegewehr) für Humanoide und Rend; Rend sammelt Waffen besiegter Humanoider auf und nutzt sie — dd6c007
- [x] Drohnen greifen an: Kamikaze-Sturzflug mit Explosion — 7646eda
- [x] Vierbeiner: sichtbare Trefferreaktion, Tod als Ragdoll statt Umkippen — 7646eda
- [x] Atlas-artiger Humanoid mit Lichtring: tritt aus Nischen/Gängen im Hintergrund, leuchtet auf, wenn Rend vorbeirennt — f9871b3
- [x] Vordergrund-Silhouetten (Rohre, Kabel) für Tiefe; Montageband auch über den Gang

## Erledigt 24.10.2026 (wartet auf Playtest)

- [x] Tempo, Alarm-Einstieg, Trupp-KI (Funk, Zange, Takt), Schildträger, Verstärkung — 959170f
- [x] Roboterstimmen + Durchsagen, Klettern/Überholen, Waffenslots 1–4, Schild aufnehmen — 89be477
- [x] Schweißroboter, Überwachungskameras, erwachender Rohling, Schuss-/Schadenseffekte, Zeitlupe — c7d4341

## Als Nächstes

- [ ] Weitere Durchsagen/Sprüche nach Playtest; Stimmen evtl. stärker verfremden
- [ ] Panzertür-Lockdown hinter Rend in einem späteren Sektor (bewusst noch nicht gebaut: Rückweg/Checkpoint-Logik)

- [ ] Fenster-Tests (window) neu laufen lassen, sobald die Anzeige wieder verfügbar ist (23.10. abends nicht möglich)
- [ ] Rends Waffenhaltung verfeinern (Waffe sitzt in Hüfthöhe statt im Anschlag, wenn er nicht schießt); Munition im HUD hervorheben

- [ ] Ruhigere Kampfhaltung für Rend — aktueller Idle schwankt und dreht sich
- [ ] Warnsymbole pro Schlag — Seitwärts / von oben / Aufwärtshieb / Stoß statt nur hoch/tief/schwer, damit die Gegenmaßnahme lesbar ist
- [ ] Balancing nach Einführung der Tiefenbewegung und der vier Schläge
- [ ] Rend-Animationen: Armgriff beim Treffer, Interaktionen (P40; Ducken erledigt)
- [ ] Bewegung und Kamera weiter polieren: Run/Stop/Turn/Jump messen und glätten (P05)

## Gegner

- [ ] Mini-Drohnen-Schwarm und fahrender Roboter (Epic GEGNER)
- [ ] Gepanzerter Festnahme-Wächter — Brute-Chassis existiert, Festnahme-Verhalten fehlt (P16)
- [ ] Roboter-KI-Vertrag: Patrol/Alert/Chase/Attack/Recover/Search/Death, Festnahme (P14)
- [ ] Begegnungen schrittweise in die Route integrieren (P18)
- [ ] Roboter-Aufseher als Boss: Konzept, Modell, Rig, mechanischer Tod (P28, P29)
- [ ] Bestiarium: eine Seite pro Robotertyp (Verhalten, Waffen, Schwachstellen, Beute, Sound, Zone)
- [ ] Festnahme-Mechanik als Game-Over-Variante entwerfen (Flucht-QTE oder Ressourcenabgabe)

## Kampf und Arsenal

- [ ] Kampfvertrag Roboterarm: Schlagbahnen, Gewicht, Waffenwechsel (P06)
- [ ] Armfund, Waffenwechsel und erste Ausrüstungsbelohnung (P21)
- [ ] Waffen- und Gear-Datenmodell, an Farming-Baum angebunden (P19)
- [ ] Folgewaffe: industrieller Bolzenwerfer (P20)
- [ ] Waffen-Tier-Leiter v0–vN inkl. Schusswaffen und Granaten (max. ~12 Waffen + 3 Granaten)
- [ ] Special-Gear-Baum: Panzerung aus Roboterteilen, Endgame-Begleitdrohne

## Welt und Level

- [ ] Erste Fluchtstrecke als Vertical Slice durchgängig verbinden (P30)
- [ ] Zonen-Schema und Levelfluss dokumentieren (Montagehalle, Serverräume, Logistik, Prüfparcours, Quarantäne)
- [ ] Modernes Fabrik-Kit: Böden, Wände, Decken, Türen (P08) und Integration mit Kollisionen und Gegnerwegen (P09)
- [ ] Fabrik-Hintergründe mit Tiefenstaffelung (P10)
- [ ] Wiederverwendbare Props: Lampen, Server, Behälter (P12) und Türen/Interaktionen (P13)
- [ ] Orientierung und erkundete Räume (P38)
- [ ] Nächster Sektor: Auswahl, Erweiterungskit, Integration (P33, P34, P35) — erst nach Slice-Freigabe
- [ ] Spätere Traversal-Erweiterungen (Ledge-Grab, Wall-Jump) nur bei Bedarf (P37)

## Rätsel und Druck-Tasks

- [ ] Rätsel-Katalog mit Schwierigkeitskurve (Farben, Zahlen, Logik, Kabel, Timing)
- [ ] Druck-Task-System: Timer-Aufgaben unter Lebensgefahr, Fairness-Regeln

## Erzählung

- [ ] Comic-Stil-Guide (Palette, Strich, Fonts)
- [ ] Episodenplan E0–E6 und Timing im Spielfluss
- [ ] Twist-Dokument: Parcours und Menschen als KI-Datenfutter

## Sound

- [ ] Audio-Paket: Servos, Metall, Waffen, Serverräume (P24)
- [ ] Raumabhängiges Serverbrummen und Audiomix mit Bussen (P25)

## Farming (später, Design steht)

Kanonisch: `docs/design/farming-design-v02.txt`, `docs/design/farming-tree-v02.json`.

- [ ] Loot, Gear und Verlustregeln vollständig umsetzen (P39; Servo-Teilumsetzung vorhanden)

## Technik, HUD, Release

- [ ] v1: spielspezifisches Bug-Formular `.github/ISSUE_TEMPLATE/bug_report.yml` (Version, OS, Eingabegerät, Zone, Spielstand-Datei, Log-Ort `user://logs`); ersetzt dann das allgemeine Formular aus swarvex-ai/.github (Brief B7; Entwurf in geschlossener Aufgabe #42)

- [ ] HUD: Ausrüstung, Munition, Rätsel (P26)
- [ ] Savegame: Fabrikfortschritt, Ausrüstung, Respawn (P27)
- [ ] Slice-Regression und gemessene Performance, Ziel 1080p/60 fps (P31)
- [ ] Nutzer-Playtest und Freigabe des Slice (P32)
- [ ] Demo-Build, Credits, reproduzierbarer Export (P36)
- [ ] Asset-Namenskonvention und Bibliotheksplan festschreiben
- [ ] `hud_integration_test` wackelt im Gesamtlauf (7 Checks rot, einzeln dreimal grün) — Timing unter Last stabilisieren
