extends SceneTree
## Credits scroll: a tall credit table scrolls via wheel and right stick, the Back row
## stays pinned last and focusable, and left-click handling on rows is unaffected.
## Headless test: events are injected and the scroll function is called directly.

var failures := 0
var activated: Array = []

func check(label: String, ok: bool, detail := "") -> void:
	if not ok:
		failures += 1
	print("CREDITS_SCROLL ", "PASS " if ok else "FAIL ", label, detail)

func _key(action: String) -> void:
	var ev := InputEventAction.new();ev.action = action;ev.pressed = true
	root.push_input(ev)
	ev = InputEventAction.new();ev.action = action;ev.pressed = false
	root.push_input(ev)
	await process_frame

func _push_wheel(down: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_WHEEL_DOWN if down else MOUSE_BUTTON_WHEEL_UP
	ev.pressed = true;ev.position = Vector2(100, 100)
	root.push_input(ev)
	await process_frame

func _push_stick(value: float) -> void:
	var ev := InputEventJoypadMotion.new();ev.axis = JOY_AXIS_RIGHT_Y;ev.axis_value = value
	root.push_input(ev)
	await process_frame

func _build_tall_menu():
	var menu = preload("res://modules/ui/menu_screen.gd").new()
	menu.title = "Credits"
	for i in range(24):
		menu.add_button("section_%d" % i, "Section %d" % i)
	menu.add_button("back", "Back")
	menu.row_activated.connect(func(id: String): activated.append(id))
	root.add_child(menu)
	menu.open_screen()
	await process_frame
	await process_frame
	return menu

func run() -> void:
	if not OS.get_user_data_dir().begins_with("/tmp/"):quit(2);return
	await process_frame

	# --- A tall credits-like table (rows exceed the panel) ---------------------
	var menu = await _build_tall_menu()
	check("credits table tall enough to scroll", menu._scroll_max > 0.0,
		"max=%.0f panel_h=%.0f" % [menu._scroll_max, menu._panel.size.y])
	check("back row is last", not menu.rows.is_empty() and menu.rows[-1].id == "back",
		"last=%s" % menu.rows[-1].id)
	check("back row enabled and focusable", menu.rows[-1].enabled and not menu.rows[-1].node.disabled)

	# --- wheel scrolls --------------------------------------------------------
	var off = menu._scroll_offset
	_push_wheel(true)
	check("wheel down scrolls", menu._scroll_offset > off, "off=%.0f" % menu._scroll_offset)
	off = menu._scroll_offset
	_push_wheel(false)
	check("wheel up scrolls back", menu._scroll_offset < off, "off=%.0f" % menu._scroll_offset)

	# --- right stick scrolls --------------------------------------------------
	_push_stick(1.0)   # down
	off = menu._scroll_offset
	_push_stick(0.0)   # re-arm (release)
	_push_stick(-1.0)  # up
	check("right stick scrolls down then up", menu._scroll_offset < off, "off=%.0f" % menu._scroll_offset)

	# --- left click on a row still emits its click handling -------------------
	activated.clear()
	menu.rows[3].node.pressed.emit()
	await process_frame
	check("row click still emits row_activated", activated.has("section_3"),
		"activated=%s" % str(activated))

	# --- ui_down reaches Back with scroll following focus ---------------------
	menu.focus_index = 0
	menu._scroll_offset = 0.0;menu._apply_scroll()
	var start_offset = menu._scroll_offset
	for i in range(menu.rows.size() - 1):
		_key("ui_down")
	check("ui_down reaches the Back row", menu.focused_id() == "back", menu.focused_id())
	check("scroll followed focus down", menu._scroll_offset > start_offset,
		"off=%.0f max=%.0f" % [menu._scroll_offset, menu._scroll_max])
	check("back row visible at the end", menu._scroll_offset >= menu._scroll_max - 1.0,
		"off=%.0f max=%.0f" % [menu._scroll_offset, menu._scroll_max])

	menu.queue_free()

	# --- credits_menu.gd: Back last and reachable via ui_down -----------------
	var credits = preload("res://modules/ui/credits_menu.gd").new()
	root.add_child(credits)
	credits.open_screen()
	await process_frame
	await process_frame
	check("credits_menu back row is last", not credits.rows.is_empty() and credits.rows[-1].id == "back",
		"last=%s" % credits.rows[-1].id)
	credits.focus_index = 0
	for i in range(credits.rows.size() - 1):
		_key("ui_down")
	check("credits_menu back reachable via ui_down", credits.focused_id() == "back",
		credits.focused_id())
	credits.queue_free()

	print("CREDITS_SCROLL SUMMARY failures=", failures)
	quit(1 if failures else 0)

func _initialize() -> void:
	call_deferred("run")
