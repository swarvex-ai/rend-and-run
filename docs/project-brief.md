# Projektbrief: Rend&Run

> Ergebnis des Projekt-Interviews (swarvex LEAD.md, Phase 0). Aufgaben für den Schwarm entstehen erst, wenn neVs den Brief bestätigt.
> Stand 28.10.2026 · Interview-Runden: 1 (aus Vision, GDD, Backlog und Playtest-Kommentaren) · **bestätigt von neVs am 28.10.2026** („alles ja“)

Rend&Run ist kein neues Projekt: Vision, GDD und 24 Tage Entwicklung liegen vor. Der Lead hat deshalb nur Lücken abgefragt (G13) und alles andere aus dem Bestand vorgeschlagen.

## Entscheidungen

| ID | Entscheidung | Ergebnis | Stand | Runde | Quelle |
|---|---|---|---|---|---|
| G1 | Typ | Spiel | entschieden | – | Vision |
| G2 | Kern in einem Satz | siehe unten | Empfehlung angenommen | 1 | Vision, GDD §1 |
| G3 | Zielgruppe | PC-Spieler von Action-Metroidvanias, Gamepad, Sitzungen 20–60 min | Empfehlung angenommen | 1 | GDD §3, §5 |
| G4 | Säulen | siehe unten (5) | Empfehlung angenommen | 1 | Vision, Playtests |
| G5 | Nicht-Ziele | siehe unten | Empfehlung angenommen | 1 | GDD §6, aktualisiert |
| G6 | Erfolgskriterien v1 | erste Fluchtstrecke (Vertical Slice) spielbar und von neVs abgenommen | Empfehlung angenommen | 1 | Backlog P30–P32 |
| G7 | Plattformen | Linux und Windows (Desktop) | Empfehlung angenommen | 1 | GDD §2 (Linux) |
| G8 | Engine / Sprache | Godot 4.7, GDScript (typisiert) | entschieden | – | Bestand |
| G9 | Lizenz | Code GPL-3.0-or-later, Assets CC BY-SA 4.0, Name/Logo bei neVs | delegiert | – | `docs/open-source/freigabe-pruefung.md` |
| G10 | Projektsprache | Aufgaben und Code Englisch, Vision/Design vorerst Deutsch; Spieltexte Englisch | Empfehlung angenommen | 1 | Roboterstimmen sind englisch |
| G11 | Qualitätsstufe | Indie, poliert im Gefühl, nicht im Umfang | Empfehlung angenommen | 1 | Combat-Feel-Richtung |
| G12 | Referenzen | siehe unten | entschieden | – | GDD §5, neVs |
| G13 | Bestand | Repo, 76 Tests, Meshy-Bibliothek, Design-Docs | erhoben | – | Prüfbericht |
| G14 | Unantastbar | Vision-Text, Held Rend, Fabrik-Setting, Gamepad-first, Steuerungsgefühl | Empfehlung angenommen | 1 | |
| G15 | Ressourcen | 3–10 aktive Agenten zum Start; 100 Meshy-Credits je Meilenstein ohne Rückfrage | Empfehlung angenommen | 1 | Frage 6 |
| G16 | Barrierefreiheit | vorläufig: frei belegbare Tasten, Untertitel für Durchsagen, Zeitlupe abschaltbar | offen | – | spätere Runde |
| G17 | Datenschutz | keine Nutzerdaten, kein Netzwerk im Spiel | Empfehlung angenommen | 1 | |
| G18 | Veröffentlichung | itch.io, Zeitpunkt entscheidet neVs | offen | – | spätere Runde |
| G19 | Einnahmen | kostenlos | Empfehlung angenommen | 1 | Frage 7 |
| G20 | Rolle neVs | Kreativdirektor: Playtest und Abnahme jedes Meilensteins, Designfragen gehen an neVs | Empfehlung angenommen | 1 | CLAUDE.md |
| S1 | Genre / Perspektive | 2,5D-Action-Plattformer, Seitenkamera, Tiefenbewegung in Gassen | entschieden | – | GDD §2, Playtests |
| S2 | Kernschleife | 10 s: ausweichen, zuschlagen, Waffe greifen · 1 min: Raum freikämpfen oder durchrennen · 10 min: Sektor entkommen, Beute sichern | Empfehlung angenommen | 1 | Scope-Doku |
| S3 | Steuerung | Gamepad primär, Tastatur vollständig | entschieden | – | GDD §3 |
| S4 | Fortschritt | Hollow-Knight-Modell mit Kontrollpunkten, Splitter als Todeswährung | entschieden | – | GDD §4 |
| S5 | Gefühl | Dead Cells als Maß: Eingabe → Reaktion ≤ 100 ms, Treffer mit Hit-Stop, Gefahr vorher lesbar | entschieden | – | Combat-Feel-Richtung |
| S7 | Umfang v1 | eine Fluchtstrecke, ~6 Robotertypen, ~6 Waffen, 1 Druck-Task-Art | Empfehlung angenommen | 1 | Scope-Doku |
| S8 | Inhalte als Daten | Waffen, Gegnerwerte, Durchsagen, Rätsel | Empfehlung angenommen | 1 | Frage 9 |
| S9 | Asset-Stil | Meshy-3D, glattes modernes Lab, Amber-Akzente | entschieden | – | Vision |
| S12 | Mehrspieler | nein | entschieden | – | GDD §6 |

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
