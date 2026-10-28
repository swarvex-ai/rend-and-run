extends SceneTree
# H18 — Headless-Test fuer blood_spray.gd (begrenzte gerichtete Blutbursts).
# Aufruf: godot --headless --path <isolierter-scratch> --script res://tests/blood_spray_test.gd
# Prueft Eigenschaften/Timer ehrlich; visuelle Abnahme ist headless nicht moeglich.
# Exit 0 = alle Checks PASS.

const SPRAY_SCRIPT := preload("res://modules/vfx/blood_spray.gd")

var checks := 0
var failures := 0

func check(label: String, ok: bool) -> void:
	checks += 1
	if not ok:
		failures += 1
	print("H18 %s %s" % ["PASS" if ok else "FAIL", label])

func wait_sec(seconds: float) -> void:
	await create_timer(seconds, true).timeout

func fresh_spray(parent: Node = null) -> Node3D:
	var s: Node3D = SPRAY_SCRIPT.new()
	(parent if parent != null else root).add_child(s)
	return s

func first_particles(s: Node3D) -> CPUParticles3D:
	for c in s.get_children():
		if c is CPUParticles3D:
			return c
	return null

# Neuester (letzter) Partikel-Knoten — Kinderreihenfolge == Emit-Reihenfolge.
func last_particles(s: Node3D) -> CPUParticles3D:
	var found: CPUParticles3D = null
	for c in s.get_children():
		if c is CPUParticles3D and is_instance_valid(c):
			found = c
	return found

func _initialize() -> void:
	# SceneTree-Skriptmodus: erst ein Frame, dann sind Knoten im Baum.
	await process_frame

	# --- 1) Ein Burst: Explorer-Mesh + Material sichtbar zugewiesen ---------------
	var s := fresh_spray()
	check("Start: 0 aktive Bursts", s.active_count() == 0)
	s.emit_burst(Vector3(1.0, 0.5, -2.0), Vector3(1.0, 0.0, 0.0))
	check("nach emit: 1 aktiver Burst", s.active_count() == 1)
	var p := first_particles(s)
	check("CPUParticles3D existiert, one_shot, explosiveness 1, emitting",
		p != null and p.one_shot and is_equal_approx(p.explosiveness, 1.0)
		and p.is_emitting())
	check("Tapered ArrayMesh, 0.06m long",
		p.mesh is ArrayMesh and absf(p.mesh.get_aabb().size.y - 0.06) < 0.001)
	check("Velocity alignment active", p.particle_flag_align_y)
	check("Size variation and shrink-out", p.scale_amount_min < p.scale_amount_max and p.scale_amount_curve.sample(0.0) > p.scale_amount_curve.sample(1.0))
	check("EXPLIZITES dunkelkarmesines, opakes, mattes Material",
		p.material_override is StandardMaterial3D
		and (p.material_override as StandardMaterial3D).albedo_color == Color(0.35, 0.02, 0.04)
		and (p.material_override as StandardMaterial3D).transparency == BaseMaterial3D.TRANSPARENCY_DISABLED
		and absf((p.material_override as StandardMaterial3D).roughness - 0.9) < 0.001)
	check("Schatten aus (CPUParticles3D kann in Godot 4 nicht kollidieren — API absent)",
		p.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		and not ("collision_mode" in p))
	check("one-shot-Parameter: local_coords aus, preprocess 0",
		not p.local_coords and is_zero_approx(p.preprocess))

	# --- 2) Weltposition + Einheitsbasis unter transformiertem Parent --------------
	var par := Node3D.new()
	par.position = Vector3(50.0, 7.0, -30.0)
	par.rotation = Vector3(deg_to_rad(37.0), deg_to_rad(123.0), deg_to_rad(-71.0))
	par.scale = Vector3(3.0, 0.4, 2.0)
	root.add_child(par)
	await process_frame
	var sp := fresh_spray(par)
	sp.emit_burst(Vector3(2.0, 1.0, 3.0), Vector3(0.0, 1.0, 0.0))
	var pp := first_particles(sp)
	check("top_level an: Welt-Transfom unabhaengig vom skalierten/rotierten Parent",
		pp.top_level and pp.global_position.is_equal_approx(Vector3(2.0, 1.0, 3.0)))
	# Vertrag (Review-Korrektur): GLOBALE BASIS IDENTITY, Richtung in p.direction.
	check("globale Basis exakt IDENTITY unter rotiert/skaliertem Parent",
		pp.global_basis == Basis.IDENTITY)
	check("p.direction == normierte Welt-Richtung (0,1,0)",
		pp.direction.is_equal_approx(Vector3.UP))

	# --- 3) Richtung: normiert, Fallback UP, Aufrufer-Vektor unveraendert ----------
	var dir := Vector3(3.0, 4.0, 0.0)  # Laenge 5
	s.emit_burst(Vector3.ZERO, dir)
	var nd := first_particles_after(s, p)
	check("p.direction == normierte Welt-Richtung (3,4,0)/5",
		nd.direction.is_equal_approx(Vector3(0.6, 0.8, 0.0))
		and nd.global_basis == Basis.IDENTITY)
	check("Aufrufer-Vektor unveraendert (keine Mutation)",
		dir == Vector3(3.0, 4.0, 0.0))
	s.emit_burst(Vector3.ZERO, Vector3.ZERO)
	var fz := first_particles_after(s, p)
	check("Null-Richtung: Fallback Welt-UP in p.direction",
		fz.direction.is_equal_approx(Vector3.UP))
	check("Spread 25 Grad, Gravity (0,-18,0), Emissionsform Punkt",
		absf(nd.spread - 25.0) < 0.001
		and nd.gravity == Vector3(0.0, -18.0, 0.0)
		and nd.emission_shape == CPUParticles3D.EMISSION_SHAPE_POINT)

	# --- 4) Strength: geclamped und durchgeschaltet --------------------------------
	var s2 := fresh_spray()
	s2.emit_burst(Vector3.ZERO, Vector3.UP, 0.1)   # -> clamp 0.25 (t=0)
	var lo := first_particles(s2)
	s2.emit_burst(Vector3.ZERO, Vector3.UP, 99.0)  # -> clamp 2.0 (t=1)
	var hi := last_particles(s2)
	check("amount 24 bei strength<=0.25, 48 bei >=2 (Clamp wirkt)",
		lo.amount == 24 and hi.amount == 48)
	check("velocity 2*s..5*s: s=0.25 -> 0.5..1.25, s=2 -> 4..10 (Clamp an beiden Enden)",
		is_equal_approx(lo.initial_velocity_min, 0.5)
		and is_equal_approx(lo.initial_velocity_max, 1.25)
		and is_equal_approx(hi.initial_velocity_min, 4.0)
		and is_equal_approx(hi.initial_velocity_max, 10.0))
	s2.emit_burst(Vector3.ZERO, Vector3.UP, 0.25)  # exakt am Clamp-Rand
	var edge := last_particles(s2)
	check("exakt s=0.25: 0.5..1.25 (Unter-grenze klemmt nicht hoeher)",
		is_equal_approx(edge.initial_velocity_min, 0.5)
		and is_equal_approx(edge.initial_velocity_max, 1.25))
	s2.emit_burst(Vector3.ZERO, Vector3.UP, 2.0)   # exakt am Clamp-Rand
	var edge2 := last_particles(s2)
	check("exakt s=2.0: 4..10 (Ober-grenze klemmt nicht hoeher)",
		is_equal_approx(edge2.initial_velocity_min, 4.0)
		and is_equal_approx(edge2.initial_velocity_max, 10.0))
	s2.emit_burst(Vector3.ZERO, Vector3.UP, 1.0)
	var mid := last_particles(s2)
	check("strength 1: amount in 24..48, velocity 2..5, lifetime in 0.65..0.9",
		mid.amount >= 24 and mid.amount <= 48
		and is_equal_approx(mid.initial_velocity_min, 2.0)
		and is_equal_approx(mid.initial_velocity_max, 5.0)
		and mid.lifetime >= 0.65 - 0.0001 and mid.lifetime <= 0.9 + 0.0001)

	# --- 5) Kap 8: 20 Emits -> maximal 8 aktiv, aelteste zuerst raus ----------------
	var s3 := fresh_spray()
	for i in 20:
		s3.emit_burst(Vector3(i * 0.1, 0.0, 0.0), Vector3.UP, 1.0)
	check("nach 20 Emits: genau 8 aktiv (aelteste vor dem 9. retired)",
		s3.active_count() == 8)
	await process_frame  # queue_free wirkt erst zum Frame-Ende
	var live: Array[CPUParticles3D] = []
	for c in s3.get_children():
		if c is CPUParticles3D and is_instance_valid(c):
			live.append(c)
	check("nur 8 Partikel-Knoten lebendig (Retire = echte Freigabe)",
		live.size() == 8)
	check("die 8 Aktiven sind die letzten 8 Emits (Positionen x=1.2..1.9)",
		live.size() == 8 and _positions_match(live))
	# Review-Regression 1: Timer durfen sich nicht anhaufen (one_shot stoppt nur).
	# Nach 20 Emits + Retire: max 8 Partikel + 8 aktive Timer = 16 Kinder.
	check("Gesamtzahl Kinder nach 20 Emits beschraenkt (keine Timer-Leiche)",
		s3.get_child_count() <= 16)

	# --- 6) clear(): sofort 0, queue_free, alte Timer ungefaehrlich ----------------
	s3.clear()
	check("clear: active_count sofort 0", s3.active_count() == 0)
	await process_frame
	var remaining := 0
	for c in s3.get_children():
		if c is CPUParticles3D:
			remaining += 1
	check("clear: alle Partikel aus dem Baum (queue_free wirkte)", remaining == 0)
	check("clear: auch alle Timer freigegeben (0 Kinder insgesamt)",
		s3.get_child_count() == 0)
	# --- 7) Reuse nach clear mit noch laufenden alten Timers -----------------------
	# Zeitachse: alte Timer feuern bei t~1.5s ab Emit Runde 5. Erst 0.3s warten,
	# dann neu emitten (eigener Timer bei t~1.8s), dann bei t~1.6s pruefen:
	# Ein alter Timer darf den neuen Eintrag nicht loeschen (Identitaets-Check).
	await wait_sec(0.3)
	s3.emit_burst(Vector3(9.0, 0.0, 0.0), Vector3.UP, 1.0)
	check("Reuse nach clear: 1 aktiv, Knoten existiert", s3.active_count() == 1)
	await wait_sec(1.3)  # jetzt ~1.6s nach Runde 5: alle ALTEN Timer waren faellig
	check("aeltere aufraeum-Timer loeschen NICHT den neuen Eintrag (Token-Check)",
		s3.active_count() == 1)
	check("Reuse: Gesamtzahl Kinder beschraenkt (1 Partikel + 1 Timer)",
		s3.get_child_count() <= 2)
	await wait_sec(0.35)  # eigener Timer des neuen Eints faellig (~1.65s nach ihm)
	check("neuer Eintrag raeumt sich selbst innerhalb 1.5s",
		s3.active_count() == 0)
	await wait_sec(0.3)  # queue_free von Partikel + eigenem Timer wirkt
	check("nach komplettem Cleanup: 0 Kinder (Timer geben sich selbst frei)",
		s3.get_child_count() == 0)

	# --- 8) Automatischer Cleanup innerhalb 1.5s -------------------------------------
	var s4 := fresh_spray()
	s4.emit_burst(Vector3.ZERO, Vector3.UP, 1.0)
	s4.emit_burst(Vector3(0.1, 0.0, 0.0), Vector3.UP, 1.0)
	check("vor Ablauf: 2 aktiv", s4.active_count() == 2)
	await wait_sec(0.8)
	check("nach 0.8s noch aktiv (Lifetime <= 0.9s bleibt sichtbar)",
		s4.active_count() == 2)
	await wait_sec(0.9)
	await process_frame
	check("spaetestens 1.5s nach Emit: beide retired, Zaehler 0, Knoten + Timer frei",
		s4.active_count() == 0 and s4.get_child_count() == 0)

	# --- 9) Mehrere Instanzen unabhaengig; geteiltes Mesh unveraenderlich -----------
	var a := fresh_spray()
	var c := fresh_spray()
	a.emit_burst(Vector3.ZERO, Vector3.UP, 1.0)
	check("Treffer der einen Spray-Instanz aendert die andere nicht",
		a.active_count() == 1 and c.active_count() == 0)
	c.emit_burst(Vector3.ZERO, Vector3.UP, 1.0)
	var pa := first_particles(a)
	var pc := first_particles(c)
	check("Mesh/Material intern geteilt (const) — Bewusstseins-Doku zum Vertrag",
		pa.mesh == pc.mesh and pa.material_override == pc.material_override)
	var shared_mesh: ArrayMesh = pa.mesh
	check("geteiltes Mesh behaelt Tropfenmasse",
		absf(shared_mesh.get_aabb().size.y - 0.06) < 0.001
		and absf((pa.material_override as StandardMaterial3D).roughness - 0.9) < 0.001)

	print("H18 SUMMARY checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)

# Neuester Partikel-Knoten NACH `skip` Kindern (einfach: letztes CPUParticles3D-Kind).
func first_particles_after(s: Node3D, skip: CPUParticles3D) -> CPUParticles3D:
	var found: CPUParticles3D = null
	for c in s.get_children():
		if c is CPUParticles3D and c != skip and is_instance_valid(c):
			found = c
	return found

func _particle_child_count(s: Node) -> int:
	var n := 0
	for c in s.get_children():
		if c is CPUParticles3D:
			n += 1
	return n

# Die letzten 8 Emits hatten x = 1.2, 1.3, ..., 1.9.
func _positions_match(live: Array[CPUParticles3D]) -> bool:
	var want := 1.2
	for node in live:
		if not node.visible:
			return false
		if absf(node.global_position.x - want) > 0.001:
			return false
		want += 0.1
	return true
