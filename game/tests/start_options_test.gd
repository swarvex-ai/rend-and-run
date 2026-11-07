extends SceneTree
## E11.4b — Options round trip from the real start scene: real ui_down/ui_accept
## opens the Options screen (menu hidden), real ui_cancel closes it and returns
## to the main list with focus on Options. Headless, fixed 1/60 s frames.

const SAVE_PATH := "user://rendrun_route_v12.json"

var _fail := 0
var _checks := 0

func _check(label: String, ok: bool, detail := "") -> void:
	_checks += 1
	if not ok:
		_fail += 1
	print("E11.4b %s %s %s" % ["PASS" if ok else "FAIL", label, detail])

func _key(action: String) -> void:
	var ev := InputEventAction.new();ev.action = action;ev.pressed = true
	root.push_input(ev)
	ev = InputEventAction.new();ev.action = action;ev.pressed = false
	root.push_input(ev)
	await process_frame

func _initialize() -> void:
	# Deletes the route save below: only ever run on isolated test data.
	if not OS.get_user_data_dir().begins_with("/tmp/"): quit(2); return
	await process_frame
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	var start = load("res://start.tscn").instantiate()
	root.add_child(start)
	await process_frame
	await process_frame
	var menu: Control = start.menu
	var options: Control = start.options_menu

	_check("startet_auf_neue_runde", menu.is_open() and menu.focused_id() == "new_run", menu.focused_id())
	await _key("ui_down")
	_check("ui_down_erreicht_options", menu.focused_id() == "options", menu.focused_id())
	await _key("ui_accept")
	await process_frame
	_check("options_offen_menue_versteckt", options.is_open() and not menu.is_open())
	_check("options_fokus_erste_zeile", options.focused_id() == "master_volume", options.focused_id())

	await _key("ui_cancel")
	for i in 30:
		await process_frame
	_check("menue_wieder_offen_options_zu", menu.is_open() and not options.is_open())
	_check("fokus_zurueck_auf_options", menu.focused_id() == "options", menu.focused_id())

	print("E11.4b SUMMARY checks=%d failures=%d" % [_checks, _fail])
	quit(1 if _fail else 0)
