extends SceneTree
# H65 Smoke — Headless-Test fuer attack_cadence.gd (res://modules/combat/attack_cadence.gd).
# Reine Datenlogik; Start deferred; SUMMARY gibt den Laufzeit-Zaehler aus.

var checks := 0
var failures := 0

func _chk(ok: bool, label: String) -> void:
	checks += 1
	if ok:
		print("PASS " + label)
	else:
		failures += 1
		print("FAIL " + label)

func _initialize() -> void:
	call_deferred("_run_all")

func _run_all() -> void:
	await process_frame
	var mod = preload("res://modules/combat/attack_cadence.gd").new()

	# 1) Erste gueltige Beanspruchung gelingt.
	_chk(mod.try_claim(0.0) == true, "first_claim_succeeds")
	_chk(mod.active_count() == 1, "active_count_after_first")

	# 2) Gegenlaeufige Urspruenge im selben Tick: zweiter wird abgelehnt.
	mod.reset()
	var a: bool = mod.try_claim(-3.0)
	var b: bool = mod.try_claim(3.0)
	_chk(a and not b, "opposed_same_tick_second_denied")

	# 3) Genau 8.0 Abstand ist unabhaengig; 7.999 nicht.
	mod.reset()
	_chk(mod.try_claim(0.0), "origin_zero")
	_chk(mod.try_claim(8.0), "exactly_8_independent")
	_chk(not mod.try_claim(7.999), "just_under_8_denied")

	# 4) Kurz vor Ablauf bleibt die Sperre; bei 0.12 ist sie abgelaufen.
	mod.reset()
	mod.try_claim(0.0)
	mod.advance(0.10)
	_chk(not mod.try_claim(1.0), "blocked_before_expiry")
	mod.advance(0.02)
	_chk(mod.try_claim(1.0), "independent_at_expiry")

	# 5) Abgelehnte Beanspruchung verlaengert keine Sperre:
	#    haette die Ablehnung bei t=0.10 die Sperre bis 0.22 neu gestartet,
	#    muesste die Beanspruchung bei t=0.121 noch fehlschlagen.
	mod.reset()
	mod.try_claim(0.0)          # Sperre bis t=0.12
	mod.advance(0.10)
	_chk(not mod.try_claim(5.0), "reject_inside_window")
	mod.advance(0.021)
	_chk(mod.try_claim(2.0), "rejected_claim_did_not_extend")

	# 6) Weit entfernte Urspruenge sind unabhaengig.
	mod.reset()
	_chk(mod.try_claim(0.0) and mod.try_claim(100.0) and mod.try_claim(-100.0), "distant_origins_independent")
	_chk(mod.active_count() == 3, "count_three_distant")

	# 7) reset() leert alles.
	mod.reset()
	_chk(mod.active_count() == 0, "reset_clears")
	_chk(mod.try_claim(0.0), "claim_after_reset")

	# 8) Kapazitaet 32: der 33. wird abgelehnt; kein lebender Eintrag weicht.
	mod.reset()
	var cap_ok := true
	for i in 33:
		var got: bool = mod.try_claim(float(i) * 8.0)
		if i < 32 and not got:
			cap_ok = false
		if i == 32 and got:
			cap_ok = false
	_chk(cap_ok, "cap_first_32_last_denied")
	_chk(mod.active_count() == 32, "cap_stays_32")
	_chk(not mod.try_claim(2000.0), "cap_full_denies_even_far_origin")
	_chk(mod.active_count() == 32, "cap_no_eviction_of_live")

	# 9) Nach Ablauf gibt die Kapazitaet wieder frei.
	mod.advance(0.125)
	_chk(mod.try_claim(2000.0), "cap_frees_after_expiry")

	# 10) advance(): negativ und NAN verderben die Zeit nicht.
	mod.reset()
	mod.try_claim(0.0)
	mod.advance(-1.0)
	mod.advance(0.12)
	_chk(mod.try_claim(1.0), "negative_delta_ignored")
	mod.reset()
	mod.try_claim(0.0)
	mod.advance(NAN)
	mod.advance(0.05)
	_chk(not mod.try_claim(1.0), "nan_delta_no_advance")
	mod.advance(0.07)
	_chk(mod.try_claim(1.0), "nan_delta_time_recovers")

	# 11) Quelltext-Scan: keine Uhr, keine Szenenankopplung, keine Klassendeklaration.
	var f: FileAccess = FileAccess.open("res://modules/combat/attack_cadence.gd", FileAccess.READ)
	var src := ""
	if f != null:
		src = f.get_as_text()
		f.close()
	_chk(src.length() > 100, "source_readable")
	_chk(not src.contains("class_name"), "no_class_name")
	_chk(not src.contains("static var"), "no_static_data")
	_chk(not src.contains("OS.get_ticks"), "no_os_clock")
	_chk(not src.contains("Time.get_ticks"), "no_time_clock")
	_chk(not src.contains("_process("), "no_frame_callback")
	_chk(not src.contains("SceneTree"), "no_scene_tree_ref")
	_chk(not src.contains("Timer"), "no_timer")

	print("SUMMARY checks=%d failures=%d" % [checks, failures])
	quit(1 if failures > 0 else 0)
