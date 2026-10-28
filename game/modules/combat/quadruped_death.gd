extends SkeletonModifier3D
## Death ragdoll for the robot dog (rig from tools/blender/rig_quadruped.py: Body, then
## thigh_*/calf_* per leg). Same idea as articulated_death.gd for the humanoids: rigid
## proxies take over from the current pose, the body is thrown by the killing blow and the
## legs fold under it. Calves have no child bone, so they end on the floor below the knee.

var bindings: Array = []
var physics_root: Node3D
var _settle := 0.0
const SETTLE_SPEED := 5.0
const SETTLE_SPIN := 10.0

func build(actor: CharacterBody3D, impulse: Vector3) -> bool:
	var sk := get_skeleton()
	var body_bone := sk.find_bone("Body")
	if body_bone < 0:return false
	physics_root = Node3D.new();physics_root.name = "DeathPhysics";actor.add_child(physics_root)
	var floor_y := actor.global_position.y + 0.02
	var to_world := sk.global_transform
	# Torso: a box around the body bone, sized like the dog's hurtbox.
	var body_pose: Transform3D = to_world * sk.get_bone_global_pose(body_bone)
	var torso := _body("Body", Transform3D(Basis(Quaternion(actor.get_node("VisualPivot").global_basis.get_rotation_quaternion())), body_pose.origin), 9.0)
	var box := BoxShape3D.new();box.size = Vector3(0.95, 0.28, 0.36)
	_shape(torso, box, Transform3D.IDENTITY)
	bindings.append([body_bone, torso, torso.global_transform.affine_inverse() * body_pose])
	for i in sk.get_bone_count():
		var name := sk.get_bone_name(i)
		if not name.begins_with("thigh_"):continue
		var calf := sk.find_bone("calf_" + name.trim_prefix("thigh_"))
		if calf < 0:continue
		var hip: Transform3D = to_world * sk.get_bone_global_pose(i)
		var knee: Transform3D = to_world * sk.get_bone_global_pose(calf)
		var foot := Vector3(knee.origin.x, floor_y, knee.origin.z)
		var thigh_body := _limb(name, hip, knee.origin, 1.2, 0.05)
		var calf_body := _limb("calf_" + name.trim_prefix("thigh_"), knee, foot, 0.8, 0.04)
		bindings.append([i, thigh_body, thigh_body.global_transform.affine_inverse() * hip])
		bindings.append([calf, calf_body, calf_body.global_transform.affine_inverse() * knee])
		_joint(torso, thigh_body, hip.origin, knee.origin - hip.origin, 40.0)
		_joint(thigh_body, calf_body, knee.origin, foot - knee.origin, 55.0)
	# A short shove along the blow and a roll about the long axis: the dog drops onto its
	# side (a pitch, as for the humanoids, would rear it up on its hind legs).
	var side := 1.0 if randf() < 0.5 else -1.0
	for binding in bindings:
		var b: RigidBody3D = binding[1]
		b.linear_velocity = Vector3(impulse.x * .2, clampf(impulse.y * .5, 0.3, 1.2), 0)
		b.angular_velocity = Vector3(side * 2.2, 0, 0)
	physics_root.global_position.y += 0.05  # capsules must not start inside the floor
	_settle = .4
	return true

func _body(name: String, at: Transform3D, mass: float) -> RigidBody3D:
	var body := RigidBody3D.new();body.name = name
	body.collision_layer = 0;body.collision_mask = 1;body.mass = mass
	body.linear_damp = .3;body.angular_damp = 1.5;body.continuous_cd = true
	var pm := PhysicsMaterial.new();pm.friction = .85;pm.bounce = 0.0;body.physics_material_override = pm
	body.add_child(preload("res://modules/combat/debris_pause.gd").new())
	physics_root.add_child(body);body.global_transform = at
	return body

func _shape(body: RigidBody3D, shape: Shape3D, at: Transform3D) -> void:
	var cs := CollisionShape3D.new();cs.shape = shape;cs.transform = at;body.add_child(cs)

func _limb(name: String, start: Transform3D, end: Vector3, mass: float, radius: float) -> RigidBody3D:
	var body := _body(name, Transform3D(start.basis.orthonormalized(), (start.origin + end) * 0.5), mass)
	var capsule := CapsuleShape3D.new();capsule.radius = radius
	capsule.height = maxf(radius * 2.0, start.origin.distance_to(end))
	var axis := (body.global_basis.inverse() * (end - start.origin)).normalized()
	_shape(body, capsule, Transform3D(Basis(Quaternion(Vector3.UP, axis)), Vector3.ZERO))
	return body

func _joint(a: RigidBody3D, b: RigidBody3D, at: Vector3, along: Vector3, swing_deg: float) -> void:
	var joint := ConeTwistJoint3D.new();physics_root.add_child(joint)
	joint.global_position = at
	joint.global_basis = Basis(Quaternion(Vector3.RIGHT, along.normalized()))
	joint.node_a = joint.get_path_to(a);joint.node_b = joint.get_path_to(b)
	joint.swing_span = deg_to_rad(swing_deg);joint.twist_span = deg_to_rad(10.0)

func _physics_process(delta: float) -> void:
	if _settle <= 0.0:return
	_settle -= delta
	for binding in bindings:
		var body: RigidBody3D = binding[1]
		if not is_instance_valid(body):continue
		body.linear_velocity = body.linear_velocity.limit_length(SETTLE_SPEED)
		body.angular_velocity = body.angular_velocity.limit_length(SETTLE_SPIN)

func _process_modification() -> void:
	var sk := get_skeleton()
	for binding in bindings:
		var body: RigidBody3D = binding[1]
		if is_instance_valid(body):
			sk.set_bone_global_pose(binding[0], sk.global_transform.affine_inverse() * body.global_transform * binding[2])
