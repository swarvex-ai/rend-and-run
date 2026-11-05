extends "res://modules/ui/menu_screen.gd"
## Options: the reference screen every other menu copies (E11.2, decision 0002).
## Rows in the order of the style guide; every change is applied and saved at once
## (no Apply button). B / Esc and the Back row emit back_requested; the owner closes it.
## No key rebinding in M1.
##
##   var options = preload("res://modules/ui/options_menu.gd").new()
##   options.back_requested.connect(func(): await options.close_screen())
##   layer.add_child(options);options.open_screen()

const SettingsStore = preload("res://modules/persistence/settings_store.gd")
const VOLUME_ROWS := [["master_volume", "Master volume"], ["music_volume", "Music volume"], ["effects_volume", "Effects volume"], ["voices_volume", "Voices volume"]]
const SWITCH_ROWS := [["vsync", "VSync"], ["subtitles", "Subtitles"], ["slow_motion", "Slow motion"], ["screen_shake", "Screen shake"]]
const WINDOW_OPTIONS := [["windowed", "Windowed"], ["borderless", "Borderless"], ["fullscreen", "Fullscreen"]]

var settings = SettingsStore.new()
var settings_path := SettingsStore.PATH
var last_save_error := OK

func _init() -> void:
	super._init()
	name = "OptionsMenu"
	title = "Options"

## Loads the store from settings_path unless the owner already loaded one.
func _build() -> void:
	if settings.values == SettingsStore.DEFAULTS:settings.load_from(settings_path)
	for row in VOLUME_ROWS:add_slider(row[0], row[1], int(settings.get_value(row[0])))
	add_cycle("window_mode", "Window mode", WINDOW_OPTIONS, settings.get_value("window_mode"))
	for row in SWITCH_ROWS:add_switch(row[0], row[1], bool(settings.get_value(row[0])))
	add_button("back", "Back")
	value_changed.connect(_on_value_changed)
	row_activated.connect(_on_row_activated)

func _on_row_activated(id: String) -> void:
	if id == "back":back_requested.emit()

func _on_value_changed(id: String, value: Variant) -> void:
	if not settings.set_value(id, value):return
	settings.apply()
	last_save_error = settings.save_to(settings_path)
	if last_save_error != OK:push_warning("settings not saved (%s): %s" % [error_string(last_save_error), settings_path])
