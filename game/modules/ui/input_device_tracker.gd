class_name InputDeviceTracker
extends Node
## Last-used-device tracker: reports whether the player last used keyboard/mouse
## or a gamepad. Owned by main.gd (not an autoload); UI hints connect to
## device_changed. The _input handler only forwards to feed() so the logic stays
## testable without a display.

signal device_changed(is_pad: bool)

## Joypad axes only count as pad use at or above this deflection (matches the
## fire-action deadzone, see docs/measurements/input-hints.md Part 2).
const AXIS_DEADZONE := 0.4

var is_pad: bool = false

func _ready() -> void:
	Input.joy_connection_changed.connect(_on_joy_connection_changed)

func _input(event: InputEvent) -> void:
	feed(event)

## Classifies one input event; emits device_changed only when the kind flips.
func feed(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventMouseMotion:
		_set_pad(false)
	elif event is InputEventJoypadButton:
		_set_pad(true)
	elif event is InputEventJoypadMotion and absf(event.axis_value) >= AXIS_DEADZONE:
		_set_pad(true)

func _set_pad(value: bool) -> void:
	if is_pad == value:
		return
	is_pad = value
	device_changed.emit(is_pad)

func _on_joy_connection_changed(_device: int, connected: bool) -> void:
	if not connected and Input.get_connected_joypads().is_empty():
		_set_pad(false)
