extends SceneTree
## E9 performance probe: measures physics step time, active enemies, bodies, and nodes along the route.
## Copies the pattern of game/tests/route_playthrough.gd and prints measurements.
const MISSION = preload("res://modules/world/notstrom_layout.gd")
const ROUTE = preload("res://data/route_layout.gd")
const TICK := 1.0 / 60.0          # the headless runner uses --fixed-fps 60: one physics tick per frame
const MAX_WALK_TICKS := 60 * 300  # 5 minutes of game time for the whole route
var failures := 0
var p: CharacterBody3D

func check(label: String, ok: bool, info := "") -> void:
	print("PERF_PROBE ", "PASS " if ok else "FAIL ", label, ("  " + info) if info != "" else "")
	if not ok: failures += 1

func finish() -> void:
	for action in InputMap.get_actions(): Input.action_release(action)
	print("PERF_PROBE SUMMARY failures=", failures)
	quit(1 if failures else 0)

func tap(action: String) -> void:
	Input.action_press(action);await physics_frame;await physics_frame;Input.action_release(action)

func alive(e) -> bool:
	return is_instance_valid(e) and e.is_inside_tree() and not bool(e.get("_dead"))

func run() -> void:
	if not OS.get_user_data_dir().begins_with("/tmp/"): quit(2); return
	# Remove any stale save file so route starts fresh
	var save_file := "user://rendrun_route_v12.json"
	if FileAccess.file_exists(save_file):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_file))

	seed(20261105)
	var main = load("res://main.tscn").instantiate();root.add_child(main);current_scene = main
	await create_timer(0.3).timeout
	main.pause_controller.resume()
	p = main.player
	var route = main.route

	# (c) Death at the start: back in control in under 10 s of game time.
	p._iframes = 0.0
	p.take_damage(p.hp, p.global_position + Vector3(1, 0, 0))
	var ticks := 0
	var died := false
	while ticks < 60 * 20:
		await physics_frame;ticks += 1
		if p._dying: died = true
		elif died: break
	check("scripted death happens", died)
	check("back in control in under 10 s of game time", died and not p._dying and ticks * TICK < 10.0, "%.2f s" % (ticks * TICK))
	var before: float = p.global_position.x
	Input.action_press("move_right")
	for i in 30: await physics_frame
	Input.action_release("move_right")
	check("input moves Rend again after the respawn", p.global_position.x > before + 0.3, "x %.2f -> %.2f" % [before, p.global_position.x])

	var zone_names := [
		MISSION.zone(5.0),
		MISSION.zone(15.0),
		MISSION.zone(26.0),
		MISSION.zone(45.0),
		MISSION.zone(75.0)
	]
	var zone_records := {}
	for z in zone_names:
		zone_records[z] = {
			"samples": 0,
			"physics_ms_sum": 0.0,
			"physics_ms_max": 0.0,
			"nodes_max": 0,
			"bodies_max": 0,
			"enemies_max": 0,
			"draw_calls_max": 0,
			"peak_sample": {}
		}

	var all_samples: Array = []

	# (a) Walk the route from the start to the airlock exit.
	var best_x: float = p.global_position.x
	var stuck := 0
	var visited: Array = []
	ticks = 0
	while ticks < MAX_WALK_TICKS and not route.completed:
		p.hp = p.max_hp
		for e in get_nodes_in_group("enemies"):
			if alive(e) and e.global_position.distance_to(p.global_position) < 4.0:
				e.take_melee_hit(50, Vector3(signf(e.global_position.x - p.global_position.x), 0, 0))
		Input.action_press("move_right")
		await physics_frame;ticks += 1

		# Record metrics
		var cur_zone := MISSION.zone(p.global_position.x)
		var physics_ms := Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
		var node_count := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
		var bodies_count := int(Performance.get_monitor(Performance.PHYSICS_3D_ACTIVE_OBJECTS))
		var draw_calls := int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))

		var enemy_count := 0
		for e in get_nodes_in_group("enemies"):
			if alive(e):
				enemy_count += 1

		var sample := {
			"tick": ticks,
			"time_s": ticks * TICK,
			"x": p.global_position.x,
			"zone": cur_zone,
			"physics_ms": physics_ms,
			"nodes": node_count,
			"bodies": bodies_count,
			"enemies": enemy_count,
			"draw_calls": draw_calls
		}
		all_samples.append(sample)

		if zone_records.has(cur_zone):
			var rec: Dictionary = zone_records[cur_zone]
			rec["samples"] += 1
			rec["physics_ms_sum"] += physics_ms
			if physics_ms > rec["physics_ms_max"]:
				rec["physics_ms_max"] = physics_ms
			if node_count > rec["nodes_max"]:
				rec["nodes_max"] = node_count
			if bodies_count > rec["bodies_max"]:
				rec["bodies_max"] = bodies_count
			if enemy_count > rec["enemies_max"]:
				rec["enemies_max"] = enemy_count
			if draw_calls > rec["draw_calls_max"]:
				rec["draw_calls_max"] = draw_calls
			# Peak busy moment in zone by combined load (nodes + enemies * 50)
			var cur_load: int = node_count + enemy_count * 50
			var peak_load: int = int(rec["peak_sample"].get("load", 0))
			if cur_load > peak_load:
				sample["load"] = cur_load
				rec["peak_sample"] = sample

		if p.global_position.x > best_x + 0.05:
			best_x = p.global_position.x;stuck = 0
		else:
			stuck += 1
		if stuck == 20: await tap("interact")
		elif stuck == 40: await tap("jump")
		elif stuck >= 90:
			print("PERF_PROBE stuck at x=%.2f y=%.2f z=%.2f" % [p.global_position.x, p.global_position.y, p.global_position.z])
			stuck = 0
		var bucket := int(p.global_position.x / 10.0)
		if not bucket in visited:
			visited.append(bucket)
			print("PERF_PROBE x=%.1f after %.1f s game time, cleared %d/%d" % [p.global_position.x, ticks * TICK, MISSION.cleared_count(route.cleared), MISSION.ENCOUNTERS.size()])

	Input.action_release("move_right")
	check("every mission encounter cleared", MISSION.cleared_count(route.cleared) == MISSION.ENCOUNTERS.size(), "%d/%d" % [MISSION.cleared_count(route.cleared), MISSION.ENCOUNTERS.size()])
	check("Rend reaches the airlock exit and the route completes", route.completed and p.global_position.x > MISSION.EXIT_X, "x=%.2f after %.1f s" % [p.global_position.x, ticks * TICK])

	print("PERF_PROBE === ZONE MEASUREMENTS ===")
	for z in zone_names:
		var rec: Dictionary = zone_records[z]
		var avg_physics := 0.0
		if rec["samples"] > 0:
			avg_physics = rec["physics_ms_sum"] / float(rec["samples"])
		var peak: Dictionary = rec["peak_sample"]
		print("PERF_PROBE ZONE: '%s' samples=%d enemies_max=%d bodies_max=%d nodes_max=%d draw_calls_max=%d physics_ms_avg=%.3f physics_ms_max=%.3f peak=[x=%.2f t=%.2fs enemies=%d bodies=%d nodes=%d physics_ms=%.3f]" % [
			z, rec["samples"], rec["enemies_max"], rec["bodies_max"], rec["nodes_max"], rec["draw_calls_max"], avg_physics, rec["physics_ms_max"],
			peak.get("x", 0.0), peak.get("time_s", 0.0), peak.get("enemies", 0), peak.get("bodies", 0), peak.get("nodes", 0), peak.get("physics_ms", 0.0)
		])

	# Sort all samples by load (nodes + enemies * 50)
	all_samples.sort_custom(func(a, b): return (a["nodes"] + a["enemies"] * 50) > (b["nodes"] + b["enemies"] * 50))
	print("PERF_PROBE === TOP BUSIEST MOMENTS ===")
	for i in mini(5, all_samples.size()):
		var s: Dictionary = all_samples[i]
		print("PERF_PROBE TOP [%d]: x=%.2f t=%.2fs zone='%s' enemies=%d bodies=%d nodes=%d physics_ms=%.3f draw_calls=%d" % [
			i + 1, s["x"], s["time_s"], s["zone"], s["enemies"], s["bodies"], s["nodes"], s["physics_ms"], s["draw_calls"]
		])

	finish()

func _initialize() -> void:
	call_deferred("run")
