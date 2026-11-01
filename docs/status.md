# Status

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
