extends SkeletonModifier3D
## Holds the drawn firearm like a person would and puts Rend's hands on it.
## Long guns (SMG, scatter gun, energy rifle): stock in the right shoulder pocket, barrel
## dipped at low ready while he moves, level when he aims or fires; right hand on the grip,
## left hand under the fore-end. Pistol: two-handed in front of the chest, lowered at rest.
## Two-bone IK per arm with the elbows down and out; the hands take the grip orientation.
## Places the gun node itself (gun.gd: local +Y barrel, +X top). Add after the locomotion
## modifiers and before the hit reactions so blows still shake the aim.

var actor: CharacterBody3D
var gun: Node3D                 # set by the player while a gun is drawn
var aim := 0.0                  # 0 low ready .. 1 aiming (smoothed by the player)
var weight := 0.0               # blends the hold in and out on draw / holster
var aim_point := Vector3.ZERO   # world point the barrel comes onto when aiming

const LOW_READY := 0.5          # rad the barrel dips at low ready (long guns)
const PISTOL_LOW := 0.75

func _process_modification() -> void:
	if not is_instance_valid(actor) or not is_instance_valid(gun) or weight <= 0.001:return
	var sk := get_skeleton()
	_square_hips(sk)
	var to_sk := sk.global_transform.affine_inverse()
	var up := Vector3.UP
	# His body's facing (it turns toward the depth he walks in), not just left/right.
	var forward: Vector3 = (actor.pivot.global_basis.x * Vector3(1, 0, 1)).normalized()
	var right := forward.cross(up)  # his right-hand side
	var spec: Dictionary = gun.spec()
	var length: float = spec.length
	var long_gun: bool = gun.kind != "pistol"
	var chest := sk.global_transform * sk.get_bone_global_pose(sk.find_bone("mixamorig_Spine2")).origin
	var shoulder := sk.global_transform * sk.get_bone_global_pose(sk.find_bone("mixamorig_RightArm")).origin
	var low := -(LOW_READY if long_gun else PISTOL_LOW)
	var ready_dir := (forward * cos(low) + up * sin(low)).normalized()
	var aim_dir := forward
	if aim_point != Vector3.ZERO:
		aim_dir = (aim_point - shoulder).normalized()
		if aim_dir.dot(forward) < 0.3:aim_dir = forward  # never aim behind him
	var barrel := ready_dir.slerp(aim_dir, aim).normalized()
	# Reload: the gun comes down and rolls its well toward him while the left hand drops the
	# old magazine, fetches one from the hip and seats it.
	var reloading: bool = gun.is_reloading()
	var p: float = gun.reload_progress() if reloading else 1.0
	var tilt := sin(p * PI) if reloading else 0.0
	if reloading:barrel = barrel.slerp((forward * cos(-0.55) + up * sin(-0.55)).normalized(), tilt).normalized()
	var top := (up - barrel * up.dot(barrel)).normalized()
	top = top.rotated(barrel, -0.7 * tilt).normalized()
	var origin: Vector3
	var rear: Vector3
	var fore: Vector3
	if long_gun:
		# Butt in the shoulder pocket, a little inward and forward of the joint.
		var pocket := shoulder - right * 0.07 + forward * 0.06 - up * 0.06
		origin = pocket + barrel * (length * 0.5)
		rear = origin - barrel * (length * 0.18) - top * 0.07
		fore = origin + barrel * (length * 0.2) - top * 0.05
	else:
		# Both hands on the pistol in front of the chest, arms half extended.
		var reach := lerpf(0.32, 0.46, aim)
		origin = chest + forward * reach + up * lerpf(-0.22, 0.02, aim) + barrel * (length * 0.25)
		rear = origin - barrel * (length * 0.3) - top * 0.06
		fore = rear - right * 0.035 - barrel * 0.02
	gun.global_transform = Transform3D(Basis(top, barrel, top.cross(barrel)), origin)
	if reloading:
		var well: Vector3 = gun.mag_well() - top * 0.05
		var pouch := chest - up * 0.38 - right * 0.12 + forward * 0.05  # left hip
		var hand: Vector3
		if p < 0.15:hand = fore.lerp(well, p / 0.15)
		elif p < 0.45:hand = well.lerp(pouch, smoothstep(0.15, 0.45, p))
		elif p < 0.8:hand = pouch.lerp(well, smoothstep(0.45, 0.8, p))
		else:hand = well.lerp(fore, smoothstep(0.8, 1.0, p))
		fore = hand
		gun.show_spare_mag(p > 0.42 and p < 0.82, hand)
	# Arms onto the grips (blended in by weight from where the animation has the hands).
	_arm(sk, to_sk, "Right", rear, -up + right * 0.6, barrel * 0.5 - up * 0.85, -right)
	_arm(sk, to_sk, "Left", fore, -up - right * 0.3, barrel, up if long_gun else right)

# The idle clip sways his whole body toward the camera; with a gun up he stands square to
# his facing: take the clip's yaw out of the hips (the legs and spine follow).
func _square_hips(sk: Skeleton3D) -> void:
	var hips := sk.find_bone("mixamorig_Hips")
	if hips < 0:return
	var pose := sk.get_bone_global_pose(hips)
	var delta := pose.basis * sk.get_bone_global_rest(hips).basis.inverse()
	var turned := delta * Vector3.BACK
	var yaw := atan2(turned.x, turned.z)
	pose.basis = Basis(Vector3.UP, -yaw * weight) * pose.basis
	_set_global(sk, hips, pose)

func _arm(sk: Skeleton3D, to_sk: Transform3D, side: String, goal_world: Vector3, pole_world: Vector3, fingers_world: Vector3, palm_world: Vector3) -> void:
	var upper := sk.find_bone("mixamorig_" + side + "Arm")
	var lower := sk.find_bone("mixamorig_" + side + "ForeArm")
	var hand := sk.find_bone("mixamorig_" + side + "Hand")
	if upper < 0 or lower < 0 or hand < 0:return
	var hand_now := sk.get_bone_global_pose(hand).origin
	var goal := hand_now.lerp(to_sk * goal_world, weight)
	var pole := (to_sk.basis * pole_world).normalized()
	_two_bone(sk, upper, lower, hand, goal, pole)
	# Hand orientation: fingers (bone +Y) along the grip, palm (+Z) toward it.
	var y := (to_sk.basis * fingers_world).normalized()
	var z := (to_sk.basis * palm_world)
	z = (z - y * z.dot(y)).normalized()
	var pose := sk.get_bone_global_pose(hand)
	var held := Basis(y.cross(z), y, z).orthonormalized()
	pose.basis = Basis(pose.basis.get_rotation_quaternion().slerp(held.get_rotation_quaternion(), weight))
	_set_global(sk, hand, pose)

func _two_bone(sk: Skeleton3D, upper: int, lower: int, end: int, goal: Vector3, pole_dir: Vector3) -> void:
	var root := sk.get_bone_global_pose(upper).origin
	var l1 := root.distance_to(sk.get_bone_global_pose(lower).origin)
	var l2 := sk.get_bone_global_pose(lower).origin.distance_to(sk.get_bone_global_pose(end).origin)
	var delta := goal - root
	var d := clampf(delta.length(), absf(l1 - l2) + 0.001, l1 + l2 - 0.001)
	var axis := delta.normalized()
	var pole := (pole_dir - axis * pole_dir.dot(axis)).normalized()
	var along := (l1 * l1 - l2 * l2 + d * d) / (2.0 * d)
	var joint := root + axis * along + pole * sqrt(maxf(0.0, l1 * l1 - along * along))
	_aim(sk, upper, lower, joint)
	_aim(sk, lower, end, root + axis * d)

func _aim(sk: Skeleton3D, bone: int, child: int, target: Vector3) -> void:
	var pose := sk.get_bone_global_pose(bone)
	var current := sk.get_bone_global_pose(child).origin - pose.origin
	var desired := target - pose.origin
	if current.length_squared() < 0.000001 or desired.length_squared() < 0.000001:return
	pose.basis = Basis(Quaternion(current.normalized(), desired.normalized())) * pose.basis
	_set_global(sk, bone, pose)

func _set_global(sk: Skeleton3D, bone: int, pose: Transform3D) -> void:
	var parent := sk.get_bone_parent(bone)
	var local := sk.get_bone_global_pose(parent).affine_inverse() * pose if parent >= 0 else pose
	sk.set_bone_pose_position(bone, local.origin)
	sk.set_bone_pose_rotation(bone, local.basis.orthonormalized().get_rotation_quaternion())
