# Drone

The kamikaze drone is a flying robot that hovers near a home point, locks on with a blinking red eye and warning beeps, then commits to a straight dive and detonates, damaging everything in its blast radius.

## Role in milestone 1

The drone is the glossary's flying kamikaze robot (`docs/glossary.md:15`) and an optional route threat. The security-wing pair is spawned outside the mission encounter list (`game/lab_route.gd:678-683`); the power-sector pair is tracked separately (`game/modules/world/power_sector.gd:69-72`). It is a flying self-destruct hazard, not a humanoid duel.

## Behaviour

- Dormant: with `enabled` false it never moves or counts down (`game/modules/combat/maintenance_drone.gd:43`) and hangs in place (`game/modules/combat/maintenance_drone.gd:42`); a route distance check wakes it.
- Hover (`game/modules/combat/maintenance_drone.gd:46`): it bobs near home. It changes to lock-on when its timer expires, Rend is within 5 m in x (`game/modules/combat/maintenance_drone.gd:48`), and Rend is within 7 m of home (`game/modules/combat/maintenance_drone.gd:48`).
- Lock-on (`game/modules/combat/maintenance_drone.gd:50`): it hangs back, rises, and tracks Rend's aim point (`game/modules/combat/maintenance_drone.gd:52-53`). Its eye brightens and beeps quicken from a 0.28 s to a 0.07 s interval (`game/modules/combat/maintenance_drone.gd:58`). After `LOCK_TIME` 0.9 s (`game/modules/combat/maintenance_drone.gd:9`) it dives (`game/modules/combat/maintenance_drone.gd:61`).
- Committed dive (`game/modules/combat/maintenance_drone.gd:62`): it fires once at the last tracked target at `DIVE_SPEED` 10.0 m/s (`game/modules/combat/maintenance_drone.gd:8`) and no longer steers (`game/modules/combat/maintenance_drone.gd:61`). It detonates within 0.7 m of the aim point, on floor, wall or ceiling, on a slide collision, or after its 1.2 s timer (`game/modules/combat/maintenance_drone.gd:65`).
- Detonation: the blast uses `BLAST_RADIUS` 1.7 m (`game/modules/combat/maintenance_drone.gd:6`) and `BLAST_DAMAGE` 2 (`game/modules/combat/maintenance_drone.gd:7`); it emits `destroyed` and frees itself (`game/modules/combat/maintenance_drone.gd:99-100`).
- Recoil: a parry (`game/modules/combat/maintenance_drone.gd:101`) or melee hit (`game/modules/combat/maintenance_drone.gd:103`) sends it into a braking phase, then it returns to hover and restores its blue eye (`game/modules/combat/maintenance_drone.gd:67-69`).
- Destruction: at `hp` 2 (`game/modules/combat/maintenance_drone.gd:15`) reaching zero, it emits `destroyed` and breaks into shell debris without exploding (`game/modules/combat/maintenance_drone.gd:107-117`).

## Attacks and tells

| attack | tell (what the player sees/hears) | tell duration (s) | hit window (s) | counter |
|---|---|---|---|---|
| dive and detonation | Red eye brightens and blinks faster; warning beeps quicken from a 0.28 s to a 0.07 s interval (`game/modules/combat/maintenance_drone.gd:58`); it rises and tracks Rend (`game/modules/combat/maintenance_drone.gd:52-53`). | 0.9 (`game/modules/combat/maintenance_drone.gd:9`) | Instant at detonation; contact within 0.7 m (`game/modules/combat/maintenance_drone.gd:65`) or timeout after 1.2 s (`game/modules/combat/maintenance_drone.gd:61`); radius 1.7 m (`game/modules/combat/maintenance_drone.gd:6`). | Strike it down before the dive, leave the aim point, or put a robot in the blast. |

## How Rend beats it

- Strike it down first: `hp` 2 (`game/modules/combat/maintenance_drone.gd:15`). Normal melee deals 1, reinforced arm 2 (`game/player.gd:887`); guns also call `take_melee_hit` (`game/modules/combat/gun.gd:228-231`). At zero HP it breaks apart without a blast (`game/modules/combat/maintenance_drone.gd:107-117`).
- Dodge the dive: it does not steer (`game/modules/combat/maintenance_drone.gd:61`). Moving off the aim point makes it meet the floor, a wall, a case or its 1.2 s timer (`game/modules/combat/maintenance_drone.gd:65`); Rend must be outside the 1.7 m blast radius (`game/modules/combat/maintenance_drone.gd:6`).
- Lure it into robots: the blast loop covers Rend, the `enemies` group and throwables (`game/modules/combat/maintenance_drone.gd:84`), applies the same 2 damage to robots (`game/modules/combat/maintenance_drone.gd:97-98`), and cover blocks the ray (`game/modules/combat/maintenance_drone.gd:89-91`).

## Drops

No pickup drops. The security-wing pair has no `destroyed` listener in `_spawn_wing_drones` (`game/lab_route.gd:678-683`), so it awards nothing. The power-sector pair connects `destroyed` to `_defeated` (`game/modules/world/power_sector.gd:72`), which grants 2 shards and saves progress (`game/modules/world/power_sector.gd:79`); detonation also emits `destroyed` (`game/modules/combat/maintenance_drone.gd:99`), so the award applies either way.

## Sound and voice

The warning beep reuses `block` at rising pitch, -12 dB (`game/modules/combat/maintenance_drone.gd:58`); a hit adds metal contact and `hit` (`game/modules/combat/maintenance_drone.gd:105`), a parry only metal contact (`game/modules/combat/maintenance_drone.gd:102`). Detonation has 0.08 s hitstop at 0.05 scale, 0.9 shake, and `die` (`game/modules/combat/maintenance_drone.gd:82`), plus explosion VFX (`game/modules/combat/maintenance_drone.gd:80`). No `say`, `announce` or voice call exists (`game/modules/combat/maintenance_drone.gd:1-117`).

## Where it appears

| placement | x (m) | y (m) | wake condition |
|---|---|---|---|
| security wing | 45.5 (`game/lab_route.gd:663`) | 2.2 (`game/lab_route.gd:663`) | Rend within 9.0 m of home in x (`game/lab_route.gd:688`) |
| relay corridor | 62.0 (`game/lab_route.gd:663`) | 2.5 (`game/lab_route.gd:663`) | same as security wing (`game/lab_route.gd:688`) |
| power sector, first | 20.0 (`game/modules/world/power_sector.gd:72`, index 0) | 1.7 (`game/modules/world/power_sector.gd:72`, index 0) | Rend past x 17.2 (`game/modules/world/power_sector.gd:74`) |
| power sector, second | 26.0 (`game/modules/world/power_sector.gd:72`, index 1) | 2.15 (`game/modules/world/power_sector.gd:72`, index 1) | Rend past x 17.2 (`game/modules/world/power_sector.gd:74`) |

## Gaps against the brief

The milestone-1 rule requires every attack to be announced by light and/or sound at least 0.5 s before it can hit (pillar "Lesbare Gefahr", `docs/project-brief.md:51`; the robot telegraph floor is `WINDUP_S` 0.5 s, `game/enemy.gd:51`). The drone has one attack, dive and detonation. Its tell is the lock-on: `LOCK_TIME` 0.9 s (`game/modules/combat/maintenance_drone.gd:9`) of red eye and warning beeps before the dive is committed (`game/modules/combat/maintenance_drone.gd:49-61`). Checked: 0.9 s lock (`game/modules/combat/maintenance_drone.gd:9`), 1.2 s dive timeout (`game/modules/combat/maintenance_drone.gd:61`), 0.7 m contact (`game/modules/combat/maintenance_drone.gd:65`), 1.7 m radius (`game/modules/combat/maintenance_drone.gd:6`), 2 damage (`game/modules/combat/maintenance_drone.gd:7`). None found shorter than 0.5 s (`game/enemy.gd:51`).

## Open questions for neVs

1. Is the 0.9 s `LOCK_TIME` (`game/modules/combat/maintenance_drone.gd:9`) the intended tell length, or should it be longer?
2. Should warning beeps continue through the dive, or is the red eye enough once it starts (`game/modules/combat/maintenance_drone.gd:61`)?
3. Should security-wing drones grant the same 2 shards as the power-sector pair (`game/modules/world/power_sector.gd:79`), or stay rewardless?
4. Should a drone blast damaging robots remain intended, or should friendly fire be limited (`game/modules/combat/maintenance_drone.gd:84-98`)?
5. Should drones re-sleep when Rend leaves their wake range (`game/lab_route.gd:688`, `game/modules/world/power_sector.gd:74`), or stay awake after first contact?
