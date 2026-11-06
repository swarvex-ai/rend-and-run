# Diagnosis: guard_integration_test

base_commit: `af4b9fb1e6ae2a81fd809cbcbee75e7c9a450c54` (the snapshot has no `.git`, so the commit could not be re-resolved locally).

Here "guard" means Rend blocking with the salvage shield, not the guard robot. The test unlocks `salvage_shield` (`game/modules/equipment/item_catalog.gd:21-29`, effect `guard`) at `route.shield_pos`, presses the `guard` action and inspects `p.guard` (`game/tests/guard_integration_test.gd:17-64`).

## How I ran it

From `/work`:

```
tools/run_tests.sh --headless guard_integration_test
```

Two runs were identical. Runner summary at base_commit:

```
FAIL    quarantine guard_integration_test
---
      1 FAIL quarantine
H14 FAIL guard break and hurt cues playing
H14 FAIL attack releases guard without stamina cost
H14 SUMMARY checks=20 failures=2
```

The test is a `V14_TEST` hook, so the runner starts it through `lab_route.gd:196-198`. No display was available (`DISPLAY` and `WAYLAND_DISPLAY` empty), so no window run was possible. Audio uses the Dummy driver. Cue detection does work headless: `parry` and `block` cue checks pass in the same run.

## Failing checks

| check | test expects (file:line) | game does (evidence) | verdict |
|---|---|---|---|
| guard break and hurt cues playing | `game/tests/guard_integration_test.gd:57`: after a break, `sounding("guard_break")` and `sounding("ow")` are both true; `sounding()` scans only `FX._players` for a stream equal to `FX._sfx[cue]` (`:8-10`). | The break does play its cue, but hurt uses a voice group, not `ow`. Temporary probe output after `take_damage`: `audio_events={"guard_break":1,"rend_hurt_heavy":1}`, `generic_playing=["res://audio/guard_break.wav"]`, `guard_break_seen=true`, `ow_seen=false`; the hurt take played on `FX._voice_player` as `res://audio/voice/rend_hurt_heavy_06.wav`. `take_damage` calls `FX.play("guard_break")` at `game/player.gd:913`, then `FX.voice("rend_hurt_heavy")` at `game/player.gd:928`. No game code calls `FX.play("ow")`; `ow.wav` remains only in the `_sfx` list (`game/fx.gd:22`). | test-stale. Rule: the break cue is `FX.play("guard_break")` and Rend's hurt sound is a variant voice line via `FX.voice` (`game/player.gd:913,928`; `game/fx.gd:82-111`). The test asserts the removed `ow` cue and cannot observe the separate `_voice_player`. |
| attack releases guard without stamina cost | `game/tests/guard_integration_test.gd:63-64`: immediately after `p._start_attack(1)`, guard is down and `p._attack_phase == 1`. | The player is unarmed, so the call is a no-op. Probe output: before and after the call `weapon="" slot=1 phase=0 guarding=true`. `slot 1` is `SLOT_FREE`; `_start_attack` returns before `_release_guard()` because `weapon_id.is_empty()` and the slot is not `SLOT_MELEE` (`game/player.gd:818`; `_release_guard` at `:822`). The test never equips or collects an arm, and under `V14_TEST` progress loading is skipped (`game/lab_route.gd:472`), so Rend starts with no weapon. | test-stale. Rule: only an armed melee player can attack; the current arm test asserts "unarmed player cannot produce weapon attack" (`game/player.gd:818`; `game/tests/vision_arm_integration.gd:33`). The guard-release behaviour is not broken, it is never reached. |

## Root causes

The first red is a stale sound API: the test looks for `ow`, while the game replaced that cue with the `rend_hurt_light`/`rend_hurt_heavy` voice groups played on a separate `FX._voice_player`; the `guard_break` half is already playing, and the headless Dummy driver is not the cause.

The second red is a stale setup assumption: the test calls `_start_attack()` on the unarmed new-game player, but attacks now require an equipped melee weapon, so the guard-release path is never entered; both failures are test-side and the game behaves as designed.

## Proposed fixes

- `game/tests/guard_integration_test.gd`, `run()`: replace the `sounding("ow")` assertion with a check of the hurt voice (for example an increment of `FX.audio_events["rend_hurt_heavy"]`, or extend `sounding()` to scan `FX._voice_player` against `FX._voices["rend_hurt_heavy"]`).
- `game/tests/guard_integration_test.gd`, `run()`: equip a melee weapon before the attack check (`p.equip_weapon("robot_arm")`, or collect the start arm and return to the test position) so `_start_attack(1)` reaches the guard-release code.
