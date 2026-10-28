extends SceneTree
## H48 — eigenstaendiger Test fuer recovery_step.gd (Scratch-Baum, kein Spielcode).
## Abdeckung: beide Richtungen, Ablauf, Teilframe-Exaktheit (viele kleine Frames,
## ein einziger Riesen-frame, Grenze), cancel, Restart, ungueltige/nichtfinite
## Eingaben, negatives/harmloses delta, Node-/Ressourcen-Freiheit.
## Aufruf: godot --headless --path <scratch> --script res://h48_recovery_check.gd
## Nachweis: 'SUMMARY checks=N failures=0' und Exit-Code 0.

const RS := preload("res://modules/combat/recovery_step.gd")

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

	# --- 1) Gueltiger Start: Richtung entgegen committetem front ---
	var r: RefCounted = RS.new()
	_ok(not r.is_active(), "frisch_inaktiv")
	_ok(r.start(1.0), "start_front_plus_ok")
	_ok(r.is_active(), "start_aktiv")
	var v: float = r.advance(0.016)
	_ok(v < 0.0, "front_plus_rueckt_negativ", "v=%f" % v)
	r.cancel()
	_ok(r.start(-1.0), "start_front_minus_ok")
	v = r.advance(0.016)
	_ok(v > 0.0, "front_minus_rueckt_positiv", "v=%f" % v)

	# Richtung FIXIERT: spaeterer front-Wechsel wirkt nicht (kein Homing)
	r.cancel()
	_ok(r.start(1.0, 2.8, 0.5), "start_fixierung")
	var v1: float = r.advance(0.016)
	_ok(v1 < 0.0, "fixierung_negativ", "v=%f" % v1)
	r.cancel()

	# --- 2) Ablauf nach duration ---
	r.start(1.0, 2.8, 0.18)
	var t := 0.0
	var frames := 0
	while r.is_active() and t < 1.0:
		r.advance(0.01)
		t += 0.01
		frames += 1
	_ok(not r.is_active(), "nach_duration_inaktiv", "frames=%d t=%f" % [frames, t])
	_ok(frames == 18, "genau_erwartete_framezahl", "frames=%d" % frames)
	_ok(is_equal_approx(r.advance(0.01), 0.0), "nach_ablauf_liefert_0")

	# --- 3) Teilframe: integrierte Strecke ueberschreitet nie speed*duration ---
	var speed := 2.8
	var dur := 0.18
	var budget := speed * dur
	# 3a) viele kleine Frames (0.01 passt 18x, letzter Teilframe 0.0000...: exakt 0.18/0.01)
	r.start(1.0, speed, dur)
	var acc := 0.0
	for i in range(40):
		acc += absf(r.advance(0.01)) * 0.01
	_ok(absf(acc - budget) < 1e-9, "summe_gleich_budget_kleine_frames", "acc=%.12f budget=%.12f" % [acc, budget])
	# 3b) NICHT-exakte Teilung: 0.18/0.016 = 11.25 -> 11 volle + 1 Teilframe
	r.start(1.0, speed, dur)
	acc = 0.0
	var n := 0
	while r.is_active() and n < 100:
		acc += absf(r.advance(0.016)) * 0.016
		n += 1
	_ok(n == 12, "12_frame_mit_teilframe", "n=%d" % n)
	_ok(absf(acc - budget) < 1e-9, "summe_gleich_budget_teilframe", "acc=%.12f budget=%.12f" % [acc, budget])
	_ok(absf(r.distance_traveled() - budget) < 1e-9, "distance_traveled_exakt", "d=%.12f" % r.distance_traveled())
	# 3c) EIN einziger Riesen-frame: Strecke = budget, nie mehr
	r.start(1.0, speed, dur)
	var big := 5.0
	v = r.advance(big)
	acc = absf(v) * big
	_ok(absf(acc - budget) < 1e-9, "riesenframe_exakt_budget", "acc=%.12f" % acc)
	_ok(not r.is_active(), "riesenframe_beendet")
	_ok(absf(r.advance(0.01)) < 1e-12, "riesenframe_danach_0")

	# --- 4) cancel ---
	r.start(1.0, 2.8, 0.5)
	r.advance(0.01)
	r.cancel()
	_ok(not r.is_active(), "cancel_inaktiv")
	_ok(r.advance(0.016) == 0.0, "cancel_danach_0")
	_ok(is_equal_approx(r.distance_traveled(), 2.8 * 0.01), "cancel_strecke_eingefroren", "d=%f" % r.distance_traveled())

	# --- 5) Restart ersetzt Zustand komplett ---
	r.start(-1.0, 1.0, 0.1)     # positive Richtung, langsam
	r.advance(0.02)
	_ok(r.start(1.0, 5.0, 0.2), "restart_ok")
	v = r.advance(0.02)
	_ok(v < 0.0, "restart_richtung_neu", "v=%f" % v)
	acc = absf(v) * 0.02
	_ok(is_equal_approx(acc, 5.0 * 0.02), "restart_speed_neu", "acc=%f" % acc)
	r.cancel()

	# --- 6) Ungueltige Eingaben sicher abgelehnt, Zustand unveraendert ---
	r.start(1.0, 2.8, 0.18)     # laufender Bezugszustand
	var v_before: float = r.advance(0.01)
	_ok(not r.start(0.0), "front_0_abgelehnt")
	_ok(not r.start(NAN), "front_nan_abgelehnt")
	_ok(not r.start(INF), "front_inf_abgelehnt")
	_ok(not r.start(1.0, NAN, 0.18), "speed_nan_abgelehnt")
	_ok(not r.start(1.0, -1.0, 0.18), "speed_negativ_abgelehnt")
	_ok(not r.start(1.0, 2.8, 0.0), "duration_0_abgelehnt")
	_ok(not r.start(1.0, 2.8, NAN), "duration_nan_abgelehnt")
	_ok(r.is_active(), "ablehnungen_lassen_laufend_aktiv")
	# Richtung/Takt unveraendert: naechster Frame weiter negativ, gleiche Groesse
	v = r.advance(0.01)
	_ok(is_equal_approx(v, v_before), "abgelehnter_start_ohne_wirkung", "%f vs %f" % [v, v_before])
	r.cancel()

	# --- 7) delta-edgefaelle harmless ---
	r.start(1.0, 2.8, 0.18)
	_ok(r.advance(-0.5) == 0.0, "negatives_delta_0")
	_ok(r.is_active(), "negatives_delta_haelt_aktiv")
	_ok(r.advance(NAN) == 0.0, "nan_delta_0")
	_ok(r.advance(INF) == 0.0, "inf_delta_0")
	_ok(r.advance(0.0) == 0.0, "null_delta_0")
	# Takt steht still: danach normaler Schritt voller Geschwindigkeit
	v = r.advance(0.01)
	_ok(is_equal_approx(absf(v), 2.8), "delta_0_ohne_taktverlust", "v=%f" % v)
	r.cancel()

	# --- 8) Kein Node-/Ressourcen-Bedarf: funktioniert ohne Baum komplett ---
	var orphan: RefCounted = RS.new()
	_ok(orphan.start(1.0), "orphan_start")
	var ov: float = orphan.advance(0.05)
	_ok(absf(ov + 2.8) < 1e-6, "orphan_advance", "v=%f" % ov)

	print("SUMMARY checks=", _checks, " failures=", _failures)
	quit(1 if _failures > 0 else 0)
