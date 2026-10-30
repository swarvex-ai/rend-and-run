# Glossary

One term per thing. Use these terms literally in code, tasks and summaries. Code identifiers in brackets.

| Term | Meaning |
|---|---|
| **Rend** (`player`) | the hero: an AI researcher who wakes up in the humanoid factory; the only one who bleeds |
| **robot** (`enemy`) | any machine that hunts Rend; robots never bleed, they break into parts |
| **guard** | light humanoid with a baton or gun; works in squads |
| **duelist** | light humanoid with blade footwork |
| **brute** | heavy humanoid chassis, slow, armoured, cleaver |
| **shield bearer** | robot with a riot shield that blocks frontal hits; in code `role 1` ("Duelist") with `shield: true` (`docs/milestone-1.md`) |
| **sentinel** (`sentinel`) | humanoid that waits in a wall alcove, wakes when Rend runs past; head ring lights up, red before a strike |
| **dog** (`enemy_dog`) | four-legged robot |
| **drone** (`maintenance_drone`) | flying robot; kamikaze drones dive and explode |
| **welder** | stationary welding robot, hazard |
| **overseer** (`lab_overseer`) | boss-class robot supervising the lab |
| **robot arm** (`robot_arm`) | Rend's first weapon, torn off a humanoid |
| **gun** (`gun`) | firearm dropped by robots: pistol, smg, scattergun, energy_rifle |
| **mod** | gun upgrade bought at the weapon bench (laser, extmag, quickload, piercer) |
| **weapon bench** (`GUN_BENCH_POS`) | station where mods are bought with shards |
| **shards** (`shards`) | currency (German UI today: „Splitter“); dropped at death, recoverable once (Hollow Knight model) |
| **checkpoint** | save and respawn point |
| **alarm** | factory-wide alert: sirens, announcements, reinforcements |
| **announcement** (`announce`) | factory PA voice line; robot voice lines are `say` |
| **pressure task** | timed puzzle under threat of death (e.g. quick maths before an explosion) |
| **severance** | a robot losing a limb from a heavy hit |
| **hit stop** (`hitstop`) | a few frames of freeze on a heavy hit (feel) |
| **depth lane** | Rend's movement into or out of the screen within a corridor (2.5D) |
| **encounter** | a placed group of robots with its own id (`encounter_id`) |
| **route** (`lab_route`) | the first escape stretch (vertical slice) |
| **window test** / **headless test** | test that needs a display / runs without one (`game/tests/manifest.txt`) |

In-game texts are still German; switching them to English is a planned task (project brief, G10).
