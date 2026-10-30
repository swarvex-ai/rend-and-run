# Projektbrief: Rend&Run

> Ergebnis des Projekt-Interviews (swarvex LEAD.md, Phase 0). Aufgaben für den Schwarm entstehen erst, wenn neVs den Brief bestätigt.
> Stand 30.10.2026 · Interview-Runden: 3 (Runde 1 am 28.10., Runden 2–3 „Roast“ am 30.10.2026) · Runde 1 bestätigt von neVs am 28.10.2026 („alles ja“) · **Runde 3 am 30.10.2026 · **Brief neu zu bestätigen****

Rend&Run ist kein neues Projekt: Vision, GDD und 24 Tage Entwicklung liegen vor. Der Lead hat deshalb nur Lücken abgefragt (G13) und alles andere aus dem Bestand vorgeschlagen.

## Entscheidungen

| ID | Entscheidung | Ergebnis | Stand | Runde | Quelle |
|---|---|---|---|---|---|
| G1 | Typ | Spiel | entschieden | – | Vision |
| G2 | Kern in einem Satz | siehe unten | Empfehlung angenommen | 1 | Vision, GDD §1 |
| G3 | Zielgruppe | PC-Spieler von Action-Metroidvanias, Gamepad, Sitzungen 20–60 min | Empfehlung angenommen | 1 | GDD §3, §5 |
| G4 | Säulen | siehe unten (5) | Empfehlung angenommen | 1 | Vision, Playtests |
| G5 | Nicht-Ziele | siehe unten | Empfehlung angenommen | 1 | GDD §6, aktualisiert |
| G6 | Erfolgskriterien v1 | Meilenstein 1 = Fluchtstrecke M1; messbar: (a) automatischer Durchlauf Start→Schleuse ohne Absturz, (b) Erstdurchlauf 9–11 min (Playtest neVs + 2 Fresh-Eyes-Playtests), (c) Retry < 10 s, (d) Tastatur und Gamepad vollständig, (e) 1080p/60 fps auf Referenz-Hardware (G21), (f) 0 rote, 0 wackelnde, 0 quarantänierte M1-Tests; danach Abnahme durch neVs | Empfehlung angenommen | 2 (F2) | Roast 30.10. |
| G7 | Plattformen | Linux und Windows (Desktop); Windows-Nachweis für M1: Export baut fehlerfrei + Smoke-Test auf echtem Windows (Level-A-Aufgabe) | Empfehlung angenommen | 1, 3 (Q6) | GDD §2 (Linux) |
| G8 | Engine / Sprache | Godot 4.7, GDScript (typisiert) | entschieden | – | Bestand |
| G9 | Lizenz | Code GPL-3.0-or-later, Assets CC BY-SA 4.0, Name/Logo bei neVs | delegiert | – | `docs/open-source/freigabe-pruefung.md` |
| G10 | Projektsprache | Aufgaben und Code Englisch, Vision/Design vorerst Deutsch; Spieltexte Englisch, Umstellung (Texte als Datentabelle) ist Teil von M1 | Empfehlung angenommen | 1, 2 (F10) | Roboterstimmen sind englisch |
| G11 | Qualitätsstufe | Indie, poliert im Gefühl, nicht im Umfang | Empfehlung angenommen | 1 | Combat-Feel-Richtung |
| G12 | Referenzen | siehe unten | entschieden | – | GDD §5, neVs |
| G13 | Bestand | Repo, 76 Headless-Tests grün (30.10.), dazu 11 Fenster-Tests, 28 in Quarantäne; Meshy-Bibliothek, Design-Docs | erhoben | – | Prüfbericht, Testlauf 30.10. |
| G14 | Unantastbar | Vision-Text, Held Rend, Fabrik-Setting, Gamepad-first, Steuerungsgefühl | Empfehlung angenommen | 1 | |
| G15 | Ressourcen | 3–10 aktive Agenten zum Start; 100 Meshy-Credits je Meilenstein ohne Rückfrage | Empfehlung angenommen | 1 | Frage 6 |
| G16 | Barrierefreiheit | M1 Pflicht: Untertitel für Durchsagen, Zeitlupe abschaltbar, Bildschirmwackeln abschaltbar, Alarmlicht ≤ 3 Hz; frei belegbare Tasten nach M1 | Empfehlung angenommen | 3 (Q5) | |
| G17 | Datenschutz | keine Nutzerdaten, kein Netzwerk im Spiel | Empfehlung angenommen | 1 | |
| G18 | Veröffentlichung | nach Abnahme M1 kostenloser Pre-Alpha-Slice (Linux, Windows) auf itch.io, auch zur Anwerbung; Zeitpunkt bestimmt neVs | Empfehlung angenommen | 3 (Q8) | |
| G19 | Einnahmen | kostenlos | Empfehlung angenommen | 1 | Frage 7 |
| G20 | Rolle neVs | Kreativdirektor: Playtest und Abnahme jedes Meilensteins, Designfragen gehen an neVs | Empfehlung angenommen | 1 | CLAUDE.md |
| S1 | Genre / Perspektive | 2,5D-Action-Plattformer, Seitenkamera, Tiefenbewegung in Gassen | entschieden | – | GDD §2, Playtests |
| S2 | Kernschleife | 10 s: ausweichen, zuschlagen, Waffe greifen · 1 min: Raum freikämpfen oder durchrennen · 10 min: Sektor entkommen, Beute sichern | Empfehlung angenommen | 1 | Scope-Doku |
| S3 | Steuerung | Gamepad primär, Tastatur vollständig | entschieden | – | GDD §3 |
| S4 | Fortschritt | Hollow-Knight-Modell mit Kontrollpunkten, Splitter als Todeswährung | entschieden | – | GDD §4 |
| S5 | Gefühl | Dead Cells als Maß: Eingabe → Reaktion ≤ 100 ms, Treffer mit Hit-Stop, Gefahr vorher lesbar | entschieden | – | Combat-Feel-Richtung |
| S7 | Umfang v1 | eine Fluchtstrecke, 6 Robotertypen (S13), 6 Waffen (S14), 1 Druck-Task (S16), Comic-Vorspann (S17) | Empfehlung angenommen | 1, 2 | Roast 30.10. |
| S8 | Inhalte als Daten | Waffen, Gegnerwerte, Durchsagen, Rätsel | Empfehlung angenommen | 1 | Frage 9 |
| S9 | Asset-Stil | Meshy-3D, glattes modernes Lab; Grundfarben Petrol und Kupfer (Art Bible §2), Amber nur als Warn-/Telegraph-Farbe (#F2B05E) | entschieden | 1, 3 | Vision, Art Bible, neVs 30.10. |
| S12 | Mehrspieler | nein | entschieden | – | GDD §6 |
| G21 | Referenz-Hardware | Playtest-PC neVs: AMD Ryzen 7 5800X3D, Radeon RX 6800-Klasse (Navi 21), 32 GB RAM, Linux; Grund: fps-Kriterien sind nur auf einer festen Maschine prüfbar; untere Grenze erst nach M1 | entschieden | 3 (Q1) | |
| S10 | Verbindliche Strecke | `docs/milestone-1.md` (neu, aus Code-Stand V12); `scope-first-route.md` und GDD §2/§6 als historisch markiert | Empfehlung angenommen | 2 (F1) | |
| S13 | Robotertypen v1 | Pflicht und poliert: guard, shield bearer, sentinel, dog, Kamikaze-drone, overseer (Boss); welder = Falle; duelist und brute keine eigenen Platzierungen, ihr Code bleibt Teil von M1 (shield bearer = duelist + Schild, overseer baut auf brute auf; Präzisierung 30.10.); Schwarm, Fahrroboter, Festnahme später | Empfehlung angenommen | 2 (F4) | |
| S14 | Waffen v1 | Roboterarm, Pistole, MP, Streugewehr, Energiegewehr, Schild; werfbare Kisten; Werkbank-Mods bleiben; Granaten später | Empfehlung angenommen | 2 (F5) | |
| S15 | Farming v1 | nur Splitter, Todes-Cache, Werkbank-Mods; restliches Farming (servo trial, prefix ledger) eingefroren; item catalog ist M1-Ausrüstung (Präzisierung 30.10.) bis M1-Abnahme; Farming-Baum = Thema M2 | Empfehlung angenommen | 2 (F6) | |
| S16 | Druck-Task v1 | genau eine Kopfrechenaufgabe an einer Tür; Ankündigung Ton+Licht, ≥ 10 s, sichtbarer Countdown, einstellige Rechnungen; Scheitern = Tod, Kontrollpunkt direkt davor; Rätsel später | Empfehlung angenommen | 2 (F7) | Vision |
| S17 | Comic-Vorspann v1 | ≤ 6 Bilder, ≤ 60 s; beim ersten Start nicht überspringbar, danach schon; Einblendungen im Spiel später | Empfehlung angenommen (Abweichung vom Wortlaut der Vision bewusst bestätigt) | 2 (F8) | Vision |
| S19 | Kontrollpunkte M1 | zwei (x = 26 m, Relay x = 58 m); Druck-Task-Tür direkt hinter Relay, Tod dort kostet ≤ ~20 s | Empfehlung angenommen | 3 (Q2) | Code V12 |
| S20 | Schwierigkeit | Ziel 2–5 Tode im Erstdurchlauf, Boss härteste Stelle, ein Schwierigkeitsgrad; Messung in den Playtests aus G6 | Empfehlung angenommen | 3 (Q3) | |
| S21 | Boss overseer | Code-Stand (2 Phasen, Phase 2 ≤ 50 % HP) als Vertrag; jeder Schlag ≥ 0,5 s angekündigt (Licht + Ton); Erstsieg 60–150 s | Empfehlung angenommen | 3 (Q4) | Code V12 |
| S22 | Comic-Herstellung | erst Comic-Stilguide (Level A), dann Asset-Brief zweistufig (Vorschau → Freigabe neVs → Final); Werkzeug frei mit Herkunftsnachweis; ≤ 60 der 100 M1-Credits | Empfehlung angenommen | 3 (Q7) | |
| S23 | Streckenlänge | vor dem Inhaltsschnitt misst neVs einen Durchlauf (Zeit, Tode); < 9 min → Strecke verlängern ist erster Inhaltsblock, > 11 min → kürzen | Empfehlung angenommen, **Messung ausstehend** | 3 (Q9) | |
| S18 | Festnahme | nicht in v1; Roboter töten nur; kommt mit dem Twist | Empfehlung angenommen | 2 (F9) | Vision |

Die folgenden Abschnitte fassen die Tabelle lesbar zusammen; bei Widerspruch gilt die Tabelle.

## In einem Satz

Rend, ein KI-Forscher, wacht in einer Fabrik der Humanoiden auf und muss sich mit dem, was er findet, an Robotern vorbei, durch Fallen und Druckaufgaben, in die Freiheit kämpfen; ein schnelles, brutales 2,5D-Actionspiel, in dem nur Rend blutet.

## Säulen

1. **Flucht unter Druck:** Stillstand ist gefährlich, die Fabrik reagiert (Alarm, Verstärkung, Durchsagen). Merkt man daran, dass Spieler weiterlaufen, statt Räume leer zu farmen.
2. **Lesbare Gefahr:** Jeder Angriff, jede Falle kündigt sich an (Warnsymbol, Licht, Ton). Merkt man daran, dass jeder Tod sich verdient anfühlt.
3. **Wuchtiger Kampf:** Treffer haben Gewicht, Roboter zerfallen in Teile. Merkt man an Hit-Stop, Trümmern, Ton.
4. **Improvisieren statt Arsenal:** Rend nutzt, was die Fabrik hergibt: Roboterarm, Kisten, Waffen der Gegner, Schilde. Merkt man daran, dass jede neue Waffe aus der Welt kommt.
5. **Eine glaubwürdige Fabrik:** glattes, modernes Lab, Serverbrummen hinter Türen, Roboter mit Funktion. Merkt man daran, dass Räume einen Zweck erkennen lassen.

## Nicht-Ziele

- keine offene Welt und kein prozedurales Level-Generieren
- kein Mehrspieler, kein Koop
- kein Crafting-Menü, kein Dialogsystem (Erzählung über Comic-Einblendungen, Durchsagen, Umgebung)
- kein Permadeath
- kein Gore an Robotern (Roboter zerfallen, bluten nicht)

GDD §6 „keine Schusswaffe für Rend“ ist überholt: neVs hat am 23.10. Schusswaffen eingeführt.

## Referenzen

| Referenz | übernehmen | nicht übernehmen |
|---|---|---|
| Dead Cells | Tempo, Kampfgefühl, Treffer-Feedback | Roguelike-Struktur |
| Shadow Complex | 2,5D-Seitenansicht, verbundene Map, Fähigkeiten öffnen Wege | Militär-Setting |
| Hollow Knight | Kontrollpunkte, Todeswährung | 2D-Handzeichnung |
| Figure, Boston Dynamics, Optimus, Unitree | Anmutung realer Humanoide | Namen und erkennbare Produktdesigns (deshalb heißt der Alkoven-Gegner „Sentinel“, nicht „Atlas“) |

## Ressourcen

- Schwarmgröße zum Start: 3–10 Agenten, Lead Claude
- Asset-Bedarf: Animationen (Ersatz der Meshy-Bibliothek), Gegnermodelle, Fabrik-Kit, Soundeffekte
- Spendenbudget je Meilenstein: 100 Meshy-Credits ohne Rückfrage, darüber fragt der Lead

## Interview Runde 1 (beantwortet 28.10.2026: alle Empfehlungen angenommen)

1. **Kern (G2):** Passt der Satz oben?
2. **Säulen (G4):** Die fünf Säulen so? Wenn eine fehlt oder zu viel ist, sag welche.
3. **Plattformen (G7):** Linux und Windows. Empfehlung: ja, Windows kostet uns nur einen Export-Test.
4. **Sprache (G10):** Aufgaben, Code und Spieltexte Englisch, Vision und Design-Docs bleiben vorerst Deutsch. Empfehlung: ja, weil Beitragende weltweit und ihre Modelle Englisch am besten können.
5. **Version 1 (G6, S7):** v1 ist die erste Fluchtstrecke als Vertical Slice mit ~6 Robotertypen und ~6 Waffen, abgenommen von dir. Empfehlung: ja.
6. **Spendenbudget (G15):** Wie viele Meshy-Credits darf ich je Meilenstein ohne Rückfrage für Spenden-Aufträge einplanen? Empfehlung: 100 Credits; alles darüber frage ich.
7. **Einnahmen (G19):** Rend&Run bleibt kostenlos. Empfehlung: ja, das passt zur offenen Lizenz und zum Pilot.
8. **Unantastbar (G14):** Vision-Text, Held Rend, Fabrik-Setting, Gamepad-first und das Steuerungsgefühl ändern Beitragende nie. Empfehlung: ja; Änderungen daran gehen nur über dich.
9. **Inhalte als Daten (S8):** Beitragende sollen Waffen, Gegnerwerte, Durchsagen und Rätsel als Daten ergänzen können, ohne Code anzufassen. Empfehlung: ja, das ist die wichtigste Erweiterungsstelle für einen Schwarm.
10. **Deine Rolle (G20):** Du spielst jeden Meilenstein und nimmst ihn ab, Designfragen kommen gebündelt zu dir; Code-Reviews und Aufgabenschnitt mache ich. Empfehlung: ja.

## Interview Runde 2 „Roast“ (30.10.2026: F1–F10 Empfehlungen angenommen)

F1 verbindliche Strecke (S10) · F2 messbare Fertig-Kriterien (G6) · F3 Referenz-Hardware (G21) · F4 Robotertypen (S13) · F5 Waffen (S14) · F6 Farming eingefroren (S15) · F7 Druck-Task (S16) · F8 Comic-Vorspann (S17) · F9 keine Festnahme in v1 (S18) · F10 Spieltexte Englisch in M1 (G10).

Korrekturen durch den Lead: G13 Testzahl präzisiert. Offen: Verweis in G9 auf `docs/open-source/freigabe-pruefung.md`, die Datei fehlt im öffentlichen Repo.

## Interview Runde 3 (30.10.2026: Q1 entschieden, Q2–Q9 Empfehlungen angenommen)

Q1 Referenz-Hardware (G21) · Q2 Kontrollpunkte (S19) · Q3 Schwierigkeit (S20) · Q4 Boss (S21) · Q5 Barrierefreiheit (G16) · Q6 Windows (G7) · Q7 Comic-Herstellung (S22) · Q8 Veröffentlichung (G18) · Q9 Streckenlänge (S23, Messung durch neVs ausstehend).
