extends Node3D
## Assembly bay interior (vision: "Montagehallen mit Hakenreihen und Rohlingen"): an
## overhead rail behind the glazing carries unpainted humanoid blanks on hooks, some still
## missing an arm or the head. They creep along and wrap behind the opaque wall beside the
## glass. Visual only. Build with setup(); the bay owner marks meshes for interior light.

const MODEL := "res://assets3d/characters/light_humanoid_severable_v1/model.glb"
const SPEED := 0.22         # m/s, a slow production line
const HANG_DROP := 1.5      # model origin (soles) below the yoke
# Inside a bay: rail just under the bay header, four whole blanks. Over the corridor
# (configure() before setup()): a long rail high up carrying torsos only, above every head.
var rail_y := 3.7
var span := 5.8             # rail length; the blanks wrap at its ends
var blanks := 4
var torso_only := false

func configure(length: float, count: int, height: float, torsos: bool) -> void:
	span = length;blanks = count;rail_y = height;torso_only = torsos

var _blanks: Array[Node3D] = []
var _hooks: Array[Node3D] = []
var _offset := 0.0

func setup(primer: Material, steel: Material, dark: Material, seed_index: int) -> void:
	var rail := MeshInstance3D.new();rail.name = "Rail"
	var beam := BoxMesh.new();beam.size = Vector3(span, 0.12, 0.16);rail.mesh = beam
	rail.material_override = dark;rail.position = Vector3(0, rail_y + 0.12, 0);add_child(rail)
	var flange := MeshInstance3D.new();var flange_mesh := BoxMesh.new()
	flange_mesh.size = Vector3(span, 0.025, 0.3);flange.mesh = flange_mesh
	flange.material_override = steel;flange.position = Vector3(0, rail_y + 0.05, 0);add_child(flange)
	for i in blanks:
		var hook := _hook(steel, dark);add_child(hook);_hooks.append(hook)
		var blank := load(MODEL).instantiate() as Node3D
		blank.name = "Blank%d" % i
		hook.add_child(blank)
		blank.position = Vector3(0, -0.42 - HANG_DROP, 0)  # hangs from the yoke at its shoulders
		_prime(blank, primer)
		_pose_hanging(blank, (seed_index * 7 + i * 3) % 5)
		if torso_only:_strip_legs(blank)
		_blanks.append(blank)
	_offset = fmod(seed_index * 1.37, span)
	_place()

func _hook(steel: Material, dark: Material) -> Node3D:
	var hook := Node3D.new()
	var trolley := MeshInstance3D.new();var t := BoxMesh.new();t.size = Vector3(0.22, 0.1, 0.22)
	trolley.mesh = t;trolley.material_override = dark;hook.add_child(trolley)
	var rod := MeshInstance3D.new();var r := CylinderMesh.new()
	r.top_radius = 0.018;r.bottom_radius = 0.018;r.height = 0.42
	rod.mesh = r;rod.material_override = steel;rod.position.y = -0.21;hook.add_child(rod)
	var yoke := MeshInstance3D.new();var y := BoxMesh.new();y.size = Vector3(0.34, 0.05, 0.08)
	yoke.mesh = y;yoke.material_override = steel;yoke.position.y = -0.42;hook.add_child(yoke)
	return hook

func _prime(blank: Node3D, primer: Material) -> void:
	for mesh in blank.find_children("*", "MeshInstance3D", true, false):
		mesh.material_override = primer
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

# Arms hang limp; variant 1 lacks the left arm, 2 the head, 3 both forearms.
func _pose_hanging(blank: Node3D, variant: int) -> void:
	var sk := blank.find_child("Skeleton3D", true, false) as Skeleton3D
	var player := blank.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if player:player.stop()
	if sk == null:return
	for side in [["LeftArm", 1.0], ["RightArm", -1.0]]:
		var bone := sk.find_bone(side[0])
		if bone >= 0:sk.set_bone_pose_rotation(bone, sk.get_bone_rest(bone).basis.get_rotation_quaternion() * Quaternion(Vector3.FORWARD, deg_to_rad(68.0) * side[1]))
	for leg in ["LeftUpLeg", "RightUpLeg"]:
		var bone := sk.find_bone(leg)
		if bone >= 0:sk.set_bone_pose_rotation(bone, sk.get_bone_rest(bone).basis.get_rotation_quaternion() * Quaternion(Vector3.RIGHT, deg_to_rad(6.0)))
	match variant:
		1:
			var arm := blank.find_child("arm_left_severable", true, false) as Node3D
			if arm:arm.hide()
		2:
			var head := sk.find_bone("neck")
			if head >= 0:sk.set_bone_pose_scale(head, Vector3.ONE * 0.001)
		3:
			for forearm in ["LeftForeArm", "RightForeArm"]:
				var bone := sk.find_bone(forearm)
				if bone >= 0:sk.set_bone_pose_scale(bone, Vector3.ONE * 0.001)

# Torso shells for the corridor line: legs not fitted yet, so nothing hangs into the fight.
func _strip_legs(blank: Node3D) -> void:
	var sk := blank.find_child("Skeleton3D", true, false) as Skeleton3D
	if sk == null:return
	for leg in ["LeftUpLeg", "RightUpLeg"]:
		var bone := sk.find_bone(leg)
		if bone >= 0:sk.set_bone_pose_scale(bone, Vector3.ONE * 0.001)

func _process(delta: float) -> void:
	_offset = fmod(_offset + SPEED * delta, span)
	_place()

func _place() -> void:
	for i in _hooks.size():
		var x := fmod(_offset + i * span / blanks, span) - span * 0.5
		_hooks[i].position = Vector3(x, rail_y, 0)
		# A slight sway, as if the hook had just been nudged along.
		_hooks[i].rotation.z = sin(Time.get_ticks_msec() * 0.0011 + i * 1.7) * 0.03
