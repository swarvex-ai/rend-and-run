# E7: warning time per M1 robot attack

Measurement only. This page records how long Rend has between the first tell of a robot
attack and the first frame in which that attack can deal damage. It makes no balancing
recommendation; any change is neVs's call.

## How it was measured

`game/tests/tell_duration_probe.gd` loads `main.tscn`, removes the route and its robots,
keeps Rend invulnerable and stationary in reach, and creates each robot with
`main._make_enemy(...)` (or the drone with its own script). It then forces the attack
(`_enter(WINDUP)`, `_ranged_attack`, the overseer phase/brace counters, the dog's attack
counter) and steps physics frames at the fixed 60 Hz game clock.

- `t_tell`: first stepped frame with a tell. Visible = `_attack_cue._pivot.visible`
  (for the drone: first change of the eye colour/energy). Audible = a new entry in the
  `FX.audio_events` counters.
- `t_hit`: first frame the attack can hit. Melee = the swing hit window opens
  (`SWING` and `_state_t >= 0.075`); ranged = the first bolt leaves the muzzle
  (`shots_fired` increases); drone = the committed dive starts (`phase == 2`).
- `warning = (t_hit - t_tell) / 60` in seconds of game time. A sound or light in the hit
  frame itself is a consequence and is not counted as a tell.
- Per attack the probe prints one `TELL` line and one `CHANNEL` line with the visible and
  audible warnings separated. Three runs produced identical lines.

Command (from `/work`):

```
mkdir -p /tmp/e7-tell/data /tmp/e7-tell/config
XDG_DATA_HOME=/tmp/e7-tell/data XDG_CONFIG_HOME=/tmp/e7-tell/config \
  godot --headless --fixed-fps 60 --audio-driver Dummy --path game \
  -s res://tests/tell_duration_probe.gd
```

## Results

| robot | attack | first tell | can hit at | warning (s) | below 0.5 s? | source (windup; hit) |
|---|---|---|---:|---:|---|---|
| guard (role 0) | melee high (slash/side) | visible: amber chevron | melee window opens 0.075 s into swing | 0.517 | no | `enemy.gd:1145-1146`; `enemy.gd:408` |
| guard (role 0) | melee heavy (overhead/uppercut/thrust) | visible: copper chevron | melee window opens 0.075 s into swing | 0.517 | no | `enemy.gd:1145-1146`; `enemy.gd:408` |
| guard (role 3) | melee with gun | visible: chevron | melee window opens 0.075 s into swing | 0.517 | no | `enemy.gd:1145-1146`; `enemy.gd:408` |
| guard (role 3) | ranged, pulse emitter | visible: cyan chevron, charge light | first bolt leaves muzzle (0.075 s into swing) | 0.917 | no | `enemy.gd:1145-1146`; `enemy.gd:408`, `enemy.gd:1023` |
| guard (role 3) | ranged, SMG | visible: cyan chevron | first bullet leaves muzzle (0.075 s into swing) | 0.917 | no | `enemy.gd:1145-1146`; `enemy.gd:408`, `gun.gd:188-210` |
| guard (role 3) | ranged, pistol | visible: cyan chevron | first bullet leaves muzzle (0.075 s into swing) | 0.917 | no | `enemy.gd:1145-1146`; `enemy.gd:408`, `gun.gd:188-210` |
| guard (role 3) | ranged, energy rifle | visible: cyan chevron | first bolt leaves muzzle (0.075 s into swing) | 0.917 | no | `enemy.gd:1145-1146`; `enemy.gd:408`, `gun.gd:188-210` |
| duelist / shield bearer | melee high | visible: amber chevron | melee window opens 0.075 s into swing | 0.483 | **yes** | `enemy.gd:1145-1146`; `enemy.gd:408`, `enemy.gd:1102-1103` |
| duelist / shield bearer | melee low (every second attack) | visible: low amber chevron | melee window opens 0.075 s into swing | 0.483 | **yes** | `enemy.gd:1145-1146`; `enemy.gd:408`, `enemy.gd:1102-1103` |
| brute (role 2) | melee heavy cleaver | visible: copper chevron | melee window opens 0.075 s into swing | 0.717 | no | `enemy.gd:1145-1146`; `enemy.gd:408` |
| overseer (phase 1/2) | high cleaver | visible: high chevron | melee window opens 0.075 s into swing | 0.867 | no | `lab_overseer.gd:48-49`; `enemy.gd:408` |
| overseer (phase 1/2) | low sweep | visible: low chevron | melee window opens 0.075 s into swing | 0.767 | no | `lab_overseer.gd:48-49`; `enemy.gd:408` |
| overseer (phase 1/2) | braced high cleaver | visible: high chevron, "STANDHAFT" label | melee window opens 0.075 s into swing | 0.867 | no | `lab_overseer.gd:48-49,88-99`; `enemy.gd:408` |
| sentinel | melee high (punch) | visible: red ring + high chevron | melee window opens 0.075 s into swing | 0.483 | **yes** | `enemy.gd:1145-1146`; `enemy.gd:408`, `sentinel.gd:125-128` |
| sentinel | melee low (elbow, every second attack) | visible: red ring + low chevron | melee window opens 0.075 s into swing | 0.483 | **yes** | `enemy.gd:1145-1146`; `enemy.gd:408`, `sentinel.gd:97-103,125-128` |
| dog | bite / pounce | visible: low amber chevron, crouch | melee window opens 0.075 s into swing | 0.583 | no | `enemy_dog.gd:87-88`; `enemy.gd:408`, `enemy_dog.gd:76-77` |
| dog | arm swipe | visible: high chevron, claw sensor flare | melee window opens 0.075 s into swing | 0.550 | no | `enemy_dog.gd:87-88`; `enemy.gd:408`, `enemy_dog.gd:76-77` |
| drone | dive and detonation | visible + audible: eye brightens/blinks, warning beep | committed dive starts (phase 2) | 0.883 | no | `maintenance_drone.gd:9,48-61`; `maintenance_drone.gd:61` |

The route's role-3 guns all use the same ranged windup and hit path; the four rows above
were measured separately to show that the gun kind does not change the warning.

## Attacks below 0.5 s

- duelist / shield bearer, melee high: 0.483 s
- duelist / shield bearer, melee low: 0.483 s
- sentinel, melee high: 0.483 s
- sentinel, melee low: 0.483 s

No other measured attack is below 0.5 s. The dog's arm swipe has a 0.48 s windup
(`enemy_dog.gd:88`), but its first possible hit is 0.550 s after the tell. The four attacks
above come from the shared role-1 windup of 0.40 s plus the first hit check 0.075 s into
the swing (nominal 0.475 s; at the fixed 60 Hz clock the frame steps give 0.483 s).

## Visible versus audible tell

- Melee robots (guard, duelist, brute, overseer, sentinel, dog): there is no windup sound.
  The visible chevron/ring starts with WINDUP; the only pre-hit sound is the `swing` effect
  on SWING entry (`enemy.gd:497`), 0.083 s before the hit window. Their audible warning is
  therefore 0.083 s while the table's visible warning is 0.48-0.87 s.
- Ranged guards: the cyan chevron starts with WINDUP, but the shot sound plays when the bolt
  leaves the muzzle (`enemy.gd:1045`, `gun.gd:212`), in the hit frame itself. They have no
  audible tell before the hit, so the first tell is visible only.
- Drone: the eye light change and the warning beep start in the same frame, so visible and
  audible warnings are both 0.883 s.
