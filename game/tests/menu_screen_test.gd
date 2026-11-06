extends SceneTree
## Contract test for the MenuScreen base (game/modules/ui/menu_screen.gd) through the
## reference Options screen (game/modules/ui/options_menu.gd): rows, wrap-around focus,
## a focus cue that is not colour alone, clamped sliders, immediate save, back, timing.
const OPTIONS = preload("res://modules/ui/options_menu.gd")
const STORE = preload("res://modules/persistence/settings_store.gd")
const PATH := "user://menu_screen_test.cfg"
var failures := 0
var events: Array = []

func check(label: String, ok: bool) -> void:
	print("MENU ", "PASS " if ok else "FAIL ", label)
	if not ok: failures += 1

func press(action: String) -> void:
	var ev := InputEventAction.new();ev.action = action;ev.pressed = true
	root.push_input(ev)
	ev = InputEventAction.new();ev.action = action;ev.pressed = false
	root.push_input(ev)
	await process_frame

func stored(key: String) -> Variant:
	var s = STORE.new();s.load_from(PATH);return s.get_value(key)

func run() -> void:
	if not OS.get_user_data_dir().begins_with("/tmp/"): quit(2); return
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	var menu = OPTIONS.new();menu.settings_path = PATH
	for sig in ["opened", "closed", "back_requested"]:
		menu.connect(sig, func(): events.append(sig))
	root.add_child(menu);menu.open_screen()
	await process_frame
	var ids: Array = menu.rows.map(func(r): return r.id)
	check("rows in style-guide order", ids == ["master_volume", "music_volume", "effects_volume", "voices_volume", "window_mode", "vsync", "subtitles", "slow_motion", "screen_shake", "back"])
	check("no key rebinding row", not ids.any(func(id): return "bind" in id or "key" in id))
	check("open emits opened and shows the screen", "opened" in events and menu.is_open())
	check("focus starts on the first row", menu.focused_id() == "master_volume")
	var focused_style: StyleBoxFlat = menu.rows[0].node.get_theme_stylebox("normal")
	check("focus has a marker bar and an outline, not colour alone", menu._marker.visible and menu._marker.size == menu.MARKER_SIZE and focused_style.border_width_left == 2 and focused_style.content_margin_left == menu.ROW_INSET + menu.FOCUS_OFFSET)
	await press("ui_up")
	check("up on the first row wraps to the last", menu.focused_id() == "back")
	await press("ui_down")
	check("down on the last row wraps to the first", menu.focused_id() == "master_volume")
	await press("ui_right")
	check("sliders clamp at 100 and do not wrap", menu.value_of("master_volume") == 100)
	await press("ui_down");await press("ui_right")
	check("music volume steps by 5 and saves at once", menu.value_of("music_volume") == 75 and stored("music_volume") == 75)
	for i in 3: await press("ui_down")
	check("focus reaches window mode", menu.focused_id() == "window_mode")
	await press("ui_right")
	check("window mode cycles and saves", menu.value_of("window_mode") == "borderless" and stored("window_mode") == "borderless")
	await press("ui_down");await press("ui_accept")
	check("accept toggles a switch and saves", menu.value_of("vsync") == false and stored("vsync") == false)
	check("settings save without error", menu.last_save_error == OK)
	menu.rows[2].enabled = false
	menu.focus_index = 1;await press("ui_down")
	check("disabled rows are skipped", menu.focused_id() == "voices_volume")
	menu.rows[2].enabled = true
	await press("ui_cancel")
	check("B / Esc emits back_requested", events.count("back_requested") == 1)
	menu.focus_index = menu.rows.size() - 1;await press("ui_accept")
	check("the Back row emits back_requested", events.count("back_requested") == 2)
	var ticks := 0
	menu.close_screen()
	while menu.is_open() and ticks < 60:
		await process_frame;ticks += 1
	check("close emits closed within 300 ms", "closed" in events and not menu.is_open() and ticks * (1.0 / 60.0) <= 0.3)
	check("all transitions are at most 300 ms", menu.SCREEN_IN <= 0.3 and menu.SCREEN_OUT <= 0.3 and menu.FOCUS_MOVE <= 0.3)
	menu.open_screen();await process_frame
	menu.set_row_enabled("music_volume", false);menu.focus_index = 0;await press("ui_down")
	check("set_row_enabled disables a row and focus skips it", menu.focused_id() == "effects_volume" and menu.rows[1].node.disabled)
	menu.clear_rows();menu.set_title("Quit?");menu.add_button("cancel", "Cancel");menu.add_button("quit", "Quit")
	await menu.show_rows("cancel")
	check("clear_rows and show_rows swap the rows on the open screen", menu.is_open() and menu.rows.size() == 2 and menu.focused_id() == "cancel")
	await press("ui_down");await press("ui_down")
	check("focus wraps inside a confirmation", menu.focused_id() == "cancel")
	check("options never touch the route save", not FileAccess.file_exists("user://rendrun_route_v12.json"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	print("MENU SUMMARY failures=", failures)
	quit(1 if failures else 0)

func _initialize() -> void:
	call_deferred("run")
