# Diagnosis: overseer low blade during the hit window

## How I ran it

base_commit: `87871ef06fa9dc664aa19e759babaa6758d5cf93`. From `/work`:

```
tools/run_tests.sh --headless overseer_integration
```

The quarantined test is the only red check of that run:

```
P28 FAIL visible low blade matches hit band
P28 SUMMARY checks=33 failures=1
```

Temporary prints were added only to `game/tests/overseer_integration.gd` and
`game/modules/combat/overseer_low_pose.gd`; both files were restored byte-for-byte
(md5 `507b10f7aab05538665334049d07091f` and `362a17c182ea1e4e6116950d84c9cd94`).
For one experiment the bone lookup below was patched temporarily (never submitted) to
confirm the proposed fix; the result is quoted as "with the name fallback".

## What the check reads

`game/tests/overseer_integration.gd:100-109` waits for `physics_frame`, then on the first
SWING frame with `_state_t >= .09` stores `kind`, calls `await capture(kind)` (which awaits
one `process_frame`) and only then reads
`boss._weapon_pivot.global_position.y - boss.global_position.y` (band `0.2..0.6`) and
`absf(_weapon_pivot.global_basis.y.normalized().y) < .15`.

`_weapon_pivot` is not an abstract probe. It is a `Node3D` under an `aim` node under a
`BoneAttachment3D` bound to the added bone `hand_r`, which is parented to `RightHand`
(`game/enemy.gd:240-259`). So the check reads the actual weapon socket that carries the
blade. `hand_r` exists (`grip=24`) and the parent chain is correct
(`RightShoulder -> RightArm -> RightForeArm -> RightHand -> hand_r`).

## 2a) Where is the visible blade at 0.075-0.15 s?

Nowhere near shin height. Frame values from the physics loop (temporary print `TM`,
unfixed code, low attack, `seed(20261106)`, airlock arena):

| physics frame | `_state_t` (s) | height above boss (m) | flatness | `_swing_hit` |
|---|---|---|---|---|
| 203 | 0.000 | 2.674 | 0.553 | false |
| 206 | 0.050 | 2.449 | 0.606 | false |
| 208 | 0.083 | **2.065** | 0.569 | **true** |
| 209 | 0.100 | 1.788 | 0.518 | true |
| 210 | 0.117 | 1.458 | 0.416 | true |
| 211 | 0.133 | 1.062 | 0.212 | true |
| 212 | 0.150 | **0.617** | 0.092 | true |
| 213 | 0.167 | 0.253 | 0.294 | true |
| 214 | 0.183 | -0.014 | 0.377 | true |

The damage actually lands at `_state_t = .083` (first frame in the 0.075-0.15 window,
`game/enemy.gd:408`), when the blade is at 2.065 m. The test's own read is shifted by the
`await capture()` and lands around `_state_t = .117`, where the blade is 1.458 m. There is
no frame inside the hit window where both conditions hold: at .150 the height is 0.617 m
(just outside the .6 band), and the first frame with a height in the band (.167, 0.253 m)
already has flatness 0.294 > 0.15 and is outside the hit window. The blade follows the
authored slash arc, not the shin-height grip target in
`game/modules/combat/overseer_low_pose.gd:28` (`... + Vector3(..., .43, .12)`).

## 2b) Is the low IK applied when physics reads `_weapon_pivot`?

No - it is never applied at all. The modifier returns before changing a single bone.

The robot chassis is the Meshy heavy humanoid, whose Skeleton3D bones are **unprefixed**:

```
Hips,Spine02,Spine01,Spine,neck,Head,...,RightArm,RightForeArm,RightHand,...,hand_r
```

`overseer_low_pose.gd:14-16` asks only for the Mixamo names and then bails out:

```
var upper:=sk.find_bone("mixamorig_RightArm")     # -1
var lower:=sk.find_bone("mixamorig_RightForeArm") # -1
var hand:=sk.find_bone("mixamorig_RightHand")     # -1
var grip:=sk.find_bone("hand_r")                  # 24
if mini(mini(upper,lower),mini(hand,grip))<0:return
```

Temporary print in that branch on every eligible call (172 times in the run):

```
LOWM bonefail upper=-1 lower=-1 hand=-1 grip=24
```

`LOWM end` (the print after the IK solve) never appeared in the unfixed run: no bone was
ever touched. `game/enemy.gd:249-251` already uses `"RightHand"` when `_mechanical`, and
`game/crouch_pose.gd:114-119` has a `mixamorig_` -> short-name fallback, so the rest of the
rig handles this naming; only the low pose does not.

Timing: `_process_modification` runs on the idle frame because `Skeleton3D`'s default
`modifier_callback_mode_process` is `MODIFIER_CALLBACK_MODE_PROCESS_IDLE` (1, checked via
ClassDB). The prints show the modifier on process frame 185 / physics frame 186 and the
test's read on process frame 186 / physics frame 187, i.e. the read sees the last modifier
result. This ordering is **not** the failure: the modifier does nothing, so the process-side
rendered pose and the physics-side read are the same animation pose.

## 2c) Root cause

**Game bug.** The overseer's low strike never gets its shin-height arm IK on screen because
the modifier looks up Mixamo bone names on an unprefixed Meshy rig and returns at
`overseer_low_pose.gd:18`. The visible blade is at 2.065 m when the hit registers at
`.083 s` and still 1.458 m at the test's `.117 s` sample - far above the intended 0.43 m
and the 0.2-0.6 m band. The test is reading the correct node (`_weapon_pivot` under
`hand_r`) and is not merely reading a stale pose; a one-frame reorder cannot explain a
1.4 m error. The measurement is at most lenient: `await capture()` moves the sample from
the damage frame to ~.117 s, but both values are red anyway.

## Proposed fix (not implemented)

**Primary, `game/modules/combat/overseer_low_pose.gd:14-16`:** resolve the bones with the
same fallback the rest of the project uses (as in `crouch_pose.gd:114-119`):

- try `mixamorig_RightArm`, else `RightArm`
- try `mixamorig_RightForeArm`, else `RightForeArm`
- try `mixamorig_RightHand`, else `RightHand`
- keep `hand_r` (it is added by `_attach_weapon`)

Consequence, verified with a temporary local patch: `_process_modification` reaches the
solve, the check turns green (`SUMMARY checks=33 failures=0`; read at `.117 s`:
height 0.519 m, flatness ~3e-7), and the grip settles at 0.421 m against the 0.43 m target.

**Caveat for neVs (not decided here):** even with the name fallback the arm is fully
extended during the first part of SWING. In skeleton units the hand target is 45.09 (cm)
while the animated shoulder is still near 158-165 cm at `_state_t = 0`, so the hand cannot
reach; the blade is 0.688 m at the damage frame `.083 s` and only reaches 0.421 m at about
`.133 s`. If "hits while the blade is visibly at shin height" must hold at the exact damage
frame, the commit/hit-window or the crouch/shoulder timing has to move; that is a feel and
balancing decision for neVs. The current check would not catch it because the `await
capture()` samples at ~.117 s.

Alternatives and consequences:

1. **Only the bone-name fallback** (above). Minimal, fixes the actual cause, test green;
   leaves the early-swing reach caveat.
2. **Name fallback plus physics-side modifier evaluation**, e.g.
   `_skeleton.set_modifier_callback_mode_process(Skeleton3D.MODIFIER_CALLBACK_MODE_PROCESS_PHYSICS)`
   in `game/enemy.gd`/`game/modules/combat/lab_overseer.gd`. Physics reads then see the
   pose computed in the same step, but this affects all modifiers on the skeleton (crouch,
   hit reactions) and does not fix the name guard by itself.
3. **Change only the test** to read after the modifier (e.g. after `process_frame`, or read
   the skeleton pose after `force_update_all_bone_transforms`). Consequence: removes the
   one-frame ordering caveat only; the blade is still 1.458 m with the current code, so the
   check stays red. It is no substitute for 1.
4. **Change pose timing** (start the IK earlier, lower the shoulder during early SWING, or
   move the hit window / commit time). Consequence: makes the blade genuinely low at the
   damage frame, but changes feel and timings - balancing, neVs decides.

## Screenshots

Not possible in this environment: `DISPLAY` and `WAYLAND_DISPLAY` are empty and there is no
X socket, so the window mode could not run.