extends SceneTree
## Contract test for the settings store (game/modules/persistence/settings_store.gd):
## defaults, validation, save and reload, broken files, audio buses, and that the route
## save is never touched.
const STORE = preload("res://modules/persistence/settings_store.gd")
const PATH := "user://settings_store_test.cfg"
var failures := 0

func check(label: String, ok: bool) -> void:
	print("SETTINGS ", "PASS " if ok else "FAIL ", label)
	if not ok: failures += 1

func _initialize() -> void:
	if not OS.get_user_data_dir().begins_with("/tmp/"): quit(2); return
	var s = STORE.new()
	s.load_from(PATH)
	check("missing file gives the defaults", s.values == STORE.DEFAULTS)
	check("defaults from decision 0002", s.get_value("master_volume") == 100 and s.get_value("music_volume") == 70 and s.get_value("effects_volume") == 85 and s.get_value("voices_volume") == 90 and s.get_value("vsync") and s.get_value("subtitles") and s.get_value("slow_motion") and s.get_value("screen_shake"))
	check("volume snaps to steps of 5", s.set_value("music_volume", 43) and s.get_value("music_volume") == 45)
	check("volume clamps to 0..100", s.set_value("effects_volume", 140) and s.get_value("effects_volume") == 100 and s.set_value("voices_volume", -5) and s.get_value("voices_volume") == 0)
	check("window mode accepts only known modes", s.set_value("window_mode", "fullscreen") and not s.set_value("window_mode", "huge") and s.get_value("window_mode") == "fullscreen")
	check("switches accept only bool", s.set_value("screen_shake", false) and not s.set_value("subtitles", "no") and s.get_value("subtitles") == true)
	check("unknown keys are refused", not s.set_value("key_rebinding", true) and not s.values.has("key_rebinding"))
	check("save returns OK", s.save_to(PATH) == OK)
	var fresh = STORE.new();fresh.load_from(PATH)
	check("reload restores every saved value", fresh.values == s.values)
	var broken := FileAccess.open(PATH, FileAccess.WRITE);broken.store_string("[settings]\nmusic_volume=\"loud\"\nvsync=7\nwindow_mode=\"huge\"\n[[[broken");broken.close()
	var after_break = STORE.new();after_break.load_from(PATH)
	check("broken file falls back to the defaults", after_break.values == STORE.DEFAULTS)
	var bad_values := ConfigFile.new();bad_values.set_value("settings", "music_volume", "loud");bad_values.set_value("settings", "master_volume", 55);bad_values.save(PATH)
	var partial = STORE.new();partial.load_from(PATH)
	check("bad values fall back per key", partial.get_value("music_volume") == 70 and partial.get_value("master_volume") == 55)
	s.set_value("master_volume", 100);s.set_value("music_volume", 0);s.set_value("voices_volume", 50)
	s.apply()
	var music := AudioServer.get_bus_index("Music");var voice := AudioServer.get_bus_index("Voice")
	check("apply creates the Music and Voice buses", music >= 0 and voice >= 0 and AudioServer.get_bus_send(music) == &"Master" and AudioServer.get_bus_send(voice) == &"Master")
	check("apply sets bus volumes", is_equal_approx(AudioServer.get_bus_volume_db(0), 0.0) and AudioServer.is_bus_mute(music) and is_equal_approx(AudioServer.get_bus_volume_db(voice), linear_to_db(0.5)))
	var buses_before := AudioServer.bus_count;s.apply()
	check("apply twice adds no extra buses", AudioServer.bus_count == buses_before)
	check("settings never touch the route save", not FileAccess.file_exists("user://rendrun_route_v12.json"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	print("SETTINGS SUMMARY failures=", failures)
	quit(1 if failures else 0)
