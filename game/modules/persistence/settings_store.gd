extends RefCounted
## Player settings (audio volumes, window, accessibility), stored in user://settings.cfg.
## Separate from the route save: a settings change never touches rendrun_route_v12.json.
## Values and defaults follow docs/design/menus/style-guide-variant-2.md (Options screen)
## with the defaults from docs/decisions/0002-menu-style-guide.md.
##
## Use:
##   var settings = preload("res://modules/persistence/settings_store.gd").new()
##   settings.load_from()            # missing or broken file -> defaults
##   settings.set_value("music_volume", 40)
##   settings.apply()                # audio buses, window mode, VSync
##   settings.save_to()              # -> OK or an Error code
## Changes apply and save immediately in the menu; there is no Apply button.

const PATH := "user://settings.cfg"
const SECTION := "settings"
const VOLUME_STEP := 5
const WINDOW_MODES := ["windowed", "borderless", "fullscreen"]
const DEFAULTS := {
	"master_volume": 100,
	"music_volume": 70,
	"effects_volume": 85,
	"voices_volume": 90,
	"window_mode": "windowed",
	"vsync": true,
	"subtitles": true,
	"slow_motion": true,
	"screen_shake": true,
}
# Volume key -> audio bus. Music and Voice are created on demand; effects play on Combat.
const BUSES := {"master_volume": "Master", "music_volume": "Music", "effects_volume": "Combat", "voices_volume": "Voice"}

var values: Dictionary = DEFAULTS.duplicate()

## Returns the stored value of a known key; push_error and null for an unknown key.
func get_value(key: String) -> Variant:
	if not DEFAULTS.has(key):
		push_error("unknown setting: %s" % key)
		return null
	return values[key]

## Sets a known key. Volumes are clamped to 0..100 and snapped to steps of 5; window mode
## must be one of WINDOW_MODES; switches must be bool. Returns false if the value is refused.
func set_value(key: String, value: Variant) -> bool:
	if not DEFAULTS.has(key):
		push_error("unknown setting: %s" % key)
		return false
	var clean: Variant = _clean(key, value)
	if clean == null:return false
	values[key] = clean
	return true

## Loads settings; a missing file, a broken file or bad values fall back to the defaults.
func load_from(path := PATH) -> void:
	values = DEFAULTS.duplicate()
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:return
	for key in DEFAULTS:
		if cfg.has_section_key(SECTION, key):
			var clean: Variant = _clean(key, cfg.get_value(SECTION, key))
			if clean != null:values[key] = clean

## Writes all settings; returns OK or the ConfigFile error.
func save_to(path := PATH) -> Error:
	var cfg := ConfigFile.new()
	for key in DEFAULTS:cfg.set_value(SECTION, key, values[key])
	return cfg.save(path)

## Applies audio volumes (creating the Music and Voice buses if missing) and, with a
## display, window mode and VSync. Accessibility switches are read by the systems that
## use them (subtitles, slow motion, screen shake).
func apply() -> void:
	for key in BUSES:
		var index := bus_index(BUSES[key])
		AudioServer.set_bus_volume_db(index, volume_db(int(values[key])))
		AudioServer.set_bus_mute(index, int(values[key]) == 0)
	if DisplayServer.get_name() == "headless":return
	match String(values.window_mode):
		"fullscreen":DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		"borderless":DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		_:DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if values.vsync else DisplayServer.VSYNC_DISABLED)

## Index of an audio bus; creates it (sending to Master) if it does not exist.
static func bus_index(bus_name: String) -> int:
	var index := AudioServer.get_bus_index(bus_name)
	if index >= 0:return index
	AudioServer.add_bus()
	index = AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, bus_name)
	AudioServer.set_bus_send(index, "Master")
	return index

## 0..100 % -> dB; 0 % is muted separately, so it maps to -80 dB here.
static func volume_db(percent: int) -> float:
	return -80.0 if percent <= 0 else linear_to_db(percent / 100.0)

func _clean(key: String, value: Variant) -> Variant:
	if key.ends_with("_volume"):
		if not (value is int or value is float):return null
		return clampi(int(round(float(value) / VOLUME_STEP)) * VOLUME_STEP, 0, 100)
	if key == "window_mode":
		return value if value is String and value in WINDOW_MODES else null
	return value if value is bool else null
