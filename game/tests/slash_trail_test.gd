extends SceneTree
## H47 — isolierter Smoke-Test fuer slash_trail.gd (Scratch-Baum, kein Spielcode).
## Aufruf: godot --headless --path <scratch> --script res://h47_trail_check.gd
## Nachweis: 'SUMMARY checks=N failures=0' und Exit-Code 0.

const Trail := preload("res://modules/vfx/slash_trail.gd")

var _checks := 0
var _failures := 0


func _ok(cond: bool, name: String, detail := "") -> void:
	_checks += 1
	if cond:
		print("PASS ", name)
	else:
		_failures += 1
		print("FAIL ", name, " ", detail)


func _init() -> void:
	await process_frame
	var parent := Node3D.new()
	parent.position = Vector3(5.0, 0.0, -2.0)   # transformierter Parent
	root.add_child(parent)
	var t: Node3D = Trail.new()
	parent.add_child(t)
	await process_frame

	# 1) Konstruktion: genau EIN Nachfahr (MeshInstance3D), kein Licht/Keine Kollision
	#    (count_all zaehlt Nachfahren des Moduls selbst, nicht das Modul)
	var kids := _count_all(t)
	_ok(kids == 1, "genau_1_Kind_Nachfahr", "kinder=%d" % kids)
	_ok(not _has_type(t, "Light3D"), "kein_Licht")
	_ok(not _has_type(t, "CollisionShape3D"), "keine_Kollision")
	_ok(not _has_type(t, "AudioStreamPlayer"), "kein_Audio")

	# 2) Vor erstem sample: unsichtbar
	_ok(not t.is_trailing(), "unsichtbar_vor_sample")

	# 3) Ein Sample reicht noch nicht fuer ein Segment
	t.sample(Vector3(5, 1, -2), Vector3(6, 1, -2), 0.016)
	_ok(t.point_count() == 1, "1_sample_history1")
	_ok(not t.is_trailing(), "1_sample_ohne_Segment_sichtbar")
	t.sample(Vector3(5.1, 1, -2), Vector3(6.1, 1, -2), 0.016)
	_ok(t.is_trailing(), "2_samples_Spur_sichtbar")

	# 4) Welt->lokal: Weltpunkt (6,1,-2) bei Parent (5,0,-2) muss lokal x=1,y=1,z=0 sein
	var arr := _first_surface_arrays(t)
	var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var has_local_tip := false
	for v in verts:
		if is_equal_approx(v.x, 1.0) and is_equal_approx(v.y, 1.0) and is_equal_approx(v.z, 0.0):
			has_local_tip = true
	_ok(has_local_tip, "weltpunkt_lokal_umgerechnet", "verts=%s" % str(verts))

	# Regression: old world points must not drift when the parent moves/rotates.
	parent.position += Vector3(2, 0, 1)
	parent.rotation.y = 0.5
	t.sample(Vector3(5.2, 1, -2), Vector3(6.2, 1, -2), 0.016)
	var anchored := false
	for vertex: Vector3 in _first_surface_arrays(t)[Mesh.ARRAY_VERTEX]:
		if (t.global_transform * vertex).distance_to(Vector3(6, 1, -2)) < 0.001:
			anchored = true
	_ok(anchored, "history_stays_world_anchored_after_parent_motion")

	# 5) Budget: 40 schnelle Samples -> History hoechstens 8, Surface bleibt 1
	for i in range(40):
		t.sample(Vector3(5.0 + 0.02 * i, 1.0, -2.0), Vector3(6.0 + 0.02 * i, 1.0, -2.0), 0.01)
	_ok(t.point_count() <= 8, "history_max8", "n=%d" % t.point_count())
	var m: ImmediateMesh = _mesh_of(t)
	_ok(m.get_surface_count() == 1, "genau_1_surface")
	var arr2 := _first_surface_arrays(t)
	var verts2: PackedVector3Array = arr2[Mesh.ARRAY_VERTEX]
	# Segmente <= 7 => max 7*6 = 42 Eckpunkte (2 Dreiecke a 3 pro Segment)
	_ok(verts2.size() <= 42, "max_7_Segmente", "verts=%d" % verts2.size())

	# 6) Keine Node-Erzeugung pro sample: Nachfahrenzahl vor/nach 100 weiteren Samples
	var before := _count_all(t)
	for i in range(100):
		t.sample(Vector3(4.0, 1.0 + 0.001 * i, -2.0), Vector3(5.0, 1.0 + 0.001 * i, -2.0), 0.008)
	var after := _count_all(t)
	_ok(before == after, "kein_Node_Wachstum", "%d vs %d" % [before, after])

	# 7) Alpha-Monotonie: jung (neu) heller als alt innerhalb eines Aufbaus
	t.clear()
	for i in range(6):
		t.sample(Vector3(5.0 + 0.01 * i, 1.0, -2.0), Vector3(6.0 + 0.01 * i, 1.0, -2.0), 0.005)
	var cols: PackedColorArray = _first_surface_arrays(t)[Mesh.ARRAY_COLOR]
	var a_newest := -1.0
	var a_oldest := 2.0
	for c in cols:
		a_newest = maxf(a_newest, c.a)
		a_oldest = minf(a_oldest, c.a)
	_ok(a_oldest < a_newest, "alpha_alte_Samples_swaecher", "alt=%0.3f neu=%0.3f" % [a_oldest, a_newest])
	_ok(a_newest <= 0.55 + 1e-3 and a_newest > 0.2, "alpha_Pegel_dezent", "neu=%0.3f" % a_newest)

	# 8) Verfall: nach genug weiter Zeit ohne neuen Punkt faellt die Historie
	t.clear()
	t.sample(Vector3(5, 1, -2), Vector3(6, 1, -2), 0.016)
	t.sample(Vector3(5.1, 1, -2), Vector3(6.1, 1, -2), 0.10)  # 100 ms > 60 ms Fenster
	_ok(t.point_count() == 1, "verfall_ueber_Fenster", "n=%d" % t.point_count())

	# 9) clear(): sofort unsichtbar, History leer, keine Surface
	t.clear()
	_ok(not t.is_trailing(), "clear_unsichtbar")
	_ok(t.point_count() == 0, "clear_history_leer")
	_ok(m.get_surface_count() == 0, "clear_ohne_Surface")

	# 10) Material: transparent, unshaded, Schatten aus, kupferweiss getoont
	var mi := t.get_child(0) as MeshInstance3D
	var mat: StandardMaterial3D = mi.material_override
	_ok(mat.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA, "material_transparent")
	_ok(mat.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED, "material_unshaded")
	_ok(mi.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "schatten_aus")
	var r := cols[0]
	_ok(r.r > r.b and r.g > r.b and r.r > 0.6, "kupferweisser_Ton", str(r))

	print("SUMMARY checks=", _checks, " failures=", _failures)
	parent.free()
	quit(1 if _failures > 0 else 0)


func _count_all(n: Node) -> int:
	var c := 0
	for ch: Node in n.get_children():
		c += 1 + _count_all(ch)
	return c


func _has_type(n: Node, type_name: String) -> bool:
	for ch: Node in n.get_children():
		if ch.is_class(type_name):
			return true
		if _has_type(ch, type_name):
			return true
	return false


func _mesh_of(t: Node) -> ImmediateMesh:
	var mi := t.get_child(0) as MeshInstance3D
	return mi.mesh as ImmediateMesh


func _first_surface_arrays(t: Node) -> Array:
	var m := _mesh_of(t)
	if m.get_surface_count() == 0:
		return []
	return m.surface_get_arrays(0)
