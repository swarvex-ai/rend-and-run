# Milestone 1: the first escape route

> Binding specification for milestone 1 (M1). Replaces `docs/scope-first-route.md` and GDD §2/§6 where they disagree.
> Source of the decisions: `docs/project-brief.md` (IDs in brackets). Owner: lead; scope changes only with neVs.
> Status 30.10.2026: written from the code state "route V12" (`game/lab_route.gd`, `game/modules/world/notstrom_layout.gd`, revision 2).

## Goal

Rend wakes up in the factory, finds a robot arm, fights through five zones and escapes through the airlock after destroying the overseer. A first run takes 9–11 minutes (G6). M1 ships as a free pre-alpha slice after neVs accepts it (G18).

## Done means (G6)

| # | Criterion | Checked by |
|---|---|---|
| a | an automated run reaches the airlock from the start without a crash | headless test `route_playthrough` (F4, since 06.11.2026) |
| b | first run takes 9–11 min; 2–5 deaths (S20) | playtest neVs + 2 fresh-eyes playtests |
| c | back in control < 10 s after death | headless test `route_playthrough` (2.43 s game time) |
| d | complete with keyboard and with gamepad | playtest checklist |
| e | 1080p at 60 fps on the reference PC (Ryzen 7 5800X3D, RX 6800 class, 32 GB, Linux; G21) | measurement run |
| f | 0 red, 0 flaky, 0 quarantined M1 tests | test pipeline |
| g | Windows export builds; smoke test on real Windows passes (G7) | export + level-A task |
| – | neVs accepts the slice | playtest neVs |

## The route today (x in metres along the run axis)

| Zone (in-game label today) | x | Content |
|---|---|---|
| 01 Arrival („ANKUNFT“) | -3 – 11 | wake-up, robot arm pickup, entry workbench (8.9), first guard (`first`, 8.5) |
| 02 Maintenance („WARTUNG“) | 11 – 24 | shortcut door (16.5), death cache plinth (18), power sector with maintenance guard |
| 03 Supply („VERSORGUNG“) | 24 – 29.5 | shield pickup (24), **checkpoint 1** (26), workbench (28.5) |
| 04 Security („SICHERUNG“) | 29.5 – 70 | shield bearer (`duelist`, 32.5), gun guard (`guard`, 40, smg), dog (`hound`, 43.5), drones (45.5, 62), gun guard (`freight_raider`, 48, pistol), weapon bench (51.5), shield bearer (`freight_duelist`, 56), **relay checkpoint** (58), **pressure task door** (new, directly after 58; S16, S19), gun guard (`relay_guard`, 64, energy rifle) |
| 05 Airlock („SCHLEUSE“) | 70 – 83 | arena gate (70), **overseer** (73; encounter id `brute` for save compatibility), security door / exit (79) |

Sentinels stand in alcoves along the route (`_spawn_sentinels`). PA announcements at 16.8, 30.5, 44.5, 57.5 and 69.0 (`PA_CUES`).

## Content in M1

- **Robots (S13):** guard, shield bearer, sentinel, dog, kamikaze drone, overseer. The welder counts as a hazard. Duelist and brute get no placements of their own as extra robot types, but their code is part of M1: the shield bearer is a duelist with a shield (`role 1`), the overseer builds on the brute (`role 2`, encounter id `brute`).
- **Weapons (S14):** robot arm, pistol, smg, scattergun, energy rifle, shield; throwable crates. Weapon-bench mods stay.
- **Economy (S15):** shards, death cache (recoverable once), weapon-bench mods; workbench equipment from `item_catalog.gd` (reinforced arm, salvage shield, lab armour). Servo trial and prefix ledger are **frozen**: they stay in the code, get no new tasks and must not break.
- **Pressure task (S16):** one quick-maths door directly after the relay checkpoint. Announced by sound and light; ≥ 10 s visible countdown; single-digit operations; failure kills Rend.
- **Boss (S21):** two phases (phase 2 at ≤ 50 % HP); every strike announced ≥ 0.5 s before it can hit (light + sound); first win 60–150 s.
- **Intro comic (S17, S22):** ≤ 6 panels, ≤ 60 s; not skippable on the first start, skippable afterwards.
- **Accessibility (G16):** subtitles for announcements; slow motion, screen shake each can be switched off; alarm light flashes ≤ 3 Hz.
- **Language (G10):** all in-game text English, from one text table.

## Not in M1

Grenades, capture (S18), puzzles beyond the one pressure task, in-game comic inserts, mini-drone swarms, wheeled robots, farming tree, key rebinding, ledge grab / wall jump, a second sector.

## Open

- **Route length (S23):** nobody has timed a run yet. If the first playtests land below 9 min, "extend the route" becomes the first content block; above 11 min, we cut.
