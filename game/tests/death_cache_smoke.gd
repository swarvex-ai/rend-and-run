extends SceneTree
# H67 Smoke — Headless-Test fuer death_cache.gd (res://modules/loot/death_cache.gd).
# Reine Datenlogik; deferred Start; SUMMARY mit Laufzeit-Zaehler.

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
	var c = preload("res://modules/loot/death_cache.gd").new()

	# Startzustand
	_chk(c.amount() == 0 and not c.is_active(), "starts_empty")
	_chk(c.position() == Vector3.ZERO, "starts_zero_pos")
	_chk(c.take() == 0, "take_on_empty_is_zero")

	# Gueltige Ersetzung + Ersetzen eines aelteren Depots
	_chk(c.replace(42, Vector3(1.5, 0.0, -2.0)), "replace_valid")
	_chk(c.amount() == 42 and c.is_active(), "state_after_replace")
	_chk(c.replace(7, Vector3(9.0, 1.0, 9.0)), "replace_older_cache")
	_chk(c.amount() == 7 and c.position().is_equal_approx(Vector3(9.0, 1.0, 9.0)), "older_cache_replaced")

	 # Tod mit 0 entfernt altes Depot
	_chk(c.replace(0, Vector3(5.0, 0.0, 5.0)) and not c.is_active() and c.amount() == 0, "zero_death_removes_old")

	# Ablehnungen ohne jede Zustandsaenderung
	c.reset(); c.replace(10, Vector3(2.0, 0.0, 2.0))
	var rejected := true
	rejected = rejected and not c.replace(-1, Vector3.ONE)
	rejected = rejected and not c.replace(1000000, Vector3.ONE)
	rejected = rejected and not c.replace(5, Vector3(INF, 0.0, 0.0))
	rejected = rejected and not c.replace(5, Vector3(NAN, NAN, NAN))
	_chk(rejected, "invalid_replacements_denied")
	_chk(c.amount() == 10 and c.position().is_equal_approx(Vector3(2.0, 0.0, 2.0)) and c.is_active(), "rejections_did_not_mutate")
	_chk(c.replace(999999, Vector3.ONE), "max_amount_inrange")
	_chk(c.replace(0, Vector3.ONE) and c.replace(999999, Vector3.ONE), "max_amount_twice_ok")

	# take genau einmal
	c.reset(); c.replace(25, Vector3(4.0, 0.0, 4.0))
	_chk(c.take() == 25, "take_returns_amount")
	_chk(not c.is_active() and c.amount() == 0 and c.take() == 0, "take_clears_state")

	# reset
	c.replace(50, Vector3.ONE); c.reset()
	_chk(not c.is_active() and c.amount() == 0 and c.position() == Vector3.ZERO, "reset_clears")

	# Export: JSON-sicher, kein Vector3-Wert, Zero -> kanonischer Nullpunkt
	c.reset(); c.replace(33, Vector3(1.25, 0.5, -7.75))
	var ex: Dictionary = c.export_state()
	_chk(typeof(ex["amount"]) == TYPE_INT and ex["amount"] == 33, "export_amount_int")
	_chk(ex["position"] is Array and (ex["position"] as Array).size() == 3, "export_position_array3")
	c.replace(0, Vector3.ONE)
	var exz: Dictionary = c.export_state()
	_chk(exz["position"] == [0.0, 0.0, 0.0], "export_zero_canonical")

	# JSON-Hin-und-Rueckrunde (String-Umweg, wie Save-Datei)
	c.reset(); c.replace(64, Vector3(3.5, 2.0, -1.5))
	var rt = JSON.parse_string(JSON.stringify(c.export_state()))
	var c2 = preload("res://modules/loot/death_cache.gd").new()
	_chk(c2.import_state(rt), "json_roundtrip_imports")
	_chk(c2.amount() == 64 and c2.position().is_equal_approx(Vector3(3.5, 2.0, -1.5)) and c2.is_active(), "json_roundtrip_values")

	# Import-Ablehnungen ohne Mutierung (Referenzzustand vorher)
	var good := {"amount": 11, "position": [1.0, 2.0, 3.0]}
	_chk(c2.import_state(good), "import_good")
	var bad_inputs: Array = [
		null, 5.0, "x", [],
		{"amount": 5},                                   # position fehlt
		{"position": [1.0, 2.0, 3.0]},                   # amount fehlt
		{"amount": -1, "position": [0.0, 0.0, 0.0]},     # negativ
		{"amount": 1000000, "position": [0.0, 0.0, 0.0]},# ueber Grenze
		{"amount": 3.5, "position": [0.0, 0.0, 0.0]},    # nicht ganzzahlig
		{"amount": NAN, "position": [0.0, 0.0, 0.0]},    # nicht endlich
		{"amount": INF, "position": [0.0, 0.0, 0.0]},    # nicht endlich
		{"amount": "9", "position": [0.0, 0.0, 0.0]},    # String-Betrag
		{"amount": 9, "position": [1.0, 2.0]},           # zu wenig Koordinaten
		{"amount": 9, "position": [1.0, 2.0, 3.0, 4.0]}, # zu viele
		{"amount": 9, "position": [1.0, INF, 3.0]},      # nicht-endliche Koordinate
		{"amount": 9, "position": [1.0, "z", 3.0]},      # Nicht-Zahl-Koordinate
		{"amount": 9, "position": Vector3.ONE},           # Vector3 statt Array
	]
	var all_bad := true
	for b in bad_inputs:
		if c2.import_state(b):
			all_bad = false
	_chk(all_bad, "all_invalid_imports_rejected")
	_chk(c2.amount() == 11 and c2.position().is_equal_approx(Vector3(1.0, 2.0, 3.0)) and c2.is_active(), "bad_imports_no_mutation")

	# Betrag 0 im Import kanonisiert Position
	_chk(c2.import_state({"amount": 0, "position": [7.0, 8.0, 9.0]}), "import_zero_ok")
	_chk(not c2.is_active() and c2.position() == Vector3.ZERO, "import_zero_canonicalizes")

	# Import mit Float-Betrag 12.0 (JSON-typisch) akzeptiert
	_chk(c2.import_state({"amount": 12.0, "position": [0.0, 1.0, 0.0]}), "import_float_integral_ok")
	_chk(c2.amount() == 12, "import_float_amount_int")

	# Quelltext-Verbote
	var f: FileAccess = FileAccess.open("res://modules/loot/death_cache.gd", FileAccess.READ)
	var src := ""
	if f != null:
		src = f.get_as_text()
		f.close()
	_chk(src.length() > 100, "source_readable")
	# Deklarationsform pruefen (einzelne Code-Zeile), nicht Substring —
	# der Modul-Kommentar erwaehnt das Wort 'class_name' erlaeuternd.
	var has_class_decl := false
	for line in src.split("\n"):
		if line.lstrip(" 	").begins_with("class_name"):
			has_class_decl = true
	_chk(not has_class_decl, "no_class_name")
	_chk(not src.contains("static var") and not src.contains("static func"), "no_statics")
	_chk(not src.contains("Timer") and not src.contains("_process("), "no_nodes_or_frames")
	_chk(not src.contains("OS.get_ticks") and not src.contains("Time.get_ticks"), "no_system_clock")

	print("SUMMARY checks=%d failures=%d" % [checks, failures])
	quit(1 if failures > 0 else 0)
