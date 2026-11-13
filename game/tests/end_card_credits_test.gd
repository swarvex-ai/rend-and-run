extends SceneTree
## E11.6b — Credits row on the end card.
## End card -> Credits (row / A / Enter / click), Credits -> back (B / Esc / ui_cancel)
## returns to the end card with focus on the Credits row; the tree stays paused the whole
## time and the other two rows still work (explore resumes, title returns to the start).
## Like H32 the test emits `pressed` instead of synthesising clicks; ui_cancel is a real key.
## godot --headless --path game --script res://tests/end_card_credits_test.gd

const UI_TEXT = preload("res://data/ui_texts.gd")

var main: Node3D
var ctl: Node
var checks := 0
var failures := 0

func _check(label: String, ok: bool, detail := "") -> void:
	checks += 1
	if not ok:
		failures += 1
	print("E11.6b %s %s %s" % ["PASS" if ok else "FAIL", label, detail])

func _frames(n: int) -> void:
	for i in n:
		await process_frame

func _focus_name() -> String:
	var fo := root.gui_get_focus_owner()
	return str(fo.name) if fo != null else "<none>"

func _escape() -> void:
	var key := InputEventKey.new()
	key.physical_keycode = KEY_ESCAPE
	key.keycode = KEY_ESCAPE
	key.pressed = true
	Input.parse_input_event(key)
	key = InputEventKey.new()
	key.physical_keycode = KEY_ESCAPE
	key.keycode = KEY_ESCAPE
	key.pressed = false
	Input.parse_input_event(key)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if not OS.get_user_data_dir().begins_with("/tmp/"):
		quit(2)
		return
	root.size = Vector2i(960, 540)
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	await _frames(20)
	ctl = main.pause_controller
	ctl.resume()
	for enemy in main.route.enemies:
		enemy.set_physics_process(false)

	# --- end card with the Credits row between the other two rows
	ctl.show_completion({"save_ok": true})
	await process_frame
	_check("end card opens paused", ctl.summary.visible and paused)
	var btn_credits: Button = ctl.summary.get("_btn_credits")
	_check("credits row exists", btn_credits != null)
	if btn_credits == null:
		print("E11.6b SUMMARY checks=%d failures=%d" % [checks, failures])
		quit(1)
		return
	_check("credits row text", btn_credits.text == UI_TEXT.t("end_credits"), btn_credits.text)
	var box := btn_credits.get_parent()
	_check("row order explore/credits/title",
		box.get_children().find(ctl.summary.get("_btn_explore")) + 1 == box.get_children().find(btn_credits) \
		and box.get_children().find(btn_credits) + 1 == box.get_children().find(ctl.summary.get("_btn_title")))

	# --- Credits opens from the row, end card hidden, tree still paused
	btn_credits.pressed.emit()
	await process_frame
	var credits: Control = ctl.get("credits_menu")
	_check("credits screen opens", credits != null and credits.is_open(), str(credits))
	if credits == null:
		print("E11.6b SUMMARY checks=%d failures=%d" % [checks, failures])
		quit(1)
		return
	_check("end card hidden while credits open", not ctl.summary.visible)
	_check("tree stays paused for credits", paused)
	_check("pause menu stays closed", not ctl.menu.visible)

	# --- ui_cancel returns to the end card, focus on the Credits row
	_escape()
	await _frames(30)
	_check("back closes credits", not credits.is_open())
	_check("end card shown again", ctl.summary.visible)
	_check("focus on credits row", _focus_name() == "BtnCredits", _focus_name())
	_check("still paused after return", paused)
	_check("pause menu stays closed after return", not ctl.menu.visible)

	# --- the other two rows still work
	ctl.summary.get("_btn_explore").pressed.emit()
	await process_frame
	_check("explore resumes from the returned card", not paused and not ctl.summary.visible)
	ctl.show_completion({"save_ok": true})
	await process_frame
	ctl.summary.get("_btn_title").pressed.emit()
	await _frames(30)
	_check("title returns to the start scene",
		current_scene != null and current_scene.scene_file_path == "res://start.tscn" and not paused)

	print("E11.6b SUMMARY checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
