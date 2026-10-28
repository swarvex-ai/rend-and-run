extends SceneTree
# H19 — Headless-Test fuer landing_dust.gd (beidseitiger Landestaub).
# Aufruf: godot --headless --path <isolierter-scratch> --script res://tests/landing_dust_test.gd
# Prueft Schwellen/Parameter/Cleanup ehrlich; visuelle Abnahme ist headless nicht moeglich.
# Exit 0 = alle Checks PASS.

const DUST_SCRIPT := preload("res://modules/vfx/landing_dust.gd")

var checks := 0
var failures := 0

func check(label: String, ok: bool) -> void:
	checks += 1
	if not ok:
		failures += 1
	print("H19 %s %s" % ["PASS" if ok else "FAIL", label])

func wait_sec(seconds: float) -> void:
	await create_timer(seconds, true).timeout

func fresh_dust(parent: Node = null) -> Node3D:
	var d: Node3D = DUST_SCRIPT.new()
	(parent if parent != null else root).add_child(d)
	return d

func fans_of(d: Node3D) -> Array[CPUParticles3D]:
	var out: Array[CPUParticles3D] = []
	for c in d.get_children():
		if c is CPUParticles3D and is_instance_valid(c):
			out.append(c)
	return out

func _initialize() -> void:
	# SceneTree-Skriptmodus: erst ein Frame, dann sind Knoten im Baum.
	await process_frame

	# --- 1) Schwelle + ein Landing: zwei Facher, beidseitig -----------------------
	var d := fresh_dust()
	check("Start: 0 aktive Landungen", d.active_count() == 0)
	d.emit_landing(Vector3.ZERO, 3.9)
	check("|speed| 3.9 < 4: kein Staub, keine Knoten (auch kein Timer)",
		d.active_count() == 0 and d.get_child_count() == 0)
	d.emit_landing(Vector3(1.0, 0.0, -2.0), -4.0)  # exakt Schwelle: 4.0 ist NICHT < 4
	check("|speed| exakt 4: emitziert (untere Grenze klemmt richtig herum)",
		d.active_count() == 1)
	var f := fans_of(d)
	check("genau ZWEI Facher pro Landung", f.size() == 2)
	if f.size() == 2:
		check("Faecher gegenlaeufig und flach: direction (-1,.2,0) und (1,.2,0) normiert",
			f[0].direction.is_equal_approx(Vector3(-1, 0.2, 0).normalized())
			and f[1].direction.is_equal_approx(Vector3(1, 0.2, 0).normalized())
			and f[0].direction.x * f[1].direction.x < 0.0)
		check("beide one_shot, explosiveness 1, emitting, local_coords aus",
			f[0].one_shot and f[1].one_shot
			and is_equal_approx(f[0].explosiveness, 1.0)
			and f[0].is_emitting() and f[1].is_emitting()
			and not f[0].local_coords and not f[1].local_coords)
		check("EXPLIZITE winzige Low-Poly-SphereMesh r=0.015",
			f[0].mesh is SphereMesh and absf((f[0].mesh as SphereMesh).radius - 0.015) < 0.001
			and (f[0].mesh as SphereMesh).radial_segments <= 6)
		check("mattgraues Material, Schatten aus",
			f[0].material_override is StandardMaterial3D
			and absf((f[0].material_override as StandardMaterial3D).roughness - 1.0) < 0.001
			and f[0].cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
		check("Fade ramp vorhanden (Alpha endet 0 — kein opaker Dauerqualm)",
			f[0].color_ramp is Gradient
			and f[0].color_ramp.colors[0].a > 0.9
			and f[0].color_ramp.colors[f[0].color_ramp.colors.size() - 1].a == 0.0)
		check("spread 15°, gravity (0,-6,0), Emissionsform Punkt",
			absf(f[0].spread - 15.0) < 0.001
			and f[0].gravity == Vector3(0.0, -6.0, 0.0)
			and f[0].emission_shape == CPUParticles3D.EMISSION_SHAPE_POINT)
		check("Zufallsscale 0.4..1",
			is_equal_approx(f[0].scale_amount_min, 0.4)
			and is_equal_approx(f[0].scale_amount_max, 1.0))
		check("lifetime beider Faecher in 0.2..0.35s",
			f[0].lifetime >= 0.2 - 0.0001 and f[0].lifetime <= 0.35 + 0.0001
			and f[1].lifetime >= 0.2 - 0.0001 and f[1].lifetime <= 0.35 + 0.0001)
		check("beide Faecher an derselben Weltposition (1,0,-2)",
			f[0].global_position.is_equal_approx(Vector3(1.0, 0.0, -2.0))
			and f[1].global_position.is_equal_approx(Vector3(1.0, 0.0, -2.0)))

	# --- 2) strength-Formel: velocity 1..2.5 * (0.5+s), amount 6..10, s=clamp ------
	# speed 4  -> s=0 : velocity 0.5..1.25 , amount 6
	# speed 14 -> s=1 : velocity 1.5..3.75 , amount 10
	# speed 30 -> s=1 (clamp) identisch zu 14
	d.clear()
	await process_frame
	d.emit_landing(Vector3.ZERO, 4.0)
	var lo := fans_of(d)
	d.emit_landing(Vector3(0.1, 0.0, 0.0), 14.0)
	var mid := fans_of(d)
	mid = [mid[2], mid[3]]
	d.emit_landing(Vector3(0.2, 0.0, 0.0), 300.0)
	var hi := fans_of(d)
	hi = [hi[4], hi[5]]
	check("s=0 (speed 4): velocity 0.5..1.25, amount 6",
		lo.size() == 2 and is_equal_approx(lo[0].initial_velocity_min, 0.5)
		and is_equal_approx(lo[0].initial_velocity_max, 1.25)
		and lo[0].amount == 6)
	check("s=1 (speed 14): velocity 1.5..3.75, amount 10",
		mid.size() == 2 and is_equal_approx(mid[0].initial_velocity_min, 1.5)
		and is_equal_approx(mid[0].initial_velocity_max, 3.75)
		and mid[0].amount == 10)
	check("s clamp: speed 300 == speed 14 (keine ueberzogene Wolke)",
		hi.size() == 2 and is_equal_approx(hi[0].initial_velocity_min, 1.5)
		and is_equal_approx(hi[0].initial_velocity_max, 3.75)
		and hi[0].amount == 10)
	d.clear()
	await process_frame
	d.emit_landing(Vector3.ZERO, 9.0)
	var mm := fans_of(d)
	check("speed 9: s=(9-4)/10=0.5 -> velocity 1.0..2.5, amount 8",
		mm.size() == 2 and is_equal_approx(mm[0].initial_velocity_min, 1.0)
		and is_equal_approx(mm[0].initial_velocity_max, 2.5)
		and mm[0].amount == 8)

	# --- 3) Weltposition + IDENTITY-Basis unter rotiert/skaliertem Parent ----------
	var par := Node3D.new()
	par.position = Vector3(40.0, 9.0, -25.0)
	par.rotation = Vector3(deg_to_rad(-53.0), deg_to_rad(140.0), deg_to_rad(77.0))
	par.scale = Vector3(2.5, 0.3, 4.0)
	root.add_child(par)
	await process_frame
	var dp := fresh_dust(par)
	dp.emit_landing(Vector3(3.0, 0.5, 1.0), 12.0)
	var pf := fans_of(dp)
	check("top_level + globale Basis exakt IDENTITY unter rotiert/skaliertem Parent",
		pf.size() == 2 and pf[0].top_level and pf[0].global_basis == Basis.IDENTITY
		and pf[1].global_basis == Basis.IDENTITY)
	check("global_position = Weltposition (3,0.5,1), nicht parent-transformiert",
		pf[0].global_position.is_equal_approx(Vector3(3.0, 0.5, 1.0))
		and pf[1].global_position.is_equal_approx(Vector3(3.0, 0.5, 1.0)))
	check("direction bleibt Weltvorgabe (kein Parent-Rotationsdrall)",
		pf[0].direction.is_equal_approx(Vector3(-1, 0.2, 0).normalized())
		and pf[1].direction.is_equal_approx(Vector3(1, 0.2, 0).normalized()))

	# --- 4) Kap 4 Landungen / 8 Emitters: 10 Landungen ------------------------------
	var d2 := fresh_dust()
	for i in 10:
		d2.emit_landing(Vector3(i * 0.5, 0.0, 0.0), 10.0)
	check("nach 10 Landungen: genau 4 aktiv (aelteste vor der 5. retired)",
		d2.active_count() == 4)
	await process_frame  # queue_free wirkt erst zum Frame-Ende
	var live := fans_of(d2)
	check("genau 8 Emitter-Kinder lebendig", live.size() == 8)
	check("Gesamtzahl Kinder beschraenkt: 8 Partikel + 4 Timer = 12",
		d2.get_child_count() == 12)
	check("die 4 aktiven Landungen sind die letzten (x = 3.0, 3.5, 4.0, 4.5)",
		_positions_match(live))

	# --- 5) Vollstaendiges Cleanup <= 0.6s (Timer + Kinder wirklich frei) ----------
	var d3 := fresh_dust()
	d3.emit_landing(Vector3.ZERO, 10.0)
	check("vor Ablauf: 1 aktiv", d3.active_count() == 1)
	await wait_sec(0.61)
	await process_frame
	check("spaetestens 0.6s nach Emit: active_count 0 und 0 Kinder (auch Timer frei)",
		d3.active_count() == 0 and d3.get_child_count() == 0)

	# --- 6) clear() sofort + Reuse bei noch laufenden Alt-Timern --------------------
	var d4 := fresh_dust()
	for i in 3:
		d4.emit_landing(Vector3(i, 0.0, 0.0), 12.0)
	# Alt-Timer-Fenster offen lassen: erst 0.3s nach den Alt-Emits clear + reuse.
	await wait_sec(0.3)
	d4.clear()
	check("clear: active_count sofort 0", d4.active_count() == 0)
	await process_frame
	check("clear: alle Kinder (Partikel UND Timer) aus dem Baum",
		d4.get_child_count() == 0)
	# Reuse: neue Landung um t~0.35 (eigener Timer faellig ~0.90); die Alt-Timer
	# waeren bei 0.55 faellig gewesen — die naechste Pruefung bei ~0.74 liegt
	# dazwischen: kein (Alter) Timer darf die neue Landung loeschen.
	d4.emit_landing(Vector3(7.0, 0.0, 0.0), 12.0)
	check("Reuse direkt nach clear: 1 aktiv", d4.active_count() == 1)
	await wait_sec(0.4)  # jetzt ~0.75s: alle ALTEN Timer waren faellig
	check("aeltere Cleanup-Timer loeschen NICHT die neue Landung (Identitaets-Check)",
		d4.active_count() == 1)
	await wait_sec(0.3)  # eigener Timer der neuen Landung faellig (~0.90s)
	await process_frame
	check("neue Landung raeumt sich selbst: active_count 0, 0 Kinder",
		d4.active_count() == 0 and d4.get_child_count() == 0)

	# --- 7) Instanzen unabhaengig; geteilte Ressourcen intern ----------------------
	var a := fresh_dust()
	var b := fresh_dust()
	a.emit_landing(Vector3.ZERO, 10.0)
	check("Treffer der einen Instanz aendert die andere nicht",
		a.active_count() == 1 and b.active_count() == 0)
	var fa := fans_of(a)
	b.emit_landing(Vector3.ZERO, 10.0)
	var fb := fans_of(b)
	check("Mesh/Material/Ramp intern geteilt",
		fa.size() == 2 and fb.size() == 2
		and fa[0].mesh == fb[0].mesh
		and fa[0].material_override == fb[0].material_override
		and fa[0].color_ramp == fb[0].color_ramp)

	print("H19 SUMMARY checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)

# Die letzten 4 Landungen hatten x = 3.0, 3.5, 4.0, 4.5 (je 2 Faecher gleich x).
func _positions_match(live: Array[CPUParticles3D]) -> bool:
	if live.size() != 8:
		return false
	var xs: Array[float] = []
	for node in live:
		if not node.visible:
			return false
		xs.append(node.global_position.x)
	var want := [3.0, 3.0, 3.5, 3.5, 4.0, 4.0, 4.5, 4.5]
	for i in 8:
		if absf(xs[i] - want[i]) > 0.001:
			return false
	return true
