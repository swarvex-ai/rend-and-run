extends SceneTree

const GLYPHS = preload("res://modules/ui/input_glyphs.gd")

var failures := 0

func check(label_text: String, ok: bool, detail := "") -> void:
	print("GLYPHS %s %s %s" % ["PASS" if ok else "FAIL", label_text, detail])
	if not ok:
		failures += 1

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if not OS.get_user_data_dir().begins_with("/tmp/"):
		quit(2)
		return

	# jump -> "Space" (keyboard) and "A" (pad)
	check("jump keyboard is Space", GLYPHS.label("jump", false) == "Space", "got: " + GLYPHS.label("jump", false))
	check("jump pad is A", GLYPHS.label("jump", true) == "A", "got: " + GLYPHS.label("jump", true))

	# attack pad -> "X"
	check("attack pad is X", GLYPHS.label("attack", true) == "X", "got: " + GLYPHS.label("attack", true))

	# crouch pad -> "RB"
	check("crouch pad is RB", GLYPHS.label("crouch", true) == "RB", "got: " + GLYPHS.label("crouch", true))

	# unknown action -> "?"
	check("unknown action keyboard is ?", GLYPHS.label("non_existent_action_xyz", false) == "?")
	check("unknown action pad is ?", GLYPHS.label("non_existent_action_xyz", true) == "?")

	# code-created action added with InputMap.add_action in the test
	var custom_action := "test_custom_action"
	if InputMap.has_action(custom_action):
		InputMap.erase_action(custom_action)
	InputMap.add_action(custom_action)
	var custom_key := InputEventKey.new()
	custom_key.physical_keycode = KEY_E
	InputMap.action_add_event(custom_action, custom_key)
	var custom_pad := InputEventJoypadButton.new()
	custom_pad.button_index = JOY_BUTTON_Y
	InputMap.action_add_event(custom_action, custom_pad)

	check("custom action keyboard is E", GLYPHS.label(custom_action, false) == "E", "got: " + GLYPHS.label(custom_action, false))
	check("custom action pad is Y", GLYPHS.label(custom_action, true) == "Y", "got: " + GLYPHS.label(custom_action, true))
	InputMap.erase_action(custom_action)

	# format("{jump} - go", false) == "Space - go"
	check("format jump keyboard replaces with Space", GLYPHS.format("{jump} - go", false) == "Space - go", "got: " + GLYPHS.format("{jump} - go", false))

	# unknown placeholder unchanged
	check("format unknown placeholder unchanged", GLYPHS.format("{unknown_action_foo} remains", false) == "{unknown_action_foo} remains", "got: " + GLYPHS.format("{unknown_action_foo} remains", false))

	# additional coverage: mouse button, trigger axis, format pad
	var test_fire := "test_fire_action"
	if InputMap.has_action(test_fire):
		InputMap.erase_action(test_fire)
	InputMap.add_action(test_fire)
	var mouse_event := InputEventMouseButton.new()
	mouse_event.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event(test_fire, mouse_event)
	var trigger_event := InputEventJoypadMotion.new()
	trigger_event.axis = JOY_AXIS_TRIGGER_RIGHT
	trigger_event.axis_value = 1.0
	InputMap.action_add_event(test_fire, trigger_event)

	check("fire mouse is LMB", GLYPHS.label(test_fire, false) == "LMB", "got: " + GLYPHS.label(test_fire, false))
	check("fire trigger is RT", GLYPHS.label(test_fire, true) == "RT", "got: " + GLYPHS.label(test_fire, true))
	check("format format fire pad replaces with RT", GLYPHS.format("Press {test_fire_action} to shoot", true) == "Press RT to shoot", "got: " + GLYPHS.format("Press {test_fire_action} to shoot", true))
	InputMap.erase_action(test_fire)

	print("GLYPHS SUMMARY failures=", failures)
	quit(1 if failures else 0)
