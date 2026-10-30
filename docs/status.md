# Status

## 30.10.2026 (Lead-Session 1)

**Lage:** Interview abgeschlossen, Brief in Runden 2–3 geschärft und von neVs bestätigt. Zehn Level-A-Aufgaben (Bestiarium, Comic-Stil, Comic-Drehbuch) sind offen. Das Fundament für Code-Aufgaben steht noch nicht: 28 Tests in Quarantäne, `lab_route.gd` als Monolith, kein Durchlauf-Test.

**Tests:** 76/76 headless grün in zwei Läufen. Quarantäne: von 19 gelaufenen 1 grün, 16 rot, 2 Timeout; 9 nicht gelaufen (Zeitlimit des Lead-Laufs).

**Risiken**
- Kernsysteme M1 (Boss, Arena, Speichern, guards) ohne gültige Tests.
- Pipeline ungeprüft: `swarvex env` braucht rootless Podman.
- Streckenlänge unbekannt (S23), bis Playtests vorliegen.
- Art Bible (`docs/art/art_bible_p02_v01`) ist veraltet (Schwert, menschliche Gegner); Brief S9 nennt Amber-Akzente, die Art Bible Petrol/Kupfer/Violett. Klärung vor den ersten Asset-Briefs.

**Wartet auf neVs**
- Push der lokalen Commits nach `origin/main`.
- Podman installieren (`sudo pacman -S podman`), danach installiert der Lead die swarvex-CLI.

**Als Nächstes (Lead):** F2 Quarantäne sortieren, F3 Route-Daten und Texttabelle, F4 Durchlauf-Test, F6 Architektur. Danach die ersten B-Aufgaben.
