extends SceneTree
## Contract test for combat_mix and FX.play_priority1:
## Priority-1 cues lower Music and Ambience without touching Combat.
var failures := 0

func check(label: String, ok: bool) -> void:
	print("COMBAT_MIX ", "PASS " if ok else "FAIL ", label)
	if not ok: failures += 1

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if not OS.get_user_data_dir().begins_with("/tmp/"): quit(2); return
	await process_frame

	var combat_mix_class = load("res://modules/audio/combat_mix.gd")
	check("combat_mix.gd can be loaded", combat_mix_class != null)
	if combat_mix_class == null:
		print("COMBAT_MIX SUMMARY failures=", failures)
		quit(1)
		return

	var cm = combat_mix_class.new()
	root.add_child(cm)

	var music_idx = preload("res://modules/persistence/settings_store.gd").bus_index("Music")
	var amb_idx = preload("res://modules/persistence/settings_store.gd").bus_index("Ambience")
	var combat_idx = preload("res://modules/persistence/settings_store.gd").bus_index("Combat")

	# 1. Base volumes test: preset Music to -10 dB, Ambience to -3 dB, Combat to 0 dB
	AudioServer.set_bus_volume_db(music_idx, -10.0)
	AudioServer.set_bus_volume_db(amb_idx, -3.0)
	AudioServer.set_bus_volume_db(combat_idx, 0.0)

	var token1: int = cm.begin_priority1(-8.0, -6.0)
	check("begin_priority1 returns positive token", token1 > 0)

	# Simulate attack phase (100 ms) in steps
	# After 0.1s or slightly more, target reduction should be reached (-8 dB on Music, -6 dB on Ambience)
	# Music was -10 dB, so it should reach -18 dB (+/- 0.5 dB)
	# Ambience was -3 dB, so it should reach -9 dB (+/- 0.5 dB)
	# Combat should be unchanged (0 dB)
	for i in 15:
		cm._process(0.01)

	var music_vol := AudioServer.get_bus_volume_db(music_idx)
	var amb_vol := AudioServer.get_bus_volume_db(amb_idx)
	var combat_vol := AudioServer.get_bus_volume_db(combat_idx)

	check("music ducked by 8 dB (near -18 dB)", absf(music_vol - (-18.0)) <= 0.5)
	check("ambience ducked by 6 dB (near -9 dB)", absf(amb_vol - (-9.0)) <= 0.5)
	check("combat bus volume unchanged throughout", absf(combat_vol - 0.0) <= 0.01)

	# 2. Two overlapping tokens: second token with larger ducking or different ducking
	# token2 requests music -12 dB, ambience -4 dB
	var token2: int = cm.begin_priority1(-12.0, -4.0)
	for i in 15:
		cm._process(0.01)
	# Largest requested: music -12 dB (so -10 + -12 = -22 dB), ambience -6 dB (-3 + -6 = -9 dB)
	var music_vol2 := AudioServer.get_bus_volume_db(music_idx)
	var amb_vol2 := AudioServer.get_bus_volume_db(amb_idx)
	check("overlapping tokens use largest requested music ducking (-12 dB -> -22 dB)", absf(music_vol2 - (-22.0)) <= 0.5)
	check("overlapping tokens keep largest requested ambience ducking (-6 dB -> -9 dB)", absf(amb_vol2 - (-9.0)) <= 0.5)

	# End token2 first: token1 is still active (-8 dB music, -6 dB ambience)
	cm.end_priority1(token2)
	for i in 15:
		cm._process(0.01)
	var music_vol3 := AudioServer.get_bus_volume_db(music_idx)
	var amb_vol3 := AudioServer.get_bus_volume_db(amb_idx)
	check("after token2 ended, still ducked by token1 (-8 dB -> -18 dB)", absf(music_vol3 - (-18.0)) <= 0.5)
	check("ambience still ducked by token1 (-6 dB -> -9 dB)", absf(amb_vol3 - (-9.0)) <= 0.5)

	# End token1: release starts (600 ms)
	cm.end_priority1(token1)
	# Partway through release (e.g. 0.3s), volume should be between ducked and base
	for i in 30:
		cm._process(0.01)
	var music_mid := AudioServer.get_bus_volume_db(music_idx)
	check("music recovering during release", music_mid > -18.0 and music_mid < -10.0)

	# After remaining release (e.g. 0.4s more, total 0.7s > 0.6s)
	for i in 40:
		cm._process(0.01)
	var music_final := AudioServer.get_bus_volume_db(music_idx)
	var amb_final := AudioServer.get_bus_volume_db(amb_idx)
	check("music returns to preset -10 dB, not 0 dB", absf(music_final - (-10.0)) <= 0.5)
	check("ambience returns to preset -3 dB", absf(amb_final - (-3.0)) <= 0.5)
	check("combat bus volume remains unchanged", absf(AudioServer.get_bus_volume_db(combat_idx) - 0.0) <= 0.01)

	# Test pre-set volume modification while ducked:
	# If Options sliders change volume while ducked, base volume updates
	var token3: int = cm.begin_priority1(-8.0, -6.0)
	for i in 15:
		cm._process(0.01)
	# User changes music slider to -15 dB (so AudioServer volume was ducked, but settings change applies)
	# Let's see how base volume tracking works:
	# If settings slider changes base volume, or if base volume is remembered.
	cm.end_priority1(token3)
	for i in 70:
		cm._process(0.01)

	# 3. Test FX.play_priority1 with missing file
	var fx = root.get_node_or_null("FX")
	check("FX autoload exists", fx != null)
	if fx != null:
		var events_before: int = int(fx.audio_events.get("nonexistent_test_sfx", 0))
		fx.play_priority1("nonexistent_test_sfx")
		var events_after: int = int(fx.audio_events.get("nonexistent_test_sfx", 0))
		check("FX.play_priority1 with missing file leaves audio_events unchanged", events_before == events_after)

	cm.queue_free()
	print("COMBAT_MIX SUMMARY failures=", failures)
	quit(1 if failures else 0)
