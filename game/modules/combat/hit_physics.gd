extends SkeletonModifier3D
## Physical hit reaction ("physical animation"): on a blow the upper body becomes the same
## jointed rigid proxies as the death ragdoll (articulated_death.gd), the struck part gets
## the impulse, and velocity drives pull every proxy back onto the animated pose. Drives
## start weak (the body is thrown) and stiffen until the pose is animation again, then the
## proxies are removed. The pelvis stays kinematic on the animation, so the legs keep the
## character standing. Put it after the other modifiers: it follows their result.

const UPPER := ["Hips", "Spine02", "Head", "LeftArm", "LeftForeArm", "RightArm", "RightForeArm"]
const DURATION := 0.75      # s until the proxies are gone
const LOOSE := 0.22         # s the drives stay weak after the blow
const FADE := 0.25          # s at the end blending back to pure animation

var actor: CharacterBody3D
var mixamo_prefix := ""
var physics_root: Node3D
var _bindings := []         # [bone, body, body->bone offset, minimum drive grip]
var _bodies := {}           # spec name -> body
var _targets := {}          # bone -> animated world transform (last frame)
var _t := 0.0

func is_reacting() -> bool:
	return is_instance_valid(physics_root)

## zone: "head", "torso" or "legs". velocity: world m/s added to the struck part.
func strike(zone: String, velocity: Vector3) -> void:
	if not is_reacting() and not _build():return
	_t = 0.0
	var names: Array = ["Head", "Spine02"] if zone == "head" else ["Spine02"]
	for n in names:
		var body: RigidBody3D = _bodies.get(_name(n))
		if body:body.linear_velocity += velocity * (1.0 if n == names[0] else 0.6)
	# Arms only trail the torso a little; they must not fly up on their own.
	for n in ["LeftArm", "RightArm"]:
		var body: RigidBody3D = _bodies.get(_name(n))
		if body:body.linear_velocity += velocity * 0.12

func _name(n: String) -> String:
	if mixamo_prefix.is_empty():return n
	return mixamo_prefix + preload("res://modules/combat/articulated_death.gd").MIXAMO_NAMES.get(n, n)

func _build() -> bool:
	var sk := get_skeleton()
	if sk == null or not is_instance_valid(actor):return false
	var specs: Array = preload("res://modules/combat/articulated_death.gd").limb_specs(mixamo_prefix)
	physics_root = Node3D.new();physics_root.name = "HitPhysics";actor.add_child(physics_root)
	_bindings.clear();_bodies.clear()
	for spec in specs:
		if not _name_in_upper(spec[0]):continue
		if actor.get("_severed") == true and str(spec[0]).contains("LeftArm") or actor.get("_severed") == true and str(spec[0]).contains("LeftForeArm"):continue
		var idx := sk.find_bone(spec[0]);var end_idx := sk.find_bone(spec[1])
		if idx < 0 or end_idx < 0:physics_root.queue_free();return false
		var bone: Transform3D = sk.global_transform * sk.get_bone_global_pose(idx)
		var end: Vector3 = sk.global_transform * sk.get_bone_global_pose(end_idx).origin
		var body := RigidBody3D.new();body.name = spec[0]
		body.collision_layer = 0;body.collision_mask = 0  # pure motion; nothing to snag on
		body.mass = spec[4];body.gravity_scale = 0.35
		body.linear_damp = 1.5;body.angular_damp = 3.0
		if spec[2] == "":body.freeze = true;body.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC  # pelvis rides the animation
		physics_root.add_child(body)
		body.global_transform = Transform3D(bone.basis.orthonormalized(), (bone.origin + end) * 0.5)
		var shape := CollisionShape3D.new();var capsule := CapsuleShape3D.new()
		capsule.radius = spec[3];capsule.height = maxf(capsule.radius * 2, bone.origin.distance_to(end))
		shape.shape = capsule
		shape.quaternion = Quaternion(Vector3.UP, (body.global_basis.inverse() * (end - bone.origin)).normalized())
		body.add_child(shape)
		_bindings.append([idx, body, body.global_transform.affine_inverse() * bone, 0.7 if str(spec[0]).contains("Arm") else 0.18])
		_targets[idx] = bone  # drive toward the current pose from the very first step
		_bodies[spec[0]] = body
		if _bodies.has(spec[2]):
			var joint := ConeTwistJoint3D.new();physics_root.add_child(joint)
			joint.global_position = bone.origin
			joint.global_basis = Basis(Quaternion(Vector3.RIGHT, (end - bone.origin).normalized()))
			joint.node_a = joint.get_path_to(_bodies[spec[2]]);joint.node_b = joint.get_path_to(body)
			# Tighter than the death ragdoll: a conscious body keeps its limbs together.
			joint.swing_span = deg_to_rad(spec[5] * 0.5);joint.twist_span = deg_to_rad(15.0)
	return true

func _name_in_upper(bone: String) -> bool:
	for n in UPPER:
		if bone == _name(n):return true
	return false

func _physics_process(delta: float) -> void:
	if not is_reacting():return
	_t += delta
	if _t >= DURATION:
		physics_root.queue_free();physics_root = null;_bindings.clear();_bodies.clear()
		return
	# Drive strength: loose right after the blow, then stiffening back onto the animation.
	var stiffen := smoothstep(LOOSE, DURATION - FADE, _t)
	for binding in _bindings:
		var grip := lerpf(binding[3], 1.0, stiffen)  # arms stay held to the torso, the trunk goes loose
		var body: RigidBody3D = binding[1]
		if not _targets.has(binding[0]):continue
		var goal: Transform3D = _targets[binding[0]] * (binding[2] as Transform3D).affine_inverse()
		if body.freeze:body.global_transform = goal;continue
		var reach := 0.12  # s to close the gap at full grip
		var to_goal := (goal.origin - body.global_position) / reach
		var error := (goal.basis * body.global_basis.inverse()).get_rotation_quaternion()
		var spin := Vector3.ZERO
		if error.get_angle() > 0.001:
			var axis := Vector3(error.x, error.y, error.z)
			if axis.length() > 0.0001:spin = axis.normalized() * wrapf(error.get_angle(), -PI, PI) / reach
		body.linear_velocity = body.linear_velocity.lerp(to_goal, grip * 0.35)
		body.angular_velocity = body.angular_velocity.lerp(spin, grip * 0.35)

func _process_modification() -> void:
	var sk := get_skeleton()
	if not is_reacting():
		_targets.clear()
		return
	# Read every animated target first; writing a parent would move its children.
	for binding in _bindings:
		_targets[binding[0]] = sk.global_transform * sk.get_bone_global_pose(binding[0])
	var blend := 1.0 - smoothstep(DURATION - FADE, DURATION, _t)
	var to_skeleton := sk.global_basis.inverse()
	for binding in _bindings:
		var body: RigidBody3D = binding[1]
		if body.freeze:continue
		# Rotations only: bone lengths stay as animated, so the body never stretches when
		# the proxies drift apart at their joints.
		var physical: Basis = to_skeleton * (body.global_basis * (binding[2] as Transform3D).basis)
		var parent := sk.get_bone_parent(binding[0])
		var parent_basis: Basis = sk.get_bone_global_pose(parent).basis if parent >= 0 else Basis.IDENTITY
		var local := (parent_basis.inverse() * physical).get_rotation_quaternion()
		var animated := sk.get_bone_pose_rotation(binding[0])
		sk.set_bone_pose_rotation(binding[0], animated.slerp(local, blend))
