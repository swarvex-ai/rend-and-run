extends SceneTree
## E6 — Saved options reach the FX autoload and the accessibility switches really
## switch screen shake and slow motion off. Uses a test settings path so the real
## user://settings.cfg is never touched.
const STORE = preload("res://modules/persistence/settings_store.gd")
const PATH := "user://accessibility_test.cfg"
var failures := 0

func check(label: String, ok: bool) -> void:
	print("ACCESS ", "PASS " if ok else "FAIL ", label)
	if not ok: failures += 1

func apply_settings(changes: Dictionary) -> void:
	var s = STORE.new()
	s.load_from(PATH)
	for key in changes:
		s.set_value(key, changes[key])
	s.save_to(PATH)
	var fresh = STORE.new()
	fresh.load_from(PATH)
	fresh.apply()

func run() -> void:
	if not OS.get_user_data_dir().begins_with("/tmp/"): quit(2); return
	var fx = root.get_node("FX")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))

	apply_settings({"screen_shake": false})
	check("saved screen_shake=false reaches FX", not fx.screen_shake_enabled)
	fx.shake = 0.0
	fx.add_shake(1.0)
	check("shake off leaves fx.shake at 0", fx.shake == 0.0)

	apply_settings({"screen_shake": true})
	check("saved screen_shake=true reaches FX", fx.screen_shake_enabled)
	fx.shake = 0.0
	fx.add_shake(1.0)
	check("shake on raises fx.shake", fx.shake > 0.0)

	apply_settings({"slow_motion": false})
	check("saved slow_motion=false reaches FX", not fx.slow_motion_enabled)
	Engine.time_scale = 1.0
	var hits := int(fx.fx_stats["hitstop"])
	fx.hitstop(0.1)
	check("slow motion off leaves time_scale at 1.0", is_equal_approx(Engine.time_scale, 1.0))
	check("hitstop still counted with slow motion off", int(fx.fx_stats["hitstop"]) == hits + 1)

	apply_settings({"slow_motion": true})
	check("saved slow_motion=true reaches FX", fx.slow_motion_enabled)
	Engine.time_scale = 1.0
	fx.hitstop(0.1)
	check("slow motion on drops time_scale below 1.0", Engine.time_scale < 1.0)
	Engine.time_scale = 1.0

	apply_settings({"subtitles": false})
	check("subtitles flag follows saved false", not fx.subtitles_enabled)

	apply_settings({"master_volume": 40})
	var fresh = STORE.new()
	fresh.load_from(PATH)
	fresh.apply()
	check("saved master_volume 40 is applied on start", is_equal_approx(AudioServer.get_bus_volume_db(0), STORE.volume_db(40)))

	fx.screen_shake_enabled = true
	fx.slow_motion_enabled = true
	fx.subtitles_enabled = true
	Engine.time_scale = 1.0
	AudioServer.set_bus_volume_db(0, 0.0)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	print("ACCESS SUMMARY failures=", failures)
	quit(1 if failures else 0)

func _initialize() -> void:
	call_deferred("run")
