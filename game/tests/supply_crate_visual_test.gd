extends SceneTree
## H22 — Tests fuer supply_crate_visual.gd (standalone, headless).
## Prueft: Bounding per Mesh-AABB in transformierten Weltpositionen,
## Material-/Mesh-Limits, broken-Zustand VOR Tree-Eintritt, Toggle ohne
## Knoten-Akkumulation, keine CollisionObject/Light3D/Timer-Nachfahren,
## keine Per-Frame-Logik, Fussabdruck der eingestuerzten Variante.
## Aufruf: godot --headless --path <scratch> --script res://tests/supply_crate_visual_test.gd

const MODULE := preload("res://modules/visuals/supply_crate_visual.gd")

var failures := 0
var checks := 0

func check(label: String, ok: bool, detail := "") -> void:
	checks += 1
	if not ok:
		failures += 1
	print("H22 %s %s %s" % ["PASS" if ok else "FAIL", label, detail])

func _meshes(root: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	for c in root.get_children():
		if c is MeshInstance3D:
			out.append(c)
		out.append_array(_meshes(c))
	return out

func _all_nodes(root: Node) -> Array[Node]:
	var out: Array[Node] = []
	for c in root.get_children():
		out.append(c)
		out.append_array(_all_nodes(c))
	return out

func _visible_in_chain(mi: Node, root: Node) -> bool:
	var n: Node = mi
	while n != null and n != root:
		if n is VisualInstance3D and not (n as VisualInstance3D).visible:
			return false
		n = n.get_parent()
	return true

func _visible_world_aabb(root: Node) -> AABB:
	var merged := AABB()
	var first := true
	for mi in _meshes(root):
		if not _visible_in_chain(mi, root):
			continue
		var a: AABB = mi.global_transform * mi.get_aabb()
		if first:
			merged = a
			first = false
		else:
			merged = merged.merge(a)
	return merged

func _tri_count(root: Node) -> int:
	var total := 0
	for mi in _meshes(root):
		var m := mi.mesh
		if m == null:
			continue
		if m is BoxMesh:
			# Primitive-Meshes haben keine Mesh-Surfaces: 12 Dreiecke.
			total += 12
			continue
		for s in m.get_surface_count():
			var indices: int = m.surface_get_array_index_len(s)
			total += (indices if indices > 0 else m.surface_get_array_len(s)) / 3
	return total

func _initialize() -> void:
	_run()

func _run() -> void:
	await process_frame

	# --- 1) Zustand VOR Tree-Eintritt: broken setzen, DANN erst in den Baum -------
	var c := MODULE.new()
	check("Default intakt (is_broken==false)", not c.is_broken())
	c.set_broken(true)
	check("set_broken(true) vor Tree-Eintritt ohne Fehler", c.is_broken())
	root.add_child(c)
	await process_frame
	var aabb_b0 := _visible_world_aabb(c)
	check("vorab broken: niedrige Silhouette sichtbar", aabb_b0.size.y <= 0.22 and aabb_b0.size.y > 0.0,
		"h=%.3f" % aabb_b0.size.y)
	c.set_broken(false)
	await process_frame

	# --- 2) Intakte Bounding: AABBs aller sichtbaren Meshes transformiert ---------
	var ai := _visible_world_aabb(c)
	check("intakt: Origin an Basis (y_min ~ 0)", absf(ai.position.y) <= 0.02, "y_min=%.4f" % ai.position.y)
	check("intakt: Breite ~0.8m (Budget <=0.9)", ai.size.x > 0.6 and ai.size.x <= 0.9, "w=%.3f" % ai.size.x)
	check("intakt: Hoehe ~0.7m (Budget <=0.75)", ai.size.y > 0.5 and ai.size.y <= 0.75, "h=%.3f" % ai.size.y)
	check("intakt: Tiefe ~0.7m (Budget <=0.75)", ai.size.z > 0.5 and ai.size.z <= 0.75, "d=%.3f" % ai.size.z)
	check("intakt: mittig um Ursprung (X/Z)", absf(ai.get_center().x) <= 0.06 and absf(ai.get_center().z) <= 0.06,
		"c=(%.3f,%.3f)" % [ai.get_center().x, ai.get_center().z])

	# --- 3) Limits: Meshes, Materialien, Dreiecke ---------------------------------
	var ms := _meshes(c)
	check("MeshInstance3D gesamt <= 20", ms.size() <= 20, "n=%d" % ms.size())
	var mats := {}
	for mi in ms:
		var mo = mi.material_override
		if mo != null:
			mats[mo.get_instance_id()] = true
	check("geteilte Materialien <= 4", mats.size() <= 4 and mats.size() >= 2, "n=%d" % mats.size())
	check("Dreiecke total <= 2500", _tri_count(c) <= 2500, "tris=%d" % _tri_count(c))

	# --- 4) Broken-Zustand: Fussabdruck + Maxhoehe --------------------------------
	c.set_broken(true)
	await process_frame
	var ab := _visible_world_aabb(c)
	check("broken: Maxhoehe <= 0.2m", ab.size.y <= 0.2 + 0.001, "h=%.3f" % ab.size.y)
	check("broken: Fussabdruck innerhalb intakter Grundflaeche",
		ab.position.x >= ai.position.x - 0.001 and ab.end.x <= ai.end.x + 0.001
		and ab.position.z >= ai.position.z - 0.001 and ab.end.z <= ai.end.z + 0.001,
		"broken x[%.2f,%.2f] z[%.2f,%.2f] vs intact x[%.2f,%.2f] z[%.2f,%.2f]" % [
			ab.position.x, ab.end.x, ab.position.z, ab.end.z,
			ai.position.x, ai.end.x, ai.position.z, ai.end.z])
	check("broken: is_broken==true", c.is_broken())
	c.set_broken(false)
	await process_frame
	var ai2 := _visible_world_aabb(c)
	check("restore: identische Bounding wie vorher",
		absf(ai2.position.y - ai.position.y) < 0.001 and absf(ai2.size.y - ai.size.y) < 0.001)

	# --- 5) Toggle-Akkumulation: 50x wechseln, Knoten Zahl konstant ---------------
	var n_before := c.get_child_count()
	var n_nodes_before := _all_nodes(c).size()
	for i in 50:
		c.set_broken(i % 2 == 0)
	# Ohne Frame dazwischen (schnellstes Toggle) und mit.
	check("Toggle ohne Frames: keine neuen Knoten", c.get_child_count() == n_before)
	await process_frame
	check("Toggle mit Frames: keine neuen Knoten (Total)",
		c.get_child_count() == n_before and _all_nodes(c).size() == n_nodes_before,
		"before=%d after=%d nodes_before=%d after=%d" % [n_before, c.get_child_count(), n_nodes_before, _all_nodes(c).size()])
	c.set_broken(false)

	# --- 6) Verbotene Nachfahren: Kollision, Licht, Timer, Audio ------------------
	var banned := 0
	var banned_names := ""
	for nd in _all_nodes(c):
		if nd is CollisionObject3D or nd is Light3D or nd is Timer or nd is AudioStreamPlayer:
			banned += 1
			banned_names += nd.get_class() + " "
	check("keine CollisionObject/Light3D/Timer/Audio-Nachfahren", banned == 0, banned_names)
	var sc: GDScript = c.get_script()
	var src_methods: Array[String] = []
	for m in sc.get_script_method_list():
		src_methods.append(m["name"])
	check("keine Per-Frame-Logik (_process/_physics_process nicht definiert)",
		not ("_process" in src_methods) and not ("_physics_process" in src_methods))

	# --- 7) Zweite Instanz teilt Ressourcen, Kollision der Zustände? ---------------
	var c2 := MODULE.new()
	root.add_child(c2)
	await process_frame
	check("2. Instanz unabhängig: eigene Defaults intakt", not c2.is_broken())
	c.set_broken(true)
	check("Zustand ist pro Instanz (c2 bleibt intakt)", (not c2.is_broken()) and c.is_broken())

	c.free()
	c2.free()
	print("H22 SUMMARY checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
