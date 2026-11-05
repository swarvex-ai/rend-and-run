extends SceneTree
## Contract test for the route data (game/data/route_layout.gd): every placement lies on the
## route between the west and east boundary, and the built route uses the data.
const ROUTE = preload("res://data/route_layout.gd")
const MISSION = preload("res://modules/world/notstrom_layout.gd")
var failures := 0

func check(label: String, ok: bool) -> void:
	print("LAYOUT ", "PASS " if ok else "FAIL ", label)
	if not ok: failures += 1

func on_route(x: float) -> bool:
	return x >= -3.0 and x <= MISSION.EAST_X - 1.0

func run() -> void:
	if not OS.get_user_data_dir().begins_with("/tmp/"): quit(2); return
	var xs: Array = []
	for pos in [ROUTE.ARM_PICKUP_POS, ROUTE.FIRST_SALVAGE_POS, ROUTE.SHIELD_POS, ROUTE.CACHE_POS, ROUTE.ENTRY_WORKBENCH_POS, ROUTE.WORKBENCH_POS, ROUTE.GUN_BENCH_POS, ROUTE.CHECKPOINT_POS, ROUTE.RELAY_CHECKPOINT_POS, ROUTE.SHORTCUT_POS, ROUTE.COOLANT_CANISTER_POS, ROUTE.SECURITY_COVER_POS]:
		xs.append(pos.x)
	for pos in ROUTE.CRATE_POSITIONS.values(): xs.append(pos.x)
	for pos in ROUTE.WING_DRONES: xs.append(pos.x)
	for stack in ROUTE.THROWABLE_STACKS: xs.append(float(stack[0]))
	for cue in ROUTE.PA_CUES: xs.append(float(cue[0]))
	xs.append_array(ROUTE.SERVICE_LAMP_XS);xs.append_array(ROUTE.FREIGHT_COVER_XS);xs.append(ROUTE.AWAKENING_X)
	var off: Array = xs.filter(func(x): return not on_route(x))
	check("every placement lies on the route %s" % [off], off.is_empty())
	var ids: Array = MISSION.ENCOUNTERS.map(func(e): return e.id)
	var unknown: Array = ROUTE.REINFORCEMENTS.keys().filter(func(id): return not id in ids)
	check("reinforcements name existing encounters %s" % [unknown], unknown.is_empty())
	check("checkpoints come in route order", ROUTE.CHECKPOINT_POS.x < ROUTE.RELAY_CHECKPOINT_POS.x)
	var main = load("res://main.tscn").instantiate();root.add_child(main);current_scene=main
	await create_timer(0.3).timeout
	var route = main.route
	check("route builds one supply crate per entry", route.supply_crates.size() == ROUTE.CRATE_POSITIONS.size())
	check("route builds the throwable stacks", route.throwables.size() == ROUTE.THROWABLE_STACKS.reduce(func(n, s): return n + int(s[1]), 0))
	check("route builds the wing drones", route.wing_drones.size() == ROUTE.WING_DRONES.size())
	check("arm pickup stands where the data says", route.arm_pickup.position.is_equal_approx(ROUTE.ARM_PICKUP_POS))
	check("checkpoint console stands where the data says", route.checkpoint_console.position.is_equal_approx(ROUTE.CHECKPOINT_CONSOLE_POS))
	print("LAYOUT SUMMARY failures=", failures)
	quit(1 if failures else 0)

func _initialize() -> void:
	call_deferred("run")
