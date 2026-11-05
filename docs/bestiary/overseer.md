# Overseer

The overseer is the boss-class robot of the first escape route.

## Role in milestone 1

The route spawns encounter id `brute` at `BOSS_X` (game/modules/world/notstrom_layout.gd:4,17) and attaches `lab_overseer.gd` (game/lab_route.gd:154-156). The milestone win needs it destroyed and the exit airlock reached (docs/scope-first-route.md:35).

## Behaviour

Dormant in `IDLE`, it activates when Rend reaches `ADMISSION_X` = `BOSS_ENTRY_X` 70.0 (game/modules/combat/lab_overseer.gd:5,28-33; game/modules/world/notstrom_layout.gd:5), then enters `ALERT` for 0.25 s (game/enemy.gd:50) and chases. Role 2 makes it the heavy chassis (game/modules/combat/lab_overseer.gd:14; game/enemy.gd:183-184). It is melee-only (game/enemy.gd:345-349), and its `territory_min_x` is `ADMISSION_X` (game/modules/combat/lab_overseer.gd:21). Going west of `ADMISSION_X` resets it to `MAX_HP` 12, phase 1 and home (`BOSS_X`, y 0.05) (game/modules/combat/lab_overseer.gd:28-30,69-86,4,11).

Phase 1 is above half HP. The next `WINDUP` after hp is at or below `MAX_HP`/2 (6 of the current 12) latches phase 2; damage cannot change a committed attack (game/modules/combat/lab_overseer.gd:37-41,4). Phase 1 is high, low, high, low, first high (game/modules/combat/lab_overseer.gd:43). Phase 2 resets its counter and uses `_phase_attack % 3 != 2`: first low, then one high every three windups (game/modules/combat/lab_overseer.gd:41-43). The HUD then reads "Phase 2" (game/modules/ui/overseer_status.gd:106).

Windups are 0.70 s low / 0.80 s high (game/modules/combat/lab_overseer.gd:49), the swing 0.20 s (game/enemy.gd:52), the hit window 0.075-0.15 s into the swing (game/enemy.gd:408) and recovery 0.90 s (game/modules/combat/lab_overseer.gd:52). Each hit costs 1 HP (game/enemy.gd:26).

Braced: each damaging hit while not braced adds to `_brace_hits` (game/modules/combat/lab_overseer.gd:64-67); at 2 or more the next `WINDUP` is braced (game/modules/combat/lab_overseer.gd:89). During a braced windup or swing, hits deal full damage but do not stun or interrupt (`_has_attack_momentum`, game/modules/combat/lab_overseer.gd:98-99; game/enemy.gd:706-721). The label swaps "LABOR-AUFSEHER" for "STANDHAFT" [steadfast] and turns orange (game/modules/combat/lab_overseer.gd:93-96); the HUD echoes it (game/modules/ui/overseer_status.gd:106; game/lab_route.gd:224). A completed swing or a parry clears it (game/modules/combat/lab_overseer.gd:90-92,101-103). So after two quick hits, the boss's next attack is uninterruptible rather than staggerable.

## Attacks and tells

The tell is a chevron at 1.25 m high / 0.35 m low (game/modules/vfx/enemy_attack_cue.gd:25-31), begins with `WINDUP` (game/enemy.gd:489-491), and is unshaded geometry, not a light (game/modules/vfx/enemy_attack_cue.gd:3-6).

| phase | attack | tell (what the player sees/hears) | tell duration (s) | hit window (s) | counter |
|---|---|---|---|---|---|
| 1 | high cleaver | high chevron, cleaver raised; swing sound only at swing (game/enemy.gd:497) | 0.80 (game/modules/combat/lab_overseer.gd:49) | 0.075-0.15 into the swing (game/enemy.gd:408) | duck or parry (game/modules/ui/combat_hint_text.gd:23) |
| 1 | low sweep | low chevron, crouch and shin-height blade (game/enemy.gd:106-107; game/modules/combat/overseer_low_pose.gd:22) | 0.70 (game/modules/combat/lab_overseer.gd:49) | 0.075-0.15 into the swing (game/enemy.gd:408) | jump or dodge (game/modules/ui/combat_hint_text.gd:24) |
| 2 | high cleaver | same high chevron in the phase-2 rhythm | 0.80 (game/modules/combat/lab_overseer.gd:49) | 0.075-0.15 into the swing (game/enemy.gd:408) | duck or parry (game/modules/ui/combat_hint_text.gd:23) |
| 2 | low sweep | same low chevron, now more frequent | 0.70 (game/modules/combat/lab_overseer.gd:49) | 0.075-0.15 into the swing (game/enemy.gd:408) | jump or dodge (game/modules/ui/combat_hint_text.gd:24) |

Any of these can be braced; then the label adds "STANDHAFT" and hits do not interrupt (game/modules/combat/lab_overseer.gd:89,95-99).

## How Rend beats it

High is ducked or parried, low is jumped or dodged (game/modules/ui/combat_hint_text.gd:23-24). The high band clears the 1.05 m crouch (game/enemy.gd:72; game/player.gd:211); the low band is at shin height (game/enemy.gd:610-611). A parry cancels a braced attack, clears the brace and stuns for 0.65 s (game/modules/combat/lab_overseer.gd:101-103; game/enemy.gd:996-1004). Early hits before the final 0.30 s windup interrupt; late and braced hits do not (game/modules/combat/lab_overseer.gd:57-58,98-99; game/enemy.gd:699-725,1160-1161). Punish the 0.90 s recovery, whose first 0.12 s are stationary (game/enemy.gd:417-421; game/modules/combat/lab_overseer.gd:52).

## Drops

On defeat it is recorded as `brute`, unlocking the service return, and adds 3 shards directly (game/lab_route.gd:417-421,433-434). The exit door opens only when all encounters are cleared (game/lab_route.gd:435-437,464-466). No weapon pickup: the cleaver drops as non-pickable debris (game/enemy.gd:903-935); there is no gun. The scope's R5 loot promises a splitter cache and upgrade token (docs/scope-first-route.md:57), but the code spawns neither.

## Sound and voice

German labels: "LABOR-AUFSEHER" [laboratory overseer] (game/modules/combat/lab_overseer.gd:22; game/modules/ui/overseer_status.gd:7), "STANDHAFT" [steadfast] (game/modules/combat/lab_overseer.gd:95; game/modules/ui/overseer_status.gd:106), "Phase %d" (game/modules/ui/overseer_status.gd:106). The first chase says a random taunt (game/enemy.gd:493-494; game/modules/audio/robot_voice.gd:24); at 1 HP it says "Damage critical." (game/enemy.gd:743; game/modules/audio/robot_voice.gd:12). The PA at x 69.0 says "The exit airlock is sealed. Overseer, intercept the subject." (game/lab_route.gd:726; game/modules/audio/robot_voice.gd:21). Sounds: swing at swing start (game/enemy.gd:497), hit (game/enemy.gd:618), death (game/enemy.gd:876); there is no windup sound or light.

## Where it appears

Arena in "05 / SCHLEUSE" [05 / airlock] (game/modules/world/notstrom_layout.gd:40): entry 70.0 (game/modules/world/notstrom_layout.gd:5), boss 73.0 (game/modules/world/notstrom_layout.gd:4), exit 79.0 (game/modules/world/notstrom_layout.gd:6). The entry gate object sits at `BOSS_ENTRY_X` - 0.35 (game/lab_route.gd:118) and locks at `entry_x` + 0.85 while the boss is active and alive (game/modules/combat/arena_gate.gd:5-6,20-24); it releases on player death, boss destruction or inactivity (game/modules/combat/arena_gate.gd:20-27). The exit door at `EXIT_X` - 2 (game/lab_route.gd:634) rises only when all encounters are cleared (game/lab_route.gd:435-437,464-466).

## Gaps against the brief

- **Every strike announced by light and sound at least 0.5 s (game/enemy.gd:51) before it can hit: not met.** The visual tell is 0.70/0.80 s plus the 0.075 s first-contact check (game/modules/combat/lab_overseer.gd:49; game/enemy.gd:408), so that side meets it. But the only per-strike sound starts with the swing, 0.075 s before contact (game/enemy.gd:497,408), and the cue is unlit geometry (game/modules/vfx/enemy_attack_cue.gd:3-6).
- **Fight designed to last 60-150 s for a first win: cannot tell from code.** No timer, DPS budget or measured first-win time exists. `MAX_HP` 12 and 1 damage per normal hit mean at least 12 connected hits, 6 with `reinforced_arm` (game/modules/combat/lab_overseer.gd:4; game/player.gd:885), but not a duration. The 60-150 s window comes from the task's S21 statement; no repository file states it.
- **Model reuse:** the header says "P28 greybox ... using the existing Brute asset" (game/modules/combat/lab_overseer.gd:2), and role 2 selects the heavy humanoid (game/enemy.gd:183-184).
- **Loot mismatch:** the scope promises a cache and upgrade token (docs/scope-first-route.md:57); the code gives 3 shards and the service return (game/lab_route.gd:421,434).

## Open questions for neVs

1. Should the phase change latch immediately at half HP or at the next windup?
2. Is STANDHAFT tied to the second phase or a reaction to repeated hits in either phase?
3. Should there be a light and sound during the windup before the swing?
4. What first-win duration should tuning target?
5. Should R5 grant the splitter cache and upgrade token instead of the direct shard credit?
