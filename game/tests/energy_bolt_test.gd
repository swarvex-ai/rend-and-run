extends SceneTree
# H17 — Headless-Physik-Test fuer energy_bolt.gd (Sweep-Ray gegen echte StaticBody3D).
# Aufruf: godot --headless --path <isolierter-scratch> --script res://tests/energy_bolt_test.gd
# Nutzt echte Physik-Frames (await physics_frame); Exit 0 = alle Checks PASS.

const BOLT_SCRIPT := preload("res://modules/combat/energy_bolt.gd")

var checks := 0
var failures := 0

func check(label: String, ok: bool) -> void:
	checks += 1
	if not ok:
		failures += 1
	print("H17 %s %s" % ["PASS" if ok else "FAIL", label])

func wait_physics(n: int) -> void:
	for i in n:
		await physics_frame

# Waitet hoch max_frames Physik-Frames, bis pred() wahr ist. true = Bedingung erreicht.
func wait_until(pred: Callable, max_frames: int) -> bool:
	var i := 0
	while i < max_frames and not pred.call():
		await physics_frame
		i += 1
	return pred.call()

func add_wall(x: float, layer: int, thickness: float = 0.05, y: float = 0.0) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = layer
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(thickness, 6.0, 6.0)
	shape.shape = box
	body.add_child(shape)
	body.position = Vector3(x, y, 0.0)
	root.add_child(body)
	return body

func fresh_bolt(parent: Node = null, bolt_lifetime: float = 3.0) -> Node3D:
	var b: Node3D = BOLT_SCRIPT.new()
	b.lifetime = bolt_lifetime
	(parent if parent != null else root).add_child(b)
	return b

func watch(b: Node3D, events: Array) -> void:
	b.impacted.connect(func(c: Object, p: Vector3, n: Vector3) -> void:
		events.append({"c": c, "p": p, "n": n}))

func _initialize() -> void:
	# SceneTree-Skriptmodus: erst ein Frame, dann ist die Welt synchronisiert.
	await physics_frame

	# --- 0) Startzustand ---------------------------------------------------------
	var b := fresh_bolt()
	check("vor launch: resolved (nichts laeuft), Visual unsichtbar",
		b.is_resolved() and not b.get_node("BoltVisual").visible)

	# --- 1) Flug durch leere Welt: bewegt sich, bleibt ungelöst bis Expiry --------
	b = fresh_bolt(null, 0.5)
	var events_empty: Array = []
	watch(b, events_empty)
	b.launch(Vector3(-5.0, 0.0, 0.0), Vector3(10.0, 0.0, 0.0), 1)
	check("launch setzt Position (Weltkoordinaten)",
		b.global_position.is_equal_approx(Vector3(-5.0, 0.0, 0.0)))
	await physics_frame
	await physics_frame
	var moved := b.global_position.x > -5.0
	check("leere Welt: bewegt sich mit der Geschwindigkeit", moved and not b.is_resolved())
	check("Expiry nach lifetime: resolved, KEIN impacted, Visual aus",
		await wait_until(func() -> bool: return b.is_resolved(), 60)
		and events_empty.is_empty() and not b.get_node("BoltVisual").visible)
	# Position ~ start + v*lifetime (0.5s * 10 = 5m, -5+~4.9)
	check("Expiry-Position plausibel (nahe -0.1, nicht teleportiert)",
		b.global_position.x > -1.0 and b.global_position.x < 0.2)

	# --- 2) Duenne Wand bei hoher Geschwindigkeit: Sweep faengt sie --------------
	var wall := add_wall(5.0, 1)  # y-Bereich [-3,3]
	await physics_frame  # statischer Body muss im Physikraum sein
	var hit_bolt := fresh_bolt()
	var events: Array = []
	watch(hit_bolt, events)
	hit_bolt.launch(Vector3(-5.0, 0.0, 0.0), Vector3(300.0, 0.0, 0.0), 1)
	# 300 m/s * 1/60s = 5m/Frame — ohne Sweep Tunneln durch die 0.05m-Wand.
	var hit_ok := await wait_until(func() -> bool: return not events.is_empty(), 10)
	check("duenne Wand 300m/s: impacted innerhalb weniger Frames", hit_ok)
	check("resolved VOR Signal (Handler sieht resolved=true)", hit_bolt.is_resolved())
	await wait_physics(20)
	check("genau EIN impacted nach weiteren 20 Frames", events.size() == 1)
	check("exakter Collider == Wand-Node", events[0]["c"] == wall)
	check("Touchpoint auf Wandvorderseite x~4.975, NICHT dahinter",
		absf(events[0]["p"].x - 4.975) < 0.01 and hit_bolt.global_position.x < 5.0)
	check("Normal zeigt zurueck zum Werfer (-X)", events[0]["n"].x < -0.99)
	check("Bolt sitzt am Touchpoint, Visual aus, Processing aus",
		hit_bolt.global_position.is_equal_approx(events[0]["p"])
		and not hit_bolt.get_node("BoltVisual").visible
		and not hit_bolt.is_physics_processing())
	check("Root lebt weiter (kein self-free im Signal)", is_instance_valid(hit_bolt))

	# --- 3) Maske wird respektiert: Wand auf Layer 2, Bolt-Maske 1 -> durch -------
	# Eigene Bahn bei y=4 (Layer-1-Wand deckt nur [-3,3] ab).
	add_wall(5.0, 2, 0.05, 4.0)
	await physics_frame
	b = fresh_bolt(null, 0.5)
	var events_m: Array = []
	watch(b, events_m)
	b.launch(Vector3(-5.0, 4.0, 0.0), Vector3(60.0, 0.0, 0.0), 1)
	check("fremde Maske: kein impacted, durchquert die Wandebene",
		await wait_until(func() -> bool: return b.is_resolved(), 60)
		and events_m.is_empty() and b.global_position.x > 5.0)

	# --- 4) Exclude-RID wird respektiert ------------------------------------------
	b = fresh_bolt(null, 0.5)
	var events_x: Array = []
	watch(b, events_x)
	var excl: Array[RID] = [wall.get_rid()]
	b.launch(Vector3(-5.0, -2.0, 0.0), Vector3(60.0, 0.0, 0.0), 1, excl)
	check("ausgeschlossene RID: kein impacted, Bahn frei",
		await wait_until(func() -> bool: return b.is_resolved(), 60)
		and events_x.is_empty() and b.global_position.x > 5.0)

	# --- 5) Nullgeschwindigkeit harmlos --------------------------------------------
	b = fresh_bolt(null, 0.2)
	var events_z: Array = []
	watch(b, events_z)
	b.launch(Vector3(1.0, 3.0, 0.0), Vector3.ZERO, 1)
	await wait_physics(3)
	check("null v: keine Bewegung, kein Impuls, nicht geloest",
		b.global_position.is_equal_approx(Vector3(1.0, 3.0, 0.0))
		and events_z.is_empty() and not b.is_resolved())
	check("null v: laeuft nach lifetime sauber aus (ohne Event)",
		await wait_until(func() -> bool: return b.is_resolved(), 60)
		and events_z.is_empty())

	# --- 6) Reuse nach Treffer (derselbe hit_bolt von Abschnitt 2) -----------------
	hit_bolt.launch(Vector3(-5.0, 0.0, 0.0), Vector3(300.0, 0.0, 0.0), 1)
	check("Reuse nach Treffer: Position zurueckgesetzt, wieder ungelöst",
		hit_bolt.global_position.is_equal_approx(Vector3(-5.0, 0.0, 0.0))
		and not hit_bolt.is_resolved() and hit_bolt.get_node("BoltVisual").visible)
	var hit2 := await wait_until(func() -> bool: return events.size() >= 2, 10)
	check("zweiter Flug trifft wieder (events=2, gleicher Collider)",
		hit2 and events.size() == 2 and events[1]["c"] == wall)

	# --- 7) Reuse nach Verfall + Timer-Reset ----------------------------------------
	var b2 := fresh_bolt(null, 0.3)
	var events_r: Array = []
	watch(b2, events_r)
	b2.launch(Vector3(-20.0, 4.0, 0.0), Vector3(5.0, 0.0, 0.0), 1)
	await wait_physics(3)
	check("Reuse nach Verfall: Timer neu (nach 3 Frames noch ungelöst)",
		not b2.is_resolved())
	check("Verfall Nr.2 ohne Event",
		await wait_until(func() -> bool: return b2.is_resolved(), 60) and events_r.is_empty())
	b2.launch(Vector3(-5.0, 0.0, 0.0), Vector3(200.0, 0.0, 0.0), 1)
	check("dritte Nutzung (nach 2 Verfaellen) trifft Wand",
		await wait_until(func() -> bool: return not events_r.is_empty(), 10)
		and events_r.size() == 1)

	# --- 8) launch VOR Ready ---------------------------------------------------------
	var cold: Node3D = BOLT_SCRIPT.new()
	cold.lifetime = 3.0
	var events_c: Array = []
	watch(cold, events_c)
	cold.launch(Vector3(-5.0, 0.0, 0.0), Vector3(200.0, 0.0, 0.0), 1)
	root.add_child(cold)
	# Vor Tree-Eintritt liefert global_position nur Identitaet — lokal pruefen.
	check("launch vor Baum: Position sofort gesetzt, ungelöst",
		cold.position.is_equal_approx(Vector3(-5.0, 0.0, 0.0))
		and not cold.is_resolved())
	check("Flug laeuft ab Tree-Eintritt normal weiter -> Treffer",
		await wait_until(func() -> bool: return not events_c.is_empty(), 10))

	# --- 9) Transformierter Parent: Weltkoordinaten fuehren ---------------------------
	var parent := Node3D.new()
	parent.position = Vector3(100.0, 0.0, 50.0)
	parent.rotation.y = deg_to_rad(90.0)
	root.add_child(parent)
	await physics_frame
	b = fresh_bolt(parent)
	var events_p: Array = []
	watch(b, events_p)
	b.launch(Vector3(-5.0, 0.0, 0.0), Vector3(200.0, 0.0, 0.0), 1)
	check("transformierter Parent: Bolt startet auf WELT-origin",
		b.global_position.is_equal_approx(Vector3(-5.0, 0.0, 0.0)))
	check("transformierter Parent: Weltflug trifft Wand bei x~4.975",
		await wait_until(func() -> bool: return not events_p.is_empty(), 10)
		and absf(events_p[0]["p"].x - 4.975) < 0.01)

	# --- 10) Instanzunabhaengigkeit ----------------------------------------------------
	var a := fresh_bolt()
	var c := fresh_bolt()
	var events_a: Array = []
	var events_c2: Array = []
	watch(a, events_a)
	watch(c, events_c2)
	a.launch(Vector3(-5.0, 0.0, 0.0), Vector3(200.0, 0.0, 0.0), 1)
	c.launch(Vector3(-5.0, 1.0, 0.0), Vector3(50.0, 0.0, 0.0), 2)  # andere Maske
	await wait_physics(10)
	check("Treffer der einen Instanz erzeugt kein Event der anderen",
		events_a.size() == 1 and events_c2.is_empty() and not c.is_resolved())
	check("eigene Mesh-/Material-Ressourcen pro Instanz",
		a.get_node("BoltVisual").mesh != c.get_node("BoltVisual").mesh
		and a.get_node("BoltVisual").material_override != c.get_node("BoltVisual").material_override)

	print("H17 SUMMARY checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
