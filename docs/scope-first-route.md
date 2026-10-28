# Rend&Run — Spielumfang und erste 10-Minuten-Strecke (P01)

> Status: **Arbeit konkretisiert (01.10.26)** gemäß Produktionsplan P01 (`t_d8af4365`).
> Alles in diesem Dokument ist Arbeitsfassung mit Abnahmepflicht: neVs nickt am
> Playtest-Gate P32 ab (Designhoheit bleibt bei neVs, vgl. `docs/gdd.md`).
> **Bindend bleibt das GDD:** persistente verbundene Welt, Erkundung,
> Fähigkeits-Gating, Todeswährung, Kontrollpunkte. Die 10-Minuten-Strecke ist der
> **erste Produktionsmeilenstein**, keine Umdefinition zum linearen Spiel — sie ist
> der erste begbare Ausschnitt der späteren zusammenhängenden Lab-Welt und wird
> von P33 (zweites Gebiet) nahtlos weiterconnected, nicht weggebaut.

## 1. Genre-Paket (Konkretisierung GDD §1–§5)

| Achse | Festlegung |
|---|---|
| Setting | **Düstere Sci-Fi**: verlassenes, teilzerstörtes Forschungslabor („N-Labor", Arbeitstitel). KI-Beleuchtung, Blitze, Nebel, kaputte Terminals; keine Fantasy-Elemente. |
| Held | **Rend** — menschlicher Nerd mit Brille (Kontrast zur Metzlei), corpo-anonyme Labor-Kleidung; Startwaffe: **Schwert** (Nahkampf, brutal, Trefferfeedback mit Biss gemäß GDD §2). |
| Gegner | **Humanoid**: Labor-Personal/Wärter, mutiert oder augmentiert (Chaser, Wächter, Suppressor — siehe P15–P17). Keine Tier-/Kreatur-Gegner im Meilenstein 1. |
| Perspektive | **2,5D-Side-Scroller** (GDD §2): 3D-Welt/Modelle, starre Seitenkamera; Leitreferenz Shadow Complex (GDD §5). |
| Kernschleife | **Erkunden → Kämpfen → Upgrade → Abkürzung**: Abschnitt erkunden und Splitter verdienen → Gegner besiegen → Splitter/Fähigkeit am Kontrollpunkt ausgeben → neue Wege/Abkürzen öffnen sich → tiefer erkunden. Eine Schleife ≈ 3–6 Minuten. |

## 2. Todeswährung und Kontrollpunkte (Produktionsnamen, Arbeitstitel)

- **Splitter** = laufende Sammelwährung (leuchtende Daten-/Reaktor-Splitter aus
  Kisten, Fässern, Gegnern). Ausgeben am **Kiosk** des Kontrollpunkts
  (Heilung + Upgrade-Angebot; GDD §4).
- Tod: Splitter fallen an der Todesstelle ab, **einmalig zurückholbar** (GDD §4).
  Regel für erneuten Tod vor Rückholung (Kontrakt für P39): der **jüngste** Haufen
  ersetzt den alten — genau ein aktiver Haufen, keine Stapel.
- Ausrüstung/Fähigkeiten bleiben immer erhalten. Kontrollpunkt = Speichern,
  Heilung, (später Schnellreise); Bossgegner bleiben dauerhaft tot.

## 3. Win/Lose und Zielspielzeit

- **Win (Meilenstein 1):** Labor-Aufseher (Mini-Boss) besiegt **und** Schleuse des
  Ausstiegs erreicht. Danach: Kurz-Abspann-Karte „Abschnitt gesichert" +
  freigeschaltete Abkürzung zurück zum Einstieg.
- **Lose:** HP 0 → Respawn am zuletzt aktivierten Kontrollpunkt (VorCheckpoint:
  Einstieg) mit Splitter-Verlustregel §2. Kein Game-Over-Screen, kein Neustart der
  Strecke; Retry-Zeit < 10 s (P30-Akzeptanz).
- **Zielspielzeit Meilenstein 1:** Erstcleans **9–11 min** (Benchmark 10 min);
  Wiederdurchlauf über die Abkürzung **6–7 min**. Tod-Kosten: +30–60 s pro Tod,
  ohne die 11 min deutlich zu sprengen.

## 4. Die erste Labor-Strecke (Beat-Tabelle; Blockvorlage für P07)

Räume liegen entlang +X (Laufachse), Höhen über Y; Kameraräume pro Raum (P07/P11).
Alle Maße sind Greybox-Startwerte, P07 verfeinert Grid/Sichtlinien/Spawn-Zonen.

| # | Raum | Beat | Zielzeit | Inhalt / Nachweis |
|---|------|------|----------|-----------|
| R0 | **Einfahrt / Kaltstart** | Einstieg | 0:00–1:00 | Spawn in gescheiterter Experimentkammer; Laufen/Sprung-Tutorial über eine niedrige Stufe (≤1,0 m); ein Terminal-Flackern als Story-Hinweis; keine Gegner. Tür öffnet nach 10 s oder Sprung zur Türplatte. |
| R1 | **Lernkampf** | Kämpfen lernen | 1:00–2:30 | Enger Korridor (~3 × 12 m), **1× Chaser**: Combo-Vertrag hero_combat_v05 (slash_light → zweiter Druck ≤0,45 s → slash_combo_2) und Trefferfeedback erfahrbar; eine Splitter-Kiste als Belohnung. |
| R2 | **Traversalschacht** | Bewegen lernen | 2:30–4:00 | Vertikaler Schacht mit Plattformen **1,0–1,6 m** (P05-Maße, ohne Ledge-Grab/Wall-Jump — die kommen erst mit P37 in Gebiet 2); Sturz kostet Zeit, nicht Leben; Kamera-Lesbarkeit (vorderer/ferner Grund) hier erstmals bewusst eingesetzt. |
| R3 | **Mischkampf-Halle** | Kampf vertiefen | 4:00–6:00 | Halle (~16 × 10 m, zwei Ebenen): **2× Chaser + 1× Suppressor**; zerstörbare Fässer/Kisten mit Splintern; kein Chokepoint, der Tod erzwingt. |
| R4 | **Kontrollraum** | Sicherer Hafen | 6:00–7:00 | **Checkpoint #1** (einziger vor dem Boss): Speichern, Heilung, Kiosk (Upgrade-Liste sichtbar; Kiosk-Funktionalität liefert P27/P39). Eindeutig als sicher lesbar (Licht, Musikwechsel). |
| R5 | **Aufseher-Arena** | Mini-Boss | 7:00–9:30 | Arena gate-rt beim Betreten (Tür fällt zu — klassisch, kein Weglaufen needed): **Labor-Aufseher**, humanoid, 2 klar telegraphierte Attacken + verwundbare Recovery, 2 Phasen (P28-Vertrag). Beute: Splitter-Cache + erstes Upgrade-Zeichen. |
| R6 | **Schleuse** | Ausstieg | 9:30–10:00 | Ausstiegsschleuse öffnet nach Boss-Tod; **Abkürzung** (Schacht-Rutsche) zurück nach R0 wird sichtbar/freigeschaltet — erster physischer Beweis der Metroidvania-Schleife Erkunden→Upgrade→Abkürzung. |

Nebenpfad (Pflicht-Erkundung, optional für Win): hinter R2 ein toter Endzweig
(~20 s Umweg) mit Splitter-Cache und Weltbau-Terminal — belohnt genaues Schauen,
ohne die Route zu blockieren.

## 5. Must / Should / Later

**Must (Meilenstein 1 = P30-Abschluss, sonst kein Done):**
- Schwert-Nahkampf nach Combo-Vertrag hero_combat_v05 (speed=1.0, Fenster 0,45 s; P04/P06).
- Strecke R0→R6 spielbar mit Greybox + gelieferten Platzhalter-Assets, ohne
  Debug-Konsole; Tastatur **und** Gamepad (GDD §3).
- Checkpoint R4 mit Speichern/Heilen; Tod → Respawn + Splitter-Regel §2 (P27/P39).
- Mini-Boss mit 2 telegraphierten Attacken, 2 Phasen, Arena-Gating (P28–P30).
- Win/Lose wie §3; Zielspielzeit §3 wird im P32-Playtest gemessen.
- Menschliche, humanoide Gegner (Chaser + Suppressor mindestens).

**Should (rein, wenn P30-Termintoleranz bleibt):**
- Wächter (gepanzert) als dritte Klasse im Mischkampf R3 (P18).
- Zerstörbare Props mit Drop-Variante (P13), Labor-Ambience + Kampfloop (P25),
  HUD-Hp/Splitter-Zähler sauber (P26), ein Kiosk-Upgrade tatsächlich kaufbar.

**Later (explizit NICHT in Meilenstein 1):**
- Ledge-Grab/Wall-Jump und Fähigkeits-Gates (P37), zweites Gebiet + Anbindung (P33–P35),
  Weltkarte/Schnellreise (P38), zweite Waffe (P20/P21), Gore-Feinschliff (P23),
  Performance-Härtung (P31), alles danach.

## 6. Anti-Goals (GDD §6 — Scope-Schutz)

Keine offene Welt (verbundene, handgesetzte Map). Kein Multiplayer/Koop.
Kein Prozedur-Generieren von Levels. Keine Schusswaffe für Rend (Nahkampf-Sprache
bleibt der Unterschied zu Shadow Complex, GDD §5). Kein Crafting-System.
Kein Dialog-/Narrativ-UI (Weltbau nur über Environment/Terminals).
Kein Permadeath, kein Punkte-Jagd-Modus. Keine weiteren Gebiete vor P33-Freigabe.

## 7. Anschluss an die Karte

- **P02 (Art-Bible)** übernimmt: Palette Petrol/Kupfer/Violett, Silhouetten,
  Metermaß/Grid aus §4-Raumbreiten.
- **P07 (Greybox)** blockt exakt die Beat-Tabelle §4 inkl. Nebenpfad.
- **P28–P30** bespielen R5/R6; **P27/P39** liefern R4-Mechanik und Splitter-Vertrag.
- **P32 (Playtest neVs)** misst Erstcleans-Zeit gegen §3 und nimmt §1–§6 ab.
