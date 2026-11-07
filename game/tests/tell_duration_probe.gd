extends SceneTree
## E7 measurement probe (not part of the suite): warning time from the first
## visible/audible tell to the first frame an attack can deal damage.
## Per attack it prints one TELL line and one CHANNEL line (visible/audible split).
## Run with: godot --headless --fixed-fps 60 --path game -s res://tests/tell_duration_probe.gd
## XDG_DATA_HOME/XDG_CONFIG_HOME must point under /tmp (as tools/run_tests.sh does).

const FPS := 60
const MAX_FRAMES := 180
const PLAYER_X_OFFSET := 1.2

var main: Node
var player: Node
var rows: Array = []

func _initialize() -> void:
	call_deferred("run")

func audio_total() -> int:
	var n := 0
	var events: Dictionary = root.get_node("FX").audio_events
	for key in events:
		n += int(events[key])
	return n

func _world() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	await create_timer(0.3).timeout
	main.pause_controller.set_process_input(false)
	main.pause_controller.resume()
	player = main.player
	player.set_physics_process(false)
	player.hp = 1000
	player._iframes = 1e9
	# The route and its robots are not part of this measurement; its props would
	# also stand in the swing lanes. Keep only main.tscn's own ground.
	var route = main.route
	if is_instance_valid(route):
		route.set_physics_process(false)
		route.set_process(false)
	for e in get_nodes_in_group("enemies"):
		e.set_physics_process(false)
	for e in get_nodes_in_group("enemies"):
		e.queue_free()
	if is_instance_valid(route):
		route.queue_free()
	await physics_frame
	await physics_frame
	# One flat strip under every probe position (regular robots at x=0, boss at x=73).
	var ground := StaticBody3D.new()
	ground.name = "TellProbeGround"
	ground.collision_layer = 1
	ground.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(140, 1, 8)
	shape.shape = box
	shape.position = Vector3(40, -0.5, 0)
	ground.add_child(shape)
	main.add_child(ground)

func _visible(e) -> bool:
	if is_instance_valid(e._attack_cue) and e._attack_cue._pivot.visible:
		return true
	return false

func _measure_enemy(c: Dictionary) -> void:
	var ex: float = c.get("x", 0.0)
	var e = main._make_enemy(ex, int(c.get("role", 0)),
		c.get("script"), c.get("gun", ""), bool(c.get("shield", false)))
	e.set_physics_process(false)
	e.global_position = Vector3(ex, 0.05, 0)
	e.get_node("VisualPivot").rotation.y = 0.0
	if c.get("overseer", false):
		e.active = true
	if c.get("sentinel", false):
		e.sentinel = e.AWAKE
	if c.has("attack_count"):
		e._attack_count = int(c.attack_count)
	if c.has("phase_attack"):
		e._phase_attack = int(c.phase_attack)
	if c.has("brace_hits"):
		e._brace_hits = int(c.brace_hits)
	if c.has("strike"):
		e.forced_strike = c.strike
	e._ranged_attack = bool(c.get("ranged", false))
	player.global_position = Vector3(ex + PLAYER_X_OFFSET, 0.05, 0.0)

	var audio_before := audio_total()
	var frame := 0
	e._enter(e.WINDUP)
	var visible_frame := -1
	var audible_frame := -1
	var hit_frame := -1
	var shots_before: int = e.shots_fired
	e.set_physics_process(true)
	while frame < MAX_FRAMES:
		await physics_frame
		frame += 1
		if visible_frame < 0 and _visible(e):
			visible_frame = frame
		if audible_frame < 0 and audio_total() > audio_before:
			audible_frame = frame
		var hit: bool = e.shots_fired > shots_before if bool(c.get("ranged", false)) \
			else e._state == e.SWING and e._state_t >= 0.075
		if hit:
			hit_frame = frame
			if visible_frame == frame:
				visible_frame = -1
			if audible_frame == frame:
				audible_frame = -1
			break
	_report(str(c.get("robot", "?")), str(c.get("attack", "?")),
		int(c.get("kind", -1)), visible_frame, audible_frame, hit_frame)
	e.queue_free()
	await physics_frame

func _measure_drone(c: Dictionary) -> void:
	var drone = load("res://modules/combat/maintenance_drone.gd").new()
	drone.encounter_id = "tell_probe_drone"
	drone.player = player
	main.add_child(drone)
	drone.global_position = Vector3(0, 2.2, 0)
	drone.home = drone.global_position
	drone.timer = 0.0
	drone.enabled = true
	await physics_frame
	var eye_color = drone.eye.emission
	var eye_energy: float = drone.eye.emission_energy_multiplier
	var audio_before := audio_total()
	player.global_position = Vector3(1.0, 0.05, 0)

	var frame := 0
	var visible_frame := -1
	var audible_frame := -1
	var hit_frame := -1
	while frame < MAX_FRAMES:
		await physics_frame
		frame += 1
		if drone.phase == 2:
			hit_frame = frame
			break
		if audible_frame < 0 and audio_total() > audio_before:
			audible_frame = frame
		if visible_frame < 0 and (drone.eye.emission != eye_color \
			or absf(drone.eye.emission_energy_multiplier - eye_energy) > 0.01):
			visible_frame = frame
	_report("drone", str(c.get("attack", "dive")), 3, visible_frame, audible_frame, hit_frame)
	drone.queue_free()
	await physics_frame

func _report(robot: String, attack: String, _kind: int,
		visible_frame: int, audible_frame: int, hit_frame: int) -> void:
	var tell_frame := hit_frame
	if visible_frame >= 0:
		tell_frame = visible_frame
	if audible_frame >= 0:
		tell_frame = mini(tell_frame, audible_frame)
	var cue := "visible"
	if visible_frame >= 0 and audible_frame >= 0:
		cue = "both"
	elif audible_frame >= 0:
		cue = "audible"
	var tell_s := float(tell_frame) / FPS
	var hit_s := float(hit_frame) / FPS
	var warning := float(hit_frame - tell_frame) / FPS
	print("TELL %s %s tell=%.3f hit=%.3f warning=%.3f cue=%s" % [
		robot, attack, tell_s, hit_s, warning, cue])
	var vis := "none" if visible_frame < 0 else "%.3f" % (float(hit_frame - visible_frame) / FPS)
	var aud := "none" if audible_frame < 0 else "%.3f" % (float(hit_frame - audible_frame) / FPS)
	print("CHANNEL %s %s visible=%s audible=%s" % [robot, attack, vis, aud])
	if hit_frame < 0:
		push_error("no hit frame for %s %s" % [robot, attack])
		quit(1)
	rows.append({"robot": robot, "attack": attack, "warning": warning})

func run() -> void:
	if not OS.get_user_data_dir().begins_with("/tmp/"):
		quit(2)
		return
	seed(7)
	await _world()
	var cases: Array = [
		{"robot": "guard", "attack": "melee_high", "role": 0, "strike": "slash"},
		{"robot": "guard", "attack": "melee_heavy", "role": 0, "strike": "overhead"},
		{"robot": "guard", "attack": "melee_with_gun", "role": 3, "gun": "smg"},
		{"robot": "guard", "attack": "ranged_pulse", "role": 3, "ranged": true},
		{"robot": "guard", "attack": "ranged_smg", "role": 3, "gun": "smg", "ranged": true},
		{"robot": "guard", "attack": "ranged_pistol", "role": 3, "gun": "pistol", "ranged": true},
		{"robot": "guard", "attack": "ranged_energy_rifle", "role": 3, "gun": "energy_rifle", "ranged": true},
		{"robot": "duelist", "attack": "melee_high", "role": 1, "shield": true},
		{"robot": "duelist", "attack": "melee_low", "role": 1, "shield": true, "attack_count": 1},
		{"robot": "brute", "attack": "melee_heavy", "role": 2},
		{"robot": "overseer", "attack": "high", "role": 2, "x": 73.0,
			"script": load("res://modules/combat/lab_overseer.gd"), "overseer": true},
		{"robot": "overseer", "attack": "low", "role": 2, "x": 73.0,
			"script": load("res://modules/combat/lab_overseer.gd"), "overseer": true,
			"phase_attack": 1},
		{"robot": "overseer", "attack": "braced", "role": 2, "x": 73.0,
			"script": load("res://modules/combat/lab_overseer.gd"), "overseer": true,
			"brace_hits": 2},
		{"robot": "sentinel", "attack": "melee_high", "role": 1,
			"script": load("res://modules/combat/sentinel.gd"), "sentinel": true,
			"strike": "punch"},
		{"robot": "sentinel", "attack": "melee_low", "role": 1,
			"script": load("res://modules/combat/sentinel.gd"), "sentinel": true,
			"attack_count": 1, "strike": "elbow"},
		{"robot": "dog", "attack": "bite", "role": 0,
			"script": load("res://modules/combat/enemy_dog.gd")},
		{"robot": "dog", "attack": "swipe", "role": 0,
			"script": load("res://modules/combat/enemy_dog.gd"), "attack_count": 1},
	]
	for c in cases:
		await _measure_enemy(c)
	await _measure_drone({"attack": "dive"})
	print("TELL PROBE rows=%d" % rows.size())
	quit(0)
