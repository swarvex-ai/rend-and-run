# Sound bible — variant 1

## Identity in three words

**Clean, mechanical, under pressure.** The factory is a maintained precision machine: dry servos, tight solenoids, low structural hum, and no organic texture except Rend. Every object keeps one recognisable voice, so the player reads the room by ear while danger stays first.

## Audio pillars

1. **Warning before impact.** Every attack tell and warning is priority 1: full level on Combat or Voice, Music −9 dB, Ambience −4 dB underneath. A tell sounds at least 0.5 s before the hit; no score layer occupies its 1–4 kHz band.
2. **Machines are matter, not bodies.** Robots are steel, ceramic, polymer and cable; impacts are knocks, shears, cracks and electrical ticks. Robots never get organic, blood or gore sounds; only Rend breathes, grunts and bleeds.
3. **Weight is low end plus a hole.** A heavy hit adds a 60–120 Hz body for 120–180 ms and a 40–80 ms gap; a light hit stays above 200 Hz.
4. **One source, one signature.** Each robot, door and console keeps a fixed timbre and pitch range.
5. **The factory answers.** Ventilation, server fans, relays and pressure changes move with the zone and react to alarms.

## Sound palette

Priority-1 tells live at 1–4 kHz plus a 90–140 Hz thump. Impacts fill 80 Hz–6 kHz; metal 1–6 kHz; structural weight 60–160 Hz. Servos are 1.2–4.5 kHz whines over 200–600 Hz motors; Rend sits at 150–800 Hz. Ambience stays at 40–400 Hz.

Recipes: thick steel rings 300–900 ms at 2.4 kHz; aluminium rattles 80–200 ms; ceramic cracks in a 3–5 kHz burst under 60 ms; polymer thuds 150–300 Hz without ring; cables snap at 1.5 kHz. Electrical events use 50/100 Hz hum and a 2.8 kHz tick. PA is 200 Hz–6 kHz with a 1.8 s hall tail; robot voice 300 Hz–4 kHz with 1.2 kHz resonance.

## Music by game state

| State | Music | Loudness and timing |
|---|---|---|
| Exploration | 60–72 BPM; sub pulses, filtered noise; no melody | −20 LUFS; starts 1.5 s after control, fades over 2 s |
| Combat | 108–124 BPM; metal percussion, low ostinato, servo motifs | −16 LUFS; within 400 ms of aggro, 2.5 s tail |
| Danger / alarm | 90 BPM 50 Hz pulse and high warning tone; siren on effects | −22 LUFS; melody muted, Music −9 dB under siren |
| Boss | 100 BPM phase 1; 120 BPM phase 2, metallic percussion and wider low layer; 800 ms stinger | −15 LUFS; each strike clears the tell band for 0.5 s |
| Death | cut within 120 ms; 2.5 s sub drop 40→25 Hz; 1.5 s room tone | no music after; death line priority 1 |
| Menu | no music in M1; only UI sounds | Music bus silent |

## Mix priorities

| Bus | Role | Baseline | Ducks |
|---|---|---|---|
| Master | final output and safety ceiling | 0.0 dB, limiter at −1.0 dBTP | nothing |
| Combat | attacks, impacts, weapons, priority-1 tells | −3.0 dB | Ambience −4 dB while a priority-1 sound plays |
| Ambience | ventilation, servers, room beds, alarm siren | −3.0 dB | nothing |
| Music | score and stingers | −3.0 dB | nothing |
| Voice | Rend's pain and death, robot lines, PA | 0.0 dB | Music −6 dB, Ambience −3 dB |

Voice ducks Music by 6 dB and Ambience by 3 dB. A priority-1 Combat event ducks Music by 9 dB and Ambience by 4 dB. The siren, pressure door and PA duck Music by 12 dB and Ambience by 6 dB. Music never ducks Combat or Voice; Ambience never ducks anything; Master only limits peaks.

## Event list (M1)

Priority 1 = must never be masked; 2 = important but may sit under speech or a priority-1 tell; 3 = background detail. Paths are relative to `game/`.

| Event | Trigger | Priority | Ducks | File |
|---|---|---|---|---|
| Rend arm swing | arm windup begins | 2 | Ambience −3 | `audio/swing.wav` |
| Rend hit lands | arm or projectile meets a robot | 2 | Ambience −3 | `audio/hit.wav` |
| Rend light hurt | damage 1–2 | 2 | Music −2 | `audio/voice/rend_hurt_light_01.wav` |
| Rend heavy hurt | damage 3 or more | 1 | Music −4, Ambience −3 | `audio/voice/rend_hurt_heavy_01.wav` |
| Rend death | hp 0 | 1 | Music −12, Ambience −6 | `audio/voice/rend_death_01.wav` |
| Parry or guard break | perfect guard or zero endurance | 2 | Ambience −3 | `audio/parry.wav`, `audio/guard_break.wav` |
| Guard windup or shot | WINDUP ≥0.55 s or fire | 1 | Music −9, Ambience −4 | new: `audio/telegraph/guard_windup_01.wav`, `audio/weapons/pistol_fire_01.wav` |
| Robot voice line | taunt, damage or death call | 3 | Music −3 | `audio/voice/robot_intruder.wav` |
| Shield bearer | raises, bashes or loses shield | 1 | Music −9, Ambience −4 | new `audio/telegraph/shield_bash_windup_01.wav`, `audio/block.wav` |
| Sentinel | wake, or red ring in WINDUP | 1 | Music −9, Ambience −4 | new: `audio/telegraph/sentinel_wake_01.wav`, `audio/telegraph/sentinel_windup_01.wav` |
| Dog | crouch before pounce, or arm cocks | 1 | Music −9, Ambience −4 | new: `audio/telegraph/dog_lunge_windup_01.wav`, `audio/telegraph/dog_arm_windup_01.wav` |
| Drone | lock-on, then committed dive | 1 | Music −9, Ambience −4 | new: `audio/telegraph/drone_lock_beep_01.wav`, `audio/telegraph/drone_dive_01.wav` |
| Drone blast | detonation | 2 | Ambience −4 | new `audio/robot/drone_explode_01.wav` |
| Overseer strike or brace | WINDUP 0.7/0.8 s or braced windup | 1 | Music −9, Ambience −4 | new: `audio/telegraph/overseer_windup_01.wav`, `audio/telegraph/overseer_brace_01.wav` |
| Overseer phase 2 | hp at 50 % or lower | 1 | Music −12, Ambience −6 | new `audio/robot/overseer_phase2_01.wav` |
| Pressure door | arms, ticks each second, opens or kills | 1 | Music −12, Ambience −6 | new: `audio/world/pressure_arm_01.wav`, `audio/world/pressure_tick_01.wav`, `audio/world/pressure_fail_01.wav` |
| Checkpoint save | console first activation | 2 | Music −3 | new `audio/world/checkpoint_save_01.wav` |
| Alarm siren | escape alarm starts | 1 | Music −9, Ambience −4 | `audio/alarm_siren.wav` |
| PA announcement | cues at 16.8/30.5/44.5/57.5/69.0 m | 1 | Music −6, Ambience −4 | `audio/voice/pa_escape.wav`, `pa_lockdown.wav`, `pa_intact.wav`, `pa_assembly.wav`, `pa_capture.wav`, `pa_airlock.wav` |
| Ambience bed | zone entered | 3 | none | `audio/ambience/factory_ventilation.wav`, `audio/ambience/server_fans.wav` |

## Technical specs

**Format:** WAV PCM 16-bit for effects, voice and ambience; Ogg Vorbis quality 6 for music. **Rate:** 48,000 Hz, no resampling. **Mono/stereo:** effects, UI and voice mono; music and ambience beds stereo. **Loudness:** music −18 LUFS ±1, ambience −26 LUFS ±2 per zone, effects −20 LUFS ±2 over the file, voice −16 LUFS ±1 per line. **True peak:** −1.0 dBTP. Measure EBU R128 / ITU-R BS.1770-4; under 400 ms use maximum short-term. **Durations:** priority-1 tells 150–350 ms, impacts 60–250 ms, UI at most 90 ms, point reverb at most 1.2 s. **Loops:** exact points, no inner fade, zero-crossing end.

**Naming pattern:** `audio/<category>/<subject>_<action>_<NN>.wav`, lowercase snake_case with a two-digit variant, e.g. `audio/telegraph/dog_arm_windup_02.wav`. Categories are `telegraph`, `robot`, `weapons`, `world`, `ui`, `voice`, `ambience`; music uses `audio/music/<state>_<layer>.ogg`. Existing anchors keep their names.

## Sources and licences

| Source | Use | Licence | URL |
|---|---|---|---|
| HaelDB, "Male Grunt/Yelling sounds" | existing Rend voice | CC0 1.0 | https://opengameart.org/content/male-gruntyelling-sounds |
| Piper and `piper-voices` models | robot and PA voice synthesis | MIT | https://github.com/rhasspy/piper |
| LibriVox recordings | public-domain reference audio | public domain | https://librivox.org/public-domain/ |
| Godot Engine audio | runtime playback | MIT | https://godotengine.org/license/ |

Only CC0 1.0, MIT and public-domain sources are accepted; project audio ships under CC BY-SA 4.0 (https://creativecommons.org/licenses/by-sa/4.0/). No attribution-only, non-commercial or unclear library terms.

## Do and don't

| Do | Don't |
|---|---|
| Give every priority-1 tell a unique 1–4 kHz signature and test it under full music. | Let a score layer, siren or impact mask a tell. |
| Use metal, ceramic, polymer and electrical textures for robots. | Use breathing, flesh, blood or gore for robots. |
| Keep point sounds mono and let the 3D mixer place them. | Put stereo width or reverb on a point sound. |
| Leave 60–120 ms of space after a heavy hit. | Stack hit, explosion and music sting at full level. |


## Open questions for neVs

1. **Music baseline:** start Music at −3.0 or −6.0 dB? Recommendation: −3.0 dB with the ducking above; playtests can add −2 dB later.
2. **Alarm siren bus:** the siren currently runs on Ambience. Recommendation: mirror it to Combat at −3 dB, keep the Ambience copy at −18 dB so it survives a loud room and a voice line.
3. **Robot servo source:** real servos or deterministic synthesis? Recommendation: hybrid — synthesised priority-1 tells, recorded CC0 metal and servo layers for detail.
4. **M1 music scope:** one exploration bed plus combat and boss layers, or stings only? Recommendation: the layered set, because the boss needs a readable phase change.
