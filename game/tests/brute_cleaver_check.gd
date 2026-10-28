extends SceneTree
## H28 — Knappe Geometrie-Validierung fuer brute_cleaver_visual.gd.
## Prueft Budgets (Meshes<=16, Materialien<=4, Dreiecke<=600), Root identity,
## Authoring-Achsen (Spitze +Y ~0.95, Grip-Ende ~-0.10), Breite X / Tiefe Z
## innerhalb der Vertragsbander, CULL_BACK + opake Standardmaterialien ohne
## Emission, Aussen-Normalen/Windung des ArrayMesh, Duplizierbarkeit des
## Zweigs (Rigid-Weapon-Weg von enemy._drop_weapon) und Abwesenheit von
## Kollision/Licht/Audio/Timer-Kindern.
## Aufruf: godot --headless --path game --script res://tests/brute_cleaver_check.gd

var _fail := 0
var _checks := 0

func _check(label: String, ok: bool, detail := "") -> void:
	_checks += 1
	if not ok:
		_fail += 1
	print("H28 %s %s %s" % ["PASS" if ok else "FAIL", label, detail])

func _initialize() -> void:
	await process_frame
	var mod: Node3D = load("res://modules/visuals/brute_cleaver_visual.gd").new()
	# Root identity vor Baum-Eintritt (Reuse/Persistenz-Pflicht aus H22-Muster)
	_check("root_identity", mod.transform == Transform3D(), str(mod.transform.origin))
	# Aufbau erfolgt in _ready beim ersten Baumeintritt (Duplizierbarkeits-
	# Guard, siehe Modul); fuer die Pruefungen haengen wir an den root.
	root.add_child(mod)
	await process_frame
	await process_frame
	var meshes: Array[MeshInstance3D] = []
	var mats: Dictionary = {}
	var tris := 0
	for c in mod.get_children():
		if c is MeshInstance3D:
			meshes.append(c)
			var mi := c as MeshInstance3D
			if mi.material_override != null:
				mats[mi.material_override.get_instance_id()] = mi.material_override
			var m := mi.mesh
			if m is BoxMesh:
				tris += 12
			elif m is ArrayMesh:
				for s in m.get_surface_count():
					tris += m.surface_get_array_len(s) / 3
	_check("budget_meshes<=16", meshes.size() <= 16, "meshes=%d" % meshes.size())
	_check("budget_materials<=4", mats.size() <= 4, "materials=%d" % mats.size())
	_check("budget_triangles<=600", tris <= 600, "triangles=%d" % tris)
	# Materialien: opak, CULL_BACK, keine Emission (kein Hero-Cyan)
	var ok_mat := true
	for id in mats:
		var sm := mats[id] as StandardMaterial3D
		if sm == null or sm.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED \
				or sm.cull_mode != BaseMaterial3D.CULL_BACK or sm.emission_enabled:
			ok_mat = false
	_check("materialien_opak_cullback_ohne_emission", ok_mat, "n=%d" % mats.size())

	# Welt-AABB an der Szene (Root identity): L/Y, Breite/X, Tiefe/Z
	var aabb := _union_aabb(mod)
	var size := aabb.size
	print("H28 METRO aabb_pos=%s size=%s" % [str(aabb.position), str(size)])
	_check("laenge_y_0.95..1.10", size.y >= 0.95 and size.y <= 1.10, "%.3f" % size.y)
	_check("breite_x_0.22..0.28", size.x >= 0.22 and size.x <= 0.28, "%.3f" % size.x)
	_check("tiefe_z_0.035..0.07", size.z >= 0.035 and size.z <= 0.07, "%.3f" % size.z)
	_check("griffende_y~-0.10", absf(aabb.position.y + 0.100) <= 0.01, "%.3f" % aabb.position.y)
	_check("spitze_y~0.95", absf(aabb.end.y - 0.950) <= 0.01, "%.3f" % aabb.end.y)
	# Blatt in Z ±0.020 -> breite Seite in XY, +Z-Kamera sieht Blattflaeche
	_check("blatt_tiefe_und_kameraseite", size.z < size.x and size.z < size.y,
		"z=%.3f x=%.3f y=%.3f" % [size.z, size.x, size.y])

	# ArrayMesh-Windung/Normale: jedes Dreieck muss von aussen CLOCKWISE sein
	# (RIGHT-Hand-Normale zeigt gegen Centroid-Richtung des Volumens) und die
	# gescriebene Normalenrichtung mit der FRONT-Richtung uebereinstimmen.
	var blade: MeshInstance3D = mod.find_child("Blade", true, false) as MeshInstance3D
	var am := blade.mesh as ArrayMesh
	var verts: PackedVector3Array = am.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var norms: PackedVector3Array = am.surface_get_arrays(0)[Mesh.ARRAY_NORMAL]
	var vol_c := Vector3.ZERO
	for v in verts:
		vol_c += v
	vol_c /= float(verts.size())
	var bad := 0
	for i in range(0, verts.size(), 3):
		var p0 := verts[i]
		var p1 := verts[i + 1]
		var p2 := verts[i + 2]
		var rh := (p1 - p0).cross(p2 - p0)         # RIGHT-Hand
		var front := -rh                           # Godot CLOCKWISE-Front
		var c := (p0 + p1 + p2) / 3.0
		if front.dot(c - vol_c) <= 0.0:
			bad += 1                                # Front zeigt nicht nach aussen
		elif rh.dot(norms[i]) > 0.0:
			bad += 1                                # Normal zeigt entgegen der Front
	_check("winding_und_normalen_aussen", bad == 0, "bad=%d/%d" % [bad, verts.size() / 3])

	# Keine verbotenen Kinder: Kollision/Licht/Audio/Timer/Animation
	var forbidden := 0
	for c in mod.get_children(true):
		if c is CollisionObject3D or c is CollisionShape3D or c is Light3D \
				or c is AudioStreamPlayer or c is Timer or c is AnimationPlayer:
			forbidden += 1
	_check("keine_kollision_licht_audio_timer", forbidden == 0, "n=%d" % forbidden)

	# Duplizierbarkeit (enemy._drop_weapon: _weapon_pivot.duplicate() als Rigid-Kind)
	var dup: Node3D = mod.duplicate() as Node3D
	var dup_meshes := 0
	for c in dup.get_children():
		if c is MeshInstance3D:
			dup_meshes += 1
	_check("duplizierbar_kinder_kommen_mit", dup != null and dup_meshes == meshes.size(),
		"dup=%d orig=%d" % [dup_meshes, meshes.size()])
	root.add_child(dup)   # Drop-Simulation: Kopie an RigidBody haengen -> _ready der Kopie
	await process_frame
	await process_frame
	var dup_after := 0
	for c in dup.get_children():
		if c is MeshInstance3D:
			dup_after += 1
	_check("dup_nach_anhaegen_keine_doppelgeometrie", dup_after == dup_meshes,
		"after=%d dup=%d" % [dup_after, dup_meshes])

	print("H28 SUMMARY checks=%d failures=%d" % [_checks, _fail])
	quit(1 if _fail else 0)

func _union_aabb(n: Node) -> AABB:
	var res := AABB()
	var first := true
	for c in n.get_children(true):
		if c is MeshInstance3D:
			var mi := c as MeshInstance3D
			var a := mi.global_transform * mi.get_aabb()
			res = a if first else res.merge(a)
			first = false
	return res
