# arm_first_fight: script load order changes the first melee fight

Type: diagnosis only (no fix submitted).
Base: `7fd16358e7ac821e9d99b24b273a9b743c46aaef`.

## Reproduction

1. `tools/run_tests.sh --headless arm_first_fight` → green:
   `ARM FIRST FIGHT PASS weapon=robot_arm hp=5 enemy_hp=0 x=3.32416582107544`
2. Add to `game/tests/ranged_integration_test.gd` right after `extends Node`:
   ```gdscript
   const _BOLT_PROBE = preload("res://modules/combat/energy_bolt.gd")
   ```
   (`lab_route.gd` preloads this test in its `_ready`, so the extra script is compiled at game start.)
3. Run the same test → red, 2/2 runs:
   `ARM FIRST FIGHT FAIL weapon=robot_arm hp=5 enemy_hp=1 x=3.32416582107544`

The random seed does not matter (1–8 give the same result) and the runner uses
`--fixed-fps 60`, so this is load order / object allocation, not chance or timing.

For the frame dumps below I temporarily printed per physics frame in
`arm_first_fight.gd`: attack phase, sequence, active time, hit-id count, robot hp
and hit count, robot AI state/time, both hp values, and both positions. Those probe
edits were reverted afterwards; only this report is submitted.

## First differing frame

Frame `i` is the fight loop index in `arm_first_fight.gd` (after the walk to the
robot and the arm pickup).

The very first captured frame already differs in the robot's depth position:

```
i=0  GREEN patk=0 seq=0 at=0.0 hit_ids=0 foe_hp=2 foe_hits=0 foe_state=2 foe_st=0.267 p_hp=5 px=1.511 pxz=0.063 fx=7.647 fz=0.039
i=0  RED   patk=0 seq=0 at=0.0 hit_ids=0 foe_hp=2 foe_hits=0 foe_state=2 foe_st=0.267 p_hp=5 px=1.511 pxz=0.063 fx=7.647 fz=0.070
```

Rend, the robot's X position and all attack state are identical; only the robot's
Z (depth lane) differs. That difference existed during the approach already because
the lane offset is set in the robot's `_ready`.

The first hit/attack divergence is frame `i=35`, in the same combo attack
(`seq=3`, active phase `patk=2`, `at=0.200`):

```
i=35 GREEN patk=2 seq=3 at=0.200 hit_ids=0 foe_hp=2 foe_hits=0 foe_state=2 foe_st=0.85  p_hp=5 px=3.324 pxz=0.063 fx=4.730 fz=-0.505
i=35 RED   patk=2 seq=3 at=0.200 hit_ids=1 foe_hp=1 foe_hits=1 foe_state=5 foe_st=0.017 p_hp=5 px=3.324 pxz=0.063 fx=4.857 fz=0.404
```

Same attack, same phase, same timing; the RED blade sweep connects (enemy hp 2→1),
the GREEN one misses because the robot is half a metre deeper (z −0.505 vs +0.404).

The run then plays out as follows (all other state identical unless shown):

```
i=63  GREEN patk=2 seq=1 at=0.200 hit_ids=1 foe_hp=1 foe_hits=1 ... fz=-0.049  (green's first hit)
i=63  RED   patk=1 seq=1 at=0.117 hit_ids=0 foe_hp=1 foe_hits=1 ... fz= 0.465  (red whiffs)
i=116 GREEN patk=2 seq=1 at=0.200 hit_ids=1 foe_hp=0 foe_hits=2 ... fz= 0.396 fdead=true
i=116 RED   patk=2 seq=1 at=0.167 hit_ids=0 foe_hp=1 foe_hits=1 ... fz= 0.677 (red whiffs)
```

So RED lands the first hit and then never lands the second one; GREEN misses the
first swing but lands the two hits it needs. The robot needs two sword hits
(`foe_hp` 2 → 0), which is why RED ends with `enemy_hp=1`.

## Responsible code

`game/enemy.gd:143` in `_ready()`:

```gdscript
_lane_offset = float(get_instance_id() % 3 - 1) * 0.25
```

The gameplay-relevant depth lane is derived from the engine object instance ID.
`game/enemy.gd:369` uses it in the chase:

```gdscript
var lane_gap := dz + _lane_offset * clampf(absf(dx) / 3.0, 0.0, 1.0)
```

and `_clear_lane()` (`enemy.gd:535`) amplifies it by picking the nearest clear
entry of `LANES`.

Preloading one more script before the route is built consumes ObjectDB slots, so
the robot gets a different instance ID. Measured probe values:

```
RED  (with preload): foe_id=211359373831  lane= 0.00
GREEN(no preload)  : foe_id=211292264967  lane=-0.25
```

The IDs differ by 67 108 864 (= 2^26), which flips `instance_id() % 3` and therefore
the lane offset. The lane offset is the only trigger: forcing it directly changes
the outcome in both directions, without touching load order.

```
GREEN source, no preload, foe._lane_offset forced to  0.00 → FAIL  enemy_hp=1
RED   source, with preload, foe._lane_offset forced to -0.25 → PASS  enemy_hp=0
```

The lane difference turns into a hit/miss in the player's blade query:
`player.gd:870` calls `_blade_contact.query(..., global_position.z, ...)`;
`modules/combat/blade_contact.gd:14-15` snaps the sword segment to Rend's lane
(`blade_base.z = blade_tip.z = lane_z`). The robot's collision box is 0.8 deep
(`enemy.gd:152`), i.e. half-depth 0.4, plus the blade capsule radius 0.10
(`blade_contact.gd:4`) gives a ±0.50 m window around `lane_z = 0.063`.
At `i=35` RED's `fz=0.404` is inside that window (diff 0.341), GREEN's `fz=-0.505`
is outside (diff 0.568). At `i=115` RED's `fz=0.677` is outside (diff 0.614), so
the second hit can never land.

## Proposed fix (one paragraph)

Remove the instance-ID-derived lane in `game/enemy.gd:143`. Assign the lane slot
deterministically at spawn time instead: give the encounter spec an explicit lane
(or compute `index % 3` from the encounter's position in `MISSION.ENCOUNTERS` /
the route's spawn loop) and set `foe._lane_offset = float(lane - 1) * 0.25` from
that stable value — for example in the `for spec in MISSION.ENCOUNTERS` loop in
`lab_route.gd` that already sets `encounter_id`, `territory_min_x` and
`pursuit_min_x`. This keeps the same three-lane spread so pairs still flank and
do not stack, but the value no longer depends on how many scripts/resources were
loaded before the node was created. It also makes the depth lane reproducible in
tests and saves.

## Tests that would show it

- `arm_first_fight`: must stay green both without and with the extra
  `preload("res://modules/combat/energy_bolt.gd")` line from the reproduction.
- A new headless regression test (name it for the lead to register, e.g.
  `enemy_lane_assignment_test`): build the route twice with different preloaded
  script sets and assert every encounter gets the same `_lane_offset` and the same
  first-fight result. It must fail on the current instance-ID code and pass after
  the fix.
- Existing lane/spacing tests must stay green: `security_pair_test`, `squad_test`,
  `nav_test`, `depth_strip_test`, `combat_spacing_test`.
