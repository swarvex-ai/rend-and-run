extends SceneTree
## Regression test for deterministic robot depth lanes: robots get their lane offset
## from the scene spawn order, not from engine instance ids shifted by load order.
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(label: String, ok: bool) -> void:
	print("LANE %s %s" % ["PASS" if ok else "FAIL", label])
	if not ok: failures += 1

func _collect_lanes(route) -> Dictionary:
	var lanes := {}
	for e in route.enemies:
		lanes[e.encounter_id] = e._lane_offset
	return lanes

func run() -> void:
	if not OS.get_user_data_dir().begins_with("/tmp/"):
		quit(2)
		return
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	await create_timer(0.3).timeout

	var first_lanes := _collect_lanes(main.route)
	var expected := [-0.25, 0.0, 0.25]
	var ordered: bool = main.route.enemies.size() == 8
	for i in main.route.enemies.size():
		if not is_equal_approx(main.route.enemies[i]._lane_offset, expected[i % 3]):
			ordered = false
	check("route robots follow -0.25/0.0/+0.25 by spawn order", ordered)

	main.queue_free()
	await process_frame
	await process_frame

	# Shift the engine's object ids before the second scene allocates its robots.
	var objs: Array = []
	for i in 1000:
		objs.append(RefCounted.new())
	var second = load("res://main.tscn").instantiate()
	root.add_child(second)
	current_scene = second
	await create_timer(0.3).timeout

	var same := true
	for e in second.route.enemies:
		if not first_lanes.has(e.encounter_id):
			same = false
		elif not is_equal_approx(float(first_lanes[e.encounter_id]), e._lane_offset):
			same = false
	check("lanes survive a shift of 1000 engine object ids", same)

	var a = second._make_enemy(0, 0)
	var b = second._make_enemy(0, 0)
	a.set_physics_process(false)
	b.set_physics_process(false)
	check("consecutive spawns get different lanes", not is_equal_approx(a._lane_offset, b._lane_offset))

	second.queue_free()
	objs.clear()
	await process_frame
	await process_frame
	print("LANE SUMMARY failures=", failures)
	quit(1 if failures else 0)
