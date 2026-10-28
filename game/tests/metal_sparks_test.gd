extends SceneTree
## H24 — Tests fuer metal_sparks.gd (standalone, headless).
## Prueft: API-Aufrufe, Burst-Kapazitaet ohne Knoten-Haeufung, Parry-Variante
## (Farbmaterial + Amount), Parameter des Vertrags (Cone/Velocity/Gravity/
## Lifetime/Mesh/Unshaded/Ramp-Alpha), Richtungsnormierung + Zero-Fallback,
## Weltposition/Identity-Basis, Timer-Cleanup <= 0.5s inkl. Timer-Knoten,
## clear()/Reuse sicher, stale Timer ungefaehrlich, keine Per-Frame-Logik.
## Aufruf: godot --headless --path <scratch> --script res://tests/metal_sparks_test.gd

const MODULE := preload("res://modules/vfx/metal_sparks.gd")

var failures := 0
var checks := 0

func check(label: String, ok: bool, detail := "") -> void:
	checks += 1
	if not ok:
		failures += 1
	print("H24 %s %s %s" % ["PASS" if ok else "FAIL", label, detail])

func _particles(root: Node) -> Array[CPUParticles3D]:
	var out: Array[CPUParticles3D] = []
	for c in root.get_children():
		if c is CPUParticles3D:
			out.append(c)
	return out

func _timers(root: Node) -> Array[Timer]:
	var out: Array[Timer] = []
	for c in root.get_children():
		if c is Timer:
			out.append(c)
	return out

func _descendant_count(root: Node) -> int:
	var n := 0
	for c in root.get_children():
		n += 1 + _descendant_count(c)
	return n

func _initialize() -> void:
	_run()

func _run() -> void:
	await process_frame
	var fx := MODULE.new()
	root.add_child(fx)
	await process_frame

	# --- 1) Basis-API -----------------------------------------------------------
	check("aktiv Start: active_count()==0", fx.active_count() == 0)
	fx.emit_contact(Vector3(1.0, 0.5, -2.0), Vector3(0.0, 0.0, 1.0))
	await process_frame
	check("emit_contact -> active_count()==1", fx.active_count() == 1, "n=%d" % fx.active_count())
	var ps := _particles(fx)
	check("genau 1 CPUParticles3D nach einem Emit", ps.size() == 1)

	if ps.size() == 1:
		var p := ps[0]
		# --- 2) Weltposition / Identity / Richtung -------------------------------
		check("Weltposition exakt uebernommen", p.transform.origin == Vector3(1.0, 0.5, -2.0))
		var id_ok := p.transform.basis == Basis.IDENTITY
		check("Globale Basis IDENTITY", id_ok)
		check("top_level aktiv (unabhaengig vom Parent)", p.top_level)
		check("Richtung normalisiert", is_equal_approx(p.direction.length(), 1.0))
		check("local_coords false (Welt-Emission)", not p.local_coords)
		# --- 3) Vertragsparameter --------------------------------------------------
		check("Cone 35 deg", is_equal_approx(p.spread, 35.0), "spread=%.1f" % p.spread)
		check("Velocity 2..5", is_equal_approx(p.initial_velocity_min, 2.0) and is_equal_approx(p.initial_velocity_max, 5.0))
		check("Gravity (0,-12,0)", p.gravity == Vector3(0, -12, 0))
		check("Lifetime 0.12..0.25", p.lifetime >= 0.249 and p.lifetime <= 0.251, "lt=%.2f" % p.lifetime)
		check("Amount normal 10", p.amount == 10, "amount=%d" % p.amount)
		check("one_shot + emitting", p.one_shot and p.emitting)
		# --- 4) Mesh + Material ------------------------------------------------------
		var m: Mesh = p.mesh
		check("schmales BoxMesh 0.012/0.04/0.012", m is BoxMesh
			and (m as BoxMesh).size == Vector3(0.012, 0.04, 0.012))
		var mo: StandardMaterial3D = p.material_override
		check("unshaded emissives Material", mo != null
			and mo.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED
			and mo.emission_enabled)
		check("Alpha-Fade-Material (TRANSPARENCY_ALPHA + vertex_color)",
			mo != null and mo.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA
			and mo.vertex_color_use_as_albedo)
		var ramp: Gradient = p.color_ramp
		check("color_ramp: 2 Stopps, Alpha 1->0 (Fade statt opaker Punkt)",
			ramp != null and ramp.colors.size() == 2
			and is_equal_approx(ramp.colors[0].a, 1.0) and is_equal_approx(ramp.colors[1].a, 0.0))

	# --- 5) Parry-Variante ---------------------------------------------------------
	fx.emit_contact(Vector3(2.0, 0.5, 0.0), Vector3(0, 1, 0), true)
	await process_frame
	var all := _particles(fx)
	check("nach 2. Emit (parry): 2 Bursts", all.size() == 2 and fx.active_count() == 2)
	var parry_p: CPUParticles3D = null
	var norm_p: CPUParticles3D = null
	for p in all:
		if p.amount == 18:
			parry_p = p
		elif p.amount == 10:
			norm_p = p
	check("parry: Amount 18 (groesserer Burst), normal bleibt 10",
		parry_p != null and norm_p != null)
	if parry_p != null and norm_p != null:
		check("parry nutzt anderes (Zyan-)Material als normal",
			parry_p.material_override != norm_p.material_override)
		var cr: Gradient = parry_p.color_ramp
		check("parry-Ramp kuehler (Blaugruen-Anteil > Warm-Ramp)",
			cr.colors[0].b > norm_p.color_ramp.colors[0].b
			and cr.colors[0].r < norm_p.color_ramp.colors[0].r)

	# --- 6) Materialien gecached/geteilt --------------------------------------------
	fx.emit_contact(Vector3(3.0, 0.5, 0.0), Vector3(1, 0, 0))
	await process_frame
	var three := _particles(fx)
	var warm_mats := {}
	for p in three:
		if p.amount == 10:
			warm_mats[p.material_override.get_instance_id()] = true
	check("warm-Material gecacht (1 Instanz ueber alle Normalbursts)",
		warm_mats.size() == 1)
	var mesh_ids := {}
	for p in three:
		mesh_ids[p.mesh.get_instance_id()] = true
	check("Funken-Mesh geteilt (1 Instanz)", mesh_ids.size() == 1)

	# --- 7) Kapazitaet max 6 Bursts, kein Knoten-Wachstum -----------------------------
	for i in 10:
		fx.emit_contact(Vector3(float(i), 0.5, 0.0), Vector3(0, 1, 0))
	await process_frame
	check("active_count gedeckelt auf 6", fx.active_count() == 6, "n=%d" % fx.active_count())
	check("Partikelknoten gedeckelt (<=6 sichtbar)", _particles(fx).size() <= 6,
		"nodes=%d" % _particles(fx).size())

	# --- 8) Zero-Richtung -> Fallback UP ------------------------------------------
	fx.clear()
	await process_frame
	fx.emit_contact(Vector3(0, 1, 0), Vector3.ZERO)
	await process_frame
	var z := _particles(fx)
	check("Zero-Richtung -> Fallback (0,1,0)", z.size() == 1 and z[0].direction == Vector3.UP)

	# --- 9) clear(): sofort 0 + fullstaendiges Cleanup <= 0.5s -----------------------
	fx.clear()
	check("clear() -> active_count()==0 sofort", fx.active_count() == 0)
	# Warte 0.5s reale Zeit; alle Partikel- UND Timer-Knoten muessen weg sein.
	var t0 := Time.get_ticks_msec()
	var gone := false
	while Time.get_ticks_msec() - t0 < 700:
		await process_frame
		if _particles(fx).size() == 0 and _timers(fx).size() == 0 and _descendant_count(fx) == 0:
			gone = true
			break
	var waited := Time.get_ticks_msec() - t0
	check("nach clear(): alle Knoten (Partikel+Timer) <= 700ms weg", gone, "waited=%dms" % waited)

	# --- 10) natuerlicher Timer-Cleanup + stale Timer ungefaehrlich -------------------
	fx.emit_contact(Vector3(5, 0.5, 0), Vector3(1, 0, 0))
	await process_frame
	check("Emit nach Cleanup wieder aktiv", fx.active_count() == 1)
	# Warten bis der eigene Timer aufraeumt (Cleanup-Delay + Frame-Puffer).
	var t1 := Time.get_ticks_msec()
	var auto := false
	while Time.get_ticks_msec() - t1 < 700:
		await process_frame
		if fx.active_count() == 0 and _particles(fx).size() == 0 and _timers(fx).size() == 0:
			auto = true
			break
	check("Timer-Cleanup ohne clear(): active 0, keine Restknoten <= 700ms", auto,
		"waited=%dms" % (Time.get_ticks_msec() - t1))
	# Stale-Timer-Szenario: emit, sofort clear, sofort neu emitieren — der alte
	# Timer darf den NEUEN Burst nicht loeschen.
	fx.emit_contact(Vector3(6, 0.5, 0), Vector3(1, 0, 0))
	await process_frame
	fx.clear()
	fx.emit_contact(Vector3(7, 0.5, 0), Vector3(1, 0, 0))
	await process_frame
	check("nach clear()+sofort neu: 1 aktiv", fx.active_count() == 1)
	# Innerhalb des Alt-Fensters (0.2s) muss der neue Burst bleiben.
	var wait := 0.0
	while wait < 0.2:
		await physics_frame
		wait += 1.0 / Engine.physics_ticks_per_second
	check("stale Timer des alten Bursts loescht den neuen nicht", fx.active_count() == 1)

	# --- 11) keine Per-Frame-Logik ---------------------------------------------------
	var sc: GDScript = fx.get_script()
	var names: Array[String] = []
	for mth in sc.get_script_method_list():
		names.append(mth["name"])
	check("keine _process/_physics_process",
		not ("_process" in names) and not ("_physics_process" in names))
	check("kein globaler class_name 'MetalSparks'", not ClassDB.class_exists(&"MetalSparks"))

	fx.clear()
	await process_frame
	fx.free()
	print("H24 SUMMARY checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
