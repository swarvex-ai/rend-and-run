# Game Design Document — Rend&Run

> Arbeitstitel bestätigt von neVs (30.09.26): **Rend&Run**

> Status: **Idee folgt.** Dieses Dokument füllt neVs schrittweise;
> Hermes ergänzt Optionen/Varianten, niemals Design-Entscheidungen.

## 1. Kern-Loop (eine Runde, in einem Satz)
Arbeitsfassung: Durch Levels hüpfen, Verstecktes erkunden, Beute/Gegenstände
sammeln — Gegner mit Schwert/anderen Waffen brutal niedermetzeln — und mit dem
Erlaufenen neue Wege/Optionen freischalten.
Referenz-Feel: Dead Cells (Tempo/Kampf) x Hollow Knight (Erkundung), 3D-Optik.

## 2. Genre & Perspektive
**2,5D-Side-Scroller**: 3D-Modelle/Welt, Kamera seitlich (klassisch z. B. Like-a-Dragon-Feel oder Hollow-Knight-mit-3D). Engine: Godot 4, Ziel-OS Linux.
Kampftonalität: **brutal** — Treffer-Feedback mit Biss (Hit-Stop, Blutspritzer,
Gegner-Stummel/Death-Slowmo erwünscht, im Rahmen von Engine & Store-Freigaben).
Assets: 3D-Modelle aus KI-Generatoren (Meshy o. ä.) von neVs angeliefert, Hermes integriert sie ins Projekt.

## 3. Steuerungs-Schema
**Primär Gamepad**, Tastatur vollständig als Zweitsteuerung (Input-Abstraktion
über Godot-Input-Mapping von Anfang an, keine Tastatur-only-Hardtcodes).

## 4. Fortschritt & Ziele
**Hollow-Knight-Modell** (nicht Roguelike):
- Welt bleibt dauerhaft bestehen; Erkundungsfortschritt geht nicht verloren.
- **Kontrollpunkte:** Speichern, Schnellreise, Heilung/Upgrade-Kiosk.
- Tod = Verlust der laufenden Sammelwährung an der Todesstelle, einmalig
  zurückholbar (Hollow-Knight-Muster); Ausrüstung/Fähigkeiten bleiben.
- Gegner respawnen außerhalb des Bildschirms; einmal erledigte Boss-/
  Schlüsselgegner bleiben tot.

## 5. Stil / Referenztitel
**Heldenname: „Rend"** (von neVs abgenommen, 01.10.26) — Titelträger von Rend&Run;
„rend" = Fleischwunde/Abriss, passend zur Metzel-Sprache. Nerd-mit-Brille-Kontrast.
**Shadow Complex (Remastered)** — Leitreferenz (von neVs, 01.10.26):
- 2,5D-Metroidvania: 3D-Charakter/Welt in starrer Seitenansicht, saubere Lesbarkeit.
- Parkour als Grundvokabular: Ledge-Grabs, Wall-Jumps, raumgreifende Fortbewegung.
- Enorme, verbundene Map mit Upgrade-Gating (neue Fähigkeit öffnet neue Wege)
  statt Level-Schlüsseln.
- strukturierte, militärisch-anonyme Gegnerwellen; Combat flott und direkt.
- Übertragung auf Rend&Run: Shadow-Complex-Struktur + Motion = unser Ziel;
  Waffensprache bleibt aber unser Unterschied (brutale Nahkampf-Metzlei statt Gewehre).

## 6. Was dieses Spiel NICHT ist
Arbeitfassung P01 (01.10.26, Details in `docs/scope-first-route.md` §6):
keine offene Welt (verbundene handgesetzte Map), kein Multiplayer/Koop,
kein prozedurales Level-Generieren, keine Schusswaffe für Rend
(Nahkampf-Metzlei ist der Unterschied zur Leitreferenz), kein Crafting,
kein Dialog-/Narrativ-UI (Weltbau nur über Environment/Terminals),
kein Permadeath.

## Mechanik-Log (Hermes pflegt, neVs nickt ab)
| Mechanik | Karte | Status | Notiz |
|---|---|---|---|
| Sammelwährung „Splitter" | P01/P39 | Arbeitstitel | Produktionsname für die Todeswährung aus §4; Kiosk am Kontrollpunkt. |
| Kernschleife + 10-Min-Strecke | P01 | konkretisiert | Beat-Tabelle R0–R6 und Must/Should/Later in `docs/scope-first-route.md`; Meilenstein, kein lineares Remake des GDD. |
