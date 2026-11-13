extends SceneTree
## E11.6a — Credits menu round trip and content check from the real start scene.

const SAVE_PATH := "user://rendrun_route_v12.json"

var _fail := 0
var _checks := 0

func _check(label: String, ok: bool, detail := "") -> void:
	_checks += 1
	if not ok:
		_fail += 1
	print("E11.6a %s %s %s" % ["PASS" if ok else "FAIL", label, detail])

func _key(action: String) -> void:
	var ev := InputEventAction.new();ev.action = action;ev.pressed = true
	root.push_input(ev)
	ev = InputEventAction.new();ev.action = action;ev.pressed = false
	root.push_input(ev)
	await process_frame

func _initialize() -> void:
	if not OS.get_user_data_dir().begins_with("/tmp/"): quit(2); return
	await process_frame
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))

	# Data table check
	var CreditsData = load("res://data/credits_data.gd")
	_check("credits_data_exists", CreditsData != null)
	if CreditsData != null:
		var sections: Array = CreditsData.SECTIONS
		_check("sections_not_empty", not sections.is_empty(), "count=%d" % sections.size())
		var valid_sections := true
		for s in sections:
			var t: String = s.get("title", "")
			var lines: Array = s.get("lines", [])
			if t.strip_edges() == "" or lines.is_empty():
				valid_sections = false
				break
			for line in lines:
				if str(line).strip_edges() == "":
					valid_sections = false
					break
		_check("sections_content_valid", valid_sections)

	var start = load("res://start.tscn").instantiate()
	root.add_child(start)
	await process_frame
	await process_frame
	var menu: Control = start.menu
	var credits: Control = start.get("credits_menu")

	_check("credits_menu_created", credits != null)
	if credits == null:
		print("E11.6a SUMMARY checks=%d failures=%d" % [_checks, _fail])
		quit(1 if _fail else 0)
		return

	_check("startet_auf_neue_runde", menu.is_open() and menu.focused_id() == "new_run", menu.focused_id())
	await _key("ui_down") # Options
	_check("ui_down_x1_options", menu.focused_id() == "options", menu.focused_id())
	await _key("ui_down") # Credits
	_check("ui_down_x2_credits", menu.focused_id() == "credits", menu.focused_id())

	await _key("ui_accept")
	await process_frame

	_check("credits_offen_menue_versteckt", credits.is_open() and not menu.is_open())

	var expected_row_count: int = CreditsData.SECTIONS.size() + 1 if CreditsData != null else -1
	_check("credits_row_count", credits.rows.size() == expected_row_count, "actual=%d expected=%d" % [credits.rows.size(), expected_row_count])
	_check("credits_last_row_is_back", not credits.rows.is_empty() and credits.rows[-1].id == "back")

	await _key("ui_cancel")
	for i in 30:
		await process_frame
	_check("menue_wieder_offen_credits_zu", menu.is_open() and not credits.is_open())
	_check("fokus_zurueck_auf_credits", menu.focused_id() == "credits", menu.focused_id())

	print("E11.6a SUMMARY checks=%d failures=%d" % [_checks, _fail])
	quit(1 if _fail else 0)
