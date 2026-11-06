# Sound bible — variant 2

Rend&Run sounds like a clean machine room under load: servo whine and relay clicks sit on a low ventilation rumble, and every robot impact is dry sheet metal, never flesh. Music is built from filtered mains hum, struck aluminium and short electrical pulses. The only warm, organic layer in the mix is Rend himself.

## Identity in three words

**Precision. Pressure. Salvage.** Precision means short transients and separated bands. Pressure means the room never falls silent and the alarm is felt before it is understood. Salvage means every weapon and impact sounds recovered, bolted on and slightly mismatched.

## Audio pillars

1. **Read before hit.** Every attack tell and warning is priority 1: starts ≥ 500 ms before contact, occupies 1–5 kHz, and is never ducked or masked by Music, Ambience or other effects. Check: ≥ 500 ms long and ≥ 6 dB above music and ambience in 1–5 kHz.
2. **Machines have mass.** Each robot impact layers a 40–120 Hz body thump, a 120–600 Hz panel hit and a 2–8 kHz debris tail. Destruction uses metal, plastic, ceramic and air, never organic material.
3. **One factory, one room tone.** Ventilation is present at the same level in every zone; only server rooms add fans. One reverb preset (RT60 0.9 s, pre-delay 20 ms) keeps all contributors' assets in one space.
4. **Tools sound borrowed.** Fixed signatures: robot arm = hydraulic hiss plus heavy steel; pistol = short dry crack; smg = faster, thinner crack; scattergun = wide low burst; energy rifle = rising electrical whine before the shot.

## Sound palette

Room tone is a 40–100 Hz ventilation rumble with slow amplitude movement; server rooms add 100/200 Hz transformer hum and a 1–4 kHz fan band. Robot locomotion uses 2–8 kHz servo whine, 60–200 Hz hydraulics and foot clamps with an 80–300 Hz thump plus a 2–4 kHz click.

Impacts are layered. A light hit is 30–80 ms; a heavy hit is 120–250 ms with a 300–600 ms debris tail. Shield hits add a 1.5–3 kHz ring. Robot death breaks into panel clatter, loose servo spins and a final electrical click, never wet or gory.

Rend is the only organic source: cloth, boot leather, breath and voice at 100–400 Hz; his hurt and death lines stay dry and close. Robot voices are limited to 300–3400 Hz with 80 Hz ring modulation and 60 ms slap; PA lines add 1.4 s hall reverb. No robot breathes, growls or bleeds.

Music uses filtered 50/100 Hz mains drone, struck aluminium and short electrical clicks. No orchestral strings or guitar.

## Music by game state

|State|Music|Level|Transition|
|---|---|---|---|
|Exploration|60–70 BPM three-layer drone, no drums|−24 LUFS-I, 90–150 s loop|starts 1.5 s after last enemy, 2 s fade|
|Combat|120–132 BPM electrical pulse, bass and metal percussion|−18 LUFS-I, 8–16 s loop|beat-matched entry ≤ 250 ms; layers drop as enemies fall|
|Danger / alarm|140 BPM alarm pulse under the siren; 1–5 kHz notched −6 dB during a priority-1 tell|−16 LUFS-I, 4–8 s loop|400 ms crossfade on alarm start and clear|
|Boss|two phases; phase 1 −15 LUFS-I, phase 2 −14 LUFS-I, tempo +8 BPM, extra low pulse|8-bar loop per phase|500 ms transition at ≤ 50 % boss HP|
|Death|music stops; one 60 Hz tone for 400 ms; 1.5 s near-silence before respawn|−18 LUFS-I peak event|200 ms fade-out|
|Menu|no music in M1; UI cues only|n/a|n/a|

## Mix priorities

|Bus|Role|Nominal|Ducking rule|
|---|---|---|---|
|Master|final sum and safety limiter|0 dB, ceiling −1.0 dBTP|ducks nothing|
|Combat|gameplay effects and priority-1 warnings|0 dB|never ducked while a priority-1 warning is active|
|Ambience|room tone, fans, alarm bed|−3 dB (existing)|ducks nothing|
|Music|exploration, combat, alarm and boss score|−18 LUFS-I|ducks Ambience −3 dB in combat and boss|
|Voice|PA, robot speech, Rend lines|−16 LUFS-I|ducks Music −6 dB, Ambience −4 dB; never ducks Combat|

|Source|Ducks|Amount|Condition|
|---|---|---|---|
|Combat priority 1|Music|−8 dB|100 ms attack, hold while active, 600 ms release|
|Combat priority 1|Ambience|−6 dB|same window|
|Combat priority 1|Voice|−3 dB|non-priority speech only; PA waits ≤ 250 ms|
|Voice|Music|−6 dB|while speaking|
|Voice|Ambience|−4 dB|while speaking|
|Music|Ambience|−3 dB|combat and boss states|

Priority-1 cues are flagged at playback. While one is active, Combat ignores ducking from Voice; if a priority-1 PA and a priority-1 attack tell overlap, the PA is delayed ≤ 250 ms.

## Event list (M1)

|Event|Trigger|Priority|Ducks|File|
|---|---|---|---|---|
|Factory room tone|all zones|3|—|`audio/ambience/factory_ventilation.wav`|
|Server room hum|within 6 m of servers|3|—|`audio/ambience/server_fans.wav`|
|Escape alarm|robot arm picked up|2|Music −8, Ambience −6|`audio/alarm_siren.wav`|
|Guard melee tell|WINDUP starts, 500 ms before swing|1|Music −8, Ambience −6|new|
|Guard gunshot|ranged guard fires|1|Music −6, Ambience −4|new|
|Guard death|guard HP 0, breaks apart|2|Music −4|`audio/die.wav`|
|Shield bearer tell|shield bearer enters WINDUP|1|Music −8, Ambience −6|new|
|Shield block|frontal light hit blocked|2|—|`audio/block.wav`|
|Shield guard break|third heavy hit knocks shield away|1|Music −8, Ambience −6|`audio/guard_break.wav`|
|Shield bearer death|HP 0|2|Music −4|`audio/die.wav`|
|Sentinel tell|ring turns red, WINDUP starts|1|Music −8, Ambience −6|new|
|Sentinel death|HP 0|2|Music −4|`audio/die.wav`|
|Dog tell|dog enters WINDUP|1|Music −8, Ambience −6|new|
|Dog claw impact|swipe connects with Rend|1|Music −8, Ambience −6|`audio/hit.wav`|
|Dog death|HP 0, arm tears off|2|Music −4|`audio/die.wav`|
|Kamikaze drone lock-on|LOCK starts, 900 ms before dive|1|Music −8, Ambience −6|`audio/block.wav`|
|Kamikaze drone dive|drone commits to dive|1|Music −8, Ambience −6|new|
|Kamikaze drone detonation|hits Rend, floor, wall or prop|1|Music −8, Ambience −6|new|
|Overseer entry|arena gate closes, boss active|2|Music −6, Ambience −4|new|
|Overseer high tell|high WINDUP starts, 700–800 ms|1|Music −8, Ambience −6|new|
|Overseer low tell|low WINDUP starts, 700 ms|1|Music −8, Ambience −6|new|
|Overseer phase 2|boss HP ≤ 50 %|2|Music −6, Ambience −4|new|
|Overseer death|boss HP 0|1|Music −8, Ambience −6|`audio/die.wav`|
|Rend swing|light or heavy melee starts|2|—|`audio/swing.wav`|
|Rend hits robot|melee or crate connects|2|Music −3|`audio/hit.wav`|
|Rend parry|timed guard catches attack|1|Music −8, Ambience −6|`audio/parry.wav`|
|Rend guard break|Rend's guard breaks|1|Music −8, Ambience −6|`audio/guard_break.wav`|
|Rend hurt light|Rend takes 1 damage|2|Music −4|`audio/voice/rend_hurt_light_01.wav`|
|Rend hurt heavy|Rend takes ≥ 2 damage or boss hit|1|Music −8, Ambience −6|`audio/voice/rend_hurt_heavy_01.wav`|
|Rend death|Rend HP 0|1|Music −8, Ambience −6|`audio/voice/rend_death_01.wav`|
|Pressure door announce|2 m before door after relay|1|Music −8, Ambience −6|new|
|Pressure countdown|each whole second of countdown|1|Music −8, Ambience −6|new|
|Pressure solved|correct answer entered|2|Music −4|`audio/radio_chirp.wav`|
|Pressure failure|countdown reaches 0|1|Music −8, Ambience −6|new|
|Checkpoint save|checkpoint console activated|3|—|`audio/radio_chirp.wav`|
|PA lockdown|x = 16.8 m|1|Music −6, Ambience −4|`audio/voice/pa_lockdown.wav`|
|PA assembly|x = 30.5 m|1|Music −6, Ambience −4|`audio/voice/pa_assembly.wav`|
|PA intact|x = 44.5 m|1|Music −6, Ambience −4|`audio/voice/pa_intact.wav`|
|PA capture|x = 57.5 m|1|Music −6, Ambience −4|`audio/voice/pa_capture.wav`|
|PA airlock|x = 69.0 m|1|Music −6, Ambience −4|`audio/voice/pa_airlock.wav`|
|PA escape|first guard fight starts|1|Music −6, Ambience −4|`audio/voice/pa_escape.wav`|

## Technical specs

- Format: WAV PCM 16-bit, 48,000 Hz; no resampling in Godot.
- Channels: mono for effects, robot speech, PA and ambience beds; stereo only for music.
- Integrated loudness: music −18 LUFS-I (−16 boss, −24 exploration); ambience −28 LUFS-I; effects −20 LUFS-I over a 10 s combat pass, priority 1 at −14 LUFS short-term.
- True peak: −1.0 dBTP on Master and every file; the Master limiter at −1.0 dBTP stays.
- Durations: tells 500–800 ms; light impacts 30–80 ms; heavy 120–250 ms; debris ≤ 600 ms; UI 40–120 ms; loops 4–150 s.
- Naming: `game/audio/<group>/<event>_<nn>.wav` (group `combat|ambience|voice|music|ui`, snake_case event ≤ 24 characters, two-digit take), e.g. `game/audio/combat/robot_guard_windup_01.wav`; existing `game/audio/` names stay.

## Sources and licences

Sources are CC BY-SA 4.0-compatible; attribution goes in provenance and `CREDITS.md`.

- Existing `game/audio/` effects and ambience: CC0 1.0, https://creativecommons.org/publicdomain/zero/1.0/
- HaelDB, "Male Grunt/Yelling sounds": CC0 1.0, https://creativecommons.org/publicdomain/zero/1.0/ (https://opengameart.org/content/male-gruntyelling-sounds)
- Piper text-to-speech: MIT, https://github.com/rhasspy/piper/blob/master/LICENSE.md
- LibriVox training recordings: public domain (CC0 1.0), https://creativecommons.org/publicdomain/zero/1.0/
- Original synthesis, recordings and edits by contributors: CC BY-SA 4.0, https://creativecommons.org/licenses/by-sa/4.0/
- Python 3 `wave` module: PSF License 2.0, https://docs.python.org/3/license.html
- FFmpeg, conversion and loudness measurement: LGPL-2.1-or-later, https://ffmpeg.org/legal.html

CC BY 4.0 is accepted with attribution; no all-rights-reserved or unknown-licence source.

## Do and don't

**Do**

- Flag every attack tell and warning priority 1 on Combat, with ≥ 500 ms lead.
- Keep 1–5 kHz ≥ 6 dB clearer for priority-1 cues than music and ambience.
- Layer heavy impacts with body, panel and debris.
- Reuse the ventilation bed and 0.9 s room reverb in every zone.
- Deliver 48 kHz/16-bit mono effects, ≤ −1.0 dBTP, with provenance.

**Don't**

- No organic squelch, wet impacts, blood, bone, flesh or breathing for robots.
- No priority-1 tell on Music or Voice; no ducking Combat during a priority-1 warning.
- Don't break the −6 dB mask margin around a tell.
- Don't exceed −1.0 dBTP, clip the limiter or mix sample rates.
- Don't copy a recognizable melody, effect or product sound.

## Open questions for neVs

1. **Exploration density.** Pulse or drone only? Recommendation: drone at 60–70 BPM, −24 LUFS-I; rhythm starts with combat, so the state change is audible.
2. **Alarm.** Siren plus music layer or siren only? Recommendation: siren on Ambience plus a 140 BPM danger layer on Music; a lone siren disappears after 20 s.
3. **Death.** Continue ambience during the death pause? Recommendation: yes; music stops in 200 ms, ambience continues, 1.5 s near-silence before respawn.
4. **Pressure countdown.** Speak every second or tick? Recommendation: one PA line at start ("ten seconds") and a 90 ms tick per second; speech collides with tells.
5. **Voice separation.** One voice for PA and robots? Recommendation: keep them separate (PA hall, robot body) so a room announcement is distinct from a nearby robot.
