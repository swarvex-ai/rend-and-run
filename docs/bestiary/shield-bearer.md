# Shield bearer
The shield bearer is the route's shield-carrying duelist: a fast robot that lunges into reach, backsteps after a missed swing and alternates high strikes with low sweeps.

## Role in milestone 1
The shield bearer is M1's duelist with a shield (`docs/milestone-1.md:38`); it has 2 HP (`game/enemy.gd:17`). The 0.5 s announcement rule (`docs/project-brief.md:50`; pillar 2, `docs/project-brief.md:66`) is the target this page checks.

## Behaviour
The shield bearer is `role 1` (`game/enemy.gd:16`, internal name "Duelist") with `shield: true` (`game/modules/world/notstrom_layout.gd:11`); detection, ALERT, squad radio and the push-box are shared with the guard, see guard.

It starts an attack at 2.35 m (`game/enemy.gd:324`) once the depth offset is at most 0.35 m (`game/enemy.gd:57`). WINDUP is 0.40 s (`game/enemy.gd:1146`); from 0.10 s (`game/enemy.gd:1158`) it lunges at 3.2 m/s (`game/enemy.gd:400-401`) toward the committed front until within 1.3 m (`game/enemy.gd:62`). A missed swing enters RECOVERY (`game/enemy.gd:498`) with 0.12 s (`game/enemy.gd:418`) stationary, then a fixed 2.8 m/s backstep for 0.18 s (`game/modules/combat/recovery_step.gd:26-27`) away from the attack front (`game/modules/combat/recovery_step.gd:43`).

Every second attack is a low sweep (`game/enemy.gd:1102-1103`) with a band 0.05-0.55 m above the soles (`game/enemy.gd:610-611`); normal attacks vary and never repeat the previous strike (`game/enemy.gd:1108-1115`).

The shield is raised only outside WINDUP and SWING and while not stunned or knocked open (`game/enemy.gd:937-938`). It blocks light blows and bullets from the front (`game/enemy.gd:31-33`, `game/enemy.gd:941-942`, `game/enemy.gd:702-704`) but not from behind (`game/enemy.gd:941-942`). A frontal blow with damage 2 or more or vertical knockback above 2.5 m knocks it aside (`game/enemy.gd:703`) for 1.0 s (`game/enemy.gd:960`), stuns 0.7 s (`game/enemy.gd:960`) and costs one of 3 break points (`game/enemy.gd:35`, `game/enemy.gd:957`); the third drops it (`game/enemy.gd:963`).

## Attacks and tells
| attack | tell (what the player sees/hears) | tell duration (s) | hit window (s) | counter |
|---|---|---|---|---|
| `slash` / `side` (high) | high amber chevron at 1.25 m (`game/modules/vfx/enemy_attack_cue.gd:25,27`), strike pose; no windup sound (`game/enemy.gd:495-497`) | 0.40 (`game/enemy.gd:1146`) | 0.075-0.15 (`game/enemy.gd:408`) in the 0.2 s swing (`game/enemy.gd:52`) | duck; crouched Rend is 1.05 m (`game/player.gd:211`), below the 1.10 m slash and 1.15 m side edges (`game/enemy.gd:72-73`) |
| `overhead` / `uppercut` / `thrust` (heavy) | copper chevron at 0.95 m (`game/modules/vfx/enemy_attack_cue.gd:25,29`), strike pose; no windup sound (`game/enemy.gd:495-497`) | 0.40 (`game/enemy.gd:1146`) | 0.075-0.15 (`game/enemy.gd:408`) in the 0.2 s swing (`game/enemy.gd:52`) | overhead/uppercut: back off (0.3-1.9 m and 0.3-1.7 m bands, `game/enemy.gd:74-75`); thrust: step aside in depth (0.25 m, `game/enemy.gd:76`) |
| low sweep, every second attack | low amber chevron at 0.35 m (`game/modules/vfx/enemy_attack_cue.gd:25,28`), crouched pose; no windup sound (`game/enemy.gd:495-497`) | 0.40 (`game/enemy.gd:1146`) | 0.075-0.15 (`game/enemy.gd:408`) in the 0.2 s swing (`game/enemy.gd:52`) | jump; band 0.05-0.55 m above the soles (`game/enemy.gd:610-611`) |

## How Rend beats it
Light hits deal 1 (`game/player.gd:887`) and are turned away from the front, so hit from behind (`game/enemy.gd:941-942`) or during WINDUP/SWING, when the shield is down (`game/enemy.gd:938`). The reinforced arm and a thrown case deal 2 (`game/player.gd:887`, `game/modules/combat/throwable_crate.gd:11,72`); the combo finisher adds 3.2 m vertical knockback (`game/player.gd:884`), above the 2.5 m or 2 damage threshold (`game/enemy.gd:703`). Each knock costs one of the `SHIELD_BREAKS` 3 break points (`game/enemy.gd:35`); 3 frontal blows (`game/enemy.gd:35`) drop it (`game/enemy.gd:963`), and the 1.0 s open and 0.7 s stun (`game/enemy.gd:960`) are the punish.

## Drops
When the third heavy frontal blow knocks the shield off (`game/enemy.gd:35`, `game/enemy.gd:963`) or the robot is destroyed with it attached (`game/enemy.gd:847`), `_drop_shield()` creates a `riot` pickup (`game/enemy.gd:965-968`). It joins group `shield_pickups` (`game/modules/combat/shield_pickup.gd:19-20`); the route offers it within 1.1 m (`game/lab_route.gd:983-986`), and using it calls `player.take_shield("riot")` (`game/lab_route.gd:260-262`), which makes blocks cost 15 stamina instead of 25 (`game/player.gd:397`, `game/modules/combat/guard_state.gd:14-15`). This is the only way the shield becomes Rend's; the sword falls as debris (`game/enemy.gd:910-935`).

## Sound and voice
First CHASE says a taunt (`game/enemy.gd:493-494`) from the shared pool (`game/modules/audio/robot_voice.gd:24`). SWING plays the whoosh (`game/enemy.gd:495-497`), and hit, block, guard_break and death use the shared sounds (`game/enemy.gd:617-619`, `game/enemy.gd:947-949`, `game/enemy.gd:956-959`, `game/enemy.gd:876`). Robot lines share a 3.2 s quiet (`game/modules/audio/robot_voice.gd:23`). There is no windup sound; before SWING the tell is the chevron only (`game/modules/vfx/enemy_attack_cue.gd`).

## Where it appears
- `duelist`, x 32.5 m, role 1 with shield true, territory from 29.5 m (`game/modules/world/notstrom_layout.gd:11`).
- `freight_duelist`, x 56.0 m, role 1 with shield true, territory from 55.3 m (`game/modules/world/notstrom_layout.gd:15`).

## Gaps against the brief
- All attacks share the 0.40 s windup (`game/enemy.gd:1146`), below 0.5 s (`docs/project-brief.md:50,66`). The first hit check is 0.075 s into the 0.2 s swing (`game/enemy.gd:408`, `game/enemy.gd:52`), so the earliest hit is 0.475 s after the tell (`game/enemy.gd:1146`, `game/enemy.gd:408`), still short. This covers slash, side, overhead, uppercut, thrust and the low sweep.
- The shield bearer still attaches `hero_sword.glb` (`game/enemy.gd:264`), a leftover from before Rend lost his sword; no replacement is proposed here.
- M1 says unshielded duelists get no placements (`docs/milestone-1.md:38`), but the optional `relay_guard` reinforcement is role 1 without a shield (`game/data/route_layout.gd:47`).
- Outdated comments call the enemy "Chaser" and the weapon a "Test-Nahkampfwaffe" (`game/enemy.gd:2-5`, `game/enemy.gd:82`). Trust the code.

## Open questions for neVs
1. Should the 0.40 s windup (`game/enemy.gd:1146`) be raised to the 0.5 s rule (`docs/project-brief.md:50`), or is the 0.075 s before the first hit (`game/enemy.gd:408`) enough?
2. Should the shield stay lowered during WINDUP/SWING (`game/enemy.gd:938`), allowing a free hit, or is that intended?
3. Should every second attack remain a low sweep (`game/enemy.gd:1103`)?
4. Should an unshielded role-1 reinforcement be allowed (`game/data/route_layout.gd:47`), given M1 (`docs/milestone-1.md:38`)?
5. Should the riot shield always drop when the robot is destroyed (`game/enemy.gd:847`), or require breaking it first?
