extends SceneTree
## H26 — Ausfuehrbare Begegnungs-Messprobe (Codex-Vertrag H26, Basis c4e5fb3 / Gameplay 5cebdd1).
## Misst mit ECHTER CharacterBody-Physik und echten Input-Kanten (Input.action_press/release),
## ob die Nutzer-Beschwerden weiterhin gelten:
##   B1 Schaden schon beim Erreichen der Gegenerhoehe
##   B2 kein Überspringen von Gegnern
##   B3 mehrere Gegner greifen gemeinsam an
##   B4 Recovery zu kurz fuer Gegenschlag
## Regeln: KEINE Aufrufe von player.take_damage / _enter direkt, keine
## Produktions-Hooks, keine Gamecode-Aenderungen. Zustands-/Positions-RESETS
## zwischen Szenarien sind erlaubt und werden protokolliert (RESET ...).
## Schaden wird NUR ueber HP-Deltas beobachtet; Positionen/Hoehen/Zustandsaenderungen
## werden protokolliert. Ausgaben: METRO=Messwert, FIND=Befund/Einordnung,
## HIT=HP-Delta-Ereignis. Fail NUR bei Skriptfehlern oder Szenario-Unfaehigkeit —
## ein reproduzierter Gameplay-Mangel ist ein BEFUND (FIND), kein FAIL.
## Aufruf (Desktop-Kopie, Save-isoliert):
##   XDG_DATA_HOME=/tmp/h26_xdg timeout 150 godot --headless --path /tmp/h26_run/game \
##     --script res://tests/encounter_probe.gd

const STATE_NAMES := ["IDLE", "ALERT", "CHASE", "WINDUP", "SWING", "RECOVERY"]
const TICK := 1.0 / 60.0
# Freier Korridor auf Bodenflaeche: lab_route.gd-Plattformkoerper liegen bei
# x 10..12/13..15/16..20/21..23 (Oberkante 0.8/1.6/2.4 m) und wuerden Spieler
# UND Gegner ausserhalb blockieren (in Lauf 2 beobachtet). Kisten stehen bei
# z=-0.55 seitlich und lagen im Lauf nicht im Pfad.
const CORR_FOE_X := 5.0
const CORR_LEFT_X := 0.9
const CORR_RIGHT_X := 8.9

var main: Node
var player: CharacterBody3D
var foes: Dictionary = {}              # encounter_id -> enemy
var _fail := 0
var _checks := 0
var _wall_t0 := 0
var _frames_t0 := 0
var _hp_prev := 0
var _hits: Array[String] = []

func _initialize() -> void:
	_wall_t0 = Time.get_ticks_msec()
	_run()

func _now() -> float:
	# Absolute Simulationszeit — robust ueger Szenario- und Nachlauf-Schleifen.
	return (Engine.get_physics_frames() - _frames_t0) * TICK

func _st(e: Node) -> String:
	return STATE_NAMES[e._state]

func _dx(e: Node) -> float:
	return player.global_position.x - e.global_position.x

func _rel_feet(e: Node) -> float:
	return player.global_position.y - e.global_position.y

func _reset(foe_id: String, foe_x: float, player_x: float, hp := 99) -> void:
	# Kontrollierte Szenen-Positionierung/Reset zwischen Szenarien (vertraglich
	# erlaubt, protokolliert). Kein Eingriff in Kampflogik/Szenenstruktur.
	for id in foes:
		var e = foes[id]
		e._state = 0
		e._state_t = 0.0
		e._stun = 0.0
		e._recovery_step.cancel()
		e._swing_hit = false
		e._committed_low = false
		e._ranged_attack = false
		e._kb_timer = 0.0
		e.global_position = Vector3(e._spawn_x, 0.05, 0)
		e.velocity = Vector3.ZERO
	var focus = foes[foe_id]
	focus.global_position = Vector3(foe_x, 0.05, 0)
	Input.action_release("move_left")
	Input.action_release("move_right")
	Input.action_release("jump")
	Input.action_release("attack")
	player.hp = hp
	player._iframes = 0.0
	player._dying = false
	player._attack_phase = 0
	player.global_position = Vector3(player_x, 0.05, 0)
	player.velocity = Vector3.ZERO
	_hp_prev = player.hp
	print("RESET %s_x=%.2f player_x=%.2f hp=%d uebrige_foes_an_spawn_x (S2/S3 im freien Korridor x %.1f..%.1f)" % [
		foe_id, foe_x, player_x, hp, CORR_LEFT_X, CORR_RIGHT_X])

## Schaden NUR ueber HP-Delta beobachten; nie take_damage aufrufen.
## Attribution: Wer konnte treffen? Nahkampf nur mit foe in SWING und
## |dx|<=WEAPON_REACH(1.45); Distanzangriff nur foe in SWING mit _ranged_attack.
## Traegt kein Gegner diese Signatur, wird der naechste als KONTXT gemeldet und
## attribution=unklar vermerkt (Nahkampf-SWING koennen wir im Frame der
## HP-Aenderung schon verlassen haben — dann zuletzt-beobachteter SWING-Kandidat).
var _last_swing_ids := ""

func _watch(tag: String) -> void:
	var swing_now: Array[String] = []
	for id in foes:
		var e = foes[id]
		if not e._dead and e._state == 4:   # SWING
			swing_now.append(id + ("_ranged" if e._ranged_attack else "_melee"))
	if not swing_now.is_empty():
		_last_swing_ids = ",".join(swing_now)
	if player.hp >= _hp_prev:
		_hp_prev = player.hp
		return
	var foe = _find_nearest_foe()
	if foe == null:
		_hp_prev = player.hp
		return
	_hits.append("%s t=%.3f hp%d->%d d=%.2f rel_feet=%.2f nearest_state=%s player_on_floor=%s moegliche_schadenstecker=%s (zuletzt_Swing: %s)" % [
		tag, _now(), _hp_prev, player.hp, absf(_dx(foe)), _rel_feet(foe), _st(foe),
		str(player.is_on_floor()),
		(",".join(swing_now) if not swing_now.is_empty() else "keine_in_Swing"),
		_last_swing_ids])
	_hp_prev = player.hp

func _find_nearest_foe() -> Node:
	var best = null
	var bd := 1e9
	for id in foes:
		var e = foes[id]
		if e._dead:
			continue
		var d: float = absf(_dx(e))
		if d < bd:
			bd = d
			best = e
	return best

func _check(label: String, ok: bool, detail := "") -> void:
	_checks += 1
	if not ok:
		_fail += 1
	print("H26 %s %s %s" % ["PASS" if ok else "FAIL", label, detail])

func _run() -> void:
	await process_frame
	await process_frame
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame
	await process_frame
	_frames_t0 = Engine.get_physics_frames()
	player = main.player
	for e in get_nodes_in_group("enemies"):
		if e.encounter_id != "":
			foes[e.encounter_id] = e
	print("METRO probe=loaded route=%s foes=%s jump_v=%.2f move_speed=%.2f hurt_h=%.2f" % [
		str(main.route != null), str(foes.keys()), player.jump_velocity,
		player.move_speed, player.hurt_height()])
	_check("S0 Route+Gegner geladen", main.route != null and foes.size() >= 3,
		"foes=%d" % foes.size())

	await _scenario_s1()
	await _scenario_s2("links")
	await _scenario_s2("rechts")
	await _scenario_s3()
	await _scenario_s4("duelist")
	await _scenario_s4("brute")
	await _scenario_s5()

	var wall_ms := Time.get_ticks_msec() - _wall_t0
	for h in _hits:
		print("HIT %s" % h)
	print("METRO sim_seconds_total=%.2f wall_ms=%d" % [_now(), wall_ms])
	_check("P1 Gesamtsimulation < 90 s", _now() < 90.0,
		"sim=%.1f wall=%d" % [_now(), wall_ms])
	print("H26 NOTE befuende_in_HIT/FIND_zeilen; fail_nur_bei_skript_oder_szenario")
	print("H26 SUMMARY checks=%d failures=%d" % [_checks, _fail])
	quit(1 if _fail else 0)

# ---------------------------------------------------------------------------
# S1 — Aktivierung der ersten Wache (role0 'first') von ausserhalb/innerhalb
#      der realen Erkennungsreichweite (enemy.gd: DETECT_X=7.0, DETECT_Z=2.5,
#      Sichtstrahl gegen layer 1).

func _scenario_s1() -> void:
	_reset("first", 8.5, 17.5)
	for i in 30:
		await physics_frame
	var foe = foes["first"]
	var d: float = absf(_dx(foe))
	print("METRO S1_aussen d=%.2f state=%s nach 0.5s" % [d, _st(foe)])
	_check("S1a ausserhalb (d>7): bleibt IDLE", d > 7.0 and _st(foe) == "IDLE",
		"d=%.2f st=%s" % [d, _st(foe)])

	player.global_position = Vector3(foe.global_position.x + 6.0, 0.05, 0)
	player.velocity = Vector3.ZERO
	var st := "IDLE"
	var det_d := 0.0
	for i in 60:
		await physics_frame
		if _st(foe) != "IDLE":
			st = _st(foe)
			det_d = absf(_dx(foe))
			break
	print("METRO S1_innen aktivierung=%s bei_d=%.2f" % [st, det_d])
	_check("S1b innerhalb (d~6): aktiviert (ALERT/CHASE)",
		st == "ALERT" or st == "CHASE", "st=%s d=%.2f" % [st, det_d])
	print("FIND S1 = Erkennung greift real bei ~7 m (QUelle enemy.gd DETECT_X; ALERT 0.5 s Telegraphie, dann CHASE)")

# ---------------------------------------------------------------------------
# S2 — Sprung ueber role0 von links/rechts, frueh gut getimt: Absprung genau
#      bei WINDUP-Eintritt (0.44 s bis SWING; Kontakt +0.075..0.15 s).
#      Hiebzone rel Fussdifferenz: committed_high [1.10..1.55), low [0.05..0.55)
#      je nach Commit; Trefferbedingung enemy.gd _try_swing_hit.
#      Freier Korridor (siehe CONST), damit Plattformkoerper den Pfad nicht
#      blockieren; Positionierung im RESET protokolliert.

func _scenario_s2(side: String) -> void:
	_reset("first", CORR_FOE_X, CORR_LEFT_X if side == "links" else CORR_RIGHT_X)
	var foe = foes["first"]
	for i in 10:
		await physics_frame
	Input.action_press("move_right" if side == "links" else "move_left")
	var launched := false
	var t_press := 0.0
	var min_d := 1e9
	var feet_min := 1e9
	var contact_seen := false
	var crossed := false
	var want_dir := 1.0 if side == "links" else -1.0
	for i in 420:   # max 7 s
		await physics_frame
		var t := _now()
		if not launched:
			if _st(foe) == "WINDUP":
				Input.action_press("jump")   # echte Kante, bis Landung gehalten (kein Jump-Cut)
				launched = true
				t_press = t
				print("METRO S2_%s launch bei WINDUP t=%.3f d=%.2f feet=%.2f" % [
					side, t, absf(_dx(foe)), _rel_feet(foe)])
		else:
			var dt_sw := t - t_press - 0.44   # Kontaktfenster 0.075..0.15 nach SWING-Start
			if dt_sw >= 0.0 and dt_sw <= 0.20:
				contact_seen = true
				feet_min = minf(feet_min, _rel_feet(foe))
			if absf(_dx(foe)) < 2.0:
				min_d = minf(min_d, absf(_dx(foe)))
			if _dx(foe) * want_dir > 0.4:
				crossed = true
			if player.is_on_floor() and t - t_press > 0.3:
				break
		_watch("S2_%s" % side)
	Input.action_release("jump")
	Input.action_release("move_right")
	Input.action_release("move_left")
	var dmg: int = 99 - player.hp
	print("METRO S2_%s dmg=%d feet_min_im_kontaktfenster=%.2f ueberquert=%s min_d=%.2f foe_end=%s" % [
		side, dmg, feet_min, str(crossed), min_d, _st(foe)])
	_check("S2_%s Szenario durchgelaufen" % side, launched and contact_seen,
		"launched=%s contact=%s" % [str(launched), str(contact_seen)])
	if dmg > 0:
		print("FIND B2_%s = Schaden TROTZ frueh gut getimtem Sprung — Mangel reproduziert (BEFUND, kein FAIL)" % side)
	elif crossed:
		print("FIND B2_%s = frueher Sprung ueberspringt Gegner ohne Schaden — B2 fuer FRUEHES Timing NICHT reproduziert" % side)
	else:
		print("FIND B2_%s = kein Schaden, aber nicht ueberquert — Flugbahn/Distanz als Messwert werten" % side)

# ---------------------------------------------------------------------------
# S3 — Vergleichsfall: bewusst SPAETER Sprung (erst 0.30 s nach WINDUP; Spieler
#      dann noch bodennah) gegenueber dem fruehen S2-Sprung.

func _scenario_s3() -> void:
	_reset("first", CORR_FOE_X, CORR_RIGHT_X)
	var foe = foes["first"]
	for i in 20:
		await physics_frame
	var hp0: int = player.hp
	var t_windup := -1.0
	var jumped := false
	var t_press := -1.0
	for i in 420:   # max 7 s
		await physics_frame
		var t := _now()
		if t_windup < 0.0 and _st(foe) == "WINDUP":
			t_windup = t
		if not jumped and t_windup >= 0.0 and t - t_windup >= 0.30:
			Input.action_press("jump")
			jumped = true
			t_press = t
			print("METRO S3 spaeter_jump bei t=%.3f (WINDUP+0.30) feet=%.2f d=%.2f" % [
				t, _rel_feet(foe), absf(_dx(foe))])
		_watch("S3_spaeter")
		if jumped and t - t_press > 1.4:
			break
	Input.action_release("jump")
	print("METRO S3 dmg=%d (hp %d->%d)" % [hp0 - player.hp, hp0, player.hp])
	if hp0 - player.hp > 0:
		print("FIND B1 = Spaeter-Sprung verhindert Schaden NICHT; fruehes Timing (S2) entscheidet — Treffer im aktiven Angriffsfenster, kein Nachweis fuer Kontaktschaden")
	else:
		print("FIND B1 = Spaeter-Sprung ohne Schaden — B1 in diesem Aufbau NICHT reproduziert")

# ---------------------------------------------------------------------------
# S4 — Reale WINDUP/SWING/RECOVERY-Dauern des ERSTEN vollen Zyklus von
#      Duellist (role1) und Brecher (role2) gegen einen nur gehenden Spieler.
#      B4-Zusatz: beim ersten RECOVERY-Eintritt EIN attack-Input (echte Kante);
#      gemessen wird, ob/wann der Gegenschlag trifft (foe.hits_taken steigt)
#      bevor der Gegner wieder in SWING geht.

func _scenario_s4(id: String) -> void:
	var foe = foes[id]
	var start_x: float = foe._spawn_x + 6.5 if id == "duelist" else foe._spawn_x - 5.0
	_reset(id, foe._spawn_x, start_x)
	for i in 10:
		await physics_frame
	Input.action_press("move_left" if id == "duelist" else "move_right")
	var last_st := _st(foe)
	var t_last := _now()
	var cyc: Dictionary = {}
	var b4_pressed := false
	var attack_sent := false
	var t_recovery_start := -1.0
	var t_counter_hit := -1.0
	var hits_prev: int = foe.hits_taken
	for i in 600:   # max 10 s
		await physics_frame
		var t := _now()
		if _st(foe) != last_st:
			if last_st == "WINDUP" or last_st == "SWING" or last_st == "RECOVERY":
				cyc[last_st] = float(cyc.get(last_st, 0.0)) + (t - t_last)
			print("METRO S4_%s %s->%s t=%.3f foe_x=%.2f p_x=%.2f d=%.2f feet_rel=%.2f hits=%d" % [
				id, last_st, _st(foe), t, foe.global_position.x,
				player.global_position.x, absf(_dx(foe)), _rel_feet(foe), foe.hits_taken])
			var leaving_recovery := last_st == "RECOVERY" and cyc.has("WINDUP")
			if _st(foe) == "RECOVERY" and not b4_pressed and cyc.has("WINDUP") and cyc.has("SWING"):
				b4_pressed = true
				t_recovery_start = t
				# Fairer Konter: aktiv auf den Gegner zugehen und in Reichweite
				# angreifen (echte Kanten). Nur Stillstand-Attacke aus 4 m Distanz
				# waere ein Reichweitenartefakt, kein Kontereffekt.
				Input.action_release("move_left")
				Input.action_release("move_right")
				Input.action_press("move_left" if _dx(foe) > 0.0 else "move_right")
				print("METRO S4_%s B4 counter bei RECOVERY-Start t=%.3f d=%.2f (Geher + Attacke in d<1.2)" % [
					id, t, absf(_dx(foe))])
			last_st = _st(foe)
			t_last = t
			if leaving_recovery:
				break
		if b4_pressed and t_counter_hit < 0.0 and foe.hits_taken > hits_prev:
			t_counter_hit = t
		if b4_pressed and not attack_sent and absf(_dx(foe)) < 1.2:
			attack_sent = true
			Input.action_press("attack")
			await physics_frame
			await physics_frame
			Input.action_release("attack")
			print("METRO S4_%s B4 attack-Kante bei d=%.2f t=%.3f" % [id, absf(_dx(foe)), _now()])
		_watch("S4_%s" % id)
	# Nachlauf: Gegenschlag kann nach RECOVERY-Ende treffen, bis der naechste
	# SWING beginnt — dann war das Konterfenster zu langsam.
	if b4_pressed and t_counter_hit < 0.0:
		for i in 150:   # max 2.5 s
			await physics_frame
			if foe.hits_taken > hits_prev:
				t_counter_hit = _now()
				break
			if not attack_sent and absf(_dx(foe)) < 1.2:
				attack_sent = true
				Input.action_press("attack")
				await physics_frame
				await physics_frame
				Input.action_release("attack")
				print("METRO S4_%s B4 attack-Kante bei d=%.2f t=%.3f" % [id, absf(_dx(foe)), _now()])
				continue
			if _st(foe) == "SWING":
				t_counter_hit = -99.0
				break
			_watch("S4_%s" % id)
	Input.action_release("move_left")
	Input.action_release("move_right")
	Input.action_release("attack")
	print("METRO S4_%s erster_Zyklus windup=%.3f swing=%.3f recovery=%.3f (Frame-Raster 1/60)" % [
		id, float(cyc.get("WINDUP", -1.0)), float(cyc.get("SWING", -1.0)),
		float(cyc.get("RECOVERY", -1.0))])
	_check("S4_%s Timings gemessen (>=1 voller Zyklus)" % id,
		cyc.has("WINDUP") and cyc.has("SWING") and cyc.has("RECOVERY"),
		"keys=%s" % str(cyc.keys()))
	if t_counter_hit > 0.0:
		print("FIND B4_%s = Gegenschlag bei RECOVERY-Start trifft nach %.3f s (vor naechster Gefahr)" % [id, t_counter_hit - t_recovery_start])
	elif t_counter_hit == -99.0:
		print("FIND B4_%s = Gegenschlag bei RECOVERY-Start trifft NICHT vor naechstem SWING — Konter praktisch nicht moeglich (BEFUND)" % id)
	else:
		print("FIND B4_%s = Kontermessung ohne naechste SWING-Gefahr abgeschlossen — uneindeutig" % id)

# ---------------------------------------------------------------------------
# S5 — SICHERHEITSTRAKT: Maximum paralleler WINDUP/SWING-Zustaende bei kurzer
#      Traversal (Spieler laeuft rechts durch, greift nicht an).
#      Quellregel enemy.gd _can_attack(): blockiert erst ab 2 anderen
#      WINDUP/SWING innerhalb 8 m -> lokal maximal 2 neu zugelassene Angreifer (sequentielle Auswertung).

func _scenario_s5() -> void:
	_reset("first", 8.5, 36.5)
	for i in 10:
		await physics_frame
	Input.action_press("move_right")
	var hp0: int = player.hp
	var max_par := 0
	var max_par_names := ""
	var min_d := 1e9
	for i in 420:   # max 7 s
		await physics_frame
		var par := 0
		var names: Array[String] = []
		for id in foes:
			var e = foes[id]
			if e._dead:
				continue
			if e._state == 3 or e._state == 4:   # WINDUP, SWING
				par += 1
				names.append(id)
			var d: float = absf(player.global_position.x - e.global_position.x)
			if d < min_d:
				min_d = d
		if par > max_par:
			max_par = par
			max_par_names = ",".join(names)
		_watch("S5_traversal")
		if player.global_position.x > 51.0:
			break
	Input.action_release("move_right")
	print("METRO S5 max_parallel_windup_swing=%d (%s) end_x=%.1f dmg=%d min_d=%.2f" % [
		max_par, max_par_names, player.global_position.x, hp0 - player.hp, min_d])
	_check("S5 Traversal durchgelaufen", player.global_position.x > 50.99,
		"x=%.1f par=%d" % [player.global_position.x, max_par])
	if max_par >= 2:
		print("FIND B3 = %d Gegner gleichzeitig in WINDUP/SWING (BEFUND; Quellregel _can_attack laesst bis 2 parallel zu)" % max_par)
	else:
		print("FIND B3 = maximal %d parallel in WINDUP/SWING beobachtet" % max_par)
