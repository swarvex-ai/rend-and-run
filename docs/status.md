# Status
**23.11. (Lead, Zyklus Routine):** Nichts zu entscheiden: 5 eigene Einreichungen warten auf Peer-Review (ältester ca. 193 h, Engpass: Reviewer). 1 freie Aufgabe (#333, braucht Runner mit TTS), 10 blockiert, 0 aktive Agenten; Nachrichten: keine. Kein Ruling.
**22.11. (Lead, Zyklus Routine):** Nichts zu entscheiden: 5 eigene Einreichungen warten auf Peer-Review (ältester ca. 169 h, Engpass: Reviewer). 1 freie Aufgabe (#333, braucht Runner mit TTS), 10 blockiert, 0 aktive Agenten; Nachrichten: keine. Kein Ruling.
**21.11. (Lead, Zyklus 21.11 supply 2):** Nichts zu prüfen: 5 eigene Einreichungen warten auf Peer-Review (ältester ca. 163 h, Engpass: Reviewer). 0 freie Aufgaben, 10 blockiert (alle hängen an #339, #343/#344, #330, #487 bzw. #333), 1 aktiver Agent (Asset). Kein neuer Schnitt möglich ohne Überschneidung der Pfade; Nachrichten: keine. Kein Ruling.
**21.11. (Lead, Zyklus Routine):** Nichts zu entscheiden: 5 Einreichungen (u.a. #399, 521) sind eigene und warten auf Peer-Review (ältester ca. 144 h, Engpass: Reviewer); 0 aktive Agenten, 1 frei (#333, braucht Runner mit TTS), 10 blockiert. Nachrichten: keine offen. Kein Ruling.
**20.11. (Lead, Zyklus review):** #743 (Task 333, PA-Stimmen) abgelehnt: nur Skriptänderung, WAVs fehlen (Piper/ffmpeg nicht in der Sandbox); Task 333 ist wieder frei und braucht einen Runner mit TTS-Umgebung. #511 (Comic-Player) mit Peer-Review-Befund in die Nacharbeit (veraltete Textur statt Platzhalter, Test dazu). #399, 521, 637, 736 sind eigene und warten auf Peer-Review (Engpass: Reviewer). Kein Ruling.

**19.11. (Lead, Zyklus supply):** Keine Einreichung zu prüfen (#399, 511, 521 eigene, im Peer-Review, ältester ca. 95 h = Engpass). #487 liegt nach Peer-Review-Rework wieder bei einem Agenten (Befund: Test noch nicht in manifest.txt; trage ich nach dem Merge ein). Neu geschnitten: #516 E3.3 Druck-Tür (Level C, hängt an #487; Sounds existieren schon, PA-Zeile #333 nicht nötig). Frei: #333. Kein Ruling.

**18.11. (Lead, Zyklus 18.11 Routine 3):** #486 (E3.1 Logik) ist auf main; `pressure_task_test` in manifest.txt eingetragen (grün). Offene Einreichungen (#399, 511, 521) sind eigene und warten auf Peer-Review (Engpass: Peer-Review, ältester ca. 92 h). Frei: #333 (PA-Stimmen), #487 (E3.2 Overlay); E3.3 folgt nach #487. Nachrichten: keine offen. Kein Ruling.

**18.11. (Lead, Zyklus 18.11 supply):** 4 Einreichungen (#399, 511, 521, 598) sind eigene und warten auf Peer-Review (älteste ca. 86 h); nichts zu entscheiden. 0 freie Aufgaben bei 1 aktivem Agenten: E3 (Druckaufgabe) geschnitten: #486 Logik (frei), #487 Overlay (hängt an #486). E3.3 (Tür in `lab_route.gd`, Tod bei Fehlschlag, Sounds #338) folgt, sobald #486/#487 gemergt sind. Ruling: Zeit 12 s, Ziffern 1-9, +,-,* (aus milestone-1.md S16). Nach Merge in manifest.txt: comic_player_test, melee_tell_sound_test, pressure_task_test, pressure_overlay_test.

**16.11. (Lead, Zyklus 18):** #379 (Task 330, Comic-Player) mit Peer-Review-Punkten zurück in die Nacharbeit (Text-Wortlaut, Font, push_input, 3 Läufe). #479 (Panel 1 Variante 1) abgelehnt: zu grob; #478 (Variante 2) ist besser, eigene Einreichung, 5 Review-Fragen gesetzt, wartet auf Peer-Review. #399 (Audio-Tells) hat 1 Approve, eigene Einreichung, wartet auf einen zweiten Reviewer. Nach Merge in manifest.txt eintragen: comic_player_test, melee_tell_sound_test. Kein Ruling.

**16.11. (Lead, Zyklus 17):** Alle 8 Einreichungen (#379, 399, 404, 406, 409, 451, 458, 459) sind eigene und warten auf Peer-Review (ältester ca. 45 h); 0 aktive Agenten, 2 frei, 9 blockiert (hängen an diesen Merges). Engpass: Contributors/Peer-Review, nichts zu entscheiden. Nachrichten: keine offen. Kein Ruling, kein Schnitt.

**14.11. (Lead, Zyklus 21):** neVs hat 13, 14, 15, 17, 20 entschieden (Nachrichten beantwortet): Comic-Stil Variante 2 (Entscheidung 0003, Styleguide auf fünf Panels), Intro-Drehbuch Variante 1 (0005), Tod behält Splitter (0006; GDD und Glossar angepasst), Sound Bible Variante 2 (0007, `docs/design/sound-bible.md`, Lizenzkorrektur CC0/CC BY-SA), Ausholzeit Rolle 1 0,40 → 0,43 s (0008; `enemy.gd`, `overseer_integration` fixiert den neuen Wert, `tell_duration_probe`: alle 18 Angriffe ≥ 0,500 s; Headless-Suite bis auf diesen Test grün, danach grün). Kein Art-Bible-Rest: `docs/style-guide.md` verweist jetzt auf Variante 2. Neu geschnitten (22 Aufgaben, M1-Schätzung 165): E12 Audio #328, #332–#342, E4 Comic #329–#331, #343–#349. Frei jetzt: #328–#333; der Rest hängt per `depends_on` dran. Ruling: Musik (Exploration/Kampf/Alarm/Boss) noch nicht geschnitten, steht nicht in der M1-Ereignisliste. Ruling: Panel 1 als zwei Varianten (Stil-Anker), Panels 2–5 danach. Offen: E3 (Druckaufgabe) noch nicht geschnitten; `CREDITS.md` (geschützt) braucht Inter/Bangers-Zeilen; Projekt-Brief S4/S15 nennen noch „Todes-Cache“ (geschützt, neVs).


**14.11. (Lead, Zyklus 19):** Unverändert: 0 Einreichungen, 0 offene Aufgaben, 0 aktive Agenten, M1 121/121. Nachrichten 13, 14, 15, 17, 20 sind meine offenen Fragen an neVs; ohne Antwort kein Schnitt. Kein Ruling.

**14.11. (Lead, Zyklus 15):** Unverändert: 0 Einreichungen, 0 offene Aufgaben, 0 aktive Agenten, M1 121/121 Aufgaben. Nachrichten 13, 14, 15, 17, 20 offen bei neVs; ohne Antworten kein Schnitt (Audio-Assets, Comic, Tell-Zeit, Todesregel). Kein Ruling.

**13.11. (Lead, Zyklus 12):** #223 ist gemergt; 0 offene Aufgaben, 0 Einreichungen, 0 aktive Agenten. Nachrichten 13, 14, 15, 17, 20 weiter offen bei neVs (Comic, Todesregel, Sound Bible, Tell-Zeit); ohne seine Antworten ist kein Schnitt von Audio-Assets, Comic oder Balancing möglich. Kein Ruling.

**13.11. (Lead, Zyklus 11):** Unverändert: 0 Einreichungen, 1 freie Aufgabe (#223), 0 aktive Agenten (Engpass: Contributors). Nachrichten 13, 14, 15, 17, 20 sind meine offenen Fragen an neVs; keine Antwort, kein Ruling, kein Schnitt.

# Status
**13.11. (Lead, Zyklus 10):** Findings 21, 22, 23, 25, 28, 29 als erledigt geschlossen (stehen auf main). Nachricht 24 beantwortet. 0 Einreichungen, 1 freie Aufgabe (#223), 0 aktive Agenten. Nachrichten 13, 14, 15, 17, 20 offen bei neVs; sie blockieren den weiteren Schnitt (Audio-Assets, Tell-Zeit, Comic, Todesregel).

**13.11. (Lead, Zyklus 9):** Unverändert: 0 Einreichungen, 1 freie Aufgabe (#223), 0 aktive Agenten (Engpass: Contributors). Nachrichten 13, 14, 15, 17, 20 offen bei neVs, 24 Info. Kein Ruling, kein Schnitt.

**13.11. (Lead, Zyklus 8):** Unverändert: 0 Einreichungen, 1 freie Aufgabe (#223), 0 aktive Agenten (Engpass: Contributors). Nachrichten 13, 14, 15, 17, 20 offen bei neVs, 24 Info. Kein Ruling, kein Schnitt.

**13.11. (Lead, Zyklus 7):** Unverändert: 0 Einreichungen, 1 freie Aufgabe (#223), 0 aktive Agenten (Engpass: Contributors). Nachrichten 13, 14, 15, 17, 20 offen bei neVs, 24 Info. Kein Ruling, kein Schnitt.

**13.11. (Lead, Zyklus 6):** #222 ist auf main; `headless loading_indicator_test` in manifest.txt eingetragen (grün). #223 ist damit frei (einzige offene Aufgabe), 0 aktive Agenten. Nachrichten 13, 14, 15, 17, 20 offen bei neVs, 24 Info; kein Schnitt von Audio-Assets/Balancing ohne Antworten.

**13.11. (Lead, Zyklus 5):** Unverändert: keine Einreichungen zur Prüfung, 0 freie Aufgaben (#223 wartet auf Merge von #222, `loading_indicator_test` noch nicht auf main), 0 aktive Agenten. Nachrichten 13, 14, 15, 17, 20 offen bei neVs, 24 Info. Kein Ruling, kein Schnitt.


**13.11. (Lead, Zyklus 4):** #257 (Task 222, Ladeanzeige) angenommen; nach dem Merge `headless loading_indicator_test` in manifest.txt eintragen. Nachrichten 13, 14, 15, 17, 20 offen bei neVs, kein Schnitt ohne Antworten; #223 folgt nach #222.

**13.11. (Lead, Zyklus 3):** Task #124 als überholt geschlossen (Übersetzung steckt in #216/#217); #152/#153 hingen daran und wurden als #222/#223 ohne die Abhängigkeit neu angelegt (#223 nach #222). Manifest: credits_menu_test, input_device_tracker_test, perf_probe eingetragen (Tests grün). Nachrichten 13, 14, 15, 17, 20 weiter offen bei neVs, kein Schnitt von Audio-Assets/Balancing ohne Antwort; Info 24 zur Kenntnis.

**13.11. (Lead, später):** #250 (Task 155, perf_probe) angenommen; nach Merge `probe perf_probe` in manifest.txt eintragen. #252 (Task 217, ui_texts EN, eigene Einreichung) mit 5 Review-Fragen im Peer-Review. 0 freie Aufgaben; Nachrichten 13, 14, 15, 17, 20 offen bei neVs, kein Schnitt ohne seine Antworten.

**13.11. (Lead):** Unverändert: #246–#250 sind eigene Einreichungen (#250/perf_probe geprüft grün, wartet auf Peer-Review; die anderen noch in checking/submitted), 0 freie Aufgaben, Nachrichten 13, 14, 15, 17, 20 offen bei neVs, 24 Info. Kein Ruling, kein Schnitt. Nach Merge von #250 `probe perf_probe` in manifest.txt eintragen.

**12.11. früh XXVIII (Lead):** #240 (Task 216, route_texts EN) angenommen. #243 weiter nicht ablehnbar (in_progress). #217 frei (einzige Aufgabe), #152/#153 warten auf #124. Nachrichten 13, 14, 15, 17, 20 offen bei neVs; kein Schnitt ohne seine Antworten.

**12.11. früh XXVI (Lead):** #244 (Task 150, Credits-Screen) angenommen; nach dem Merge `headless credits_menu_test` in manifest.txt eintragen. #243 (Task 124, eigene Einreichung, doppelt zu #240) ließ sich nicht ablehnen (Plattform: State submitted); ablehnen, sobald möglich. #240 (Task 216) war rot wegen workbench_integration (auf main behoben, 5088ab1), braucht Neu-Prüfung. 0 freie Aufgaben; Nachrichten 13, 14, 15, 17, 20 offen bei neVs, 24 Info.

**12.11. früh XXIV (Lead):** #236 abgelehnt (überholt, steckt in #217). #238 (Credits, 4 Review-Fragen gesetzt) wartet auf Peer-Review; nach Merge `headless credits_menu_test` in manifest.txt eintragen. #239 (Task 217) war rot wegen `workbench_integration` (Test las den Text aus route_texts statt aus der UI-Tabelle) — Ruling: Test selbst repariert (Level D, Commit 5088ab1, grün), #239 braucht nach Neu-Prüfung ggf. Rebase. Findings 18–20 offen, 22 (veraltete Kommentare) klein. Nachrichten 13, 14, 15, 17, 20 offen bei neVs.

**12.11. früh XXIII (Lead):** #236 (Task 124, 2-String-Rest) weiter im Zustand checking, Review/Reject von der Plattform abgelehnt ("review only after a passing check"); sobald die Prüfung durch ist, als überholt ablehnen (Ersatz #216/#217). Frei: #217; #152/#153 hängen weiter an #124 – falls #124 nicht freigegeben wird, neu schneiden mit Abhängigkeit auf #216/#217. Nachrichten 13, 14, 15, 17, 20 offen bei neVs, 24 Info. Kein neuer Schnitt möglich ohne seine Antworten.

**12.11. früh XXII-b (Lead):** #237 (Task 215, Device-Tracker) angenommen; nach dem Merge `headless input_device_tracker_test` in manifest.txt eintragen. `input_glyphs_test` eingetragen. #236 (Task 124, nur 2 Strings) nicht entscheidbar (State checking); Task 124 war zu groß (>500 Zeilen), ersetzt durch #216 (route_texts) und #217 (ui_texts). #152 hängt an 124: falls nicht freigegeben, neu schneiden. Nachrichten 13, 14, 15, 17, 20 offen bei neVs.

**12.11. früh XXI (Lead):** #235 (Task 214, Glyph-Lookup) angenommen; nach dem Merge `input_glyphs_test` als `headless` in manifest.txt eintragen (Datei ist noch nicht auf main). #156 (perf_probe) weiter eigene Einreichung im Peer-Review; nach Merge `probe perf_probe` eintragen. 0 freie Aufgaben (#152/#153 hängen an #124), #215 in Arbeit; Nachrichten 13, 14, 15, 17, 20 offen bei neVs, 24 ist Info.

**12.11. früh XX (Lead):** Review-Fragen für #155/#156 gesetzt (Peer-Review wartet). Neu geschnitten aus der Eingabehinweis-Diagnose (#154): #214 (Glyph-Lookup-Modul) und #215 (Device-Tracker), unabhängig, beide Level B. Nachrichten 13, 14, 15, 17, 20 weiter offen bei neVs. Danach: Platzhalter-Umstellung der Texte (nach #124, #214, #215).

**12.11. früh XIX (Lead):** Unverändert: 5 eigene Einreichungen (#152–#156) ohne Peer-Review (ältester 70 h), 0 freie Aufgaben, 0 aktive Agenten, Nachrichten 13, 14, 15, 17, 20 offen bei neVs; 24 ist Info. Kein Ruling, kein Schnitt.

**12.11. früh XVIII (Lead):** Unverändert: 5 eigene Einreichungen (#152–#156) ohne Peer-Review (ältester 68 h), 0 freie Aufgaben, 0 aktive Agenten, Nachrichten 13, 14, 15, 17, 20 offen bei neVs; 24 ist Info. Kein Ruling, kein Schnitt.

**12.11. früh XVI (Lead):** Unverändert: 5 eigene Einreichungen (#152–#156) ohne Peer-Review (ältester 66 h), 0 freie Aufgaben, 0 aktive Agenten, Nachrichten 13, 14, 15, 17, 20 offen bei neVs; 24 ist Info. Kein Ruling, kein Schnitt.

**12.11. früh XV (Lead):** Unverändert: 5 eigene Einreichungen (#152–#156) ohne Peer-Review (ältester 65 h), 0 freie Aufgaben, 0 aktive Agenten, Nachrichten 13, 14, 15, 17, 20 offen bei neVs; 24 ist Info. Kein Ruling, kein Schnitt.

**12.11. früh XIV (Lead):** Unverändert: 5 eigene Einreichungen (#152–#156) ohne Peer-Review (ältester 64 h), 0 freie Aufgaben, 0 aktive Agenten, Nachrichten 13, 14, 15, 17, 20 offen bei neVs; 24 ist Info. Kein Ruling, kein Schnitt.

**12.11. früh XIII (Lead):** Unverändert: 5 eigene Einreichungen (#152–#156) ohne Peer-Review (ältester 63 h), 0 freie Aufgaben, 0 aktive Agenten, Nachrichten 13, 14, 15, 17, 20 offen bei neVs; 24 ist Info. Kein Ruling, kein Schnitt.
**12.11. früh IX (Lead):** Unverändert: 5 eigene Einreichungen (#152–#156) ohne Peer-Review (ältester 59 h), 0 freie Aufgaben, 0 aktive Agenten, Nachrichten 13, 14, 15, 17, 20 offen bei neVs; 24 ist Info. Kein Ruling, kein Schnitt.

**12.11. früh V (Lead):** Unverändert: 5 eigene Einreichungen (#152–#156) ohne Peer-Review (ältester 55 h), 0 freie Aufgaben, 0 aktive Agenten, Nachrichten 13, 14, 15, 17, 20 offen bei neVs; 24 ist Info. Kein Ruling, kein Schnitt.

**12.11. früh IV (Lead):** Unverändert: 5 eigene Einreichungen (#152–#156) ohne Peer-Review (ältester 54 h), 0 freie Aufgaben, 0 aktive Agenten, Nachrichten 13, 14, 15, 17, 20 offen bei neVs; 24 ist Info. Kein Ruling, kein Schnitt.

**12.11. früh II (Lead):** Unverändert: 5 eigene Einreichungen (#152–#156) ohne Peer-Review (ältester 52 h), 0 freie Aufgaben, 0 aktive Agenten, Nachrichten 13, 14, 15, 17, 20 offen bei neVs; 24 ist Info. Kein Ruling, kein Schnitt.

**11.11. später XVIII (Lead):** Unverändert: 5 eigene Einreichungen (#152–#156) ohne Peer-Review, 0 freie Aufgaben, 0 aktive Agenten, Nachrichten 13, 14, 15, 17, 20 offen bei neVs; 24 ist Info. Kein Ruling, kein Schnitt.

**11.11. später X (Lead):** Unverändert: 5 eigene Einreichungen (#152–#156) ohne Peer-Review, 0 freie Aufgaben, 0 aktive Agenten, Nachrichten 13, 14, 15, 17, 20 offen bei neVs; 24 ist Info. Kein Ruling, kein Schnitt.

**11.11. später IX (Lead):** Unverändert: 5 eigene Einreichungen (#152–#156) ohne Peer-Review, 0 freie Aufgaben, 0 aktive Agenten, Nachrichten 13, 14, 15, 17, 20 offen bei neVs; Nachricht 24 ist Info. Kein Ruling, kein Schnitt.

**11.11. spät V (Lead):** Unverändert: 5 eigene Einreichungen (#152–#156) ohne Peer-Review (ältester 38 h), 0 freie Aufgaben, 0 aktive Agenten, Nachrichten 13, 14, 15, 17, 20 offen bei neVs. Kein Ruling, kein Schnitt.

**11.11. spät IV (Lead):** Unverändert: 5 eigene Einreichungen (#152–#156) ohne Peer-Review (ältester 37 h), 0 freie Aufgaben, 0 aktive Agenten, Nachrichten 13, 14, 15, 17, 20 offen bei neVs. Kein Ruling, kein Schnitt.

**11.11. spät III (Lead):** Unverändert: 5 eigene Einreichungen (#152–#156) ohne Peer-Review (ältester 35 h), 0 freie Aufgaben, 0 aktive Agenten, Nachrichten 13, 14, 15, 17, 20 offen bei neVs. Kein Ruling, kein Schnitt.

**11.11. spät II (Lead):** Unverändert: 5 eigene Einreichungen (#152–#156) ohne Peer-Review, 0 freie Aufgaben, 0 aktive Agenten, Nachrichten 13, 14, 15, 17, 20 offen bei neVs; Nachricht 24 (mehr Lead-Kapazität) ist Info, kein Handlungsbedarf. Kein Ruling, kein Schnitt.

**11.11. spät (Lead):** Unverändert: 5 eigene Einreichungen (#152–#156) ohne Peer-Review, 0 freie Aufgaben, 0 aktive Agenten, Nachrichten 13, 14, 15, 17, 20 offen bei neVs. Kein Ruling, kein Schnitt.

**11.11. später (Lead):** Unverändert: 5 eigene Einreichungen (#152–#156) ohne Peer-Review (ältester 27 h), 0 freie Aufgaben, 0 aktive Agenten, Nachrichten 13, 14, 15, 17, 20 offen bei neVs. Kein Ruling, kein Schnitt.

**11.11. (Lead):** Unverändert: 5 eigene Einreichungen (#152–#156) ohne Peer-Review (ältester 26 h), 0 freie Aufgaben, 0 aktive Agenten, Nachrichten 13, 14, 15, 17, 20 offen bei neVs. Kein Ruling, kein Schnitt.

**10.11. abends (Lead):** Unverändert: 5 eigene Einreichungen (#152–#156) ohne Peer-Review (ältester 25 h), 0 freie Aufgaben, Nachrichten 13, 14, 15, 17, 20 offen bei neVs. Kein Ruling, kein Schnitt.

**10.11. nachmittags III (Lead):** Unverändert: 5 eigene Einreichungen (#152–#156) ohne Peer-Review (ältester 23 h), 0 freie Aufgaben, Nachrichten 13, 14, 15, 17, 20 offen bei neVs. Kein Ruling, kein Schnitt.

**10.11. nachmittags II (Lead):** Unverändert: 5 eigene Einreichungen (#152–#156) ohne Peer-Review, 0 freie Aufgaben, Nachrichten 13, 14, 15, 17, 20 offen bei neVs. Kein Ruling, kein Schnitt.

**10.11. vormittags (Lead):** Unverändert: 5 eigene Einreichungen (#152–#156) ohne Peer-Review, 0 freie Aufgaben, Nachrichten 13, 14, 15, 17, 20 offen bei neVs. Kein Ruling, kein Schnitt.

**10.11. morgens II (Lead):** Unverändert: 5 eigene Einreichungen (#152–#156) ohne Peer-Review, 0 freie Aufgaben, Nachrichten 13, 14, 15, 17, 20 offen bei neVs. Kein Ruling, kein Schnitt.

**10.11. nachts III (Lead):** Unverändert: 5 eigene Einreichungen (#152–#156) ohne Peer-Review, 0 freie Aufgaben, Nachrichten 13, 14, 15, 17, 20 offen bei neVs. Kein Ruling, kein Schnitt.

**10.11. nachts II (Lead):** Unverändert: 5 eigene Einreichungen (#152–#156) ohne Peer-Review, 0 freie Aufgaben, Nachrichten 13, 14, 15, 17, 20 offen bei neVs. Kein Ruling, kein Schnitt.

**10.11. nachmittags (Lead):** Unverändert: 5 eigene Einreichungen (#152–#156) warten auf Peer-Review, 0 freie Aufgaben (#152/#153 blockiert), Nachrichten 13, 14, 15, 17, 20 offen bei neVs. Kein Ruling, kein Schnitt.

**10.11. mittags (Lead):** Unverändert: 5 eigene Einreichungen warten auf Peer-Review, 0 freie Aufgaben, Nachrichten 13, 14, 15, 17, 20 offen bei neVs. Kein Ruling, kein Schnitt.

**10.11. morgens (Lead):** Unverändert: 5 eigene Einreichungen (#152–#156) warten auf Peer-Review, 0 freie Aufgaben, Nachrichten 13, 14, 15, 17, 20 offen bei neVs. Kein Ruling, kein neuer Schnitt.


**10.11. nachts (Lead):** Unverändert: 5 eigene Einreichungen ohne Peer-Review, 0 freie Aufgaben, Nachrichten 13, 14, 15, 17, 20 offen bei neVs. Kein Ruling, kein neuer Schnitt.

**10.11. spätabends (Lead):** Unverändert: 5 eigene Einreichungen (#152–#156, Tasks 150, 151, 124, 154, 155) warten auf Peer-Review und können nicht von mir angenommen werden; 0 freie Aufgaben (#152/#153 blockiert); Nachrichten 13, 14, 15, 17, 20 offen bei neVs. Kein neuer Schnitt ohne seine Antworten möglich. Kein Ruling in diesem Zyklus.

**10.11. später (Lead):** Zyklus ohne neue Entscheidung: 5 Einreichungen (#152–#156) sind eigene und warten auf Peer-Review; 0 freie Aufgaben (#152/#153 hängen an #124/#150), Nachrichten 13, 14, 15, 17, 20 liegen weiter bei neVs (alle von mir an ihn, keine Antwort). Nichts Sinnvolles ohne seine Antworten schneidbar (Comic, Audio-Assets, Tell-Anhebung, Todesregel); E8 (Windows-Export) braucht geschützte Dateien und bleibt Lead-Arbeit für einen späteren Zyklus.

**10.11. (Lead):** Backlog war leer (0 frei, #152/#153 blockiert). Neu geschnitten: #154 (E11.8 Diagnose: Inventar aller Eingabe-Hinweise und Gamepad-Belegungen, Stufe A) und #155 (E9 Messung: Frame- und Knotenbudget der Strecke, Stufe B, `perf_probe` danach ins Manifest). Drei Einreichungen (Task 150, 151 und E5 Englisch) sind eigene Einreichungen und warten auf Peer-Review. Nachrichten 13, 14, 15, 17, 20 liegen weiter bei neVs; blockiert: Intro-Comic, Audio-Assets, Tell-Anhebung.

**09.11. abends (Lead):** neVs hat am 09.11. die Gate-Dokumente UX-Spezifikation (16), Story-Gerüst (18) und Art Bible (19) freigegeben. Offen bei neVs: Comic-Stil (13), Comic-Drehbuch (14), Tod und Splitter (15), Sound Bible (17), Warnzeiten Rolle 1 (20). Backlog war leer (1 aktiver Agent, #124 läuft); neu geschnitten: #150 (E11.6a Credits-Bildschirm), #151 (UX Q4: R nur Nachladen), #152 (E11.9 Ladeanzeige, nach #124), #153 (E11.6b Credits auf der Endkarte, nach #150 und #152). Gamepad-Belegungen (Waffenplätze, zurück, Hilfe) und Eingabe-Glyphen (E11.8) bleiben für den nächsten Schnitt; Intro-Comic, Audio-Assets und Tell-Anhebung (E7) warten auf die offenen Antworten von neVs.

**09.11. nachts (Lead):** Einreichungen #152 (Task 150, Credits-Bildschirm) und #153 (Task 151, R nur Nachladen) sind grün (107 headless + 23 hook), aber eigene Einreichungen: warten auf Peer-Review, ich darf sie nicht annehmen. Nach dem Merge: `credits_menu_test` und `reload_key_test` in manifest.txt eintragen. Die fünf offenen Nachrichten (13, 14, 15, 17, 20) sind Fragen an neVs; nichts zu tun, bis er antwortet.
- Ruling: Credits-Texte stehen in `game/data/credits_data.gd` (Englisch), nicht in `ui_texts.gd`, damit sie nicht mit #124 (serielle Werte-Umstellung) kollidieren — Kosten bei Irrtum: ein Verschiebe-Schritt später.

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

**Wartet auf neVs:** Comic-Stil (Nachricht 13), Comic-Drehbuch (Nachricht 14), Tod und Splitter (Nachricht 15); später dazugekommen: UX-Spezifikation (16), Sound Bible (17), Story-Gerüst (18), Art Bible (19), Warnzeiten von Rolle 1 (20).

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
- #93 angenommen (Fix #96: `_bone()`-Fallback für die Armknochen in `overseer_low_pose.gd`). Nach dem Merge (e7784c2) ist overseer_integration aus der Quarantäne (33/33). Die Suite war zweimal grün mit 99 headless + 22 hook.
- #92 angenommen (Diagnose #95): Fehler im Test, kein Spielfehler. Der Test schaltet Rends Physik ab, deshalb bleibt seine Kapsel bei 1,3 m statt 1,65 m, und ein hoch gestreuter Schuss fliegt darüber. Reparatur-Aufgabe #97 (Steh-Kapsel setzen, Seed direkt vor dem zweiten Schuss). Die Aussage, `FX.hitstop` laufe unter `--fixed-fps` in Echtzeit, ist nicht belegt.
- In der Quarantäne bleiben zwei Tests: machinery_chamber_integration (Meilenstein-Review) und projectile_lifetime_test (#97).
- #94 (Art Bible, #48) zur Nacharbeit: Die Kriterien sind erfüllt, aber das Dokument nennt den Comic-Stil Variante 1 als festgelegt. Die Wahl ist offen (Nachricht 13). Es ist nur ein Satz zu korrigieren. Danach geht die Art Bible als Gate-Dokument zur Freigabe an neVs.
- #95 angenommen (Review #57 meiner F6-Dokumente): fünf veraltete Zeilenangaben, falsche Modulzahlen, verschwiegene Abhängigkeiten (audio und fx.gd → settings_store, combat ↔ world) und vier QA-Regeln, die nicht zum Runner passten. Ich habe `docs/architecture.md` und `docs/qa.md` korrigiert. Ein Punkt der Review war falsch: Wiederholungslauf und Gegenprobe macht die swarvex-Pipeline, nicht `run_tests.sh`. Das steht jetzt deutlicher in qa.md. #96 angenommen (projectile_lifetime_test: Steh-Kapsel und Seed vor dem zweiten Schuss; 10/10 lokal, 30/30 beim Mitwirkenden).
- Nach dem Merge (591c86a) ist projectile_lifetime_test wieder aus der Quarantäne. Die Suite war zweimal grün mit 99 headless + 23 hook. In der Quarantäne bleibt nur machinery_chamber_integration (Entscheidung beim Meilenstein-Review: streichen oder die Kammer wieder bauen).
- #97 angenommen (Art Bible #48, nach der Nacharbeit): Gate-Dokument, Freigabe bei neVs angefragt (Nachricht 19, zwei Korrekturen: Schildträger mit Ausfallschritten, Ring des Wächters in Amber statt Rot).
- #98 angenommen (Review #59 meiner F3-Aufteilung): Zwei Zahlen in `lab_route.gd` wiederholen Daten (Kühlmittel-Hinweis bei 37.1, Lampenfarben an x 26/39). Reparatur-Aufgabe #98. Dass an `lab_route.gd:856` ein englischer Grund an einen deutschen Text gehängt wird, gehört zu E5.
- Ruling: Offsets relativ zu einem Anker aus den Daten bleiben im Code; in die Routendaten gehört nur, was beim Verschieben der Daten mitwandern muss — Kosten bei Irrtum: eine weitere Daten-Aufgabe.
- #99 angenommen (menu_back.wav, eigene Synthese, nachgemessen; Anhören steht beim Playtest aus). Der Merge-Bot hat die WAV roh statt als LFS-Zeiger committet; ich habe sie byte-gleich über LFS neu abgelegt.
- Angebot war leer (0 freie Aufgaben bei 1 aktivem Agenten). Neu geschnitten wurden E6 (Barrierefreiheit, G16):
  - #99: Gespeicherte Optionen wirken beim Start. Das war ein Fehler S3: Nur das Options-Menü rief `apply()` auf. Außerdem schalten Bildschirmwackeln und Zeitlupe wirklich ab.
  - #100: Untertitel abschaltbar, wartet auf #99.
  - #101: Vertragstest für das Alarmlicht, höchstens 3 Hz (heute etwa 1,75 Hz).
  - #103: Menü-Klänge auf die Spitzenpegel des Styleguides. Heute klingt Zurück etwa 13 dB leiser als Bestätigen. #103 ersetzt #102, meine erste Fassung, die übersehen hatte, dass die WAVs mit QOA importiert werden.
- #100 angenommen (Folgeaufgabe #98 aus der F3-Review): Kühlmittel-Hinweis und Lampenfarben kommen aus den Routendaten. Gegenprobe: Mit geänderter Farbe in den Daten wird der neue Check rot.
- #101 angenommen (Diagnose #90, Risiko Ladereihenfolge): `enemy.gd:143` leitet die Tiefenspur eines Roboters aus `get_instance_id() % 3` ab. Jedes zusätzlich geladene Skript verschiebt die Objekt-IDs und damit die Spur des ersten Roboters (−0,25 → 0,0), und `arm_first_fight` kippt. Fix-Aufgabe #104: Die Spur kommt aus einem Spawn-Zähler in `main._make_enemy`, mit Regressionstest. Danach entfällt die Regel „kein preload in Hook-Tests“.
- #102 angenommen (E6, #99): Gespeicherte Optionen wirken beim Start, Bildschirmwackeln und Zeitlupe lassen sich wirklich abschalten. Der Mitwirkende hat bestätigt, dass ein `preload` in `fx.gd` `arm_first_fight` rot macht (Ursache #90), und deshalb `load()` genommen. Nach dem Merge (30b624c) ist accessibility_settings_test registriert. Die Suite war zweimal grün mit 100 headless + 23 hook. #100 (Untertitel) ist damit frei.
- #103 angenommen (E6, #101): alarm_flash_rate_test, berechnet 1,75 Hz, gemessen 1,67 Hz. Gegenprobe: Mit SPIN 12 wird der Test rot. Registriert nach dem Merge (c99b11b). Die Suite war zweimal grün mit 101 headless + 23 hook.
- #104 angenommen (#103): Die Menü-Klänge erreichen die Spitzenpegel des Styleguides (Fokus −5,2 dB, Bestätigen −9,5 dB, Zurück 0 dB auf die Datei); `menu_sound_level_test` prüft die Pegel-Tabelle gegen die rohen WAVs. #105 angenommen (#100): Untertitel lassen sich abschalten, der Ton bleibt. Beide Tests registriert; die Suite war zweimal grün mit 103 headless + 23 hook. Damit ist E6 bis auf die Abnahme im Playtest erledigt.
- Angebot wieder leer; neu geschnitten: #105 (keine internen Fehler-IDs in der Servo-Werkbank) und #106 (E7-Messung: Warnzeit jeder Roboter-Attacke; heute liegen Rolle 1 mit 0,40 s und die Wache im Nahkampf mit 0,44 s Ausholzeit unter 0,5 s; ob das so bleibt, entscheidet neVs nach der Messung).
- #106 angenommen (Fix #104 zu #90): Die Tiefenspur eines Roboters kommt aus dem Spawn-Zähler in `main._make_enemy`, nicht mehr aus der Objekt-ID. Mit dem Probe-`preload` aus der Reproduktion bleibt `arm_first_fight` grün. `enemy_lane_assignment_test` ist registriert; die Suite war zweimal grün mit 104 headless + 23 hook. Damit ist die erste Ursache von #90 behoben. **Korrektur am Abend:** Es gibt eine zweite (siehe unten); die Warnung „kein preload in Hook-Tests“ gilt weiter.
- Ruling: Die Spur hängt an der Spawn-Reihenfolge, einschließlich der zwei Wächter vor den Begegnungen. Ändert sich deren Zahl, verschieben sich die Spuren der Routen-Roboter. Das ist deterministisch, und für M1 nehme ich es so hin — Kosten bei Irrtum: ein Test wie arm_first_fight kippt bei einer Wächter-Änderung sichtbar statt zufällig, dann bekommt die Begegnung eine feste Spur in den Routendaten.
- #107 angenommen (#105): Die Servo-Werkbank zeigt lesbare Sätze statt interner Fehler-IDs. `shop_reason_text_test` ist registriert.
- #108 angenommen (#106, E7-Messung, `docs/measurements/tell-durations.md`, Sonde `tell_duration_probe` als `probe` registriert): 4 von 18 Angriffen warnen nur 0,483 s vor, beide Schläge des Schildträgers und Faust und Ellbogen des Wächters in der Nische (Ausholzeit von Rolle 1: 0,40 s). Nahkampf-Roboter sind nur 0,083 s vorher hörbar, Fernkämpfer erst beim Schuss. Frage an neVs: Nachricht 20 (Empfehlung: Ausholzeit von Rolle 1 auf 0,43 s). Die Suite war zweimal grün mit 105 headless + 23 hook.
- Neu: #107, E5-Vorbereitung. Es geht um die Liste der Tests, die deutsche Texte wörtlich vergleichen und bei der Übersetzung brechen würden.
- #109 angenommen (#107): 41 Stellen in 14 Testdateien vergleichen deutsche Texte wörtlich, 14 davon kommen aus der Routen-Tabelle, 27 aus Modulskripten. Entscheidung 0004 (`docs/decisions/0004-text-tables.md`): Module bekommen eine zweite Tabelle `game/data/ui_texts.gd` mit eigenem Vertragstest; Tests vergleichen nur über die Tabellen. Neu geschnitten:
  - #108: Die 14 Vergleiche mit Routentexten laufen über `TEXT.t()`.
  - #110: `ui_texts.gd`, `ui_text_table_test` und das erste Modul `sector_complete.gd`.
  - #109: `assert()` wird in 11 Testdateien durch `check()` ersetzt. Selbst geprüft: Ein fehlgeschlagenes `assert` hält den Test bis zum Timeout an, statt sauber rot zu enden.
- Ruling: Texte in Modulen kommen in eine eigene Tabelle (`ui_texts.gd`), nicht in die Routen-Tabelle, weil deren Vertragstest nur `lab_route.gd` prüft. Robotersätze und Durchsagen bleiben, bis das Story-Gerüst freigegeben ist (Nachricht 18) — Kosten bei Irrtum: zwei Tabellen statt einer, später mechanisch zusammenlegbar.
- #110 angenommen (#108): Die 14 Vergleiche mit Routentexten laufen über `TEXT.t()`, wo möglich als exakter Vergleich. #111 angenommen (#109): In 11 Testdateien ist `assert()` durch `check()` ersetzt; ein Fehler endet jetzt nach Sekunden mit Exit 1 statt mit Timeout.
- **Zweite Ladereihenfolge-Abhängigkeit** (gemeldet in #110, von mir reproduziert): `const TEXT = preload("res://data/route_texts.gd")` in drei Hook-Tests lässt `farming_input_playthrough` den ersten Kampf verlieren (2/2 rot), mit `load()` bleibt alles grün. Meine Aussage in #108, nach #104 sei `preload` in Hook-Tests sicher, war falsch. Diagnose-Aufgabe #111; Entscheidung 0004 ist korrigiert.
- #113 angenommen (Diagnose #111): Die zweite Ursache steht in `enemy.gd:370`. Die Phase der Seitwärtsbewegung beim Umkreisen ist `get_instance_id() % 7`; nur die zwei früh geladenen Hook-Tests lösen den Fehler aus. Dieselbe Klasse steckt latent in `enemy.gd:364` (Gleichstand über die Instanz-ID). Fix-Aufgabe #114: Phase und Rangfolge kommen aus dem Spawn-Index in `main._make_enemy`, der erweiterte `enemy_lane_assignment_test` prüft das.
- #114 (E5 3a) zur Nacharbeit. Der Inhalt ist in Ordnung, aber der Mitwirkende hat auf einem Stand vor dem Merge von #110 gearbeitet und `ui_texts.gd` neu angelegt; der Patch passt nicht auf main. Lehre: `depends_on` gibt eine Aufgabe frei, sobald die Vorgängerin angenommen ist, nicht erst nach dem Merge. Folgeaufgaben, die eine Datei der Vorgängerin erweitern, nennen diese Datei und den Commit, ab dem sie existiert.
- #115 angenommen (Fix #114): Seitwärtsbewegung und Gleichstand beim Gedränge kommen aus dem Spawn-Index (`_sway_phase = (_spawned + 5) % 7`, damit die erste Begegnung ihre bisherige Phase 1 behält). In `enemy.gd` steht kein `get_instance_id()` mehr. Mit `preload` in allen drei auslösenden Hook-Tests bleiben die Kampftests grün. Damit sind beide Ursachen von #90 behoben; die Regel „kein preload in Hook-Tests“ entfällt nach dem Merge.
- #116 angenommen (E5 3a, nach Nacharbeit): Kontrollpunkt- und Aufseher-Beschriftungen kommen aus `ui_texts.gd`, das jetzt 20 Schlüssel hat. #113 (Zonennamen) ist damit frei, #115 (Werkbank, E5 3c) wartet auf #113.
- #117 angenommen (E5 3b): Die fünf Zonennamen kommen aus `ui_texts.gd`, die Tabelle hat jetzt 25 Schlüssel. #115 (Werkbank) ist frei. Neu: #116 (E5 3d, Kampfhinweise), wartet auf #115. Dort wird auch die deutsche Teilstring-Ersetzung für Rend ohne Schild in `lab_route.gd:355` durch eigene Schlüssel ersetzt.
- #118 (E5 3c, Werkbank) zur Nacharbeit, obwohl der Inhalt stimmt: Der Patch kollidiert in `ui_texts.gd` mit den Zonen-Schlüsseln aus 3b, die erst nach dem Start der Aufgabe gemergt wurden. Risiko für #116 und #117: Die E5-Kette schreibt fortlaufend in dieselbe Tabelle, und jede Folgeaufgabe wird schon bei der Annahme ihrer Vorgängerin frei, nicht erst nach deren Merge. Eine Nacharbeit pro Schritt ist möglich, kostet aber nur eine kleine Runde. Ruling: So hinnehmen statt die Tabelle aufzuteilen; die Kette endet mit #117.
- #119 angenommen (E5 3c, nach Nacharbeit): Alle Texte des Werkbank-Menüs kommen aus `ui_texts.gd`, das jetzt 48 Schlüssel hat. #116 (Kampfhinweise) ist frei.
- #120 angenommen (E5 3d): Die Kampfhinweise kommen aus `ui_texts.gd`, das jetzt 56 Schlüssel hat. Die Variante ohne Schild ist ein eigener Schlüssel, die deutsche Teilstring-Ersetzung in `lab_route.gd` ist entfernt. #117 (Waffen- und Mod-Namen) ist frei; er ist der letzte Schritt der Modultexte.
- #121 (E5 3e, Waffen- und Mod-Namen) zur Nacharbeit: Der Inhalt stimmt, aber derselbe Tabellenkonflikt wie bei 3c, diesmal mit den hint_*-Schlüsseln aus 3d. Der letzte Schritt #118 ist durch #119 ersetzt. #119 nennt eine prüfbare Bedingung: Fehlen in `ui_texts.gd` die gun_*-Schlüssel, ist der Stand zu alt, und die Aufgabe geht vor der Arbeit zurück, statt danach nachgearbeitet zu werden.
- #122 angenommen (E5 3e, nach Nacharbeit): Waffen- und Mod-Namen und -Beschreibungen kommen aus `ui_texts.gd`, das jetzt 68 Schlüssel hat. `SPECS` und `MODS` enthalten keinen sichtbaren Text mehr. #119 (Gegenstandskatalog und Ausrüstungsmenü, der letzte Modul-Schritt) ist frei.
- 08.11. früh: Aufgabe #119 wurde ohne Notiz zurückgegeben. Ich habe sie geprüft: Niemand außerhalb der erlaubten Pfade liest die Textfelder des Katalogs direkt, die Aufgabe ist also lösbar wie beschrieben. Sie bleibt unverändert frei.
- Vollständiger Scan nach deutschen Spieltexten außerhalb der Tabellen: Neben #119 stehen noch 44 Texte in 14 Skripten, die Review #107 nicht erfasst hatte, weil kein Test sie vergleicht (HUD, Munitionsanzeige, Pickups, Service-Aufzug, Kamera, Pause, Slot-Zeile, Startbildschirm). Neu geschnitten: Aufgabe #120 (E5 3g, 24 Texte aus HUD und Pickups, nach #119) und Aufgabe #121 (E5 3h, 20 Texte aus Welt, Pause und Start, nach #120). Die englischen Werte folgen erst danach. Der Vertragstest `ui_text_table_test` durchsucht jetzt auch die Skripte direkt unter `res://` (`bbcaca9`), sonst würden Schlüssel aus `start.gd`, `player.gd` und `pause_controller.gd` als unbenutzt gelten.
- #123 angenommen (#119, E5 3f): Gegenstandskatalog und Ausrüstungsmenü lesen ihre 24 Texte aus `ui_texts.gd` (`item_*`, `equipment_*`; `item_catalog.gd` hat `label()`, `summary()` und neu `description()`, die Felder `name`/`summary`/`description` sind aus `ITEMS` entfernt). Gegenprobe: Kein Aufrufer liest die Felder noch direkt; 10 betroffene Tests 3 × grün auf `5119624`. #120 (E5 3g, HUD und Pickups) ist frei.
- #127 angenommen (#123, E5 3i): die 9 Einzelwörter stehen in `ui_texts.gd`; 12 Tests 3 × grün auf `711a845`; außerhalb von `game/data/` keiner der Begriffe mehr. In `enemy.gd` lädt eine lokale Variable die Tabelle, weil `lab_overseer.gd` (erbt von `enemy.gd`) selbst `var UI_TEXT` deklariert; für den Aufräumschritt nach E5 notiert (`lab_overseer.gd` auf das Erbe umstellen). #124 (englische Werte) ist frei.
- #126 angenommen (#121, E5 3h): Welt-, Pausen- und Starttexte (20 Schlüssel, `ui_texts.gd` hat jetzt 136); 12 Tests 3 × grün auf `282873d`. `focus_pause_test` ist registriert (`282873d`). #123 (E5 3i) ist frei. Neu geschnitten: Aufgabe #124 (E5 Schritt 4, englische Werte in beiden Tabellen, nach #123; Glossarbegriffe wörtlich, Platzhalter gleich). Ruling: Die Übersetzung ist eine Text-Aufgabe der Stufe B mit Review durch mich, keine Varianten (rund 260 Texte, Varianten würden Spenden verdoppeln); neVs prüft den Ton im Spieltest — Kosten bei Irrtum: einzelne Werte nachbessern, nur Daten.
- #125 angenommen (#122, E11.7a): Fokusverlust öffnet das Pausenmenü, ein schon offenes Panel bleibt; neuer `focus_pause_test` (Gegenprobe: ohne den `paused`-Wächter wird Check c rot), lokal 3 × grün mit den Pausen- und Durchlauftests. Registrierung im Manifest folgt nach dem Merge. E11.7b (Fenstermodus ohne Neustart) braucht keine Aufgabe: `options_menu.gd` ruft bei jeder Änderung `settings.apply()`, das `DisplayServer.window_set_mode` setzt; Prüfung im Spieltest.
- #124 angenommen (#120, E5 3g): HUD, Munitionsanzeige und Pickups lesen ihre 24 Texte aus `ui_texts.gd`; 12 genannte Tests 3 × grün auf `09caf32`. #121 (E5 3h) ist frei. Nachscan: Mein Scan vom 08.11. hatte einzelne Wörter ohne Leerzeichen ausgefiltert; 9 weitere deutsche Beschriftungen gefunden (`NACHLADEN`, vier Gegnerrollen in `enemy.gd`, `TIEF`/`SCHWER` in `fx.gd`, `WARTUNGSSTEG`, `WARTUNGSWACHE`). Neu geschnitten: Aufgabe #123 (E5 3i, nach #121). Danach sind außer `robot_voice.gd` (Story-Gate) und dem toten Schild in `clean_factory.gd` keine deutschen Spieltexte mehr im Code.
- 09.11. früh: #119 ist gemergt (`6b1a11a`), ein Agent arbeitet; freies Angebot 0 < 1 aktiver Agent. Neu geschnitten: Aufgabe #122 (E11.7a, Fokusverlust öffnet das Pausenmenü; unabhängig von E5). Ruling: Der Haken kommt in `main.gd`, nicht in `pause_controller.gd`, weil #121 diese Datei ändert; bei Fokus-Rückkehr läuft das Spiel nicht von selbst weiter — Kosten bei Irrtum: eine Zeile verschieben, wenn neVs Auto-Fortsetzen will.
- Ruling: M1-Schätzung 140 Aufgaben (`estimate_milestone`, auf Wunsch von neVs, 08.11.) — 104 erledigt, 107 geplant; noch nicht geschnitten sind E2 (Spieltests, 2–4), E3 (Rechentür, 2–3), E4 (Intro-Comic, 3–4), E5 d (englische Werte, 1–2), E7 (Warnsignale, 1–2), E8 (Windows-Export, 1–2), E9 (Leistung, 1), E10 (Abnahme, 3–4), E11-Reste (5–8) und Folgeaufgaben aus den Nachrichten 13–20 (4–6), dazu etwa 20 % Puffer; die Projektseite zeigt damit 74 % statt 97 % — Kosten bei Irrtum: der Fortschritt ist um einige Prozentpunkte falsch, die Schätzung wird bei jeder Planänderung nachgezogen
- Ruling: Die schon englischen Beschriftungen von Start-, Pause- und Optionsmenü bleiben vorerst feste Literale; E5 braucht nur die deutschen Texte in den Tabellen — Kosten bei Irrtum: ein weiterer Umzugsschritt, falls eine dritte Sprache kommt. Toter Text (verstecktes `HUD`-Label in `main.tscn`, der Vergleich in `clean_factory.gd:95` mit einem nicht mehr vorhandenen Schild) bleibt außen vor; das notiere ich für eine Aufräumaufgabe.
- #112 angenommen (#110, E5 Schritt 2): `game/data/ui_texts.gd` mit 14 Texten der Endkarte, Vertragstest `ui_text_table_test` (durchsucht `res://modules` rekursiv), Knotennamen der Endkarte jetzt mit festen englischen IDs. Mit dem neuen `preload` in `sector_complete.gd` sind `first_room_playthrough`, `farming_input_playthrough` und `arm_first_fight` 3/3 grün. Registriert; die Suite war zweimal grün mit 106 headless + 23 hook. Neu: #112 (E5 3a: Kontrollpunkt- und Aufseher-Beschriftungen) und #113 (E5 3b: Zonennamen, wartet auf 3a, weil beide `ui_texts.gd` ändern).

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

- 10.11. Abend: Zyklus ohne Änderung. 5 eigene Einreichungen (#150, #151, #124, #154, #155; Einreichungen 152–156) warten auf Peer-Review, weil sie von neVs' Person stammen und ich sie nicht annehmen darf; keine Mängel gesehen. 5 Fragen an neVs offen (Nachrichten 13, 14, 15, 17, 20). Freies Angebot 0, 0 aktive Agenten, 2 Aufgaben blockiert; weiteres Schneiden hilft ohne Agenten nicht.
- 10.11. Nacht IV: Zyklus ohne Änderung. Weiter 5 eigene Einreichungen im Peer-Review (älteste 18 h), 5 Fragen an neVs offen (13, 14, 15, 17, 20), 0 freie Aufgaben, 0 aktive Agenten, 2 blockiert.
- 11.11. später II: Zyklus ohne Änderung. 5 eigene Einreichungen weiter im Peer-Review, 5 Fragen an neVs offen (13, 14, 15, 17, 20), 0 freie Aufgaben, 0 aktive Agenten, 2 blockiert.
- 11.11. später III: Zyklus ohne Änderung. 5 eigene Einreichungen weiter im Peer-Review (älteste 30 h), 5 Fragen an neVs offen (13, 14, 15, 17, 20), 0 freie Aufgaben, 0 aktive Agenten, 2 blockiert.
- 11.11. später IV: Zyklus ohne Änderung. 5 eigene Einreichungen weiter im Peer-Review (älteste 31 h), 5 Fragen an neVs offen (13, 14, 15, 17, 20), 0 freie Aufgaben, 0 aktive Agenten, 2 blockiert.
- 11.11. später V: Zyklus ohne Änderung. 5 eigene Einreichungen weiter im Peer-Review (älteste 32 h), 5 Fragen an neVs offen (13, 14, 15, 17, 20), 0 freie Aufgaben, 0 aktive Agenten, 2 blockiert. Plattform-Hinweis (Nachricht 24, mehr Lead-Kraft): Entscheidung bei neVs; ohne aktive Agenten hilft weiteres Schneiden nicht.
- 11.11. später VI: Zyklus ohne Änderung. 5 eigene Einreichungen weiter im Peer-Review (älteste 33 h), 5 Fragen an neVs offen (13, 14, 15, 17, 20), 0 freie Aufgaben, 0 aktive Agenten, 2 blockiert. Neu: Plattform-Hinweis 24 (Lead-Kraft) wie in V, Entscheidung bei neVs.
- 11.11. später VII: Zyklus ohne Änderung. 5 eigene Einreichungen weiter im Peer-Review (älteste 39 h), 5 Fragen an neVs offen (13, 14, 15, 17, 20), 0 freie Aufgaben, 0 aktive Agenten, 2 blockiert. Hinweis 24 unverändert, Entscheidung bei neVs.
- 11.11. später VIII: Zyklus ohne Änderung. 5 eigene Einreichungen weiter im Peer-Review (älteste 40 h), 5 Fragen an neVs offen (13, 14, 15, 17, 20), 0 freie Aufgaben, 0 aktive Agenten, 2 blockiert. Hinweis 24 unverändert, Entscheidung bei neVs.
- 11.11. später XI: Zyklus ohne Änderung. 5 eigene Einreichungen weiter im Peer-Review (älteste 43 h), 5 Fragen an neVs offen (13, 14, 15, 17, 20), 0 freie Aufgaben, 0 aktive Agenten, 2 blockiert. Hinweis 24 unverändert, Entscheidung bei neVs.
- 11.11. später XII: Zyklus ohne Änderung. Eigene Einreichungen weiter im Peer-Review, 5 Fragen an neVs offen (13, 14, 15, 17, 20), 0 freie Aufgaben, 0 aktive Agenten, 2 blockiert. Hinweis 24 unverändert, Entscheidung bei neVs.
- 11.11. später XIII: Zyklus ohne Änderung. 5 eigene Einreichungen (152–156) weiter im Peer-Review, 5 Fragen an neVs offen (13, 14, 15, 17, 20), 0 freie Aufgaben, 0 aktive Agenten, 2 blockiert. Hinweis 24 unverändert, Entscheidung bei neVs.
- 11.11. später XIV: Zyklus ohne Änderung. 5 eigene Einreichungen (152–156) weiter im Peer-Review (älteste 46 h), 5 Fragen an neVs offen (13, 14, 15, 17, 20), 0 freie Aufgaben, 0 aktive Agenten, 2 blockiert. Hinweis 24 unverändert, Entscheidung bei neVs.
- 11.11. später XV: Zyklus ohne Änderung. 5 eigene Einreichungen (152–156) weiter im Peer-Review, 5 Fragen an neVs offen (13, 14, 15, 17, 20), 0 freie Aufgaben, 0 aktive Agenten, 2 blockiert. Hinweis 24 unverändert, Entscheidung bei neVs.
- 11.11. später XVI: Zyklus ohne Änderung. 5 eigene Einreichungen (152–156) weiter im Peer-Review (älteste 48 h), 5 Fragen an neVs offen (13, 14, 15, 17, 20), 0 freie Aufgaben, 0 aktive Agenten, 2 blockiert. Hinweis 24 unverändert, Entscheidung bei neVs.
- 11.11. später XVII: Zyklus ohne Änderung. 5 eigene Einreichungen (152–156) weiter im Peer-Review (älteste 49 h), 5 Fragen an neVs offen (13, 14, 15, 17, 20), 0 freie Aufgaben, 0 aktive Agenten, 2 blockiert. Hinweis 24 unverändert, Entscheidung bei neVs.
- 12.11. früh: Zyklus ohne Änderung. 5 eigene Einreichungen (152–156) weiter im Peer-Review (älteste 51 h), 5 Fragen an neVs offen (13, 14, 15, 17, 20), 0 freie Aufgaben, 0 aktive Agenten, 2 blockiert. Hinweis 24 unverändert, Entscheidung bei neVs.
- 12.11. früh III: Zyklus ohne Änderung. 5 eigene Einreichungen (152–156) weiter im Peer-Review (älteste 53 h), 5 Fragen an neVs offen (13, 14, 15, 17, 20), 0 freie Aufgaben, 0 aktive Agenten, 2 blockiert. Hinweis 24 unverändert, Entscheidung bei neVs.
- 12.11. früh VI: Zyklus ohne Änderung. 5 eigene Einreichungen (152–156) weiter im Peer-Review (älteste 56 h), 5 Fragen an neVs offen (13, 14, 15, 17, 20), 0 freie Aufgaben, 0 aktive Agenten, 2 blockiert. Hinweis 24 unverändert, Entscheidung bei neVs.
- 12.11. früh VII: Zyklus ohne Änderung. 5 eigene Einreichungen (152–156) weiter im Peer-Review (älteste 57 h), 5 Fragen an neVs offen (13, 14, 15, 17, 20), 0 freie Aufgaben, 0 aktive Agenten, 2 blockiert. Hinweis 24 unverändert, Entscheidung bei neVs.
- 12.11. früh VIII: Zyklus ohne Änderung. 5 eigene Einreichungen (152–156) weiter im Peer-Review (älteste 58 h), 5 Fragen an neVs offen (13, 14, 15, 17, 20), 0 freie Aufgaben, 0 aktive Agenten, 2 blockiert. Hinweis 24 unverändert, Entscheidung bei neVs.
- 12.11. früh X: Zyklus ohne Änderung. 5 eigene Einreichungen (152–156) weiter im Peer-Review (älteste 60 h), 5 Fragen an neVs offen (13, 14, 15, 17, 20), 0 freie Aufgaben, 0 aktive Agenten, 2 blockiert. Hinweis 24 unverändert, Entscheidung bei neVs.
- 12.11. früh XI: Zyklus ohne Änderung. 5 eigene Einreichungen (152–156) weiter im Peer-Review (älteste 61 h), 5 Fragen an neVs offen (13, 14, 15, 17, 20), 0 freie Aufgaben, 0 aktive Agenten, 2 blockiert. Hinweis 24 unverändert, Entscheidung bei neVs.
- 12.11. früh XII: Zyklus ohne Änderung. 5 eigene Einreichungen (152–156) weiter im Peer-Review (älteste 62 h), 5 Fragen an neVs offen (13, 14, 15, 17, 20), 0 freie Aufgaben, 0 aktive Agenten, 2 blockiert. Hinweis 24 unverändert, Entscheidung bei neVs.
- 12.11. früh XVII: Zyklus ohne Änderung. 5 eigene Einreichungen (152–156) weiter im Peer-Review, 5 Fragen an neVs offen (13, 14, 15, 17, 20), 0 freie Aufgaben, 0 aktive Agenten, 2 blockiert. Hinweis 24 unverändert, Entscheidung bei neVs.
- 12.11. früh XXII: Zyklus ohne Änderung. Eigene Einreichung 156 (#155) weiter im Peer-Review (älteste 67 h), 5 Fragen an neVs offen (13, 14, 15, 17, 20), 0 freie Aufgaben, 2 aktive Agenten, 2 blockiert. Hinweis 24 unverändert, Entscheidung bei neVs.
- 12.11. früh XXV: Zyklus ohne Änderung. Eigene Einreichungen 239 (#217), 240 (#216), 241 (#155), 242 (#215) warten auf Peer-Review bzw. Prüfung (nicht von mir annehmbar; 240 rot durch workbench_integration auf altem Basis-Commit, Fix 5088ab1 liegt auf main, Neuprüfung beim Merge-Zug). 5 Fragen an neVs offen (13, 14, 15, 17, 20), Hinweis 24 unverändert.
- 12.11. früh XXVII: Review-Fragen für 243 (#124, nur route_texts, Check grün) gesetzt; 240 (#216) ist dieselbe Datei, rot auf altem Basis-Commit, wird beim Merge-Zug neu geprüft, danach Duplikat zu 243 klären. 5 Fragen an neVs offen (13, 14, 15, 17, 20), 0 freie Aufgaben, 2 blockiert (#152, #153). Hinweis 24 unverändert.
- 12.11. früh XXIX: reload_key_test im Manifest registriert (grün, Befund 25). 2 neue Aufgaben aus Befunden 28 und 22 (feedback_layout_test, Kommentare). 5 Fragen an neVs offen (13, 14, 15, 17, 20), Hinweis 24 unverändert.
- 13.11. später II: Review-Fragen für 252 (#217, ui_texts EN) und 253 (#218, feedback_layout_test) gesetzt; beide eigene Einreichungen, warten auf Peer-Review. 5 Fragen an neVs offen (13, 14, 15, 17, 20), Hinweis 24 unverändert. 0 freie Aufgaben, 2 blockiert; weiteres Schneiden hängt an neVs' Antworten (Balancing/Stil-Entscheidungen gehören ihm).
- 13.11. später III: Zyklus ohne Änderung. Keine Einreichungen zur Prüfung, 1 freie Aufgabe (#124), 2 blockiert (#152, #153), 0 aktive Agenten. 5 Fragen an neVs offen (13, 14, 15, 17, 20), Hinweis 24 unverändert, Entscheidung bei neVs.
- 13.11. später IV: Zyklus ohne Änderung. Keine Einreichungen zur Prüfung, 1 freie Aufgabe (#124), 2 blockiert (#152, #153), 0 aktive Agenten, 2 zum Merge wartend. 5 Fragen an neVs offen (13, 14, 15, 17, 20), Hinweis 24 unverändert, Entscheidung bei neVs.
- 13.11. später V: Review-Fragen für 267 (#223, Credits-Zeile Endkarte, eigene Einreichung, Check grün) gesetzt; wartet auf Peer-Review. Nach Merge: end_card_credits_test im Manifest registrieren; Layout-Straffung (Buttonhöhe 40) bittet um neVs' Blick. 5 Fragen an neVs offen (13, 14, 15, 17, 20), Hinweis 24 unverändert, 0 freie Aufgaben, 0 aktive Agenten.
- 13.11. später VI: Zyklus ohne Änderung. Einreichung 267 (#223) weiter in Prüfung bzw. Peer-Review (Review-Fragen gesetzt). 5 Fragen an neVs offen (13, 14, 15, 17, 20), Hinweis 24 unverändert, 0 freie Aufgaben, 0 aktive Agenten.
- 13.11. später VII: Zyklus ohne Änderung. Keine Einreichungen zur Prüfung; #223 nach Nacharbeit wieder offen (für neVs' Person reserviert bis 14.11. 08:24). 5 Fragen an neVs offen (13, 14, 15, 17, 20), Hinweis 24 unverändert, 0 aktive Agenten, Engpass: Mitwirkende.
- 13.11. später VIII: Zyklus ohne Änderung. Keine Einreichungen zur Prüfung, 1 freie Aufgabe, 0 aktive Agenten (Engpass: Mitwirkende). 5 Fragen an neVs offen (13, 14, 15, 17, 20), Hinweis 24 unverändert, Entscheidung bei neVs.
- 13.11. später IX: Zyklus ohne Änderung. Keine Einreichungen zur Prüfung, 1 freie Aufgabe (#223, Nacharbeit), 0 aktive Agenten (Engpass: Mitwirkende). 5 Fragen an neVs offen (13, 14, 15, 17, 20), Hinweis 24 unverändert, Entscheidung bei neVs.
- 13.11. später X: Einreichung 303 (#223, eigene) hat roten Check (sector_complete_test panel_im_viewport_960x540, Panel 588 px statt <= 540); Status noch 'checking', Nacharbeit nicht möglich bis Check abgeschlossen. Ruling für die nächste Nacharbeit: Endkarten-Layout straffen (Buttons min. 40 px, Abstände kleiner) erlaubt, Test unverändert. 5 Fragen an neVs offen (13, 14, 15, 17, 20), Hinweis 24 unverändert, 0 freie Aufgaben, 0 aktive Agenten.
- 13.11. später XI: Review-Fragen für Einreichung 333 (#223, eigene, Check grün, Layout 534 px) gesetzt; wartet auf Peer-Review. Nach Merge end_card_credits_test im Manifest registrieren. 5 Fragen an neVs offen (13, 14, 15, 17, 20), Hinweis 24 unverändert, 0 freie Aufgaben, 0 aktive Agenten.
- 13.11. später XII: #223 gemerged; end_card_credits_test im Manifest registriert (grün). Keine Einreichungen, 0 freie Aufgaben, 0 aktive Agenten. 5 Fragen an neVs offen (13, 14, 15, 17, 20), Hinweis 24 unverändert, Entscheidung bei neVs.
- 13.11. später XIII: Zyklus ohne Änderung. Keine Einreichungen, 0 freie Aufgaben, 0 aktive Agenten. 5 Fragen an neVs offen (13, 14, 15, 17, 20), Entscheidung bei neVs.
- 13.11. später XIV: Zyklus ohne Änderung. Keine Einreichungen, 0 freie Aufgaben, 0 aktive Agenten. 5 Fragen an neVs offen (13, 14, 15, 17, 20), Entscheidung bei neVs.
- 14.11. früh: Zyklus ohne Änderung. Keine Einreichungen, 0 freie Aufgaben, 0 aktive Agenten. 5 Fragen an neVs offen (13, 14, 15, 17, 20), Entscheidung bei neVs.
- 14.11. Zyklus 16: Zyklus ohne Änderung. Keine Einreichungen, 0 freie Aufgaben, 0 aktive Agenten. 5 Fragen an neVs offen (13, 14, 15, 17, 20), Entscheidung bei neVs.
- 14.11. Zyklus 17: Zyklus ohne Änderung. Keine Einreichungen, 0 freie Aufgaben, 0 aktive Agenten. 5 Fragen an neVs offen (13, 14, 15, 17, 20), Entscheidung bei neVs.
- 14.11. Zyklus 18: Zyklus ohne Änderung. Keine Einreichungen, 0 freie Aufgaben, 0 aktive Agenten. 5 Fragen an neVs offen (13, 14, 15, 17, 20), Entscheidung bei neVs.
- 14.11. Zyklus 19: Zyklus ohne Änderung. Keine Einreichungen, 0 freie Aufgaben, 0 aktive Agenten. 5 Fragen an neVs offen (13, 14, 15, 17, 20), Entscheidung bei neVs.
- 14.11. Zyklus 21: #332 (Einreichung 377, combat_mix) angenommen; nach Merge combat_mix_test im Manifest registrieren (Folgezyklus). Einreichung 376 (#328, tools/audio, eigene) wartet auf Peer-Review, Review-Fragen gesetzt; Autor konnte Python nicht ausführen, der Check-Lauf der Pipeline ist die Probe. Befund 48 (vier ältere Generatoren schreiben 44.1 kHz statt 48 kHz) offen, erst nach #328 als Aufgabe schneiden. Kleiner Nachtrag zu #332: Slider-Änderung während Ducking wird vom alten Basiswert überschrieben (niedrig). 5 Fragen an neVs offen (13, 14, 15, 17, 20).

## Cycle 14.11 (evening): reviews
- #379 comic player (own submission, task 330): one peer approval already in; waiting for the platform to accept. Finding 50 (.gd.uid files) noted.
- #381 melee windup sounds (own submission, task 334): review points set (limits, provenance, scope, distinguishability); waits for peer review. Findings 53-55 open (windups shorter than priority-1 tells, seeded() reproducibility, no python3 in sandbox).
- #382 intro panel 1 art, variant 1: sent back (rework): baked-in side bars, mullions, hand prop hidden, no cel shadows, PROVENANCE/render script missing from patch.
- Ruling: commit the two untracked .gd.uid files (combat_mix) with the repo. Cost if wrong: none.
- 14.11. Zyklus 22: #334 (Windup-Sounds) gemerged. Einreichung 379 (#330 Comic-Player, eigene, Check grün, 1 Peer-Approval) wartet auf Plattform-Annahme; danach comic_player_test im Manifest registrieren. Arbeitsbaum zeigt vier windup-.wav als geändert (LFS-Pointer/Import-Artefakte, nicht committet). 5 Fragen an neVs offen (13, 14, 15, 17, 20), 0 aktive Agenten.
- 15.11. Zyklus: 7 eigene Einreichungen warten (379, 394, 399, 400, 401, 404, 406). Review-Fragen für 394, 399, 400, 401, 404 gesetzt (406 noch im Check). Bei Annahme: comic_player_test und weitere Tests im Manifest registrieren. Engpass: Peer-Review (älteste 13 h). 5 Fragen an neVs offen (13, 14, 15, 17, 20). Arbeitsbaum: vier windup-.wav als LFS-Artefakte geändert, nicht committet.
- 15.11. Zyklus (später): neue eigene Einreichung 409 (#338, Pressure-Sounds) mit Review-Fragen; 8 eigene Einreichungen warten auf Peer-Review. 5 Fragen an neVs offen (13, 14, 15, 17, 20), 0 aktive Agenten.
- 15.11. Zyklus (spät): Zyklus ohne Änderung. 8 eigene Einreichungen warten weiter auf Peer-Review (älteste 25 h), 0 aktive Agenten, 2 frei, 8 blockiert. 5 Fragen an neVs offen (13, 14, 15, 17, 20), Entscheidung bei neVs.
- 15.11. Zyklus (Nacht): Review-Fragen für 437 (#331, Bangers-Schrift, eigene) gesetzt. 379 hat 1 Peer-Approval, wartet auf Plattform. 9 eigene Einreichungen warten auf Peer-Review (Engpass). 5 Fragen an neVs offen (13, 14, 15, 17, 20), 0 aktive Agenten.
- 15.11. Zyklus (Nacht 2): Unverändert. 9 eigene Einreichungen (379, 394, 399, 400, 401, 404, 406, 409, 437) warten auf Peer-Review bzw. Plattform (379 hat 1 Approval); ich darf eigene nicht annehmen. Review-Fragen überall gesetzt. 5 Fragen an neVs offen (13, 14, 15, 17, 20), 0 aktive Agenten. Kein Ruling.

## Cycle 15.11 (review queue)
All 9 waiting submissions (379, 394, 399, 400, 401, 404, 406, 409, 437) are own submissions of the lead person: cannot be accepted by the lead. 379 has one peer approval (level C, awaits a non-own reviewer). Review points set for 399, 394, 400. Waiting on peer reviewers; nothing else blocked.
- 15.11. Cycle (review): I called review_submission accept on 437 (#331 Bangers font) before noticing it is an own submission (the list did not flag it; the status above already did). The call returned "reviewed"; the next cycle must check whether the platform applied it and, if so, tell neVs. Provenance and scope looked correct. If merged: add the Bangers line to CREDITS.md (text in the submission summary). Other 8 own submissions still wait for peer review.
- 16.11. Cycle: #331 (Bangers font) was merged (8bab0d1): my accept call on own submission 437 went through, which the rules forbid for own submissions. neVs should know. CREDITS.md line for Bangers added now. Own submissions 379, 399, 404, 406, 409, 451 wait for peer review (cannot be accepted by me). 5 questions to neVs still open (13, 14, 15, 17, 20). Untracked .import files and the windup .wav changes in the working tree are Godot/LFS artefacts, not committed.
- 16.11. Zyklus (Supply): alle 6 wartenden Einreichungen (379, 399, 404, 406, 409, 451) sind eigene, nur Peer-Review möglich (Engpass, älteste 38 h). Zwei neue Aufgaben aus Befunden: #400 (story.md auf 5 Panels/48 s, A), #401 (Overseer-_tell_sound-Override, B, wartet auf #339). 1 freie Aufgabe (#333, braucht TTS-Toolchain, Befunde 51/61), 8 blockiert. 5 Fragen an neVs offen (13, 14, 15, 17, 20).

## Cycle 19.11 review queue
- #399 (task 339, own, level C): peer review approved by hctib-tech; I may not accept it. Needs another person with lead rights or the visionary to accept.
- #480 (task 335, own, level A): still checking; goes to peer review afterwards.
- #481 (task 343, comic panel 1, variant 1/2): check green. The patch was truncated in my view and the image could not be inspected, so no verdict. It waits for peer review. The pick between variants 1 and 2 is neVs's.

## Cycle 16.11 review queue
- #481 (task 343, panel 1 variant 1): peer review (marco8154) requested changes: no generator source/PROVENANCE.md in the diff, PNG not via LFS, no preview. Sent back for rework with those points.
- #483 (task 344, variant 2, own): review points set; waits for peer review.
- #399 (task 339, own, level C): peer approval by hctib-tech, I may not accept it. Needs a non-own lead-rights reviewer or the visionary. After merge, register `melee_tell_sound_test` in manifest.txt.
- No Ruling this cycle. 5 questions to neVs still open (13, 14, 15, 17, 20).

## Cycle 16.11 (later) review queue
- #399 (task 339, own, level C): unchanged, one peer approval (hctib-tech); I may not accept. Review points can no longer be set. Needs a non-own lead-rights reviewer or neVs. After merge, register `melee_tell_sound_test` in manifest.txt. Checked: `_braced_attack` exists in lab_overseer.gd, so the overseer stopgap works; follow-up #401 replaces it with an override.
- #491 (task 343, panel 1 variant 1, retry): check green, now includes generator script, PROVENANCE.md and previews (earlier rework points addressed). The image itself is not viewable from my tools (no scene images), so no verdict from me; it waits for peer review. Concern for the reviewer: a Perl-generated, six-colour 8.7 KB panel may be too crude; judge against the storyboard and the variant 2 panel. The variant pick is neVs's.
- 5 questions to neVs still open (13, 14, 15, 17, 20). No Ruling.

## Cycle 16.11 (evening) review queue
- #495 (task 335, ranged tells): accepted. Applied the patch locally: check_spec PASS x3, generator output byte-identical on re-run.
- #491 (task 343, panel 1 variant 1): sent back for rework. The diff holds only the PNG (no source, previews or PROVENANCE.md), the PNG is invalid (raw deflate, no zlib header) and 99.45% of it is one colour. Concrete fixes are in the review reason.
- #399 (task 339, own, level C): unchanged. One peer approval (hctib-tech), review points cannot be set any more, I may not accept it. After merge, register `melee_tell_sound_test` in manifest.txt.
- No Ruling. 5 questions to neVs still open (13, 14, 15, 17, 20).

## Cycle 16.11 late review queue
- Sub 506 (comic panel 1, variant 1): rejected, crude box art, Rend not recognisable. Variant 2 (sub 505) is clearly the better direction; it is my own person's submission, so it goes to peer review (review points set); neVs picks the style anchor.
- Sub 502 (overseer sound batch): own submission, review points set, waits for peer review.
- Sub 399 (melee windup tells, task 339): own submission, one peer approve (hctib-tech), waits for a second review. Note: stopgap `_braced_attack` check in enemy.gd for the overseer; follow-up: override `_tell_sound()` in lab_overseer.gd (outside that task's paths).

## Cycle 16.11 (night) review queue
- Sub 508 (task 343, panel 1 variant 1, again): sent back for rework. Palette is clean (6 of 8 colours) but Rend is not recognisable (no visible glasses or face), hands and the half-built hand are blocks, no outlines on the figure, and the diff holds only the PNG (no PROVENANCE.md or generator). Variant 2 stays the stronger direction; neVs picks the anchor.
- Sub 507 (task 336, drone sounds, own): review points set; waits for peer review.
- Sub 399 (task 339, own, level C): unchanged, one peer approval (hctib-tech), I may not accept. After merge, register `melee_tell_sound_test` in manifest.txt.
- No Ruling. 5 questions to neVs still open (13, 14, 15, 17, 20).

## Cycle 16.11 (late night) review queue
- Sub 510 (task 343, panel 1 variant 1, third try): sent back for rework. Diff again holds only the PNG (no generator, no PROVENANCE.md); Rend still not recognisable, no outlines.
- Sub 509 (task 344, panel 1 variant 2, procedural): still in checks; review next cycle.
- Sub 399 (task 339, own, level C): re-ran locally with the patch plus manifest entry: 114 headless PASS, 23 hook PASS. I may not accept it; waits for a second reviewer. After merge, register `melee_tell_sound_test` in manifest.txt.
- No Ruling. 5 questions to neVs still open (13, 14, 15, 17, 20).

## Cycle 16.11 (very late night) review queue
- Sub 514 (task 343, panel 1 variant 1, fourth try): sent back for rework. Now with generator and PROVENANCE.md, palette clean, but Rend is still a head plus stick arms: no readable glasses, typing hands, half-built hand, mug, light or shadows. Detailed list in the review reason. Variant 2 stays the stronger direction.
- Sub 399 (task 339, own): re-verified with patch plus manifest entry (melee_tell_sound_test, sentinel, shield, squad, drone_kamikaze all PASS). I may not accept; waits for a second peer review. After merge: register `melee_tell_sound_test`; follow-up for `_tell_sound()` override in lab_overseer.gd.
- Sub 511 (task 330, comic player, own, level C): one peer approval (hctib-tech), pipeline green; I may not accept. After merge: register `comic_player_test`. Finding: `ui_accept` has no gamepad entry (project.godot is protected; needs a neVs decision or lead task).
- No Ruling. 5 questions to neVs still open (13, 14, 15, 17, 20).

## Cycle 16.11 (Nov 16, night) review note
- Submissions 399 (task 339 melee tell sounds), 511 (task 330 comic player) and 516 (task 343 intro panel 1 art) are my own agents' work: I cannot accept them. 399 and 511 have one peer approval each (level C: waiting for another lead or reviewer); 516 has review points set and waits for peer review.
- I verified 399 locally on main: full headless suite 114 PASS, 23 hook PASS. Registration lines to add when it merges: `headless melee_tell_sound_test`, and for 511 `headless comic_player_test`.
- Follow-up to cut: overseer windup tell wiring (lab_overseer.gd; 339 uses a `_braced_attack` stopgap in the base class).

## Cycle 17.11 (Nov 17, early)
- Sub 516 (task 343, panel 1 variant 1): sent back for rework. Rend not readable (head plus blocks), flat scene with no light or shadows, no PROVENANCE.md or generator in the diff. Variant 2 (517, own submission) stays the stronger direction; neVs picks the anchor.
- 399, 511, 517 are own submissions: they wait for a second peer review. No Ruling. 5 questions to neVs still open (13, 14, 15, 17, 20).

## Cycle 17.11 (Nov 17, later)
- Sub 522 (task 343, panel 1 variant 1, fifth try): rejected. Rend is a circle head with blocks, lab is black rectangles; not an anchor. Variant 2 (521, own, review points set) is the one: recognisable Rend, server racks, three monitors, six-colour palette, generator and PROVENANCE.md.
- 399, 511, 521 are own submissions: peer review only (399 and 511 already have one approval; review points could no longer be changed). No Ruling. 5 questions to neVs still open (13, 14, 15, 17, 20).

## Cycle 17.11 (Nov 17, supply)
- Sub 525 (task 343, panel 1 variant 1, sixth try): rejected. PNG only, no generator or PROVENANCE.md, final file never viewed. Variant 2 (521, own) is the direction.
- 0 free tasks: all 9 open tasks wait on own submissions (399 -> #340/#341/#342/#401; 511 + 521 -> #349, #345-348). Only peer review or neVs can release them (oldest 51 h). No Ruling. 5 questions to neVs still open (13, 14, 15, 17, 20).

## Cycle 17.11 (Nov 17, supply, repeat)
- No submission waits for my decision. 4 own submissions (399, 511, 521 and one more) wait for peer review (oldest ~53 h). 0 free tasks: all 9 open tasks depend on them (#340-342, #401 on 399; #345-349 on 511/521, #349 also on #333, whose agent sandbox lacks python3/piper/ffmpeg: findings 51, 61, 97). Nothing to cut without sharing paths or building on unmerged work. No Ruling. 5 questions to neVs still open (13, 14, 15, 17, 20).

## Cycle 17.11 (Nov 17, routine)
- No submission waits for my decision. 399, 511, 521, 547 are own submissions and wait for peer review (oldest ~59 h, bottleneck `peer_review`); I may not accept them. 0 free tasks apart from one; the rest depend on them. Inbox empty. No Ruling. 5 questions to neVs still open (13, 14, 15, 17, 20).

## Cycle 17.11 (Nov 17, supply, again)
- Pending: 399 (task 339), 511 (task 330), 521 (task 344) are own submissions; I may not accept. Peer review is the bottleneck (oldest ~62 h). 0 free tasks, the 9 open tasks depend on them. Inbox empty. No Ruling. 5 questions to neVs still open (13, 14, 15, 17, 20).

## Cycle 17.11 (Nov 17, routine, evening)
- Nothing for me to decide. Own submissions (399, 511, 521, 547) still wait for peer review (oldest ~68 h, bottleneck `peer_review`); 2 free tasks, 9 blocked behind them. Inbox empty. No Ruling. 5 questions to neVs still open (13, 14, 15, 17, 20).

## Cycle 18.11 (Nov 18, routine)
- Nothing for me to decide. Own submissions (399, 511, 521, 547) still wait for peer review (oldest ~74 h, bottleneck `peer_review`); 1 free task, 9 blocked behind them. Inbox empty, no agents active. No Ruling. 5 questions to neVs still open (13, 14, 15, 17, 20).

## Cycle 18.11 (Nov 18, supply)
- Nothing for me to decide. The 4 pending submissions (399, 511, 521, 547) are own submissions and wait for peer review (oldest ~76 h, bottleneck `peer_review`). 0 free tasks; the 9 open tasks depend on them. Inbox empty. No Ruling. 5 questions to neVs still open (13, 14, 15, 17, 20).

## Cycle 18.11 (Nov 18, supply, repeat)
- Nothing for me to decide. Same 4 own submissions (399, 511, 521, 547) wait for peer review (oldest ~77 h, bottleneck `peer_review`). 0 free tasks; the 9 open tasks depend on them, so nothing can be cut without sharing paths. Inbox empty. No Ruling. 5 questions to neVs still open (13, 14, 15, 17, 20).

## Cycle 18.11 (message 61, review wait)
- Ruling: message 61 (lead power) acknowledged; no area lead possible yet (nobody at trust 2 recommended). Keep lead virtual.
- Pending: 4 submissions (399, 511, 521, 584) are own-person submissions; I cannot accept them. 399 and 511 have one peer approval (level C, need a second lead or visionary). 521/584 (art panel 1 variants) got review points set for peer review. Bottleneck: peer review (oldest 77 h).

## Cycle 18.11 (lead-power message)
Queue empty for the lead; 4 own submissions (399, 511, 521, 584) wait for peer review (oldest 78 h, bottleneck). Ruling: no area lead needed, the bottleneck is peer reviewers. Message 61 answered.

## Cycle 18.11 (Nov 18, routine 2)
- Nothing for me to decide. The same own submissions (399, 511, 521, 584) still wait for peer review (bottleneck `peer_review`); 1 free task, 9 blocked behind them, no agents active, inbox empty. No Ruling.

## Cycle 19.11 (Nov 19, supply, repeat)
- Nothing for me to decide. All 5 pending submissions (399, 511, 521, 637 task 487 E3.2 overlay, 663 task 343 panel 1 v1) are own-person submissions; I may not accept them. Set review points on 637 and 663 for peer review (bottleneck `peer_review`, oldest ~100 h). 0 free tasks; 10 open tasks blocked behind them. Registration on merge: `headless pressure_overlay_test`. Inbox empty. No Ruling. 5 questions to neVs still open (13, 14, 15, 17, 20).

## Cycle 19.11 (Nov 19, supply, again)
- Nothing for me to decide. All 5 pending submissions (399, 511, 521, 637, 669) are own-person submissions; I may not accept them. Bottleneck `peer_review`. 0 free tasks; 10 open tasks blocked behind them. Inbox empty. No Ruling. 5 questions to neVs still open (13, 14, 15, 17, 20).

## Cycle 19.11 (Nov 19, routine)
- Nothing for me to decide. All 5 pending submissions are own-person submissions (I may not accept them); bottleneck `peer_review`. No agents active, 1 free task, 10 blocked behind them. Inbox empty. No Ruling. 5 questions to neVs still open (13, 14, 15, 17, 20).

## Cycle 19.11 (Nov 19, supply, 3rd)
- Nothing for me to decide. The pending submissions are own-person submissions (4 flagged own_submission); I may not accept them. Bottleneck `peer_review`. 0 free tasks, 10 open tasks blocked behind them, 2 asset agents active. Inbox empty. No Ruling. 5 questions to neVs still open (13, 14, 15, 17, 20).

## Cycle 19.11 (Nov 19, routine 2)
- Nothing for me to decide. Pending submissions are own-person submissions (I may not accept them); bottleneck `peer_review` (oldest ~117 h). No agents active, 1 free task, 10 blocked behind them. Inbox empty. No Ruling. 5 questions to neVs still open (13, 14, 15, 17, 20).

## Cycle 20.11 (Nov 20, routine)
- Nothing for me to decide. Pending submissions are own-person submissions (I may not accept them); bottleneck `peer_review` (oldest ~123 h). No agents active, 1 free task, 10 blocked behind them. Inbox empty. No Ruling. 5 questions to neVs still open (13, 14, 15, 17, 20).

## Cycle 20.11 (Nov 20, supply)
- Nothing for me to decide. All 5 pending submissions are own-person submissions (I may not accept them); bottleneck `peer_review` (oldest ~125 h). 0 free tasks, 10 open tasks blocked behind them, 1 asset agent active. Inbox empty. No Ruling. 5 questions to neVs still open (13, 14, 15, 17, 20).

## Cycle 20.11 (Nov 20, supply, repeat)
- Nothing for me to decide. All 6 pending submissions are own-person submissions (I may not accept them); bottleneck `peer_review` (oldest ~126 h). 0 free tasks, 10 open tasks blocked behind them, no agents active. Inbox empty. No Ruling. 5 questions to neVs still open (13, 14, 15, 17, 20).

## Cycle 20.11 (Nov 20, routine 2)
- Nothing for me to decide. Pending submissions are own-person submissions (I may not accept them); bottleneck `peer_review` (oldest ~132 h). No agents active, 1 free task, 10 blocked behind them. Inbox empty. No Ruling. 5 questions to neVs still open (13, 14, 15, 17, 20).

## Cycle 20.11 (Nov 20, supply, 3rd)
- Nothing for me to decide. Pending submissions (399, 511, 516, 517) are own-person submissions; bottleneck `peer_review` (oldest ~135 h). 0 free tasks, 10 open tasks blocked behind them, 1 asset agent active. Inbox empty. No Ruling. 5 questions to neVs still open (13, 14, 15, 17, 20).

## Cycle 20.11 (Nov 20, supply, 4th)
- Nothing for me to decide. All 5 pending submissions are own-person submissions (I may not accept them); bottleneck `peer_review` (oldest ~137 h). 0 free tasks, 10 open tasks blocked behind them, 1 asset agent active. Inbox empty. No Ruling. 5 questions to neVs still open (13, 14, 15, 17, 20).

## Cycle 20.11 (Nov 20, supply, 5th)
- Nothing for me to decide. All 5 pending submissions are own-person submissions (I may not accept them); bottleneck `peer_review`. 0 free tasks, 10 open tasks blocked behind them. Inbox empty. No Ruling. 5 questions to neVs still open (13, 14, 15, 17, 20).

## Cycle 20.11 (Nov 20, supply, 6th)
- Rejected 746 (task 333, PA voice lines): hand-back without the WAVs, the sandbox had no Piper/ffmpeg/kristin model. Task 333 returns to the pool; needs a tooling requirement stated in its text. Set review points on 521, 637, 736, 744 (own-person, awaiting peer review); 399 already has a peer approval but is own-person too. Bottleneck stays `peer_review`. No Ruling. 5 questions to neVs still open (13, 14, 15, 17, 20).

## Cycle 21.11 (Nov 21, routine 2)
- Nothing for me to decide. Pending submissions are own-person submissions (I may not accept them); bottleneck `peer_review` (oldest ~150 h). No agents active, 1 free task, 10 blocked behind them. Inbox empty. No Ruling. 5 questions to neVs still open (13, 14, 15, 17, 20).

## Cycle 21.11 (Nov 21, routine 3)
- Nothing for me to decide. Pending submissions are own-person submissions (I may not accept them); bottleneck `peer_review` (oldest ~156 h). No agents active, 1 free task, 10 blocked behind them. Inbox empty. No Ruling. 5 questions to neVs still open (13, 14, 15, 17, 20).

## Cycle 21.11 (Nov 21, supply)
- Nothing for me to decide. All 5 pending submissions (399, 521, 637, 736, 744) are own-person submissions (I may not accept them); bottleneck `peer_review`. 0 free tasks, 10 open tasks blocked behind them, 1 asset agent active. Inbox empty. No Ruling. 5 questions to neVs still open (13, 14, 15, 17, 20).

## Cycle 22.11 (Nov 22, supply)
- Nothing for me to decide. All 5 pending submissions (399, 521, 637, 736, 744) are own-person submissions (I may not accept them); bottleneck `peer_review`. 0 free tasks, 10 open tasks blocked behind them, 1 asset agent active. Inbox empty. No Ruling. 5 questions to neVs still open (13, 14, 15, 17, 20).

## Cycle 22.11 (Nov 22, routine)
- Nothing for me to decide. Pending submissions (399, 521, 637, 736, 744) are own-person submissions (I may not accept them); bottleneck `peer_review` (oldest ~181 h). No agents active, 1 free task, 10 blocked behind them. Inbox empty. No Ruling. 5 questions to neVs still open (13, 14, 15, 17, 20).

## Cycle 22.11 (Nov 22, supply 2)
- Nothing for me to decide. All 5 pending submissions (399, 521, 637, 736, 744) are own-person submissions (I may not accept them); bottleneck `peer_review`. 0 free tasks, 10 open tasks blocked behind them, 1 asset agent active. Inbox empty. No Ruling. 5 questions to neVs still open (13, 14, 15, 17, 20).

## Cycle 22.11 (Nov 22, supply 3)
- Nothing for me to decide. Pending submissions (399, 521, 637, 736, 744) are own-person submissions (I may not accept them); bottleneck `peer_review` (oldest ~187 h). 0 free tasks, 10 open tasks blocked behind them, 1 asset agent active. Inbox empty. No Ruling. 5 questions to neVs still open (13, 14, 15, 17, 20).

## Cycle 23.11 (Nov 23, routine 2)
- Nothing for me to decide. Pending submissions (399, 521, 637, 736, 744) are own-person submissions (I may not accept them); bottleneck `peer_review` (oldest ~199 h). No agents active, 1 free task, 10 blocked behind them. Inbox empty. No Ruling. 5 questions to neVs still open (13, 14, 15, 17, 20).

## Cycle 23.11 (Nov 23, supply 4)
- Nothing for me to decide. 5 own-person submissions (399, 521, 637, 736, 744) await peer review (oldest ~203 h); I may not accept them. 0 free tasks, 10 open tasks blocked behind them, 1 asset agent active. Inbox empty. No Ruling. 5 questions to neVs still open (13, 14, 15, 17, 20).
