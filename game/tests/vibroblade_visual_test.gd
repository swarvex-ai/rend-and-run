extends SceneTree
## H23 — Tests fuer vibroblade_visual.gd (standalone, headless).
## Prueft: nichtleere gueltige Geometrie, Material-/Mesh-Budgets, endliche
## Transforms, Konvention/Bemaessung (Grip-Pivot Ursprung, Spitze +Y,
## Reichweite ~ hero_sword 1.015 * 1.15), Windung (Godot-Front = CLOCKWISE von
## aussen bei aussen-weisender Normale), CULL_BACK an allen Materialien, keine
## verbotenen Nachfahren / Per-Frame-Code, geteilte Ressourcen zwischen
## Instanzen.
## Aufruf: godot --headless --path <scratch> --script res://tests/vibroblade_visual_test.gd

const MODULE := preload("res://modules/visuals/vibroblade_visual.gd")

var failures := 0
var checks := 0

func check(label: String, ok: bool, detail := "") -> void:
	checks += 1
	if not ok:
		failures += 1
	print("H23 %s %s %s" % ["PASS" if ok else "FAIL", label, detail])

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

func _world_aabb(root: Node) -> AABB:
	var merged := AABB()
	var first := true
	for mi in _meshes(root):
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
			total += 12   # Primitive ohne Mesh-Surfaces
			continue
		for s in m.get_surface_count():
			total += int(m.surface_get_array_len(s)) / 3
	return total

func _initialize() -> void:
	_run()

func _run() -> void:
	await process_frame

	var w := MODULE.new()
	root.add_child(w)
	await process_frame

	# --- 1) Gueltige, nichtleere Geometrie ----------------------------------------
	var ms := _meshes(w)
	check("MeshInstance3D vorhanden (<=16)", ms.size() > 0 and ms.size() <= 16, "n=%d" % ms.size())
	var nonempty := 0
	for mi in ms:
		if mi.mesh != null:
			nonempty += 1
	check("alle MeshInstance3D mit Mesh gefüllt", nonempty == ms.size(), "%d/%d" % [nonempty, ms.size()])

	# --- 2) Budgets -----------------------------------------------------------------
	var mats := {}
	for mi in ms:
		var mo = mi.material_override
		if mo != null:
			mats[mo.get_instance_id()] = mo
	check("geteilte Materialien <= 4 (>=2)", mats.size() >= 2 and mats.size() <= 4, "n=%d" % mats.size())
	check("Dreiecke total <= 3000", _tri_count(w) <= 3000 and _tri_count(w) > 0, "tris=%d" % _tri_count(w))
	var all_cull_back := true
	for id in mats:
		if (mats[id] as StandardMaterial3D).cull_mode != BaseMaterial3D.CULL_BACK:
			all_cull_back = false
	check("alle Materialien CULL_BACK (kein CULL_DISABLED)", all_cull_back)

	# --- 3) Endliche Transforms -------------------------------------------------------
	var finite := true
	for mi in ms:
		var org := mi.transform.origin
		var basis := mi.transform.basis
		for axis in 3:
			var col: Vector3 = basis[axis]
			if not (is_finite(col.x) and is_finite(col.y) and is_finite(col.z)):
				finite = false
			if not is_finite(org[axis]):
				finite = false
		if not is_finite(mi.global_position.x):
			finite = false
	check("alle Transforms endlich", finite)

	# --- 4) Konvention/Bemaessung (gemessen an hero_sword.glb, read-only) ----------
	# hero_sword: Grip-Pivot (Root/Hand) = Ursprung, Spitze +Y bei y=1.015.
	# Ziel: gleicher Pivot/Orientierung, Reichweite ~1.015*1.15 = 1.167.
	var a := _world_aabb(w)
	check("Spitze +Y ~1.167 (hero*1.15)", absf(a.end.y - 1.167) <= 0.02, "y_max=%.3f" % a.end.y)
	check("Grip haengt unter dem Pivot (y_min ~ -0.19, Griff beginnt ueberhalb)",
		a.position.y >= -0.21 and a.position.y <= -0.13, "y_min=%.3f" % a.position.y)
	check("Griff nahe am Pivot (kein schwebender Griff: Material unter y=0 reicht bis -0.13..)",
		a.position.y <= -0.09, "y_min=%.3f" % a.position.y)
	# Blattbreite deutlich ueber hero_sword (0.076); Guard ist separat geprueft.
	var blade := w.get_node_or_null("Blade")
	var blade_aabb: AABB = blade.global_transform * blade.get_aabb()
	check("Blattbreite (>0.10) uebertrifft hero_sword-Blatt 0.076", blade_aabb.size.x > 0.10, "blade_x=%.3f" % blade_aabb.size.x)
	check("Blatt duenn in Z (Schliff-Geometrie <=0.06)", blade_aabb.size.z <= 0.06, "blade_z=%.3f" % blade_aabb.size.z)
	# Fugenschluss ohne Lücken: Blatt ueberdeckt den Collar, Collar ueberdeckt
	# die Guard-Oberkante (Klemmhals ist das Fuellstuick, nicht der Guard).
	var collar := w.get_node("Collar")
	var collar_aabb: AABB = collar.global_transform * collar.get_aabb()
	check("Blatt ueberlappt Collar (kein Spalt Klinge->Hals)",
		blade_aabb.position.y <= collar_aabb.end.y, "blade_y_min=%.3f collar_y_max=%.3f" % [blade_aabb.position.y, collar_aabb.end.y])
	check("Collar ueberlappt Guard (kein Spalt Hals->Parier)",
		collar_aabb.position.y <= 0.070 + 0.001, "collar_y_min=%.3f" % collar_aabb.position.y)

	# --- 5) Windung am ArrayMesh: CLOCKWISE-Front bei aussen-weisender Normale -----
	var surf_dicts: Array = blade.mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = surf_dicts[Mesh.ARRAY_VERTEX]
	var norms: PackedVector3Array = surf_dicts[Mesh.ARRAY_NORMAL]
	var bad_handed := 0
	var bad_len := 0
	for t in verts.size() / 3:
		var p0 := verts[t * 3]
		var p1 := verts[t * 3 + 1]
		var p2 := verts[t * 3 + 2]
		var nh := (p1 - p0).cross(p2 - p0)
		var nn := norms[t * 3]
		if nh.length_squared() < 1e-14:
			continue
		if nn.length() < 0.9 or nn.length() > 1.1:
			bad_len += 1
		# Godot-Front = RIGHT-Hand-Normale der Emitierreihenfolge zeigt in
		# -Z-Blickrichtung / hier: RIGHT-Hand-Normale muss GEGEN die
		# geschriebene Aussen-Normale zeigen (dann ist die Reihenfolge von
		# aussen im Uhrzeigersinn = Godot-Frontseite).
		if nh.normalized().dot(nn) > 0.0:
			bad_handed += 1
	check("alle Dreiecke: CLOCKWISE-Front bei aussen-weisender Normale",
		bad_handed == 0, "wrong_handed=%d von %d" % [bad_handed, verts.size() / 3])
	check("alle Normaleinheiten gueltig (Laenge ~1)", bad_len == 0, "bad=%d" % bad_len)
	# Manteldreiecke = alle, deren Ecken NICHT kapplanar liegen (bei den
	# Kappen sind alle drei z gleich; Maantel haben genau zwei gleiche z —
	# nach dem Windungs-Swap darf nicht die Emissionsreihenfolge filtern).
	var outside_ok := true
	var outside_checked := 0
	for t in verts.size() / 3:
		var p0 := verts[t * 3]
		var p1 := verts[t * 3 + 1]
		var p2 := verts[t * 3 + 2]
		if is_equal_approx(p0.z, p1.z) and is_equal_approx(p1.z, p2.z):
			continue   # kapplanar
		var ctr := (p0 + p1 + p2) / 3.0
		var nn := norms[t * 3]
		if nn.dot(ctr - Vector3(-0.005, 0.45, 0.0)) < -0.05:
			outside_ok = false
		outside_checked += 1
	check("Mantelnormalen nach aussen (Heuristik, exakte Referenz)",
		outside_ok and outside_checked >= 10, "mantel=%d" % outside_checked)

	# --- 6) Keine verbotenen Nachfahren / Per-Frame-Logik ---------------------------
	var banned := 0
	var banned_names := ""
	for nd in _all_nodes(w):
		if nd is CollisionObject3D or nd is Light3D or nd is Timer or nd is AudioStreamPlayer:
			banned += 1
			banned_names += nd.get_class() + " "
	check("keine CollisionObject/Light3D/Timer/Audio-Nachfahren", banned == 0, banned_names)
	var sc: GDScript = w.get_script()
	var names: Array[String] = []
	for m in sc.get_script_method_list():
		names.append(m["name"])
	check("keine Per-Frame-Logik (_process/_physics_process)",
		not ("_process" in names) and not ("_physics_process" in names))

	# --- 7) Geteilte Ressourcen + keine class_name ---------------------------------
	var w2 := MODULE.new()
	root.add_child(w2)
	await process_frame
	var m1 := (w.get_node("Blade") as MeshInstance3D).mesh
	var m2 := (w2.get_node("Blade") as MeshInstance3D).mesh
	check("ArrayMesh wird zwischen Instanzen geteilt", m1 == m2)
	# class_name-Abwesenheit: der Name darf global nicht existieren.
	check("kein globaler class_name 'VibrobladeVisual'", not ClassDB.class_exists(&"VibrobladeVisual"))

	# --- 8) Bericht: gemessene Quelle + eigene Bemaessung -----------------------------
	print("H23 MEASURED hero_sword.glb: root=hero_sword(identity@hand) hilt_y[-0.144,0.134] blade_y[0.130,1.015] tip=+Y width_x=0.076 reach=1.015")
	print("H23 MEASURED vibroblade: y[%.3f,%.3f] x[%.3f,%.3f] z[%.3f,%.3f] reach=%.3f tris=%d meshes=%d mats=%d" % [
		a.position.y, a.end.y, a.position.x, a.end.x, a.position.z, a.end.z,
		a.end.y, _tri_count(w), ms.size(), mats.size()])

	w.free()
	w2.free()
	print("H23 SUMMARY checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
