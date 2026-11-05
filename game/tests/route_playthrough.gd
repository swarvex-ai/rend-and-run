extends SceneTree
## M1 end-to-end test (docs/milestone-1.md, criteria a and c).
## (c) Rend dies at the start and must be back in control in under 10 s of game time.
## (a) Rend then walks the whole route with real input, from the start to the airlock exit,
##     picking up the arm, opening doors and passing every encounter, without a crash.
## The fights are not the subject here: robots close to Rend are destroyed through their own
## take_melee_hit(), and Rend's HP is topped up. The test proves the route can be traversed
## and completed; combat has its own tests.
const MISSION = preload("res://modules/world/notstrom_layout.gd")
const ROUTE = preload("res://data/route_layout.gd")
const TICK := 1.0 / 60.0          # the headless runner uses --fixed-fps 60: one physics tick per frame
const MAX_WALK_TICKS := 60 * 300  # 5 minutes of game time for the whole route
var failures := 0
var p: CharacterBody3D

func check(label: String, ok: bool, info := "") -> void:
	print("ROUTE ", "PASS " if ok else "FAIL ", label, ("  " + info) if info != "" else "")
	if not ok: failures += 1

func finish() -> void:
	for action in InputMap.get_actions(): Input.action_release(action)
	print("ROUTE SUMMARY failures=", failures)
	quit(1 if failures else 0)

func tap(action: String) -> void:
	Input.action_press(action);await physics_frame;await physics_frame;Input.action_release(action)

func alive(e) -> bool:
	return is_instance_valid(e) and e.is_inside_tree() and not bool(e.get("_dead"))

func run() -> void:
	if not OS.get_user_data_dir().begins_with("/tmp/"): quit(2); return
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
		if p.global_position.x > best_x + 0.05:
			best_x = p.global_position.x;stuck = 0
		else:
			stuck += 1
		if stuck == 20: await tap("interact")
		elif stuck == 40: await tap("jump")
		elif stuck >= 90:
			print("ROUTE stuck at x=%.2f y=%.2f z=%.2f" % [p.global_position.x, p.global_position.y, p.global_position.z])
			stuck = 0
		var bucket := int(p.global_position.x / 10.0)
		if not bucket in visited:
			visited.append(bucket)
			print("ROUTE x=%.1f after %.1f s game time, cleared %d/%d" % [p.global_position.x, ticks * TICK, MISSION.cleared_count(route.cleared), MISSION.ENCOUNTERS.size()])
	Input.action_release("move_right")
	check("every mission encounter cleared", MISSION.cleared_count(route.cleared) == MISSION.ENCOUNTERS.size(), "%d/%d" % [MISSION.cleared_count(route.cleared), MISSION.ENCOUNTERS.size()])
	check("Rend reaches the airlock exit and the route completes", route.completed and p.global_position.x > MISSION.EXIT_X, "x=%.2f after %.1f s" % [p.global_position.x, ticks * TICK])
	finish()

func _initialize() -> void:
	call_deferred("run")
