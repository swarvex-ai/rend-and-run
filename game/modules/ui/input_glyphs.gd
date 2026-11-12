extends RefCounted
## Input glyph lookup module: turns an InputMap action into a player-facing label
## per device kind (keyboard/mouse or gamepad), and replaces {action} placeholders.

const JOY_BUTTON_LABELS: Dictionary = {
	JOY_BUTTON_A: "A",
	JOY_BUTTON_B: "B",
	JOY_BUTTON_X: "X",
	JOY_BUTTON_Y: "Y",
	JOY_BUTTON_BACK: "Back",
	JOY_BUTTON_START: "Start",
	JOY_BUTTON_LEFT_SHOULDER: "LB",
	JOY_BUTTON_RIGHT_SHOULDER: "RB",
	JOY_BUTTON_LEFT_STICK: "LS",
	JOY_BUTTON_RIGHT_STICK: "RS",
	JOY_BUTTON_DPAD_UP: "D-Pad Up",
	JOY_BUTTON_DPAD_DOWN: "D-Pad Down",
	JOY_BUTTON_DPAD_LEFT: "D-Pad Left",
	JOY_BUTTON_DPAD_RIGHT: "D-Pad Right",
	JOY_BUTTON_GUIDE: "Guide",
	JOY_BUTTON_MISC1: "Share",
}

const JOY_AXIS_LABELS: Dictionary = {
	JOY_AXIS_TRIGGER_LEFT: "LT",
	JOY_AXIS_TRIGGER_RIGHT: "RT",
	JOY_AXIS_LEFT_X: "LS",
	JOY_AXIS_LEFT_Y: "LS",
	JOY_AXIS_RIGHT_X: "RS",
	JOY_AXIS_RIGHT_Y: "RS",
}

const MOUSE_BUTTON_LABELS: Dictionary = {
	MOUSE_BUTTON_LEFT: "LMB",
	MOUSE_BUTTON_RIGHT: "RMB",
	MOUSE_BUTTON_MIDDLE: "MMB",
	MOUSE_BUTTON_WHEEL_UP: "Wheel Up",
	MOUSE_BUTTON_WHEEL_DOWN: "Wheel Down",
}

static func _format_key(event: InputEventKey) -> String:
	var code := event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode
	if code == KEY_NONE:
		code = event.key_label
	if code == KEY_NONE:
		return "?"
	var s := OS.get_keycode_string(code)
	return s if not s.is_empty() else "?"

static func _format_mouse(event: InputEventMouseButton) -> String:
	return MOUSE_BUTTON_LABELS.get(event.button_index, "?")

static func _format_joy_button(event: InputEventJoypadButton) -> String:
	return JOY_BUTTON_LABELS.get(event.button_index, "?")

static func _format_joy_motion(event: InputEventJoypadMotion) -> String:
	return JOY_AXIS_LABELS.get(event.axis, "?")

static func label(action: String, pad: bool) -> String:
	if not InputMap.has_action(action):
		return "?"
	for event in InputMap.action_get_events(action):
		if pad:
			if event is InputEventJoypadButton:
				var res := _format_joy_button(event)
				if res != "?":
					return res
			elif event is InputEventJoypadMotion:
				var res := _format_joy_motion(event)
				if res != "?":
					return res
		else:
			if event is InputEventKey:
				var res := _format_key(event)
				if res != "?":
					return res
			elif event is InputEventMouseButton:
				var res := _format_mouse(event)
				if res != "?":
					return res
	return "?"

static func format(text: String, pad: bool) -> String:
	var regex := RegEx.new()
	regex.compile("\\{([a-zA-Z0-9_]+)\\}")
	var matches := regex.search_all(text)
	if matches.is_empty():
		return text
	var result := ""
	var last_end := 0
	for m in matches:
		var action_name := m.get_string(1)
		result += text.substr(last_end, m.get_start() - last_end)
		if InputMap.has_action(action_name):
			result += label(action_name, pad)
		else:
			result += m.get_string(0)
		last_end = m.get_end()
	result += text.substr(last_end)
	return result
