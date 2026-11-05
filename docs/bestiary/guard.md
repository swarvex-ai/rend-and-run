# Guard

The guard is the light humanoid that works in squads, carrying a baton (role 0) or a gun (role 3); role 1 is the duelist and role 2 the brute, which have their own pages.

## Role in milestone 1

The guard is the baseline pressure robot of the first route. The milestone-1 "readable danger" rule (project brief, S21/pillar 2) requires every attack to be announced by light and/or sound at least 0.5 s before it can hit. This page records current code.

## Behaviour

States: IDLE, ALERT, CHASE, WINDUP, SWING, RECOVERY (game/enemy.gd:86). IDLE detects Rend within 10.0 m horizontally (game/enemy.gd:48) and 2.5 m in depth (game/enemy.gd:49); ALERT holds 0.25 s (game/enemy.gd:50, 317). Baton guard speed is 5.0 m/s (game/enemy.gd:15), gunner 3.8 m/s (game/enemy.gd:169). A gunner holds 2.5–6.0 m and backs off below 2.4 m (game/enemy.gd:328, 334). WINDUP is 0.44 s for a baton guard and 0.85 s for a gunner (game/enemy.gd:1145-1146); SWING is 0.2 s (game/enemy.gd:52); RECOVERY is 0.40 s for a baton guard and 1.1 s for a gunner (game/enemy.gd:1148-1149).

An engaging guard radios idle robots within 12.0 m after 0.35 s (game/modules/combat/squad_director.gd:12-13, 62-68). A second melee guard flanks to 1.9 m on the far side (game/modules/combat/squad_director.gd:15, 75-109). Only one melee guard winds up at a time (game/modules/combat/squad_director.gd:112-116).

## Attacks and tells

| attack | tell (what the player sees/hears) | tell duration (s) | hit window (s) | counter |
|---|---|---|---|---|
| Baton high (slash/side) | amber chevron, weapon raised; swing whoosh (game/enemy.gd:495-497) | 0.44 (game/enemy.gd:1145-1146) | 0.075–0.15 into swing (game/enemy.gd:408) | duck (crouch 1.05 m, game/player.gd:210-211) or parry/dodge |
| Baton heavy (overhead/uppercut/thrust) | copper chevron, weapon raised (game/enemy.gd:74-76) | 0.44 (game/enemy.gd:1145-1146) | 0.075–0.15 into swing (game/enemy.gd:408) | overhead/uppercut: back off; thrust: step aside in depth (game/enemy.gd:69-70) |
| Gun burst | cyan chevron, pulse pack charge, aim locks at 0.55 s (game/enemy.gd:396-397, 438) | 0.85 (game/enemy.gd:1145-1146) | first shot 0.075 into swing (game/enemy.gd:408); burst at gun interval (game/modules/combat/gun.gd:22-32) | cover; parry/dodge; close inside 2.4 m (game/enemy.gd:328) |

The chevron encodes only high/low/heavy/ranged, not the five strike types (game/modules/vfx/enemy_attack_cue.gd:22-27). The baton guard never repeats the previous strike (game/enemy.gd:1109-1118).

## How Rend beats it

Parry window 0.14 s from press (game/modules/combat/guard_state.gd:11), cost 10 stamina (game/modules/combat/guard_state.gd:12), cooldown 0.35 s (game/modules/combat/guard_state.gd:13); a parry stuns the guard 0.65 s (game/enemy.gd:996-1005). Dodge gives 0.18 s of movement and 0.14 s of invulnerability, with a 0.62 s cooldown (game/player.gd:243-246). A light hit deals 1 damage and a reinforced-arm hit 2 (game/player.gd:887); a guard has 2 HP (game/enemy.gd:17), so two light hits or one reinforced-arm hit destroy it. Against a gunner, close in or use cover; a depth sidestep does not break its line of fire (game/enemy.gd:1011-1016).

## Drops

A gunner drops its gun with twice the magazine (game/enemy.gd:905-908); a baton guard drops the baton as debris, not a pickup (game/enemy.gd:910-935). The first encounter leaves 3 shards (game/lab_route.gd:430), other mission encounters add 3 (game/lab_route.gd:434), and the maintenance guard adds 2 (game/modules/world/power_sector.gd:79). Default guards carry no shield (game/enemy.gd:34); see shield bearer.

## Sound and voice

First contact: a random taunt from six lines (game/enemy.gd:493-494; game/modules/audio/robot_voice.gd:24). Engaging: radio chirp and "converge" (game/modules/combat/squad_director.gd:66-68); a flanker says "flank" (game/modules/combat/squad_director.gd:94-96). Swing whoosh (game/enemy.gd:495-497), hit impact (game/enemy.gd:618), death sound (game/enemy.gd:876). Robot lines share a 3.2 s pause (game/modules/audio/robot_voice.gd:23). There is no dedicated windup sound; the tell is visual only (game/modules/vfx/enemy_attack_cue.gd).

## Where it appears

- `first`, x 8.5 m, role 0 baton (game/modules/world/notstrom_layout.gd:10).
- `guard`, x 40.0 m, role 3 smg (game/modules/world/notstrom_layout.gd:12).
- `freight_raider`, x 48.0 m, role 3 pistol (game/modules/world/notstrom_layout.gd:14).
- `relay_guard`, x 64.0 m, role 3 energy rifle (game/modules/world/notstrom_layout.gd:16).
- `awakened_blank`, x 37.2 m, role 0 (game/lab_route.gd:372, 397-398).
- `maintenance_guard`, x 24.8 m, role 3 scattergun, 5 HP, 2.4 m/s (game/modules/world/power_sector.gd:61).
- Reinforcements `guard_backup_0`, `duelist_backup_0`, and `relay_guard_backup_0` are role 0, spawning at Rend's x ± (10.0 + i × 1.4) m (game/lab_route.gd:692-711).

The `hound` at x 43.5 m is a dog, not a guard (game/modules/world/notstrom_layout.gd:13).

## Gaps against the brief

- Baton guard: the windup tell is 0.44 s (game/enemy.gd:1145-1146), shorter than 0.5 s. The first hit check is 0.075 s into the swing (game/enemy.gd:408), so the earliest hit comes after the windup plus that delay; the chevron fades at 0.44 s (game/modules/vfx/enemy_attack_cue.gd:80-84).
- `WINDUP_S` says 0.5 s (game/enemy.gd:51) but role 0 uses 0.44 s (game/enemy.gd:1145-1146); `RECOVERY_S` says 0.8 s (game/enemy.gd:54) but role 0 uses 0.40 s (game/enemy.gd:1148-1149); `SWING_CONTACT` says 0.12 s (game/enemy.gd:53) but the check runs 0.075–0.15 s (game/enemy.gd:408).
- The cue only distinguishes high/heavy/ranged (game/modules/vfx/enemy_attack_cue.gd:22-27), while the counter differs per strike (game/enemy.gd:69-70); the backlog asks for per-strike symbols (docs/backlog.md:34).
- The melee windup has no sound, only the visual chevron (game/modules/vfx/enemy_attack_cue.gd); the whoosh starts at SWING (game/enemy.gd:495-497).
- Outdated comments: the header calls the robot "Chaser" and describes a "Waffe" (game/enemy.gd:4), and the loader is `_try_load_chaser` (game/enemy.gd:158), while role 0 carries a baton (game/enemy.gd:262). Trust the code.

## Open questions for neVs

1. Does the 0.5 s rule measure the windup tell or the time to first hit? The baton guard's windup is 0.44 s (game/enemy.gd:1145-1146), but its first hit check is 0.075 s into the swing (game/enemy.gd:408).
2. Should the baton strikes get distinct warning symbols, or is the high/heavy chevron enough?
3. Should the melee windup get an audio tell, or is the visual chevron the intended channel?
4. Is the `guard` encounter (role 3 gunner) the canonical guard, with role 0 a separate "raider" variant?