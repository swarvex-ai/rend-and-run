extends Node3D
## Authored H59 accessory. Bind in rest space; animation owns all later motion.
const MODEL = preload("res://assets3d/enemies/pulse_pack_v1/model.glb")
var detached := false

static func attach(skeleton: Skeleton3D, pivot: Node3D) -> Node3D:
	var bone := skeleton.find_bone("mixamorig_Spine2")
	if bone < 0: bone = skeleton.find_bone("Spine02")  # mechanical humanoid rig
	if bone < 0: return null
	var rest := skeleton.get_bone_global_rest(bone)
	var skeleton_to_pivot := pivot.global_transform.affine_inverse() * skeleton.global_transform
	var chest := (skeleton_to_pivot * rest).origin
	# Keep this authored accessory in metres whatever the guard visual's scale.
	var target := Transform3D(Basis.from_scale(Vector3.ONE / pivot.scale.x), chest + Vector3(-0.10, -0.04, 0))
	var socket := BoneAttachment3D.new()
	socket.name = "PulsePackSocket"
	socket.bone_name = skeleton.get_bone_name(bone)
	skeleton.add_child(socket)
	var pack := load("res://modules/visuals/pulse_pack.gd").new() as Node3D
	pack.name = "PulsePack"
	socket.add_child(pack)
	pack.add_child(MODEL.instantiate())
	pack.transform = rest.affine_inverse() * skeleton_to_pivot.affine_inverse() * target
	return pack

func drop(impulse: Vector3) -> void:
	if detached: return
	detached = true
	var original := global_transform
	var debris := RigidBody3D.new()
	debris.name = "DroppedPulsePack"
	debris.add_to_group("dropped_packs")
	debris.collision_layer = 0
	debris.collision_mask = 1
	debris.mass = 2.0
	debris.angular_damp = 1.5
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.20, 0.486, 0.345)
	col.shape = box
	col.position = Vector3(-0.10, 0.003, 0.0025)
	debris.add_child(col)
	get_tree().current_scene.add_child(debris)
	debris.global_transform = Transform3D(original.basis.orthonormalized(), original.origin)
	reparent(debris, false)
	transform = Transform3D(Basis.from_scale(original.basis.get_scale()), Vector3.ZERO)
	debris.linear_velocity = Vector3(impulse.x * 0.12, 0.3, -0.2)
	debris.angular_velocity = Vector3(0.4, 0, -signf(impulse.x) * 1.5)
	get_tree().create_timer(5.0, false).timeout.connect(debris.queue_free)
