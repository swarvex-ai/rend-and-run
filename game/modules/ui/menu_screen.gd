extends Control
## MenuScreen: the base every Rend&Run menu screen extends (reference: options_menu.gd).
## Look, motion and sound follow docs/design/menus/style-guide-variant-2.md and
## docs/decisions/0002-menu-style-guide.md. Sizes are at the 1920×1080 reference.
##
## Signals
##   opened         after open_screen() has started the screen-in transition
##   closed         after close_screen() has finished the screen-out transition
##   back_requested B / Esc (ui_cancel) was pressed; the owner decides what "back" means
##   row_activated(id)  A / Enter / Space or click on a button row
##   value_changed(id, value)  a slider, cycle or switch row changed its value
##
## Build rows in _build() with add_button / add_slider / add_cycle / add_switch, then
## call open_screen(). For a confirmation on the same screen: clear_rows(), set_title(),
## add the new rows, show_rows(). set_row_enabled() disables a row (e.g. Continue). Rows are navigated with ui_up / ui_down (wrapping, disabled rows
## skipped), adjusted with ui_left / ui_right, confirmed with ui_accept.
## process_mode is ALWAYS so menus work while the tree is paused.

signal opened
signal closed
signal back_requested
signal row_activated(id: String)
signal value_changed(id: String, value: Variant)

# Palette (style guide variant 2, "Palette"). Amber is never used for focus.
const COL_BACKDROP := Color("11151E")
const COL_PANEL := Color("1A2028")
const COL_TEXT := Color("CAD5CF")
const COL_FOCUS := Color("62D6CC")
const COL_COPPER := Color("B77850")
const COL_FOCUS_FILL := Color("23525B")
const COL_WARNING := Color("F2B05E")
# Layout (style guide "Layout and grid")
const PANEL_WIDTH := 960.0
const PANEL_PADDING := 32
const PANEL_RADIUS := 8
const ROW_HEIGHT := 56.0
const ROW_GAP := 12
const ROW_INSET := 32
const FOCUS_OFFSET := 8.0
const MARKER_SIZE := Vector2(8, 32)
const MARKER_GAP := 24.0
const CONTROL_WIDTH := 240.0
const TITLE_SIZE := 48
const ITEM_SIZE := 36
const VALUE_SIZE := 26
# Motion (style guide "Motion"), seconds
const SCREEN_IN := 0.18
const SCREEN_OUT := 0.14
const FOCUS_MOVE := 0.11
# Sound (style guide "Sound"); menu_back.wav is a planned asset, block.wav stands in.
const SND_FOCUS := preload("res://audio/radio_chirp.wav")
const SND_CONFIRM := preload("res://audio/block.wav")
const SND_BACK_PATH := "res://audio/menu_back.wav"
const FOCUS_SOUND_GAP_MS := 40

var title := ""
var rows: Array[Dictionary] = []   # {id, kind, node, value_label, value, options, enabled}
var focus_index := -1
var _panel: PanelContainer
var _list: VBoxContainer
var _marker: ColorRect
var _backdrop: ColorRect
var _tween: Tween
var _marker_tween: Tween
var _players: Dictionary = {}
var _last_focus_sound_ms := -1000

func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_backdrop = ColorRect.new();_backdrop.name = "Backdrop";_backdrop.color = Color(COL_BACKDROP, 0.88)
	_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_backdrop)
	_panel = PanelContainer.new();_panel.name = "Panel"
	var box := StyleBoxFlat.new();box.bg_color = COL_PANEL;box.border_color = COL_COPPER
	box.set_border_width_all(2);box.set_corner_radius_all(PANEL_RADIUS);box.set_content_margin_all(PANEL_PADDING)
	_panel.add_theme_stylebox_override("panel", box)
	_panel.custom_minimum_size.x = PANEL_WIDTH
	add_child(_panel)
	var column := VBoxContainer.new();column.add_theme_constant_override("separation", 24);_panel.add_child(column)
	var heading := Label.new();heading.name = "Title";heading.add_theme_font_size_override("font_size", TITLE_SIZE)
	heading.add_theme_color_override("font_color", COL_TEXT);column.add_child(heading)
	var rule := ColorRect.new();rule.color = COL_COPPER;rule.custom_minimum_size = Vector2(0, 2);column.add_child(rule)
	_list = VBoxContainer.new();_list.name = "Rows";_list.add_theme_constant_override("separation", ROW_GAP);column.add_child(_list)
	_marker = ColorRect.new();_marker.name = "FocusMarker";_marker.color = COL_FOCUS
	_marker.size = MARKER_SIZE;_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE;_marker.visible = false
	add_child(_marker)

func _ready() -> void:
	(_panel.get_child(0).get_child(0) as Label).text = title

## Override to add rows. Called once, before the first open.
func _build() -> void:
	pass

func add_button(id: String, text: String, enabled := true) -> void:
	_add_row(id, "button", text, null, [], enabled)

## Slider 0..100 in steps of 5; ui_left / ui_right change it.
func add_slider(id: String, text: String, value: int) -> void:
	_add_row(id, "slider", text, value, [], true)

## Cycles through options (Array of [value, label]).
func add_cycle(id: String, text: String, options: Array, value: Variant) -> void:
	_add_row(id, "cycle", text, value, options, true)

func add_switch(id: String, text: String, value: bool) -> void:
	_add_row(id, "switch", text, value, [], true)

func open_screen() -> void:
	if rows.is_empty():_build()
	visible = true
	modulate.a = 0.0
	_center_panel()
	_panel.position.y = _panel_rest_y() + 24.0
	_run_tween(1.0, _panel_rest_y(), SCREEN_IN, Tween.EASE_OUT)
	if focus_index < 0 or not rows[focus_index].enabled:focus_index = _next_enabled(-1, 1)
	_show_focus(false)
	opened.emit()

func close_screen() -> void:
	_run_tween(0.0, _panel_rest_y() - 12.0, SCREEN_OUT, Tween.EASE_IN)
	await _tween.finished
	visible = false
	closed.emit()

func is_open() -> bool:
	return visible

## Handles one menu action: ui_up, ui_down, ui_left, ui_right, ui_accept, ui_cancel.
## Returns true if the action was used. _input forwards to this; tests may call it.
func handle_action(action: String) -> bool:
	if not visible or rows.is_empty():return false
	match action:
		"ui_up", "ui_down":
			var next := _next_enabled(focus_index, -1 if action == "ui_up" else 1)
			if next != focus_index:
				focus_index = next;_show_focus(true);_play_focus()
			return true
		"ui_left", "ui_right":
			return _adjust(rows[focus_index], -1 if action == "ui_left" else 1)
		"ui_accept":
			var row: Dictionary = rows[focus_index]
			if row.kind == "button":
				_play(SND_CONFIRM, -14.0, 0.92);row_activated.emit(row.id)
			elif row.kind == "switch" or row.kind == "cycle":
				_adjust(row, 1)
			return true
		"ui_cancel":
			_play(_back_sound(), -16.0, 0.75 if _back_sound() == SND_CONFIRM else 1.0);back_requested.emit()
			return true
	return false

## Removes all rows (e.g. to show a confirmation on the same screen); add new rows after it.
## The screen stays open; focus goes to the first enabled new row on show_rows().
func clear_rows() -> void:
	for row in rows:row.node.queue_free()
	rows.clear()
	focus_index = -1
	_marker.visible = false

## Call after adding rows to an open screen (after clear_rows()); focuses `focus_id` if given.
func show_rows(focus_id := "") -> void:
	focus_index = -1
	for i in rows.size():
		if rows[i].id == focus_id and rows[i].enabled:focus_index = i
	if focus_index < 0:focus_index = _next_enabled(-1, 1)
	await get_tree().process_frame   # let the new rows take their size
	_center_panel()
	_show_focus(false)

func set_title(text: String) -> void:
	title = text
	(_panel.get_child(0).get_child(0) as Label).text = text

## Enables or disables a row; a disabled row is dimmed and skipped by focus.
func set_row_enabled(id: String, enabled: bool) -> void:
	for i in rows.size():
		if rows[i].id == id:
			rows[i].enabled = enabled;rows[i].node.disabled = not enabled
			if not enabled and i == focus_index:
				focus_index = _next_enabled(i, 1);_show_focus(false)

func value_of(id: String) -> Variant:
	for row in rows:
		if row.id == id:return row.value
	return null

func focused_id() -> String:
	return rows[focus_index].id if focus_index >= 0 else ""

func _input(event: InputEvent) -> void:
	if not visible:return
	for action in ["ui_up", "ui_down", "ui_left", "ui_right", "ui_accept", "ui_cancel"]:
		if event.is_action_pressed(action, true) and handle_action(action):
			get_viewport().set_input_as_handled();return

func _add_row(id: String, kind: String, text: String, value: Variant, options: Array, enabled: bool) -> void:
	var row_node := Button.new();row_node.name = "Row_" + id
	row_node.custom_minimum_size = Vector2(0, ROW_HEIGHT);row_node.focus_mode = Control.FOCUS_NONE
	row_node.alignment = HORIZONTAL_ALIGNMENT_LEFT;row_node.text = text;row_node.disabled = not enabled
	row_node.add_theme_font_size_override("font_size", ITEM_SIZE)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		row_node.add_theme_color_override(state, COL_TEXT)
	row_node.add_theme_color_override("font_disabled_color", Color(COL_TEXT, 0.4))
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var style := StyleBoxFlat.new();style.bg_color = Color(0, 0, 0, 0);style.content_margin_left = ROW_INSET
		row_node.add_theme_stylebox_override(state, style)
	var value_label: Label = null
	if kind != "button":
		value_label = Label.new();value_label.name = "Value";value_label.custom_minimum_size.x = CONTROL_WIDTH
		value_label.add_theme_font_size_override("font_size", VALUE_SIZE);value_label.add_theme_color_override("font_color", COL_FOCUS)
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT);value_label.offset_left = -CONTROL_WIDTH - ROW_INSET;value_label.offset_right = -ROW_INSET
		row_node.add_child(value_label)
	_list.add_child(row_node)
	var index := rows.size()
	rows.append({"id": id, "kind": kind, "node": row_node, "value_label": value_label, "value": value, "options": options, "enabled": enabled})
	row_node.mouse_entered.connect(_on_row_hovered.bind(index))
	row_node.pressed.connect(_on_row_clicked.bind(index))
	_refresh_value(rows[index])

func _on_row_hovered(index: int) -> void:
	if rows[index].enabled and focus_index != index:
		focus_index = index;_show_focus(true);_play_focus()

func _on_row_clicked(index: int) -> void:
	focus_index = index
	handle_action("ui_accept")

func _adjust(row: Dictionary, direction: int) -> bool:
	match row.kind:
		"slider":
			var value := clampi(int(row.value) + direction * 5, 0, 100)
			if value == int(row.value):return true   # sliders clamp, never wrap
			row.value = value
		"cycle":
			var values: Array = row.options.map(func(o): return o[0])
			var at := values.find(row.value)
			row.value = values[posmod(at + direction, values.size())]
		"switch":
			row.value = not bool(row.value)
		_:
			return false
	_refresh_value(row);_play(SND_CONFIRM, -14.0, 0.92)
	value_changed.emit(row.id, row.value)
	return true

func _refresh_value(row: Dictionary) -> void:
	if row.value_label == null:return
	match row.kind:
		"slider":row.value_label.text = "%d" % int(row.value)
		"switch":row.value_label.text = "On" if row.value else "Off"
		"cycle":
			for option in row.options:
				if option[0] == row.value:row.value_label.text = option[1]

func _next_enabled(from: int, direction: int) -> int:
	for step in range(1, rows.size() + 1):
		var index := posmod(from + direction * step, rows.size())
		if rows[index].enabled:return index
	return from

## Focus is not colour alone: a solid marker bar, a 2 px outline and an 8 px text offset.
func _show_focus(animate: bool) -> void:
	for i in rows.size():
		var node: Button = rows[i].node
		var focused := i == focus_index
		var style := StyleBoxFlat.new()
		style.bg_color = COL_FOCUS_FILL if focused else Color(0, 0, 0, 0)
		style.content_margin_left = ROW_INSET + (FOCUS_OFFSET if focused else 0.0)
		if focused:
			style.border_color = COL_FOCUS;style.set_border_width_all(2)
		for state in ["normal", "hover", "pressed", "focus"]:node.add_theme_stylebox_override(state, style)
	if focus_index < 0:return
	_marker.visible = true
	var target: Vector2 = _marker_target()
	if _marker_tween:_marker_tween.kill()
	if animate and is_inside_tree():
		_marker_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_marker_tween.tween_property(_marker, "position", target, FOCUS_MOVE)
	else:
		_marker.position = target

func _marker_target() -> Vector2:
	var node: Control = rows[focus_index].node
	var at := node.get_global_rect().position - get_global_rect().position
	return Vector2(at.x - MARKER_GAP, at.y + (ROW_HEIGHT - MARKER_SIZE.y) / 2.0)

func _panel_rest_y() -> float:
	return maxf(0.0, (size.y - _panel.size.y) / 2.0)

## Centres the panel on the screen; its height follows the rows.
func _center_panel() -> void:
	_panel.reset_size()
	_panel.position = Vector2(maxf(0.0, (size.x - _panel.size.x) / 2.0), _panel_rest_y())

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _panel and (_tween == null or not _tween.is_running()):
		_center_panel()
		if focus_index >= 0:_show_focus(false)

func _run_tween(alpha: float, panel_y: float, duration: float, ease_type: Tween.EaseType) -> void:
	if _tween:_tween.kill()
	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(ease_type)
	_tween.tween_property(self, "modulate:a", alpha, duration)
	_tween.tween_property(_panel, "position:y", panel_y, duration)

func _play_focus() -> void:
	var now := Time.get_ticks_msec()
	if now - _last_focus_sound_ms < FOCUS_SOUND_GAP_MS:return
	_last_focus_sound_ms = now
	_play(SND_FOCUS, -18.0, 1.06)

func _back_sound() -> AudioStream:
	return load(SND_BACK_PATH) if ResourceLoader.exists(SND_BACK_PATH) else SND_CONFIRM

func _play(stream: AudioStream, volume_db: float, pitch: float) -> void:
	if not is_inside_tree():return
	var player: AudioStreamPlayer = _players.get(stream)
	if player == null:
		player = AudioStreamPlayer.new();player.stream = stream;player.bus = "Combat"   # Effects bus
		add_child(player);_players[stream] = player
	player.volume_db = volume_db;player.pitch_scale = pitch;player.play()
