extends Node3D
## Six-axis welding robot (Blender, tools/blender/build_robot_arm.py) working on the humanoid
## blanks: it swings to its work point, reaches in, welds for a moment - a shower of sparks
## and a flickering blue-white arc light at the torch - pulls back and waits. Each arm keeps
## its own rhythm. Visual only; the model reaches along +Z.

const MODEL := preload("res://assets3d/env/robot_arm_v1/model.glb")
enum { WAIT, REACH, WELD, RETRACT }

@export var work_yaw := 0.0       # turret angle facing the work (rad)
@export var phase := 0.0          # seconds into the cycle at start (desync neighbours)

var _joints := {}
var _rest := {"yaw": 0.0, "lower": -0.15, "upper": 0.25, "wrist": 0.2}
var _work := {"yaw": 0.0, "lower": 0.22, "upper": -0.5, "wrist": -0.25}  # torch up at the torsos
var _pose := {}
var _state := WAIT
var _t := 0.0
var _sparks: CPUParticles3D
var _arc: OmniLight3D
var welding := false              # tests / dressing: true while the torch is lit

func _ready() -> void:
	var model := MODEL.instantiate() as Node3D
	add_child(model)
	for n in ["ArmTurret", "ArmLower", "ArmUpper", "ArmWrist", "ArmTip"]:
		_joints[n] = model.find_child(n, true, false)
	_work.yaw = work_yaw
	_pose = _rest.duplicate()
	_build_weld_fx()
	_t = -phase
	_apply()

func _build_weld_fx() -> void:
	_sparks = CPUParticles3D.new();_sparks.emitting = false
	var mesh := BoxMesh.new();mesh.size = Vector3(0.008, 0.05, 0.008);_sparks.mesh = mesh
	var m := StandardMaterial3D.new();m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true;m.emission_enabled = true;m.emission = Color(1, .8, .45);m.emission_energy_multiplier = 5.0
	_sparks.material_override = m
	_sparks.amount = 40;_sparks.lifetime = 0.55;_sparks.direction = Vector3.UP;_sparks.spread = 70.0
	_sparks.initial_velocity_min = 1.0;_sparks.initial_velocity_max = 3.2;_sparks.gravity = Vector3(0, -9.8, 0)
	_sparks.particle_flag_align_y = true
	var ramp := Gradient.new();ramp.colors = PackedColorArray([Color(1, 1, .9), Color(1, .55, .15, 0)]);_sparks.color_ramp = ramp
	_joints.ArmTip.add_child(_sparks)
	_arc = OmniLight3D.new();_arc.light_color = Color(.65, .8, 1.0);_arc.light_energy = 0.0;_arc.omni_range = 2.6
	_arc.shadow_enabled = false;_joints.ArmTip.add_child(_arc)

func _process(delta: float) -> void:
	_t += delta
	if _t < 0.0:return
	match _state:
		WAIT:
			if _t > 1.4:_next(REACH)
		REACH:
			_blend(_work, delta, 2.4)
			if _t > 0.9:_next(WELD)
		WELD:
			_blend(_work, delta, 3.0)
			# The torch dances a little along the seam.
			_pose.wrist = _work.wrist + sin(_t * 9.0) * 0.06
			if _t > 1.8:_next(RETRACT)
		RETRACT:
			_blend(_rest, delta, 2.0)
			if _t > 1.0:_next(WAIT)
	welding = _state == WELD
	_sparks.emitting = welding
	_arc.light_energy = randf_range(2.0, 6.0) if welding else 0.0
	_apply()

func _next(s: int) -> void:
	_state = s;_t = 0.0

func _blend(goal: Dictionary, delta: float, rate: float) -> void:
	for k in goal:_pose[k] = lerpf(_pose[k], goal[k], minf(1.0, rate * delta))

func _apply() -> void:
	_joints.ArmTurret.rotation.y = _pose.yaw
	_joints.ArmLower.rotation.x = _pose.lower
	_joints.ArmUpper.rotation.x = _pose.upper
	_joints.ArmWrist.rotation.x = _pose.wrist
