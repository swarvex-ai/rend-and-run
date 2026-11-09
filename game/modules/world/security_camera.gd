extends Node3D
## Wall-mounted security camera (Blender, tools/blender/build_security_camera.py). It pans
## and tilts after Rend while he is in range. Seeing him run or fight in its field of view
## lights the LED red, beeps and calls the robots nearby (squad provoke); a crouching,
## sneaking Rend goes unseen. Re-arms after COOLDOWN. The lens looks along +Z.

const MODEL := preload("res://assets3d/env/security_camera_v1/model.glb")
const RANGE := 9.0
const CALL_RADIUS := 14.0
const COOLDOWN := 8.0
const PAN_LIMIT := 1.2
const UI_TEXT = preload("res://data/ui_texts.gd")

var _pan: Node3D
var _tilt: Node3D
var _led: MeshInstance3D
var _led_mat: StandardMaterial3D
var _cool := 0.0
var spotted := 0                  # tests: times it raised the alarm
var _seen := 0.0                  # s he has been in clear, loud view
const REACT := 0.3                # recognition time before it calls

func _ready() -> void:
	var model := MODEL.instantiate() as Node3D
	add_child(model)
	_pan = model.find_child("CamPan", true, false)
	_tilt = model.find_child("CamTilt", true, false)
	_led = model.find_child("CamLed", true, false) as MeshInstance3D
	if _led:
		_led_mat = StandardMaterial3D.new();_led_mat.albedo_color = Color(.4, .02, .02)
		_led_mat.emission_enabled = true;_led_mat.emission = Color(1, .06, .03);_led_mat.emission_energy_multiplier = 0.4
		_led.material_override = _led_mat

func _process(delta: float) -> void:
	_cool = maxf(0.0, _cool - delta)
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null or _pan == null:return
	var to := player.global_position + Vector3(0, 1.1, 0) - _pan.global_position
	var near: bool = to.length() < RANGE and not player._dying
	# Track him: yaw in the mount's frame, pitch down toward him.
	var local := global_basis.inverse() * to
	var yaw := clampf(atan2(local.x, local.z), -PAN_LIMIT, PAN_LIMIT) if near else sin(Time.get_ticks_msec() * 0.0004) * 0.6
	var pitch := clampf(atan2(-local.y, Vector2(local.x, local.z).length()), -0.2, 0.9) if near else 0.35
	_pan.rotation.y = lerp_angle(_pan.rotation.y, yaw, minf(1.0, 4.0 * delta))
	_tilt.rotation.x = lerp_angle(_tilt.rotation.x, pitch, minf(1.0, 4.0 * delta))
	var alert := _cool > COOLDOWN - 2.5
	if _led_mat:_led_mat.emission_energy_multiplier = (8.0 if fmod(Time.get_ticks_msec() * 0.008, 1.0) < 0.5 else 2.0) if alert else 0.4
	var loud: bool = near and _cool <= 0.0 and not player.crouching and (player.ground_speed() > 3.0 or player._attack_phase > 0)
	if loud:
		var sight := PhysicsRayQueryParameters3D.create(_pan.global_position, player.global_position + Vector3(0, 1.1, 0), 1)
		loud = get_world_3d().direct_space_state.intersect_ray(sight).is_empty()
	_seen = _seen + delta if loud else 0.0
	if _seen >= REACT:
		_seen = 0.0
		_raise_alarm(player)

func _raise_alarm(player: Node3D) -> void:
	spotted += 1;_cool = COOLDOWN
	FX.play("radio_chirp", 0.7, -6.0)
	for robot in get_tree().get_nodes_in_group("enemies"):
		if robot.has_method("provoke") and not robot._dead and robot.is_physics_processing() and absf(robot.global_position.x - player.global_position.x) < CALL_RADIUS:
			robot.provoke()
	var route := get_tree().get_first_node_in_group("robot_voice")
	if route and route.route and route.route.has_method("_message"):route.route._message(UI_TEXT.t("camera_spotted"), 2.5, 1)
