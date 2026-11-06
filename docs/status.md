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

**Für Playtest und neVs gesammelt (nicht dringend)**
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
