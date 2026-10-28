extends SceneTree
## H20 — Spring-Timing-Regression mit ECHTER Physik und ECHTEN Input-Kanten.
## Kein Eingriff in Spieler-/Szenen-/FX-Code: instanziiert res://main.tscn im
## --script-Modus (Autoloads werden geladen, main_scene nicht), deaktiviert
## Gegner, legt eine deterministische Testarena aus eigenen StaticBody3D-Koerpern
## weit ausserhalb der Lab-Route (x 100..300).
## Messung: Inputs werden auf EXPLIZITE Physikframes gesetzt
## (await physics_frame — hat kein delta-Argument); nach jedem await
## liegen Position/velocity des verarbeiteten Ticks vor. Simulationszeit =
## Engine.get_physics_frames()/physics_ticks_per_second. Kein Walltime/FPS.
## Aufruf: godot --headless --path <game> --script res://tests/jump_timing_probe.gd
## Exit-Code != 0 bei irgendeinem Fehler; synthetische Eingaben werden geraeumt.

var failures := 0
var checks := 0

func ck(label: String, ok: bool, detail := "") -> void:
	checks += 1
	if not ok:
		failures += 1
	print("H20 %s %s %s" % ["PASS" if ok else "FAIL", label, detail])

func metro(key: String, value) -> void:
	print("H20 METRO %s=%s" % [key, value])

func sim_time() -> float:
	return float(Engine.get_physics_frames()) / Engine.physics_ticks_per_second

var main: Node3D
var p: CharacterBody3D

func _initialize() -> void:
	_run()

func _run() -> void:
	# Autoloads (FX) sind vor Frame 1 registriert.
	await process_frame
	await process_frame
	var ps: PackedScene = load("res://main.tscn")
	main = ps.instantiate()
	root.add_child(main)
	# FX/_process-Logik des Spiels rechnet mit current_scene (Hauptpfad);
	# im --script-Modus muss man sie explizit setzen.
	current_scene = main
	await process_frame
	p = main.get_node("Player") as CharacterBody3D
	# Gegner (inkl. Route-Spawns) komplett aus dem Physikleben nehmen.
	for e in get_nodes_in_group("enemies"):
		e.set_physics_process(false)
		e.visible = false
	# Deterministische Arena (eigene Koerper, keine Szenen-Aenderung):
	#   Boden  x 100..300, Oberkante y=0   |  hohe Platte x 190..200, Oberkante y=4
	var _g := _plat(Vector3(200.0, -0.5, 0.0), Vector3(200.0, 1.0, 8.0))
	var _h := _plat(Vector3(195.0, 3.5, 0.0), Vector3(10.0, 1.0, 6.0))
	await physics_frame
	var dt := 1.0 / Engine.physics_ticks_per_second
	var v0: float = p.jump_velocity
	var g: float = absf(p.call("get_gravity").y) * float(p.gravity_mult)
	metro("dt", dt)
	metro("jump_velocity", v0)
	metro("gravity_effective", g)
	metro("coyote_time", p.coyote_time)
	metro("jump_buffer_time", p.jump_buffer_time)
	metro("fast_fall_mult", p.fast_fall_mult)

	# ------------------------------------------------------------------
	# T1a: variabler Sprung — TASTE GEHALTEN ueber den ganzen Flug.
	# ------------------------------------------------------------------
	p.global_position = Vector3(140.0, 0.95, 0.0)
	p.velocity = Vector3.ZERO
	await _settle(20)
	var y0: float = p.global_position.y
	Input.action_press("jump")
	var air_start := 0
	var apex := y0
	var landed := false
	var land_t := 0.0
	for i in 120:
		await physics_frame
		if air_start == 0 and p.velocity.y >= v0 * 0.95:
			air_start = Engine.get_physics_frames()
		if air_start != 0 and not landed:
			if p.global_position.y > apex:
				apex = p.global_position.y
			if p.is_on_floor():
				landed = true
				land_t = sim_time()
	Input.action_release("jump")
	var h_held: float = apex - y0
	var air_held := land_t - float(air_start) / Engine.physics_ticks_per_second
	var h_exp: float = v0 * v0 / (2.0 * g)
	metro("T1a_apex_m", snappedf(h_held, 0.001))
	metro("T1a_apex_analytic_m", snappedf(h_exp, 0.001))
	metro("T1a_airtime_s", snappedf(air_held, 0.001))
	ck("T1a gehaltener Sprung startet", air_start != 0)
	ck("T1a gehaltener Sprung landet", landed)
	ck("T1a Scheitelhoehe in Physikgrenze (analytisch +/- Euler-Ueberschuss)",
		absf(h_held - h_exp) <= g * dt * dt + v0 * dt * 0.5 + 0.05,
		"gemessen=%.3f erwartet~%.3f" % [h_held, h_exp])
	await _settle(30)

	# ------------------------------------------------------------------
	# T1b: variabler Sprung — nach 2 Physikframes loslassen (Jump-Cut).
	# ------------------------------------------------------------------
	p.global_position = Vector3(140.0, 0.95, 0.0)
	p.velocity = Vector3.ZERO
	await _settle(20)
	var y0b: float = p.global_position.y
	Input.action_press("jump")
	# StartFrame IN der Druckphase erfassen: nach 2 Ticks ist velocity.y bereits
	# unter den 0.95*vy-Schwellwert zerfallen (0.69 m/s pro Tick), dann im
	# Messloop wuerde der Start unbemerkt bleiben.
	var airb_start := 0
	var apexb := y0b
	for i in 2:
		await physics_frame
		if airb_start == 0 and p.velocity.y > 1.0:
			airb_start = Engine.get_physics_frames()
	Input.action_release("jump")
	var landb := false
	var landb_t := 0.0
	for i in 120:
		await physics_frame
		if airb_start != 0 and not landb:
			if p.global_position.y > apexb:
				apexb = p.global_position.y
			if p.is_on_floor():
				landb = true
				landb_t = sim_time()
	var h_cut: float = apexb - y0b
	var air_cut := landb_t - float(airb_start) / Engine.physics_ticks_per_second
	metro("T1b_apex_m", snappedf(h_cut, 0.001))
	metro("T1b_airtime_s", snappedf(air_cut, 0.001))
	ck("T1b Frueh-Loslassen startet Sprung", airb_start != 0)
	ck("T1b Cut-Sprung klar niedriger als gehaltener",
		h_cut < h_held - 0.15, "cut=%.3f gehalten=%.3f" % [h_cut, h_held])
	await _settle(30)

	# ------------------------------------------------------------------
	# T2a: Coyote — Kante verlassen, Druck 2 Physikframes spaeter springt noch.
	# ------------------------------------------------------------------
	p.global_position = Vector3(198.3, 4.65, 0.0)  # auf Platte (Oberkante 4.0)
	p.velocity = Vector3.ZERO
	await _settle(30)
	ck("T2a Start steht auf Plattform", p.is_on_floor(), "y=%.2f" % p.global_position.y)
	Input.action_press("move_right")
	var left_floor := -1
	for i in 60:
		await physics_frame
		if not p.is_on_floor():
			left_floor = Engine.get_physics_frames()
			break
	ck("T2a Spieler verlaeuft die Kante", left_floor != -1, "x=%.2f" % p.global_position.x)
	Input.action_release("move_right")
	# 2 Ticks nach Bodenverlust: innen im Coyote-Fenster (0.10s ~ 6 Ticks).
	await physics_frame
	await physics_frame
	Input.action_press("jump")
	var jumped_coyote := false
	for i in 6:
		await physics_frame
		if p.velocity.y > v0 * 0.5:
			jumped_coyote = true
			break
	Input.action_release("jump")
	metro("T2a_velocity_after_coyote_press", snappedf(p.velocity.y, 0.001))
	ck("T2a Coyote: Druck kurz nach Kantverlust springt", jumped_coyote)
	await _wait_ground(3.0)
	await _settle(30)

	# ------------------------------------------------------------------
	# T2b: Coyote-Fenster ABGELAUFEN — Druck darf NICHT mehr abspringen lassen.
	#      +3 Ticks Distanz gegen Float-Rand (0.10s - 6*dt liegt auf der Nadel).
	# ------------------------------------------------------------------
	p.global_position = Vector3(198.3, 4.65, 0.0)
	p.velocity = Vector3.ZERO
	await _settle(30)
	Input.action_press("move_right")
	var left2 := -1
	for i in 60:
		await physics_frame
		if not p.is_on_floor():
			left2 = Engine.get_physics_frames()
			break
	Input.action_release("move_right")
	var k_coyote: int = int(ceil(float(p.coyote_time) / dt)) + 3
	for i in k_coyote:
		await physics_frame
	var vy_before: float = p.velocity.y
	Input.action_press("jump")
	var late_jump := false
	for i in 6:
		await physics_frame
		if p.velocity.y > v0 * 0.5:
			late_jump = true
			break
	Input.action_release("jump")
	metro("T2b_frames_after_edge_at_press", k_coyote)
	metro("T2b_velocity_after_late_press", snappedf(p.velocity.y, 0.001))
	ck("T2b Coyote-Fenster abgelaufen: kein Absprung", not late_jump,
		"vy_before=%.2f vy_after=%.2f" % [vy_before, p.velocity.y])
	await _wait_ground(3.0)
	await _settle(30)

	# ------------------------------------------------------------------
	# T3a: gepufferter Sprung KURZ VOR Landung — Druck in der Fallphase
	#      (innerhalb jump_buffer_time vor dem ECHTEN Bodenkontakt)
	#      -> Absprung OHNE neuen Druck. Beweis ueber echte Zeiten:
	#      beim Druck: NICHT auf Boden und velocity.y<0; t_press notieren;
	#      echter Folge-Bodenkontakt t_land; 0 < t_land - t_press <= buffer.
	#      Der Druckzeitpunkt wird NICHT ueber eine geschaetzte Fallzeit
	#      gesetzt, sondern pro Frame aus IST-Position/-Velocity berechnet.
	# ------------------------------------------------------------------
	p.global_position = Vector3(140.0, 3.0, 0.0)  # frei ueber Arena-Boden (Oberkante 0)
	p.velocity = Vector3.ZERO
	await _settle(2)
	var a_fall: float = g * float(p.fast_fall_mult)
	# Fallphase einleiten und pro Frame Restflugzeit (Quadratik aus IST-Werten)
	# rechnen; druecken, sobald sie unter die halbe Pufferzeit faellt.
	var t_press := -1.0
	for i in 120:
		await physics_frame
		var d := p.global_position.y - 0.65   # Kapselmitte-Kontakt ~0.65 ueber Boden
		if p.is_on_floor() or p.velocity.y >= 0.0 or d <= 0.0:
			continue
		var t_rem := (sqrt(p.velocity.y * p.velocity.y + 2.0 * a_fall * d)
			+ p.velocity.y) / a_fall          # vy<0 -> Restzeit bis Kontakt
		if t_rem <= 0.5 * float(p.jump_buffer_time):
			ck("T3a Druck in Fallphase: in der Luft und sinkend",
				(not p.is_on_floor()) and p.velocity.y < 0.0,
				"on_floor=%s vy=%.2f t_rem=%.3f" % [p.is_on_floor(), p.velocity.y, t_rem])
			Input.action_press("jump")
			t_press = sim_time()
			break
	ck("T3a Druck wurde in Fallphase gesetzt", t_press > 0.0)
	# Einheitlicher Messloop: t_land VOR bounce erfassen (Spiel setzt Absprung-
	# velocity teils erst im Folge-Tick), Release nach 2 Frames.
	var t_land := -1.0
	var bounce := false
	var released := false
	for i in 90:
		await physics_frame
		if not released:
			# 2 Frames gehalten, dann los — Puffer muss OHNE neuen Edge zinden.
			Input.action_release("jump")
			released = true
		# Am Lande-Frame gilt is_on_floor UND (bei Puffer) moeglicherweise schon
		# die Absprungvelocity — t_land hat Vorrang vor dem Bounce-Ausstieg.
		if t_land < 0.0 and p.is_on_floor():
			t_land = sim_time()
		if p.velocity.y > v0 * 0.5:
			bounce = true
			break
	metro("T3a_t_press_s", snappedf(t_press, 0.001))
	metro("T3a_t_land_s", snappedf(t_land, 0.001))
	if t_land > 0.0 and t_press > 0.0:
		metro("T3a_press_to_land_s", snappedf(t_land - t_press, 0.001))
	ck("T3a echter Bodenkontakt nach dem Druck erfasst", t_land > 0.0)
	ck("T3a Druck->Landung liegt im Buffer-Fenster (0 < dt <= jump_buffer_time)",
		t_land > 0.0 and t_press > 0.0 and (t_land - t_press) > 0.0
		and (t_land - t_press) <= float(p.jump_buffer_time) + dt,
		"dt=%.3f buffer=%.3f" % [t_land - t_press, p.jump_buffer_time])
	ck("T3a Puffer kurz vor Landung startet naechsten Sprung ohne neuen Druck", bounce)
	await _wait_ground(3.0)
	await _settle(30)

	# ------------------------------------------------------------------
	# T3b: KEIN Repeat bei GEHALTENEM Input: normaler Sprung, Taste bis nach
	#      der Landung und 60 Frames weiter GEHALTEN -> genau EIN Start.
	#      (Zusaetzlich: Ein-Edge-Beweis press/release ohne erneuten Absprung.)
	# ------------------------------------------------------------------
	p.global_position = Vector3(140.0, 0.95, 0.0)
	p.velocity = Vector3.ZERO
	await _settle(20)
	Input.action_press("jump")
	var jumps := 0
	var airborne := false
	var floor_seen := false
	for i in 200:
		await physics_frame
		if not airborne and p.velocity.y > v0 * 0.5:
			jumps += 1
			airborne = true
		elif airborne and p.is_on_floor():
			airborne = false
			floor_seen = true
		if floor_seen:
			# Nach der Landung weiter gehalten: 60 Frames, keine neuen Starts.
			var repeats := 0
			for j in 60:
				await physics_frame
				if p.velocity.y > v0 * 0.5:
					repeats += 1
					break
			jumps += repeats
			break
	Input.action_release("jump")
	metro("T3b_held_total_starts", jumps)
	ck("T3b gehaltener Sprung repeatet NICHT nach Landung",
		floor_seen and jumps == 1, "starts=%d floor_seen=%s" % [jumps, floor_seen])

	# Synthetische Eingaben raeumen.
	for a in ["jump", "move_left", "move_right", "attack", "crouch", "guard", "dodge"]:
		if InputMap.has_action(a):
			Input.action_release(a)
	print("H20 SUMMARY checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)

# ---------------------------------------------------------------------------

func _plat(center: Vector3, size: Vector3) -> StaticBody3D:
	var b := StaticBody3D.new()
	b.collision_layer = 1
	b.collision_mask = 0
	var sh := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	sh.shape = bs
	b.add_child(sh)
	root.add_child(b)          # erst in den Baum, dann globale Position setzen
	b.global_position = center
	return b

func _settle(frames: int) -> void:
	for i in frames:
		await physics_frame

func _wait_ground(timeout_s: float) -> void:
	var n := int(timeout_s * Engine.physics_ticks_per_second)
	for i in n:
		await physics_frame
		if p.is_on_floor():
			return
