# second cause: circling depth sway uses the robot's instance id

Type: diagnosis only (no fix submitted).
Base: `24496835d5f5179d25d30318b5833950d8584ad9`.

## Reproduction

1. Base: `tools/run_tests.sh --headless first_room_playthrough farming_input_playthrough`
   → both PASS, 2/2 runs.
2. Replace line 2 of `game/tests/checkpoint_feedback_test.gd`,
   `game/tests/guard_spacing_test.gd` and `game/tests/hud_integration_test.gd`:
   `var TEXT = load("res://data/route_texts.gd")`
   → `const TEXT = preload("res://data/route_texts.gd")`
3. Same command → both FAIL. `farming_input_playthrough` reports
   `FARM INPUT FAIL first robot defeated without Rend dying` (Rend never dies here;
   the robot stays at hp 1 for the whole 900-frame window), then
   `FARM INPUT FAIL: fight incomplete`.

Which preload alone is enough:

| hook test changed | farming_input_playthrough |
|---|---|
| `checkpoint_feedback_test` | FAIL |
| `guard_spacing_test` | FAIL |
| `hud_integration_test` | PASS |

So one preload is enough, but only for the two tests that `main.gd` preloads
(`main.gd:41` guard, `main.gd:59` checkpoint). `hud_integration_test` is preloaded
later by `lab_route.gd:183`; loading `route_texts.gd` from there happens after the
ObjectDB slots that matter have already been assigned.

The fixed seed / `--fixed-fps 60` do not matter; this is object allocation, not
chance or timing.

For the frame dumps I temporarily printed per physics frame in the first fight
loop of `farming_input_playthrough.gd`: Rend's attack phase/sequence/timer,
`_hit_ids` count, robot hp/state/state time/x/z, Rend hp/x/z, and (for the second
diagnosis) the robot's `get_instance_id() % 7`, `_lane_offset` and `_circling`.
All probe edits were reverted; only this report is submitted.

## First differing frame

Frame `i` is the fight loop index in `farming_input_playthrough.gd` (after the
walk to the robot and the interact tap). Frames 0–39 are identical. The first
difference is `i=40`, exactly the first frame on which the robot enters the
circling branch (`_circling` flips `false` → `true`):

```
i=39 GREEN patk=2 seq=3 at=0.025 hit_ids=0 foe_hp=2 foe_state=2 st=1.100 fx=4.5932 fz=-0.4866 p_hp=5 px=3.3211 pz=0.0633 idmod7=1 lane=-0.25 circling=false
i=39 RED   patk=2 seq=3 at=0.025 hit_ids=0 foe_hp=2 foe_state=2 st=1.100 fx=4.5932 fz=-0.4866 p_hp=5 px=3.3211 pz=0.0633 idmod7=3 lane=-0.25 circling=false
i=40 GREEN patk=2 seq=3 at=0.009 hit_ids=0 foe_hp=2 foe_state=2 st=1.117 fx=4.5613 fz=-0.4453 p_hp=5 px=3.3211 pz=0.0633 idmod7=1 lane=-0.25 circling=true
i=40 RED   patk=2 seq=3 at=0.009 hit_ids=0 foe_hp=2 foe_state=2 st=1.117 fx=4.5613 fz=-0.4564 p_hp=5 px=3.3211 pz=0.0633 idmod7=3 lane=-0.25 circling=true
```

Only the robot's Z changes (GREEN moves 0.0413 m that frame, RED 0.0302 m); X,
attack state and everyone's hp are identical. `_lane_offset` is already the same
(−0.25, the #104 spawn-order lane), so the first fix is not involved. The depth
gap grows from there: at `i=45` GREEN `fz=-0.2614`, RED `fz=-0.3889`; the run ends
with GREEN killing at `i=116` (`foe_hp=0`, `fz=0.4234`) while RED lands only one
hit at `i=134` and still has `foe_hp=1, fz=-0.6765` at `i=899`.

## Responsible code

`game/enemy.gd:370` in the CHASE branch:

```gdscript
elif _circling:lane_gap = dz + sin(_state_t * 1.7 + float(get_instance_id() % 7)) * 0.55
```

When a robot is not its turn to attack, it circles and sways in depth by a sine
whose phase is the engine instance id modulo 7. Preloading one more script
before the route is built shifts the ObjectDB slot, so `get_instance_id() % 7`
goes from 1 (no preload) to 3 (checkpoint preload) and the sway starts in a
different direction. That is the whole trigger.

Probe: force the phase without touching load order and the outcome flips in both
directions (the probe replaced `get_instance_id() % 7` with an env value; all
four runs otherwise use the same source and command):

| preload | forced phase | robot `% 7` | result |
|---|---|---|---|
| none | none | 1 | PASS |
| checkpoint | none | 3 | FAIL |
| none | 3 | 3 | FAIL |
| checkpoint | 1 | 1 | PASS |

## Proposed fix (one paragraph)

Remove the instance id from the circling sway. Give the robot a deterministic
sway phase at spawn, exactly like the #104 lane: store it next to `_lane_offset`
in `main._make_enemy` (for example `e._sway_phase = float((_spawned - 1) % 7)`,
or reuse the lane slot) and use `sin(_state_t * 1.7 + _sway_phase)` at
`enemy.gd:370`. The spawn counter is already independent of script load order, so
the sway stays varied but reproducible. While there, `enemy.gd:364` (the crowd
tie-break `get_instance_id() > other.get_instance_id()`) is the same class of
latent dependency and could use the same stable spawn index; it is not the cause
of this failure because it only runs for overlapping robots in the same lane.

## Tests that would show it

- `farming_input_playthrough` and `first_room_playthrough`: green in all three
  variants — base, and with each of the three hook tests using
  `const TEXT = preload(...)` (all three at once too).
- A new headless regression test (name it for the lead to register, e.g.
  `enemy_sway_phase_test`): build the route with and without an extra preloaded
  hook script and assert the first encounter's sway phase and first-fight result
  are identical; it must fail on the current `enemy.gd:370` and pass after the
  fix.
- Existing depth/lane/spacing tests stay green: `arm_first_fight`,
  `security_pair_test`, `squad_test`, `nav_test`, `depth_strip_test`,
  `combat_spacing_test`.
