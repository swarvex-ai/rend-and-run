extends SceneTree
# H13 — Headless-Test fuer supply_crate.gd (isolated SceneTree, keine Hauptszene).
# Aufruf: godot --headless --path <projekt> --script res://tests/supply_crate_test.gd
# Exit-Code 0 = alle Checks PASS, 1 = mindestens ein FAIL.

const CRATE_SCRIPT := preload("res://modules/loot/supply_crate.gd")

var checks := 0
var failures := 0

func check(label: String, ok: bool) -> void:
	checks += 1
	if not ok:
		failures += 1
	print("H13 %s %s" % ["PASS" if ok else "FAIL", label])

func intact_visible(crate: Node) -> bool:
	var intact := crate.get_node("CrateVisual").find_child("IntactVisual", true, false)
	assert(intact != null)
	var meshes := intact.find_children("*", "MeshInstance3D", true, false)
	assert(not meshes.is_empty())
	for mesh in meshes:
		if mesh.visible:
			return true
	return false

func _initialize() -> void:
	# In `--script`-Modus laeuft _initialize() VOR der ersten Main-Loop-Iteration;
	# _ready-Benachrichtigungen werden erst mit dem ersten Frame zugestellt.
	# Ein Frame warten, damit Kollision/Mesh aufgebaut und sichtbar sind.
	await process_frame
	var root_node := get_root()

	# --- 1) Grundkonfiguration -------------------------------------------------
	var a := CRATE_SCRIPT.new()
	a.name = "CrateA"
	root_node.add_child(a)
	await process_frame  # _ready ist in Godot deferred; erst danach ist der Baum gebaut
	check("root is StaticBody3D", a is StaticBody3D)
	check("collision layers world and hittable", a.collision_layer == (1 | 2))
	check("collision mask 1", a.collision_mask == 1)
	check("not in enemies group", not a.is_in_group("enemies"))
	var col: CollisionShape3D = a.get_node("Collision")
	check("collider is one box 0.65x0.65x0.55",
		col.shape is BoxShape3D and col.shape.size == Vector3(0.65, 0.65, 0.55))
	check("not broken after ready", not a.is_broken())

	var events: Array = []
	a.broken.connect(func(cid: String, amount: int, origin: Vector3) -> void:
		events.append([cid, amount, origin]))

	# --- 2) Erster Treffer ueberlebt, zweiter zerstoert ------------------------
	a.take_melee_hit(1, Vector3.ZERO)
	check("first hit survives", not a.is_broken() and events.size() == 0)
	a.take_melee_hit(1, Vector3.ZERO)
	check("second hit breaks", a.is_broken())
	check("broken emitted exactly once", events.size() == 1)
	if events.size() == 1:
		check("signal payload id/amount/origin",
			events[0][0] == a.crate_id and events[0][1] == 3 and events[0][2] == a.global_position)
	# --- 3) Weitere Treffer bringen keine weiteren Rewards ---------------------
	a.take_melee_hit(5, Vector3(1, 0, 0))
	a.take_melee_hit(1, Vector3.ZERO)
	check("hits after break emit no further broken signal", events.size() == 1)
	# --- 4) Kollision nach einem Physikframe deaktiviert ------------------------
	await process_frame
	check("collision disabled after one frame", col.disabled)
	# --- 5) Null-/Negativ-Schaden wird ignoriert --------------------------------
	var b := CRATE_SCRIPT.new()
	root_node.add_child(b)
	await process_frame
	b.take_melee_hit(0, Vector3.ZERO)
	b.take_melee_hit(-3, Vector3.ZERO)
	check("zero/negative damage ignored", not b.is_broken())
	# --- 6) Zwei Instanzen sind unabhaengig -------------------------------------
	check("instances independent", a.is_broken() and not b.is_broken())
	b.take_melee_hit(2, Vector3.ZERO)
	check("killing b does not change a", b.is_broken() and a.is_broken())
	# --- 7) restore(true) vor _ready: kein Reward -------------------------------
	var c := CRATE_SCRIPT.new()
	var broke_early := [false]
	c.broken.connect(func(_cid, _amt, _org) -> void: broke_early[0] = true)
	c.restore_broken(true)
	check("restore(true) before ready sets broken", c.is_broken())
	root_node.add_child(c)  # _ready wendet den Zustand erst jetzt an
	await process_frame
	var col_c: CollisionShape3D = c.get_node("Collision")
	check("restore(true) before ready breaks with no reward", not broke_early[0] and c.is_broken())
	check("restore(true) before ready hides visual and collision",
		not intact_visible(c) and col_c.disabled)
	# --- 8) restore(true) nach _ready: kein Reward ------------------------------
	c.restore_broken(false)
	await process_frame
	c.take_melee_hit(1, Vector3.ZERO)
	c.restore_broken(true)
	await process_frame
	check("restore(true) after ready emits no reward", not broke_early[0])
	# --- 9) restore(false) = nutzbare Kiste, ein frischer Bruch moeglich --------
	c.restore_broken(false)
	await process_frame
	check("restore(false) resets to usable crate",
		not c.is_broken() and intact_visible(c) and not col_c.disabled)
	c.take_melee_hit(1, Vector3.ZERO)
	check("fresh crate needs full hp again (hit 1 survives)", not c.is_broken() and not broke_early[0])
	c.take_melee_hit(1, Vector3.ZERO)
	check("reset permits one fresh break with reward", c.is_broken() and broke_early[0])
	c.take_melee_hit(1, Vector3.ZERO)
	# --- 10) Reward-Hoehe stabil, nicht negativ ---------------------------------
	var d := CRATE_SCRIPT.new()
	d.reward_amount = 0
	root_node.add_child(d)
	await process_frame
	var d_events: Array = []
	d.broken.connect(func(_cid, amt, _org) -> void: d_events.append(amt))
	d.take_melee_hit(99, Vector3.ZERO)
	check("zero reward reported non-negative exactly once", d_events.size() == 1 and d_events[0] == 0)
	# --- 11) restore(false) nach Bruch loest kein broken aus ---------------------
	var before: int = d_events.size()
	d.restore_broken(false)
	check("restore(false) never emits", d_events.size() == before)

	print("H13 SUMMARY checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
