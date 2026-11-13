extends SceneTree
# Input device tracker: keyboard/mouse events fall back to keyboard, joypad button
# events and joypad motion above the deadzone switch to pad; device_changed fires
# exactly once per change; unplugging the last pad falls back to keyboard.

const TRACKER = preload("res://modules/ui/input_device_tracker.gd")

var failures := 0
var changes: Array = []

func check(label: String, ok: bool, detail := "") -> void:
	print("DEVICE %s %s %s" % ["PASS" if ok else "FAIL", label, detail])
	if not ok:failures += 1

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if not OS.get_user_data_dir().begins_with("/tmp/"):quit(2);return
	var tracker = TRACKER.new()
	root.add_child(tracker)
	tracker.device_changed.connect(func(on_pad: bool) -> void:changes.append(on_pad))
	check("starts as keyboard without a signal", not tracker.is_pad and changes.is_empty())
	# Key while already on keyboard: no change, no signal.
	tracker.feed(_key())
	check("key keeps keyboard without a signal", not tracker.is_pad and changes.is_empty())
	# Joypad motion below the deadzone: no change.
	tracker.feed(_motion(0.2))
	check("motion below deadzone keeps keyboard", not tracker.is_pad and changes.is_empty())
	# Joypad motion above the deadzone: pad, signal once.
	tracker.feed(_motion(0.9))
	check("motion above deadzone switches to pad", tracker.is_pad and changes == [true], "changes=%s"%[changes])
	# A joypad button keeps the pad without a new signal.
	tracker.feed(_pad_button())
	check("joypad button keeps pad without a signal", tracker.is_pad and changes == [true])
	# Key falls back to keyboard, signal once.
	tracker.feed(_key())
	check("key switches to keyboard", not tracker.is_pad and changes == [true, false], "changes=%s"%[changes])
	# Mouse button keeps the keyboard without a new signal.
	tracker.feed(_mouse_button())
	check("mouse button keeps keyboard without a signal", not tracker.is_pad and changes == [true, false])
	# Mouse motion switches to pad then back: two more signals.
	tracker.feed(_pad_button())
	tracker.feed(_mouse_motion())
	check("mouse motion switches back to keyboard", not tracker.is_pad and changes == [true, false, true, false], "changes=%s"%[changes])
	# Unplugging the last pad (none connected in headless) falls back to keyboard.
	tracker.feed(_pad_button())
	check("pad again before the unplug", tracker.is_pad and changes == [true, false, true, false, true])
	Input.joy_connection_changed.emit(0, false)
	check("last pad unplugged falls back to keyboard", not tracker.is_pad and changes == [true, false, true, false, true, false], "changes=%s"%[changes])
	print("DEVICE SUMMARY failures=", failures)
	quit(1 if failures else 0)

func _key() -> InputEventKey:
	var e := InputEventKey.new()
	e.keycode = KEY_E
	e.pressed = true
	return e

func _mouse_button() -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	return e

func _mouse_motion() -> InputEventMouseMotion:
	return InputEventMouseMotion.new()

func _pad_button() -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.button_index = JOY_BUTTON_A
	e.pressed = true
	return e

func _motion(value: float) -> InputEventJoypadMotion:
	var e := InputEventJoypadMotion.new()
	e.axis = JOY_AXIS_LEFT_X
	e.axis_value = value
	return e
